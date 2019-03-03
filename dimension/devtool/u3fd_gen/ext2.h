typedef unsigned char   __u8;
typedef signed char     __s8;
typedef unsigned short  __u16;
typedef signed short    __s16;
typedef unsigned int    __u32;
typedef signed int      __s32;


#define EXT2_OS_LINUX           0
#define EXT2_OS_HURD            1
#define EXT2_OS_MASIX           2
#define EXT2_OS_FREEBSD         3
#define EXT2_OS_LITES           4
#define EXT2_OS_LAST            4

#define EXT2_GOOD_OLD_REV       0       /* The good old (original) format */
#define EXT2_DYNAMIC_REV        1       /* V2 format w/ dynamic inode sizes */

#define EXT2_GOOD_OLD_INODE_SIZE	128
#define EXT2_VALID_FS                   0x0001  /* Unmounted cleanly */
#define EXT2_ERROR_FS                   0x0002  /* Errors detected */
#define EXT2_MAGIC              	0xEF53

#define EXT2_ERRORS_CONTINUE		1 /* continue as if nothing happened */
#define EXT2_ERRORS_RO			2 /* remount read-only */
#define EXT2_ERRORS_PANIC		3 /* cause a kernel panic */
#define EXT2_ERRORS_DEFAULT		EXT2_ERRORS_RO

#define EXT2_BAD_INO             1      /* Bad blocks inode */
#define EXT2_ROOT_INO            2      /* Root inode */
#define EXT2_ACL_IDX_INO         3      /* ACL inode */                         #define EXT2_ACL_DATA_INO        4      /* ACL inode */
#define EXT2_BOOT_LOADER_INO     5      /* Boot loader inode */
#define EXT2_UNDEL_DIR_INO       6      /* Undelete directory inode */
#define EXT2_GOOD_OLD_FIRST_INO 11

#define EXT2_NDIR_BLOCKS		12
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

#define EXT2_S_IFMT                     0xF000
#define EXT2_S_IFIFO                    0x1000
#define EXT2_S_IFCHR                    0x2000
#define EXT2_S_IFDIR                    0x4000
#define EXT2_S_IFBLK                    0x6000
#define EXT2_S_IFREG                    0x8000
#define EXT2_S_IFSOCK                   0xA000
#define EXT2_S_IFLNK                    0xC000
#define EXT2_S_IRUSR			0x0100
#define EXT2_S_IWUSR			0x0080
#define EXT2_S_IXUSR			0x0040
#define EXT2_S_IRGRP			0x0020
#define EXT2_S_IWGRP			0x0010
#define EXT2_S_IXGRP			0x0008
#define EXT2_S_IROTH			0x0004
#define EXT2_S_IWOTH			0x0002
#define EXT2_S_IXOTH			0x0001

#define EXT2_FT_UNKNOWN			0x00
#define EXT2_FT_REG_FILE		0x01
#define EXT2_FT_DIR			0x02
#define EXT2_FT_CHRDEV			0x03
#define EXT2_FT_BLKDEV			0x04
#define EXT2_FT_FIFO			0x05
#define EXT2_FT_SOCK			0x06
#define EXT2_FT_SYMLINK			0x07
#define EXT2_FT_MAX			0x08

#define EXT2_NAME_LEN			255

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

struct ext2_group_desc {
  __u32   bg_block_bitmap;                /* Blocks bitmap block */
  __u32   bg_inode_bitmap;                /* Inodes bitmap block */
  __u32   bg_inode_table;         /* Inodes table block */
  __u16   bg_free_blocks_count;   /* Free blocks count */
  __u16   bg_free_inodes_count;   /* Free inodes count */
  __u16   bg_used_dirs_count;     /* Directories count */
  __u16   bg_pad;
  __u32   bg_reserved[3];
};

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

struct ext2_dir_entry {
  __u32   inode;                  /* Inode number */
  __u16   rec_len;                /* Directory entry length */
  __u8    name_len;               /* Name length */
  __u8    padding;
  char    name[EXT2_NAME_LEN];    /* File name */
};

