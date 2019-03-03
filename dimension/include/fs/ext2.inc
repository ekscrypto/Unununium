;;
;; Define EXT2_PREALLOCATE to preallocate data blocks for expanding files
;;
%define EXT2_PREALLOCATE
%define EXT2_DEFAULT_PREALLOC_BLOCKS 8

;;
;; Cache-options
;;
%define EXT2_MAX_GROUP_LOADED 8

;;
;; The Second Extended File System Version
;;
%define EXT2FS_DATE "95/08/09"
%define EXT2FS_VERSION "0.5b"

;;
;; Special inode numbers
;;
%define EXT2_BAD_INO		1	; Bad blocks inode
%define EXT2_ROOT_INO		2	; Root inode
%define EXT_ACL_IDX_INO		3	; ACL inode (Access control list)
%define EXT2_ACL_DATA_INO	4	; ACL inode
%define EXT2_BOOT_LOADER_INO	5	; Boot loader inode
%define EXT2_UNDEL_DIR_INO	6	; Undelete directory inode
%define EXT2_RESIZE_INO		7	; Reserved group descriptors inode
%define EXT2_JOURNAL_INO	8	; Journal inode

;;
;; First non-reserved inode for old ext2 filesystems
;;
%define EXT2_GOOD_OLD_FIRST_INO	11

;;
;; The second extended file system magic number
;;
%define EXT2_SUPER_MAGIC	0xEF53

;;
;; Maximal count of links to a file
;;
%define EXT2_LINK_MAX		32000

;;
;; Blocks
;;
%define EXT2_MIN_BLOCK_SIZE	1024
%define EXT2_MAX_BLOCK_SIZE	4096
%define EXT2_MIN_BLOCK_LOG_SIZE	10

;; Fragments
%define EXT2_MIN_FRAG_SIZE	1024
%define EXT2_MAX_FRAG_SIZE	4096
%define EXT2_MIN_FRAG_LOG_SIZE	10

;;
;; ACL structures
;;
	struc ext2_acl_header
.aclh_size		resd 1
.aclh_file_count	resd 1
.aclh_acle_count	resd 1
.aclh_first_acle	resd 1
	endstruc
	struc ext2_acl_entry
.acle_size		resd 1
.alce_perms		resw 1	; Access permissions
.acle_type		resw 1	; type of entry
.acle_tag		resw 1	; user or group identity
.acle_pad1		resw 1
.acle_next		resd 1	; pointer to next entry for the same inode
	endstruc		; or on next free entry

;;
;; Structure of a blocks group descriptor
;;
	struc ext2_group_desc
.bg_block_bitmap	resd 1	; Blocks bitmap block
.bg_inode_bitmap	resd 1	; Inodes bitmap block
.bg_inode_table		resd 1	; Inodes table block
.bg_free_blocks_count	resw 1	; Free blocks count
.bg_free_inodes_count	resw 1	; Free inodes count
.bg_used_dirs_count	resw 1	; Directories count
.bg_pad			resw 1
.bg_reserved		resd 3
	endstruc

;;
;; Constants relative to the data blocks
;;
%define EXT2_NDIR_BLOCKS	12
%define EXT2_IND_BLOCK		EXT2_NDIR_BLOCKS
%define EXT2_DIND_BLOCK		(EXT2_IND_BLOCK + 1)
%define EXT2_TIND_BLOCK		(EXT2_DIND_BLOCK + 1)
%define EXT2_N_BLOCKS		(EXT2_TIND_BLOCK + 1)

;;
;; Inode flags
;;
%define EXT2_SECRM_FL		0x00000001	; secure deletion
%define EXT2_UNRM_FL		0x00000002	; undelete
%define EXT2_COMPR_FL		0x00000004	; compress file
%define EXT2_SYNC_FL		0x00000008	; synchronous updates
%define EXT2_IMMUTABLE_FL	0x00000010	; immutable file
%define EXT2_APPEND_FL		0x00000020	; writes to file may only append
%define EXT2_NODUMP_FL		0x00000040	; do not dump file
%define EXT2_NOATIME_FL		0x00000080	; do not update atime
%define EXT2_DIRTY_FL		0x00000100	;
%define EXT2_COMPRBLK_FL	0x00000200	; >=1 compressed clusters
%define EXT2_NOCOMPR_FL		0x00000400	; Access raw comperssed data
%define EXT2_ECOMPR_FL		0x00000800	; Compression Error
%define EXT2_BTREE_FL		0x00001000	; btree format dir
%define EXT2_INDEX_FL		0x00001000	; hash-indexed directory
%define EXT2_IMAGIC_FL		0x00002000	;
%define EXT3_JOURNAL_DATA_FL	0x00004000	; file data should be journaled
%define EXT2_RESERVED_FL	0x80000000	; reserved for ext2 lib
%define EXT2_FL_USER_VISIBLE	0x00005FFF	; user visible flags
%define EXT2_FL_USER_MODIFIABLE	0x000000FF	; user modifiable flags

;;
;; Structure f an inode on the disk
;;
	struc ext2_inode
.i_mode		resw 1	; File mode
.i_uid		resw 1	; Low 16bits of Owner's UID
.i_size		resd 1	; Size in bytes
.i_atime	resd 1	; Access time
.i_ctime	resd 1	; Creation time
.i_mtime	resd 1	; Modification time
.i_dtime	resd 1	; Deletion time
.i_gid		resw 1	; Low 16bits of Group ID
.i_links_count	resw 1	; Links count
.i_blocks	resd 1	; Blocks count
.i_flags	resd 1	; File flags (see 'Inode flags')
.osd1		resd 1	; OS Dependant 1
.i_block	resd EXT2_N_BLOCKS	; Pointers to blocks
.i_generation	resd 1	; File version (for NFS)
.i_file_acl	resd 1	; File ACL (Access control list)
.i_dir_acl	resd 1	; Directory ACL (Access control list)
.i_faddr	resd 1	; Fragment address
.osd2		resd 3	; OS Dependant 2
	endstruc
	
	struc osd1_linux
.i_reserved1	resd 1
	endstruc
	struc osd1_hurd
.i_translator	resd 1
	endstruc
	struc osd1_masix
.i_reserved	resd 1
	endstruc

	struc osd2_linux
.i_frag		resb 1	; fragment number
.i_fsize	resb 1	; fragment size
.pad		resw 1
.i_uid_high	resw 1
.i_gid_high	resw 1
.i_reserved	resd 1
	endstruc
	struc osd2_hurd
.i_frag		resb 1	; fragment number
.i_fsize	resb 1	; fragment size
.i_mode_high	resw 1
.i_uid_high	resw 1
.i_gid_high	resw 1
.i_author	resd 1
	endstruc
	struc osd2_masix
.i_frag		resb 1	; fragment number
.i_size		resb 1	; fragment size
.pad		resw 1
.i_reserved	resd 2
	endstruc

%define ext2_inode.i_size_high	ext2_inode.i_dir_acl

;;
;; File system states
;;
%define EXT2_VALID_FS		0x0001	; Unmounted cleanly
%define EXT2_ERROR_FS		0x0002	; Errors detected

;;
;; Mount flags
;;
%define EXT2_MOUNT_CHECK	0x0001	; Do mount-time checks
%define EXT2_MOUNT_GRPID	0x0004	; Create files with directory's group
%define EXT2_MOUNT_ERRORS_CONT	0x0008	; Some debugging messages
%define EXT2_MOUNT_ERRORS_RO	0x0010	; Continue on errors
%define EXT2_MOUNT_ERRORS_PANIC	0x0020	; Panic on errors
%define EXT2_MOUNT_MINIX_DF	0x0040	; Mimics the Minix statfs
%define EXT2_MOUNT_NO_UID32	0x0200	; Disable 32-bit UIDs

;;
;; Maximal mount counts between two filesystem checks
;;
%define EXT2_DFL_MAX_MNT_COUNT	20	; allow 20 mounts
%define EXT2_DFL_CHECKINTERVAL	0	; don't use interval check

;;
;; Behaviour when detecting errors
;;
%define EXT2_ERRORS_CONTINUE	1	; Continue execution
%define EXT2_ERRORS_RO		2	; Remount fs read-only
%define EXT2_ERRORS_PANIC	3	; Panic
%define EXt2_ERRORS_DEFAULT	EXT2_ERRORS_CONTINUE


;;
;; Structure of the super block
;;
	struc ext2_super_block
.s_inodes_count		resd 1	; Inodes count
.s_blocks_count		resd 1	; Blocks count
.s_r_blocks_count	resd 1	; Reserved blocks count
.s_free_blocks_count	resd 1	; Free blocks count
.s_free_inodes_count	resd 1	; Free inodes count
.s_first_data_block	resd 1	; First data block
.s_log_block_size	resd 1	; Block size
.s_log_frag_size	resd 1	; Fragment size
.s_blocks_per_group	resd 1	; Number of blocks per group
.s_frags_per_group	resd 1	; Number of fragments per group
.s_inodes_per_group	resd 1	; Number of inodes per group
.s_mtime		resd 1	; Mount time
.s_wtime		resd 1	; Write time
.s_mnt_count		resw 1	; Mount count
.s_max_mnt_count	resw 1	; Maximal mount count
.s_magic		resw 1	; Magic signture 0xEF53
.s_state		resw 1	; File system state
.s_errors		resw 1	; Behaviour when detecting errors
.s_minor_rev_level	resw 1	; Minor revision level
.s_lastcheck		resd 1	; Time of last check
.s_checkinterval	resd 1	; Max time between checks
.s_creator_os		resd 1	; OS
.s_rev_level		resd 1	; Revision level
.s_def_resuid		resw 1	; Default uid for reserved blocks
.s_def_resgid		resw 1	; Default gid for reserved blocks
 ; These fields are for EXT2_DYNAMIC_REV superblocks only
.s_first_ino		resd 1	; First non-reserved inode
.s_inode_size		resw 1	; size of inode structure
.s_block_group_nr	resw 1	; block group number of this superblock
.s_feature_compat	resd 1	; compatible feature set
.s_feature_incompat	resd 1	; incompatible feature set
.s_feature_ro_compat	resd 1	; readonly-compatible feature set
.s_uuid			resb 16	; 128bit uuid for volume
.s_volume_name		resb 16	; volume name
.s_last_mounted		resb 64	; directory were last mounted
.s_algorithm_usage_bitmap resd 1	; for compression
 ; Performance hints
.s_prealloc_blocks	resb 1	; Number of blocks to try to pre-allocate
.s_prealloc_dir_blocks	resb 1	; Number of blocks to pre-allocate for dirs
.s_padding		resw 1
 ; Journaling support
.s_journal_uuid		resb 16	; uuid of journal superblock
.s_journal_inum		resd 1	; inode number of journal file
.s_journal_dev		resd 1	; device number of journal file
.s_last_orphan		resd 1	; start os list of inodes to delete
.s_reserved		resd 197 ; padding to the end of the block
	endstruc

;;
;; Codes for operating systems
;;
%define EXT2_OS_LINUX	0
%define EXT2_OS_HURD	1
%define EXT2_OS_MASIX	2
%define EXT2_OS_FREEBSD	3
%define EXT2_OS_LITES	4

;;
;; Revision levels
;;
%define EXT2_GOOD_OLD_REV	0	; The good old (original) format
%define EXT2_DYNAMIC_REV	1	; V2 format w/ dynamic inode sizes
%define EXT2_CURRENT_REV	EXT2_GOOD_OLD_REV
%define EXT2_MAX_SUPP_REV	EXT2_DYNAMIC_REV
%define EXT2_GOOD_OLD_INODE_SIZE	128

;;
;; Feature set definitions
;;
%define EXT2_FEATURE_COMPAT_DIR_PREALLOC	0x0001
%define EXT2_FEATURE_COMPAT_IMAGIC_INODE	0x0002
%define EXT3_FEATURE_COMPAT_HAS_JOURNAL		0x0004
%define EXT2_FEATURE_COMPAT_EXT_ATTR		0x0008
%define EXT2_FEATURE_COMPAT_RESIZE_INODE	0x0010
%define EXT2_FEATURE_COMPAT_DIR_INDEX		0x0020

%define EXT2_FEATURE_RO_COMPAT_SPARSE_SUPER	0x0001
%define EXT2_FEATURE_RO_COMPAT_LARGE_FILE	0x0002
%define EXT2_FEATURE_RO_COMPAT_BTREE_DIR	0x0004

%define EXT2_FEATURE_INCOMPAT_COMPRESSION	0x0001
%define EXT2_FEATURE_INCOMPAT_FILETYPE		0x0002
%define EXT3_FEATURE_INCOMPAT_RECOVER		0x0004
%define EXT3_FEATURE_INCOMPAT_JOURNAL_DEV	0x0008

%define EXT2_FEATURE_COMPAT_SUPP	0
%define EXT2_FEATURE_INCOMPAT_SUPP	EXT2_FEATUER_INCOMPAT_FILETYPE
%define EXT2_FEATURE_RO_COMPAT_SUPP	(EXT2_FEATURE_RO_COMPAT_SPARSE_SUPER + EXT2_FEATURE_RO_COMPAT_LARGE_FILE + EXT2_FEATURE_RO_COMPAT_BTREE_DIR)

;;
;; Default value for user and/or group using reserved blocks
;;
%define EXT2_DEF_RESUID		0
%define EXT2_DEF_RESGID		0

;;
;; Structure of a directory entry
;;
%define EXT2_NAME_LEN	255
	struc ext2_dir_entry
.inode		resd 1	; Inode number
.rec_len	resw 1	; Directory entry length
.name_len	resb 1	; Name length
.file_type	resb 1	; File type (EXT2_FEATURE_IMCOMPAT_FILETYPE)
.name		resb EXT2_NAME_LEN+1	; File name
	endstruc

;;
;; Ext2 directory file types. Only the 3 low bits are used, other are reserved
;;
%define EXT2_FT_UNKNOWN		0
%define EXT2_FT_REG_FILE	1
%define EXT2_FT_DIR		2
%define EXT2_FT_CHRDEV		3
%define EXT2_FT_BLKDEV		4
%define EXT2_FT_FIFO		5
%define EXT2_FT_SOCK		6
%define EXT2_FT_SYMLINK		7

%define EXT2_FT_MAX		8

;;
;; EXT2_DIR_PAD defines the directory entries boundaries
;; note: must be a multiple of 4
%define EXT2_DIR_PAD		4
%define EXT2_DIR_ROUND		(EXT2_DIR_PAD-1)

;;
;; EXT2 Inode File Mode
;;
%define EXT2_S_IFMT	0xF000	; format mask
%define EXT2_S_IFSOCK	0xA000	; socket
%define EXT2_S_IFLNK	0xC000	; symbolic link
%define EXT2_S_IFREG	0x8000	; regular file
%define EXT2_S_IFBLK	0x6000	; block device
%define EXT2_S_IFDIR	0x4000	; directory
%define EXT2_S_IFCHR	0x2000	; character device
%define EXT2_S_IFIFO	0x1000	; fifo
     
%define EXT2_S_ISUID	0x0800	; SUID
%define EXT2_S_ISGID	0x0400	; SGID
%define EXT2_S_ISVTX	0x0200	; sticky bit
          
%define EXT2_S_IRWXU	0x01C0	; user mask
%define EXT2_S_IRUSR	0x0100	; read
%define EXT2_S_IWUSR	0x0080	; write
%define EXT2_S_IXUSR	0x0040	; execute
	       
%define EXT2_S_IRWXG	0x0038	; group mask
%define EXT2_S_IRGRP	0x0020	; read
%define EXT2_S_IWGRP	0x0010	; write
%define EXT2_S_IXGRP	0x0008	; execute
	            
%define EXT2_S_IRWXO	0x0007	; other mask
%define EXT2_S_IROTH	0x0004	; read
%define EXT2_S_IWOTH	0x0002	; write
%define EXT2_S_IXOTH	0x0001	; execute
