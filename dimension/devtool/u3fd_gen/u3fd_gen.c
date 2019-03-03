#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>

#include "ext2.h"
#include "boot.h"

#define VERSION "1.2.1"
#define DIR_SEPARATOR "/"

#define GROUP_DESC(x)	((struct ext2_group_desc *)(&img[(BLOCKSIZE*2)+(sizeof(struct ext2_group_desc)*x)]))
#define SUPERBLOCK()	((struct ext2_super_block *)&img[1024])
#define BLOCK_BITMAP(x)	((unsigned char *)&img[x->bg_block_bitmap * BLOCKSIZE])
#define INODE_BITMAP(x)	((unsigned char *)&img[x->bg_inode_bitmap * BLOCKSIZE])
#define INODE_TABLE(x)	((struct ext2_inode *)&img[x->bg_inode_table * BLOCKSIZE])
#define INODE(x)	(&INODE_TABLE(GROUP_DESC(0))[x-1])
#define BLOCK(x)	(&img[BLOCKSIZE * x])


#define BLOCKSIZE	1024
#define INODES		184
#define BLOCKS		1440


unsigned char img[1474560];
struct ext2_super_block *sb = SUPERBLOCK();

void add_directory_entry(
    unsigned char *name,
    unsigned int parent_inode_id,
    unsigned int inode_id );
void create_bitmap(
    unsigned char *bitmap,
    unsigned int total_bits);
unsigned int create_directory(
    char *name,
    unsigned int parent_inode_id,
    unsigned int inode_id );
unsigned int create_file(
    struct stat *file_stat,
    char *filepath,
    char *filename,
    unsigned int parent_inode_id,
    unsigned int inode_id );
void create_groups(
    void);
void create_superblock(
    void);
unsigned int find_inode(
    char *name,
    unsigned int parent_inode );
unsigned int get_free_block(
    void);
unsigned int get_free_inode(
    void);
void map_boot_file(
    char *filename );
void process_directory(
    unsigned int parent_inode_id,
    char *source_directory );
void read_image_file(
    unsigned char *dir,
    struct ext2_inode *inode );
void write_image_file(
    unsigned char *dir,
    struct ext2_inode *inode );



int main( int argc, char **argv ) {
  FILE *img_fp = NULL;

  if( argc != 4 ) {
    puts("U3FD-GEN version " VERSION);
    puts("Usage: u3fd_gen <image name> <path to files> <kernel relative to path>");
    exit(0);
  }

  create_superblock();
  create_groups();
  create_directory( NULL, EXT2_ROOT_INO, EXT2_ROOT_INO );
  create_directory( "lost+found", EXT2_ROOT_INO, 0 );
  process_directory( EXT2_ROOT_INO, argv[2] );
  map_boot_file( argv[3] );

  memcpy(img,boot_record,512);
  img_fp = fopen(argv[1],"wb");
  if( img_fp == NULL ) {
    fprintf(stderr,"Unable to create output file: ");
    perror(argv[1]);
    exit(-1);
  }

  if( fwrite(img,1474560,1,img_fp) != 1 ) {
    fprintf(stderr,"Write failed on output file: ");
    perror(argv[1]);
    fclose(img_fp);
    exit(-1);
  }

  fclose(img_fp);
  return 0;
}




void add_directory_entry(
    unsigned char *name,
    unsigned int parent_inode_id,
    unsigned int inode_id )
{
  struct ext2_inode *inode = INODE(parent_inode_id);
  unsigned char *dir = (unsigned char *)malloc(inode->i_size);
  struct ext2_dir_entry *dir_entry = NULL;
  unsigned char *p_dir = dir;

  read_image_file(dir,inode);

  do {
    dir_entry = (struct ext2_dir_entry *)p_dir;
    if( dir_entry->rec_len > (dir_entry->name_len + 11) ) {
      struct ext2_dir_entry *new_dir_entry	=
	(struct ext2_dir_entry *)(&p_dir[(dir_entry->name_len + 11) & ~3]);
      new_dir_entry->rec_len		= dir_entry->rec_len;
      dir_entry->rec_len		= (dir_entry->name_len + 11) & ~3;
      new_dir_entry->rec_len		-= dir_entry->rec_len;
      new_dir_entry->name_len		= strlen(name);
      new_dir_entry->inode		= inode_id;
      new_dir_entry->padding		= 0;
      strcpy(&new_dir_entry->name[0],name);
      break;
    }
    p_dir += dir_entry->rec_len;
  } while( p_dir < &dir[inode->i_size] );

  write_image_file(dir,inode);
  free(dir);
}




void allocate_file_blocks(
    struct ext2_inode *inode )
{
  unsigned int blocks = inode->i_blocks / (BLOCKSIZE/512);
  unsigned int count = 0;

  if( blocks > SUPERBLOCK()->s_free_blocks_count ) {
    printf("%i: not enough space left on device\n",__LINE__);
    return;
  }

  while( blocks != 0 ) {

    inode->i_block[count++] = get_free_block();

    blocks--;
    if( count == EXT2_NDIR_BLOCKS )
      break;
  }

  if( blocks != 0 ) {
    unsigned int *ind = (unsigned int *)BLOCK((inode->i_block[EXT2_IND_BLOCK] = get_free_block()));
    unsigned int *dind = NULL;
    inode->i_blocks += BLOCKSIZE/512;

    while( blocks != 0 ) {
      count = 0;
      
      while( blocks != 0 ) {
	
	ind[count++] = get_free_block();

	blocks--;
	if( count == BLOCKSIZE / 4 )
	  break;
      }

      if( blocks != 0 ) {
	if( dind == NULL ) {
	  dind = (unsigned int *)BLOCK((inode->i_block[EXT2_DIND_BLOCK] = get_free_block()));
	  inode->i_blocks += BLOCKSIZE/512;
	}
	
	ind = (unsigned int *)BLOCK((*dind++ = get_free_block()));
	inode->i_blocks += BLOCKSIZE/512;
      }
    }
  }
}




void create_bitmap(
    unsigned char *bitmap,
    unsigned int total_bits )
{
  unsigned char bitmask = 0xFF;
  unsigned int i;

  for(i = 0; i < BLOCKSIZE; i++ )
    bitmap[i] = bitmask;

  bitmask = 0x00;
  while( total_bits > 8 ) {
    total_bits -= 8;
    *bitmap++ = bitmask;
  }
  bitmask = 0xFF;
  while( total_bits-- )
    bitmask = bitmask << 1;
  *bitmap = bitmask;
}




unsigned int create_directory(
    char *name,
    unsigned int parent_inode_id,
    unsigned int inode_id )
{
  struct ext2_inode *inode;
  struct ext2_dir_entry *dir;
  
  printf("creating new directory: %s\n",name);
  if( inode_id == 0 )
    inode_id = get_free_inode();
  
  inode = INODE(inode_id);
  inode->i_mode =
    EXT2_S_IFDIR
    | EXT2_S_IRUSR
    | EXT2_S_IWUSR
    | EXT2_S_IRGRP
    | EXT2_S_IWGRP
    | EXT2_S_IROTH;
//  inode->i_uid			= 0;
  inode->i_size			= BLOCKSIZE;
//  inode->i_atime		= 0;
//  inode->i_ctime		= 0;
//  inode->i_mtime		= 0;
//  inode->i_dtime		= 0;
//  inode->i_gid			= 0;
  inode->i_links_count		= 2;
  inode->i_blocks		= BLOCKSIZE / 512;
//  inode->i_flags		= 0;
  inode->i_block[0]		= get_free_block();
  
  dir = (struct ext2_dir_entry *)BLOCK(inode->i_block[0]);
  dir->inode = inode_id;
  dir->rec_len = 12;
  dir->name_len = 1;
  dir->name[0] = '.';
  
  dir = (struct ext2_dir_entry *)(&BLOCK(inode->i_block[0])[12]);
  dir->inode = parent_inode_id;
  dir->rec_len = BLOCKSIZE - 12;
  dir->name_len = 2;
  dir->name[0] = '.';
  dir->name[1] = '.';

  GROUP_DESC(0)->bg_used_dirs_count++;
  if( inode_id != parent_inode_id ) {
    add_directory_entry(name, parent_inode_id, inode_id);
    INODE(parent_inode_id)->i_links_count++;
  }
  return(inode_id);
}




unsigned int create_file(
    struct stat *file_stat,
    char *filepath,
    char *filename,
    unsigned int parent_inode_id,
    unsigned int inode_id )
{
  struct ext2_inode *inode;
  unsigned int blocks =
    file_stat->st_size % BLOCKSIZE ?
    file_stat->st_size / BLOCKSIZE + 1 :
    file_stat->st_size / BLOCKSIZE;
  FILE *source_fp = NULL;
  char *buffer = (char *)malloc(blocks * BLOCKSIZE);

  if( buffer == NULL ) {
    perror("out of memory!\n");
    return 0;
  }

  printf("creating new file: %s\n",filename);
  if( inode_id == 0 )
    inode_id = get_free_inode();

  inode = INODE(inode_id);
  inode->i_mode				=
    EXT2_S_IFREG |
    EXT2_S_IRUSR |
    EXT2_S_IWUSR |
    EXT2_S_IRGRP |
    EXT2_S_IWGRP |
    EXT2_S_IROTH;
  inode->i_size				= file_stat->st_size;
  inode->i_links_count			= 1;
  inode->i_blocks			= blocks * (BLOCKSIZE/512);

  allocate_file_blocks( inode );
  source_fp = fopen(filepath,"rb");
  if( source_fp == NULL
      || fread(buffer,file_stat->st_size,1,source_fp) != 1 ) {
    if( source_fp != NULL )
      fclose( source_fp );
    perror(filepath);
    free(buffer);
    return 0;
  }
  fclose(source_fp);

  write_image_file(buffer,inode);
  add_directory_entry( filename, parent_inode_id, inode_id );
  free(buffer);
  return( inode_id );
}




void create_groups(void)
{
  struct ext2_group_desc *desc = GROUP_DESC(0);
  unsigned int i;

  printf("creating groups\n");

  desc->bg_block_bitmap = 3;
  desc->bg_inode_bitmap = 4;
  desc->bg_inode_table = 5;
  desc->bg_free_blocks_count = BLOCKS - 1;
  desc->bg_free_inodes_count = INODES;
  desc->bg_used_dirs_count = 0;

  create_bitmap( BLOCK_BITMAP(GROUP_DESC(0)), desc->bg_free_blocks_count);
  for(i = 0; i < 27; i++)
    get_free_block();
  create_bitmap( INODE_BITMAP(GROUP_DESC(0)), desc->bg_free_inodes_count);
  for(i = 0; i < EXT2_GOOD_OLD_FIRST_INO - 1; i++ )
    get_free_inode();
}




void create_superblock(void)
{
//  struct ext2_super_block *sb = (struct ext2_super_block *)&img[1024];
  struct ext2_super_block *sb = SUPERBLOCK();

  printf("creating superblock\n");
  sb->s_inodes_count			= INODES;
  sb->s_blocks_count			= BLOCKS;
  sb->s_r_blocks_count			= BLOCKS * 5 / 100;
  sb->s_free_inodes_count		= INODES;
  sb->s_free_blocks_count		= BLOCKS - 1;
  sb->s_first_data_block		= 1;
  sb->s_blocks_per_group		= 8192;
  sb->s_frags_per_group			= 8192;
  sb->s_inodes_per_group		= INODES;
  sb->s_max_mnt_count			= 30;
  sb->s_magic				= EXT2_MAGIC;
  sb->s_state				= EXT2_VALID_FS;
  sb->s_errors				= EXT2_ERRORS_RO;
  sb->s_checkinterval			= 0x00ED4E00;
  sb->s_creator_os			= EXT2_OS_LINUX;
  sb->s_rev_level			= EXT2_GOOD_OLD_REV;
}




unsigned int find_inode(
    char *name,
    unsigned int parent_inode_id )
{
  struct ext2_inode *inode = INODE( parent_inode_id );
  unsigned char *dir = (unsigned char *)malloc(inode->i_size);
  unsigned int offset = 0;
  unsigned int namelen = strlen(name);
  unsigned int inode_id = 0;
  struct ext2_dir_entry *dir_entry = NULL;
  read_image_file(dir, inode);

  do {
    dir_entry = (struct ext2_dir_entry *)&dir[offset];
    if( namelen == dir_entry->name_len
	&& strncmp( dir_entry->name, name, namelen ) == 0 ) {
      inode_id = dir_entry->inode;
      break;
    }

    offset += dir_entry->rec_len;
  } while( offset < inode->i_size );
  free( dir );

  if( inode_id == 0 )
    printf("%i: file/dir could not be located: %s\n", __LINE__,name);
  return( inode_id );
}






unsigned int get_free_block( void )
{
  unsigned char *bits = BLOCK_BITMAP(GROUP_DESC(0));
  unsigned char bitmask = 0x01;
  unsigned int  bit = 0;

  if( SUPERBLOCK()->s_free_blocks_count == 0
      || GROUP_DESC(0)->bg_free_blocks_count == 0
      ) {
    printf("no space left on disk image.");
    return 0;
  }

  while( *bits == 0xFF ) {
    bits++;
    bit += 8;
  }
  
  while( (bitmask & *bits) != 0 ) {
    bitmask = bitmask << 1;
    bit++;
  }
  *bits |= bitmask;
  
  SUPERBLOCK()->s_free_blocks_count --;
  GROUP_DESC(0)->bg_free_blocks_count --;
  return(bit + SUPERBLOCK()->s_first_data_block);
}




unsigned int get_free_inode( void )
{
  unsigned char *bits = INODE_BITMAP(GROUP_DESC(0));
  unsigned char bitmask = 0x01;
  unsigned int  bit = 0;

  if( SUPERBLOCK()->s_free_inodes_count == 0
      || GROUP_DESC(0)->bg_free_inodes_count == 0
      ) {
    printf("no free inode left on disk image.");
    return 0;
  }

  while( *bits == 0xFF ) {
    bits++;
    bit += 8;
  }
  
  while( (bitmask & *bits) != 0 ) {
    bitmask = bitmask << 1;
    bit++;
  }
  *bits |= bitmask;
  
  SUPERBLOCK()->s_free_inodes_count --;
  GROUP_DESC(0)->bg_free_inodes_count --;
  return(bit + 1);
}




void map_boot_file(
    char *filename )
{
  struct ext2_inode *inode;
  unsigned int blocks;
  unsigned int count = 0;
  unsigned int *boot_map = (unsigned int *)&img[512];
  unsigned int inode_id;
  inode_id = find_inode(
      filename,
      EXT2_ROOT_INO);
  if( inode_id == 0 )
    return;

  inode = INODE(inode_id);
  blocks = inode->i_blocks / (BLOCKSIZE/512);

  if( blocks > 127 ) {
    printf("%i: boot file is too large to be mapped\n",__LINE__);
    return;
  }

  *boot_map++ = ((BLOCKSIZE/512) << 8) | blocks;
  printf("generating boot file map for: %s\nLBA: ", filename);

  while( blocks != 0 ) {

    *boot_map = inode->i_block[count++] * (BLOCKSIZE/512);
    printf("%i ", *boot_map++);

    blocks--;
    if( count == EXT2_NDIR_BLOCKS )
      break;
  }

  if( blocks != 0 ) {
    unsigned int *ind = (unsigned int *)BLOCK(inode->i_block[EXT2_IND_BLOCK]);
    unsigned int *dind = NULL;
    img[512] --;
    blocks--;

    while( blocks != 0 ) {
      count = 0;
      
      while( blocks != 0 ) {
	
	*boot_map = ind[count++] * (BLOCKSIZE/512);
	printf("%i ", *boot_map++);

	blocks--;
	if( count == BLOCKSIZE / 4 )
	  break;
      }

      if( blocks != 0 ) {
	if( dind == NULL ) {
	  dind = (unsigned int *)BLOCK(inode->i_block[EXT2_DIND_BLOCK]);
	  img[512] --;
	  blocks--;
	}
	
	ind = (unsigned int *)BLOCK(*dind++);
	img[512] --;
	blocks--;
      }
    }
  }
  printf("\nsectors per block: %i, total blocks to load: %i\n", (BLOCKSIZE/512), img[512]);
}



void process_directory(
    unsigned int parent_inode_id,
    char *source_directory )
{

  DIR *source_dir;
  struct dirent *dir;
  char *filename = (char *)malloc(256);
  struct stat *file_stat = (struct stat *)malloc(sizeof(struct stat));

  source_dir = opendir( source_directory );
  if( source_dir == NULL ) {
    perror(source_directory);
    free( file_stat );
    free( filename );
    return;
  }

  while( (dir = readdir(source_dir)) != NULL ) {
    strcpy(filename,source_directory);
    strcat(filename,&dir->d_name[0]);
    stat(filename,file_stat);
    if( S_ISREG(file_stat->st_mode) ) {
      create_file(
	  file_stat,
	  filename,
	  dir->d_name,
	  parent_inode_id,
	  0 );
    } else if( S_ISDIR(file_stat->st_mode) ) {
      if( !(dir->d_name[0] == '.' && (
	      dir->d_name[1] == 0 || (
		dir->d_name[1] == '.' &&
		dir->d_name[2] == 0 )) )) {
	unsigned int dir_inode_id =
	  create_directory(
	      dir->d_name,
	      parent_inode_id,
	      0 );
	strcat(filename,DIR_SEPARATOR);
	process_directory(
	    dir_inode_id,
	    filename);
      }
    }
  }

  closedir( source_dir );
  free( filename );
  free( file_stat );
}




void read_image_file(
    unsigned char *dir,
    struct ext2_inode *inode )
{
  unsigned int blocks = inode->i_blocks / (BLOCKSIZE/512);
  unsigned int count = 0;

  while( blocks != 0 ) {

    memcpy(dir,BLOCK(inode->i_block[count++]),BLOCKSIZE);
    dir += BLOCKSIZE;

    blocks--;
    if( count == EXT2_NDIR_BLOCKS )
      break;
  }

  if( blocks != 0 ) {
    unsigned int *ind = (unsigned int *)BLOCK(inode->i_block[EXT2_IND_BLOCK]);
    unsigned int *dind = (unsigned int *)BLOCK(inode->i_block[EXT2_DIND_BLOCK]);

    while( blocks != 0 ) {
      count = 0;
      
      while( blocks != 0 ) {
	
	memcpy(dir,BLOCK(ind[count++]),BLOCKSIZE);
	dir += BLOCKSIZE;
	
	blocks--;
	if( count == BLOCKSIZE / 4 )
	  break;
      }
      ind = (unsigned int *)BLOCK(*dind++);
    }
  }
}





void write_image_file(
    unsigned char *dir,
    struct ext2_inode *inode )
{
  unsigned int blocks = inode->i_blocks / (BLOCKSIZE/512);
  unsigned int count = 0;

  while( blocks != 0 ) {

    memcpy(BLOCK(inode->i_block[count++]),dir,BLOCKSIZE);
    dir += BLOCKSIZE;

    blocks--;
    if( count == EXT2_NDIR_BLOCKS )
      break;
  }

  if( blocks != 0 ) {
    unsigned int *ind = (unsigned int *)BLOCK(inode->i_block[EXT2_IND_BLOCK]);
    unsigned int *dind = NULL;

    while( blocks != 0 ) {
      count = 0;
      blocks--;
      
      while( blocks != 0 ) {
	memcpy(BLOCK(ind[count++]),dir,BLOCKSIZE);
	dir += BLOCKSIZE;
	
	blocks--;
	if( count == BLOCKSIZE / 4 )
	  break;
      }

      if( dind == NULL )
	dind = (unsigned int *)BLOCK(inode->i_block[EXT2_DIND_BLOCK]);
      ind = (unsigned int *)BLOCK(*dind++);

    }
  }
}
