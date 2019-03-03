/* U3l >> Unununium Linker << -remastered-
 * Copyright (C) 2001-2003, Dave Poirier
 * Distributed under the modified BSD License
 * */

#ifndef __U3L_H__
#define __U3L_H__

#define VERSION		"2.3-dev ($Revision: 1.3 $)"
#define COPYRIGHTS	"Copyright (C) 2001-2003 Dave Poirier\nDistributed under the modified BSD License"



#define DEFAULT_C_INFO_ALIGNMENT	4
#define DEFAULT_CELL_ALIGNMENT		64
#define DEFAULT_CORE_MAP		"u3core.map"
#define DEFAULT_GLOBAL_OFFSET		0x00100000
#define DEFAULT_INIT_ALIGNMENT		1
#define DEFAULT_OUTPUT			"u3core.bin"
#define DEFAULT_SECTION_ALIGNMENT	64
#define DEFAULT_SECTION_SPACING		32
#define DEFAULT_STACK_OVERRIDE		0x00000000
#define DEFAULT_VERBOSE_LEVEL		2
#define DEFAULT_VID_LISTING		"vids.txt"
#define SECTION_FILLER_NAME		".s_filler"

#define OPT_MASK_INCLUDE_DRP		0x0001
#define OPT_MASK_ABORT_WARNING		0x0002
#define OPT_MASK_GEN_VIDLISTING		0x0004
#define OPT_MASK_HYBRID_OBJECTS		0x0008
#define OPT_MASK_WARN_MISALIGNMENTS	0x0020
#define OPT_MASK_INCLUDE_DLP		0x0040
#define OPT_MASK_REDEFINITION		0x0080
#define OPT_MASK_GEN_COREMAP		0x0100
#define OPT_MASK_FLAT_BINARY		0x0200

#define OPT_COUNT			0x1C
#define OPT_ABORT_ON_WARNING		0x01
#define OPT_ALLOW_HYBRID_OBJECTS	0x02
#define OPT_ALLOW_REDEFINITIONS		0x03
#define OPT_CELL_ALIGNMENT		0x04
#define OPT_DONT_WARN_MISALIGNMENT	0x05
#define OPT_EXCLUDE_DLP			0x06
#define OPT_EXCLUDE_DRP			0x07
#define OPT_FLAT_BINARY			0x08
#define OPT_GENERATE_CORE_MAP		0x09
#define OPT_GENERATE_VID_LISTING	0x0A
#define OPT_GLOBAL_OFFSET		0x0B
#define OPT_HELP			0x0C
#define OPT_IGNORE_WARNINGS		0x0D
#define OPT_INCLUDE_DLP			0x0E
#define OPT_INCLUDE_DRP			0x0F
#define OPT_INIT_ALIGNMENT		0x10
#define OPT_NO_CORE_MAP			0x11
#define OPT_NO_VID_LISTING		0x12
#define OPT_PROHIBIT_HYBRID_OBJECTS	0x13
#define OPT_PROHIBIT_REDEFINITIONS	0x14
#define OPT_SECTION_ALIGNMENT		0x15
#define OPT_SECTION_SPACING		0x16
#define OPT_STACK_LOCATION		0x17
#define OPT_VERSION			0x18
#define OPT_WARN_MISALIGNMENT		0x19
#define OPT_VID_NAME_FILE		0x1A
#define OPT_QUIET			0x1B
#define OPT_VERBOSITY			0x1C

#define OPT_NAME_ABORT_WARNING		0x00
#define OPT_NAME_COREMAP		0x06
#define OPT_NAME_DLP			0x04
#define OPT_NAME_DRP			0x05
#define OPT_NAME_FLAT_BINARY		0x08
#define OPT_NAME_HYBRID_OBJECTS		0x01
#define OPT_NAME_REDEFINITION		0x02
#define OPT_NAME_VIDLISTING		0x07
#define OPT_NAME_WARN_MISALIGNMENT	0x03

#define VERBOSE_LEVEL_QUIET		0x00
#define VERBOSE_LEVEL_LOW		0x01
#define VERBOSE_LEVEL_NORMAL		0x02
#define VERBOSE_LEVEL_HIGH		0x03
#define VERBOSE_LEVEL_DEBUG		0x04

#define PRE_DEFINED_GLOBALS		9
#define PRE_DEFINED_GLOBAL_MASK		0x80000000
#define PRE_DEF_CORE_HEADER		0
#define PRE_DEF_STACK_LOCATION		1
#define PRE_DEF_INFO_REDIRECTION_TABLE	2
#define PRE_DEF_INIT_SEQUENCE_LOC	3
#define PRE_DEF_CORE_SIZE		4
#define PRE_DEF_CELL_COUNT		5
#define PRE_DEF_VID_COUNT		6
#define PRE_DEF_END_OF_EXPORT		7
#define PRE_DEF_SYMBOLS_LINKAGE		8

/* ELF Header verification constants */
#define ELFMAGIC        0x464C457F
#define ELFCLASS32      0x01
#define ELFDATA2LSB     0x01
#define EV_VERSION      0x01
#define ET_REL          0x0001
#define EM_386          0x0003
/* ELF-Section Header constants */
#define SHT_PROGBITS    0x0001
#define SHT_SYMTAB      0x0002
#define SHT_STRTAB      0x0003
#define SHT_NOBITS	0x0008
#define SHT_REL         0x0009

/* ELF-Symbol Table constants */
#define SHN_UNDEF       0x0000
#define SHN_COMMON      0xFFF2
#define SHN_ABSOLUTE    0xFFF1
#define STB_LOCAL       0x00
#define STB_GLOBAL      0x01
#define STB_WEAK        0x02
#define STN_UNDEF       0x00
#define STT_NOTYPE      0x00
#define STT_OBJECT      0x01
#define STT_FUNC        0x02
#define STT_SECTION     0x03
#define STT_FILE        0x04

/* ELF-Relocation table constants */
#define R_386_NONE      0x00
#define R_386_32        0x01
#define R_386_PC32      0x02

#define ELF32_ST_TYPE(i)        ((i)&0x0F)
#define ELF32_ST_BIND(i)        ((i)>>4)
#define ELF32_R_TYPE(i)         ((i)&0xFF)
#define ELF32_R_SYM(i)          ((i)>>8)

typedef struct {
  unsigned int		e_signature;
  unsigned char		e_class,
  			e_data,
			e_hdrversion,
			e_ident[9];
  unsigned short	e_type,		/* Identifies object file type */
			e_machine;	/* Specifies required architecture */
  unsigned int		e_version,	/* Identifies object file version */
			e_entry,	/* Entry point virtual address */
			e_phoff,	/* Program header table file offset */
			e_shoff,	/* Section header table file offset */
			e_flags;	/* Processor-specific flags */
  unsigned short	e_ehsize,	/* ELF header size in bytes */
			e_phentsize,	/* Program header table entry size */
			e_phnum,	/* Program header table entry count */
			e_shentsize,	/* Section header table entry size */
			e_shnum,	/* Section header table entry count */
			e_shstrndx;	/* Section header string table index */
} Elf32_hdr;

typedef struct elf_shdr_t {
  unsigned int	sh_name,		/* Section name, index in string tbl */
		sh_type,		/* Type of section */
		sh_flags,		/* Miscellaneous section attributes */
		sh_addr,		/* Section virtual addr at execution */
		sh_offset,		/* Section file offset */
		sh_size,		/* Size of section in bytes */
		sh_link,		/* Index of another section */
		sh_info,		/* Additional section information */
		sh_addralign,		/* Section alignment */
		sh_entsize;		/* Entry size if section holds table */
} Elf32_Shdr;

typedef struct elf_rel_t {
  unsigned int	r_offset,		/* offset in section to relocation */
  		r_info;			/* symbol information */
} Elf32_Rel;

typedef struct elf_sym_t {
  unsigned int		st_name,
  			st_value,
			st_size;
  unsigned char		st_info,
  			st_other;
  unsigned short	st_shndx;
} Elf32_Sym;

struct section_t;
struct u3l_rel_t;
struct u3l_info_t;
struct u3l_param_t;
struct obj_elf_t;
struct u3vid_t;

struct section_t {
  struct section_t	*next, *reltab;
  unsigned int		global_offset,
			offset_in_core,
			size_in_core,
			size_in_mem,
			entry_point,
			shndx;
  char			*sh_name;
  Elf32_Rel		*reltab_data;
  Elf32_Shdr		*sh_entry;
  struct obj_elf_t	*obj;
};

typedef struct u3l_rel_t {
  struct u3l_rel_t	*next;
  unsigned int		offset;
  struct section_t	*sect;
} u3l_REL;

typedef struct u3l_info_t {
  unsigned char		version_major,
  			version_minor,
			version_revision,
			version_code;
  unsigned int		cell_desc,
  			cell_author,
			cell_copyright;
} u3l_INFO;

typedef struct u3l_param_t {
  struct u3l_param_t	*next;
  char			*param;
  unsigned int		offset_in_core,
			size,
			global_offset;
} u3l_PARAM;

typedef struct obj_elf_t {
  struct obj_elf_t	*next;
  char			*filename,
  			*shstr,
			*strtab,
			param_count;
  u3l_PARAM		**params;
  unsigned int		param_array_offset;
  unsigned int		param_array_size;
  u3_FILE		*fp;
  unsigned short	shstrndx,
  			shnum,
			shentsize,
			id;
  unsigned int		shoff,
			symtab_size,
			relcount;
  Elf32_Shdr		*shtab;
  Elf32_Sym		*symtab;
  struct section_t	*reltabs,
  			*c_info,
  			**sections,
			*bss;
} u3l_OBJ;


typedef struct u3viddep_t {
  struct u3viddep_t	*next;
  u3l_OBJ		*obj;
  Elf32_Sym		*sym;
  struct u3vid_t	*vid;
} u3l_VID_DEP;

typedef struct u3vid_t {
  struct u3vid_t	*next;		/* Pointer to next VID */
  unsigned int		value,		/* VOiD Global value */
  			id,		/* VOiD Global ID */
			prov_count,	/* Number of providers */
			user_count;	/* Number of users */
  char			*name;		/* Pointer to VOiD Global name */
  u3l_VID_DEP		*providers,	/* List of provider objects */
			*users;		/* List of user objects */
  u3l_REL		*rels;		/* List of relocations using it */
} u3l_VID;

typedef struct u3namedvid_t {
  struct u3namedvid_t	*next;
  unsigned int		id;
  char			name[48];
} u3l_named_VID;


typedef struct u3core_t {
  unsigned char		signature[4],
  			revision,
			reserved;
  unsigned short	cell_count;
  unsigned int		last_mem_used,
			core_size,
			core_checksum,
			mboot_magic,
			mboot_flags,
			mboot_checksum,
			mboot_header_addr,
			core_offset,
			mboot_load_end_addr,
			mboot_bss_end_addr,
			mboot_entry,
			osw_entry;
  unsigned char		mov_esp;
  unsigned int		esp_value;
  unsigned char		jmp_rel_esp[2];
  unsigned int		jmp_rel_off;
  unsigned char		dword_align;

/* note on the packed attribute:
 *
 * The `packed' attribute specifies that a variable or structure field
 * should have the smallest possible alignment--one byte for a
 * variable, and one bit for a field, unless you specify a larger
 * value with the `aligned' attribute.
 * 
 * There must be some BorlandC keyword for that, but I haven't dug in
 * official references to find out.
 */
#ifdef __BORLANDC__
  } hdr_core;
#else
  } __attribute__((packed)) hdr_core;
#endif

typedef struct u3core_init_hdr_t {
  unsigned int		move_count,
  			call_count_phase1,
			zeroize_count,
			call_count_phase2;
#ifdef __BORLANDC__
  } core_init_hdr;
#else
  } __attribute__((packed)) core_init_hdr;
#endif

typedef struct u3core_init_move_t {
  unsigned short	id;
  unsigned int		source,
			destination,
			size;
#ifdef __BORLANDC__
  } core_init_mov;
#else
  } __attribute__((packed)) core_init_move;
#endif

typedef struct u3core_init_call_t {
  unsigned short	id;
  unsigned int		entry_point;
  unsigned int		parameter_array;
  unsigned char		parameter_count;
#ifdef __BORLANDC__
  } core_init_call;
#else
  } __attribute__((packed)) core_init_call;
#endif

typedef struct u3core_init_zeroize_t {
  unsigned short	id;
  unsigned int		destination,
  			size;
#ifdef __BORLANDC__
  } core_init_zeroize;
#else
  } __attribute__((packed)) core_init_zeroize;
#endif

typedef struct u3core_vid_t {
  unsigned int		vid;
  unsigned short	providers_count,
  			users_count;
#ifdef __BORLANDC__
  } core_vid;
#else
  } __attribute__((packed)) core_vid;
#endif


typedef struct section_t u3l_SECT;


void add_obj( char *name );

u3l_SECT *alloc_u3l_SECT(
    unsigned int shndx,
    char *name,
    u3l_OBJ *obj,
    Elf32_Shdr *sh_entry );
void display_error( char *text, char *filename );
void display_warning( char *text, char *filename );
void flush_sections();
void flush_linked_sections(u3l_SECT *sect);
u3l_VID *get_vid_entry( unsigned int vid );
char *get_vid_name( unsigned int vid );
void hex_dump(void *buf, size_t size);
u3l_VID *get_vid_entry( unsigned int vid );
void list_vid(void);
void print_option( char *name );
void update_symbol_chain( u3l_VID_DEP *dep_chain, unsigned int value);

#endif /* __U3L_H__ */
