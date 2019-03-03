/* Create a map of all the sectors to load */

#include <iostream>
#include <string>
#include <vector>
using namespace std;

#include <stdio.h>

#define _DEBUG_ 0
#define SUCCESS 0
#define FAILURE 1

#define VERSION "e2u3map 0.1a by Dave Poirier"
#if _DEBUG_
  #define DEBUG(x) printf x
#else
  #define DEBUG(x) ;
#endif

string filetomap;
string device;


FILE *device_fp;

int error = 0;

typedef unsigned char	__u8;
typedef signed char	__s8;
typedef unsigned short	__u16;
typedef signed short	__s16;
typedef unsigned int	__u32;
typedef signed int	__s32;

#define EXT2_NAME_LEN 255

struct ext2_group_desc
{
  __u32   bg_block_bitmap;                /* Blocks bitmap block */
  __u32   bg_inode_bitmap;                /* Inodes bitmap block */
  __u32   bg_inode_table;         /* Inodes table block */
  __u16   bg_free_blocks_count;   /* Free blocks count */
  __u16   bg_free_inodes_count;   /* Free inodes count */
  __u16   bg_used_dirs_count;     /* Directories count */
  __u16   bg_pad;
  __u32   bg_reserved[3];
};
ext2_group_desc *group_desc;
#define EXT2_MAGIC		0xEF53
#define EXT2_BAD_INO             1      /* Bad blocks inode */
#define EXT2_ROOT_INO            2      /* Root inode */
#define EXT2_ACL_IDX_INO         3      /* ACL inode */
#define EXT2_ACL_DATA_INO        4      /* ACL inode */
#define EXT2_BOOT_LOADER_INO     5      /* Boot loader inode */
#define EXT2_UNDEL_DIR_INO       6      /* Undelete directory inode */
#define EXT2_GOOD_OLD_FIRST_INO 11
#define EXT2_NDIR_BLOCKS                12
#define EXT2_IND_BLOCK                  EXT2_NDIR_BLOCKS
#define EXT2_DIND_BLOCK                 (EXT2_IND_BLOCK + 1)
#define EXT2_TIND_BLOCK                 (EXT2_DIND_BLOCK + 1)
#define EXT2_N_BLOCKS                   (EXT2_TIND_BLOCK + 1)
#define EXT2_SECRM_FL                   0x00000001 /* Secure deletion */
#define EXT2_UNRM_FL                    0x00000002 /* Undelete */
#define EXT2_COMPR_FL                   0x00000004 /* Compress file */
#define EXT2_SYNC_FL                    0x00000008 /* Synchronous updates */
#define EXT2_IMMUTABLE_FL               0x00000010 /* Immutable file */
#define EXT2_APPEND_FL                  0x00000020 /* writes to file may only append */
#define EXT2_NODUMP_FL                  0x00000040 /* do not dump file */
#define EXT2_NOATIME_FL                 0x00000080 /* do not update atime */
/* Reserved for compression usage... */
#define EXT2_DIRTY_FL                   0x00000100
#define EXT2_COMPRBLK_FL                0x00000200 /* One or more compressed clusters */
#define EXT2_NOCOMP_FL                  0x00000400 /* Don't compress */
#define EXT2_ECOMPR_FL                  0x00000800 /* Compression error */
/* End compression flags --- maybe not all used */
#define EXT2_BTREE_FL                   0x00001000 /* btree format dir */
#define EXT2_RESERVED_FL                0x80000000 /* reserved for ext2 lib */

#define EXT2_FL_USER_VISIBLE            0x00001FFF /* User visible flags */
#define EXT2_FL_USER_MODIFIABLE         0x000000FF /* User modifiable flags */
#define EXT2_S_IFMT			0xF000
#define EXT2_S_IFIFO			0x1000
#define EXT2_S_IFCHR			0x2000
#define EXT2_S_IFDIR			0x4000
#define EXT2_S_IFBLK			0x6000
#define EXT2_S_IFREG			0x8000
#define EXT2_S_IFSOCK			0xA000
#define EXT2_S_IFLNK			0xC000
struct ext2_inode {
  __u16   i_mode;         /* File mode */
  __u16   i_uid;          /* Low 16 bits of Owner Uid */
  __u32   i_size;         /* Size in bytes */
  __u32   i_atime;        /* Access time */
  __u32   i_ctime;        /* Creation time */
  __u32   i_mtime;        /* Modification time */
  __u32   i_dtime;        /* Deletion Time */
  __u16   i_gid;          /* Low 16 bits of Group Id */
  __u16   i_links_count;  /* Links count */
  __u32   i_blocks;       /* Blocks count */
  __u32   i_flags;        /* File flags */
  union {
    struct {
      __u32  l_i_reserved1;
    } linux1;
    struct {
      __u32  h_i_translator;
    } hurd1;
    struct {
      __u32  m_i_reserved1;
    } masix1;
  } osd1;                         /* OS dependent 1 */
  __u32   i_block[EXT2_N_BLOCKS];/* Pointers to blocks */
  __u32   i_generation;   /* File version (for NFS) */
  __u32   i_file_acl;     /* File ACL */
  __u32   i_dir_acl;      /* Directory ACL */
  __u32   i_faddr;        /* Fragment address */
  union {
    struct {
      __u8    l_i_frag;       /* Fragment number */
      __u8    l_i_fsize;      /* Fragment size */
      __u16   i_pad1;
      __u16   l_i_uid_high;   /* these 2 fields    */
      __u16   l_i_gid_high;   /* were reserved2[0] */
      __u32   l_i_reserved2;
    } linux2;
    struct {
      __u8    h_i_frag;       /* Fragment number */
      __u8    h_i_fsize;      /* Fragment size */
      __u16   h_i_mode_high;
      __u16   h_i_uid_high;
      __u16   h_i_gid_high;
      __u32   h_i_author;
    } hurd2;
    struct {
      __u8    m_i_frag;       /* Fragment number */
      __u8    m_i_fsize;      /* Fragment size */
      __u16   m_pad1;
      __u32   m_i_reserved2[2];
    } masix2;
  } osd2;                         /* OS dependent 2 */
};
ext2_inode inode;

#define EXT2_VALID_FS                   0x0001  /* Unmounted cleanly */
#define EXT2_ERROR_FS                   0x0002  /* Errors detected */
struct ext2_super_block {
  __u32   s_inodes_count;         /* Inodes count */
  __u32   s_blocks_count;         /* Blocks count */
  __u32   s_r_blocks_count;       /* Reserved blocks count */
  __u32   s_free_blocks_count;    /* Free blocks count */
  __u32   s_free_inodes_count;    /* Free inodes count */
  __u32   s_first_data_block;     /* First Data Block */
  __u32   s_log_block_size;       /* Block size */
  __s32   s_log_frag_size;        /* Fragment size */
  __u32   s_blocks_per_group;     /* # Blocks per group */
  __u32   s_frags_per_group;      /* # Fragments per group */
  __u32   s_inodes_per_group;     /* # Inodes per group */
  __u32   s_mtime;                /* Mount time */
  __u32   s_wtime;                /* Write time */
  __u16   s_mnt_count;            /* Mount count */
  __s16   s_max_mnt_count;        /* Maximal mount count */
  __u16   s_magic;                /* Magic signature */
  __u16   s_state;                /* File system state */
  __u16   s_errors;               /* Behaviour when detecting errors */
  __u16   s_minor_rev_level;      /* minor revision level */
  __u32   s_lastcheck;            /* time of last check */
  __u32   s_checkinterval;        /* max. time between checks */
  __u32   s_creator_os;           /* OS */
  __u32   s_rev_level;            /* Revision level */
  __u16   s_def_resuid;           /* Default uid for reserved blocks */
  __u16   s_def_resgid;           /* Default gid for reserved blocks */
  __u32   s_first_ino;            /* First non-reserved inode */
  __u16   s_inode_size;           /* size of inode structure */
  __u16   s_block_group_nr;       /* block group # of this superblock */
  __u32   s_feature_compat;       /* compatible feature set */
  __u32   s_feature_incompat;     /* incompatible feature set */
  __u32   s_feature_ro_compat;    /* readonly-compatible feature set */
  __u8    s_uuid[16];             /* 128-bit uuid for volume */
  char    s_volume_name[16];      /* volume name */
  char    s_last_mounted[64];     /* directory where last mounted */
  __u32   s_algorithm_usage_bitmap; /* For compression */
  __u8    s_prealloc_blocks;      /* Nr of blocks to try to preallocate*/
  __u8    s_prealloc_dir_blocks;  /* Nr to preallocate for dirs */
  __u16   s_padding1;
  __u32   s_reserved[204];        /* Padding to the end of the block */
};
ext2_super_block super_block;

#define EXT2_OS_LINUX           0
#define EXT2_OS_HURD            1
#define EXT2_OS_MASIX           2
#define EXT2_OS_FREEBSD         3
#define EXT2_OS_LITES           4
#define EXT2_OS_LAST		4
char *osnames[] = {
  "Linux",
  "Hurd",
  "Masix",
  "FreeBSD",
  "Lites",
  "Other"
};
#define EXT2_GOOD_OLD_REV       0       /* The good old (original) format */
#define EXT2_DYNAMIC_REV        1       /* V2 format w/ dynamic inode sizes */
#define EXT2_GOOD_OLD_INODE_SIZE 128
struct ext2_dir_entry {
  __u32   inode;                  /* Inode number */
  __u16   rec_len;                /* Directory entry length */
  __u8    name_len;               /* Name length */
  __u8    padding;
  char    name[EXT2_NAME_LEN];    /* File name */
};
ext2_dir_entry dir_entry;


__u32	block_size;
__u32	inodes_per_block;
__u32	blocks_per_group;
__u32	itb_per_group;

vector<__u32> blocks;
vector<ext2_group_desc> groups;

void show_version(void)
{
  static int shown = 0;
  
  if( shown == 0 )
    cout << VERSION << endl;
  shown++;
}

void show_help(void)
{
  static int shown = 0;

  if( shown == 0 )
  {
    show_version();
    cout << "Usage  : e2u3map -ffilename -ddevice" << endl;
    cout << "example: e2u3map -fu3core.amp -d/dev/fd0" <<endl;
  }
  shown++;
}

ext2_group_desc *get_group(__u32 group )
{
  ext2_group_desc *gdesc = new ext2_group_desc;
  DEBUG(("reading group descriptor %i\n", group ));
  if( fseek( device_fp, (group*sizeof(ext2_group_desc))+2048, SEEK_SET)
      || (fread( gdesc, sizeof(ext2_group_desc),1,device_fp) != 1) )
  {
    DEBUG(("failed reading group descriptor %i\n", group));
    delete gdesc;
    return NULL;
  }
  return gdesc;
}

int calc_e2sb_info(void)
{
  __u32 groups_count;

  DEBUG(("reading superblock info\n"));
  if( fseek( device_fp, 1024, SEEK_SET )
      || (fread( &super_block, sizeof(super_block), 1, device_fp ) != 1)
      || (super_block.s_magic != EXT2_MAGIC )
    )
    return FAILURE;

  DEBUG(("super block info read, computing basic info\n"));
  block_size = 1024 << super_block.s_log_block_size;
  DEBUG(("block size is %i\n", block_size));
  inodes_per_block = block_size / sizeof(inode);
  DEBUG(("inodes per block %i\n", inodes_per_block ));
  groups_count = super_block.s_blocks_count / super_block.s_blocks_per_group;
  if( (super_block.s_blocks_count % super_block.s_blocks_per_group) )
    groups_count++;
  DEBUG(("groups count %i\n", groups_count ));
  while( groups_count-- )
  {
    group_desc = get_group(groups_count);
    if( !group_desc ) return FAILURE;
    groups.push_back(*group_desc);
  }
  DEBUG(("ext2 calc completed, %i groups loaded.\n", groups.size()));
  return SUCCESS;
}

int get_inode( __u32 inode_id )
{
  __u32 group_id;
  inode_id--;

  DEBUG(("trying to acquire inode id %i\n", inode_id));
  group_id = inode_id / super_block.s_inodes_per_group;
  if( group_id > groups.size() ) return FAILURE;

  if( fseek( device_fp, (groups[group_id].bg_inode_table*block_size)+(sizeof(ext2_inode)*(inode_id % super_block.s_inodes_per_group)), SEEK_SET)
      || (fread( &inode, sizeof(ext2_inode), 1, device_fp) != 1) )
    return FAILURE;
  DEBUG(("inode id %i acquired\n", inode_id));
  DEBUG(("inode mode: %02X\n",(inode.i_mode & EXT2_S_IFMT)>>12 ));
  return SUCCESS;
}

__u32 *buffer_ind = NULL;
__u32 ind_id = 0;
__u32 *buffer_bind = NULL;
__u32 bind_id = 0;
__u32 *buffer_tind = NULL;
__u32 tind_id = 0;

__u32 block_id2offset( __u32 block_id )
{
  if( block_id < EXT2_NDIR_BLOCKS )
  {
    DEBUG(("converted block id: %i to offset: %08X\n", block_id, inode.i_block[block_id] * block_size));
    return inode.i_block[block_id] * block_size;
  }

  if( !buffer_ind )
  {
    buffer_ind = (__u32 *)malloc(block_size);
    if( !buffer_ind )
      return 0;
  }
  block_id -= EXT2_NDIR_BLOCKS;
  if( block_id < (block_size/4) )
  {
    if( ind_id != inode.i_block[EXT2_IND_BLOCK] )
    {
      __u32 ind_offset = inode.i_block[EXT2_IND_BLOCK] * block_size;
      DEBUG(("Loading IND block-table at %08X\n", ind_offset));
      if( (ind_offset == 0)
	  || fseek( device_fp, ind_offset, SEEK_SET )
	  || (fread( buffer_ind, block_size, 1, device_fp ) != 1 )
	)
	return FAILURE;
    }
    return buffer_ind[block_id] * block_size;
  }
  else
  {
    DEBUG(("bind/tind not done! finish me!\n"));
  }
    
  return 0;
}

int read_file( __u32 offset, __u32 *size, __u32 minsize, void *buftmp )
{
  __u32 copyoffset;
  __u32 sizeinblock;
  __u32 sizeleft;
  __u32 block_id;
  __u32 devoffset;
  __u8  *buffer = (__u8 *)buftmp;

  DEBUG(("read file called with: %08X %08X %08X %p\n", offset, *size, minsize, buffer));
  if( (offset + *size) > inode.i_size ) *size = inode.i_size - offset;
  if( *size < minsize)
  {
    DEBUG(("not enough data in file: %i to perform minimum requested read: %i\n", *size, minsize));
    return FAILURE;
  }

  sizeleft = *size;

  while( sizeleft != 0 )
  {
    block_id = offset / block_size;
    copyoffset = offset % block_size;
    sizeinblock = block_size - copyoffset;
    if( sizeinblock > sizeleft ) sizeinblock = sizeleft;
    sizeleft -= sizeinblock;

    devoffset = block_id2offset( block_id );
    if( devoffset == 0 )
      return FAILURE;

    DEBUG(("reading %i bytes starting at %08x in device\n", sizeinblock, (devoffset+copyoffset)));
    if( fseek( device_fp, devoffset + copyoffset, SEEK_SET )
      || (fread( buffer, sizeinblock, 1, device_fp ) != 1)
      )
      return FAILURE;
    buffer += sizeinblock;
    offset += sizeinblock;
  }
  return SUCCESS;
}

int find_dir_entry(string & name)
{
  __u32 offset = 0;
  __u32 size;

  if( (inode.i_mode & EXT2_S_IFMT) != EXT2_S_IFDIR )
  {
    DEBUG(("find_dir_entry called for non-dir inode!\n"));
    return FAILURE;
  }

  DEBUG(("searching for: %s\n",name.c_str()));
  do
  {
    size = sizeof(ext2_dir_entry);
    if( read_file( offset, &size, size-EXT2_NAME_LEN+1, &dir_entry) )
    {
      DEBUG(("couldn't locate name requested.\n"));
      return FAILURE;
    }
    offset += dir_entry.rec_len;
    dir_entry.name[dir_entry.name_len] = '\0';
    DEBUG(("comparing [%s] against len: %i [%s]\n", name.c_str(), dir_entry.name_len, &dir_entry.name[0]));
  } while( name != &dir_entry.name[0] );  
  DEBUG(("match found!"));
  return SUCCESS;
}

int find_file_inode(void)
{
  string path = filetomap.c_str();
  string dirname = "";
  __u32 inode_id = EXT2_ROOT_INO;


  do
  {
    if( path.substr(0,1) == "/" )
    {
      path.erase(0,1);
    }
    DEBUG(("path is: %s\n", path.c_str()));
    if( get_inode( inode_id )
	|| ((inode.i_mode & EXT2_S_IFMT) != EXT2_S_IFDIR )
      )
    {
      cerr << "Invalid path in provided filename: " << filetomap <<endl;
      error++;
      return FAILURE;
    }
    
    dirname = path.substr(0,path.find("/",1));
    path.erase(0,dirname.length());
    DEBUG(("searching for directory entry: %s\n", dirname.c_str()));
    if( find_dir_entry(dirname) )
    {
      cerr << "Couldn't locate requested filename on specified device: " << filetomap <<endl;
      error++;
      return FAILURE;
    }

    inode_id = dir_entry.inode;
  } while( path.length() != 0 );

  if( get_inode( inode_id )
      || ((inode.i_mode & EXT2_S_IFMT) != EXT2_S_IFREG )
    )
  {
    cerr << "Filename specified does not point to a file: " << filetomap <<endl;
    error++;
    return FAILURE;
  }
  
  return SUCCESS;
}

__u32 loadmap[128], *loadmap_ptr=&loadmap[0];

int gen_block_list(void)
{
  __u32 filesize = inode.i_size;
  __u32 block_id = 0;
  __u32 blockloc = 0;

  while( 1 )
  {
    blockloc = block_id2offset( block_id++ );
    if( blockloc == 0 )
      return FAILURE;
    blockloc = blockloc >> 9;
    printf("blockloc: %08X...\n", blockloc );
    blocks.push_back( blockloc );
    if( filesize <= block_size ) break;
    filesize -= block_size;
  }

  DEBUG(("%i blocks listed. generating load table\n",blocks.size()));
  
  if( blocks.size() > 127 )
    return FAILURE;

  for(unsigned i=0; i<blocks.size(); i++)
  {
    *++loadmap_ptr = blocks[i];
  }
  loadmap[0] = blocks.size() | (block_size >> 1);
  return SUCCESS;
}

void map_file(void)
{
  cout << "mapping  : " << filetomap <<endl;
  cout << "on device: " << device <<endl;

  device_fp = fopen(device.c_str(), "r+b");
  if( !device_fp )
  {
    error++;
    cerr << "Unable to open device for read/write: " << device <<endl;
    return;
  }

  if( calc_e2sb_info()
      || find_file_inode()
      || gen_block_list()
      || fseek( device_fp, 512, SEEK_SET )
      || (fwrite( loadmap, 512, 1, device_fp ) != 1 )
    ) return;
  DEBUG(("loadmap written on disk\n"));
}


int main(int argc, char **argv)
{
  int procargs = 1;
  int processed;

  filetomap = "u3core.bin";
  device = "/dev/fd0";
  while( procargs && --argc )
  {
    processed = 0;
    if( argv[argc][0] == '-')
    {
      switch ( argv[argc][1] )
      {
	case 'd':
	  device = &argv[argc][2];
	  processed++;
	  break;
	case 'f':
	  filetomap = &argv[argc][2];
	  processed++;
	  break;
	case 'v':
	  show_version();
	  procargs = 0;
	  processed++;
	  break;
	case 'h':
	  show_help();
	  procargs = 0;
	  processed++;
	  break;
      }
    }
    if( processed == 0)
    {
      cerr << "Unknown option: " << argv[argc] <<endl;
      error++;
    }
  }
  if( error == 0 )
  {
    map_file();
  }
  else
    show_help();

  if( device_fp ) fclose(device_fp);
  return error;
}

