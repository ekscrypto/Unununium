#ifndef _ELF2CORE_H
#define _ELF2CORE_H

#include <stdio.h>
#include <string.h>

/* Option flags */
#define OPT_COUNT		4
#define OPT_ABORTWARNING	0x01	/* Abort on warnings */
#define OPT_SILENTWARNING	0x02	/* Silently ignore warnings */
#define OPT_FIXEDLOCATION	0x04	/* exclude DRP information */
#define OPT_TRACEOUTPUT		0x08	/* Send linker trace on stdout */
#define OPT_QUIT		0x100	/* Quit even if no warning/error */

#define SECT_COUNT		12	/* number of known segments */

/* ELF Header verification constants */
#define ELFMAGIC	0x464C457F	/* ELF Object signature */
#define ELFCLASS32	0x01		/* type id for Class32 Objects */
#define ELFDATA2LSB	0x01		/* type of byte ordering */
#define EV_VERSION	0x01		/* current header version number */
#define ET_REL		0x0001		/* e_type relocatable object */
#define EM_386		0x0003		/* 80386+ e_machine */

/* ELF-Section Header constants */
#define SHT_SYMTAB	0x0002
#define SHT_STRTAB	0x0003

/* ELF-Symbol Table constants */
#define SHN_UNDEF	0x0000
#define SHN_COMMON	0xFFF2
#define SHN_ABSOLUTE	0xFFF1
#define STB_LOCAL	0x00
#define STB_GLOBAL	0x01
#define STB_WEAK	0x02
#define STN_UNDEF	0x00
#define STT_NOTYPE	0x00
#define STT_OBJECT	0x01
#define STT_FUNC	0x02
#define STT_SECTION	0x03
#define STT_FILE	0x04

/* ELF-Relocation table constants */
#define R_386_NONE	0x00
#define R_386_32	0x01
#define R_386_PC32	0x02

/* Core Headers signatures */
#define CORESIGN "_CoREiD_"
#define CELLSIGN "_CeLLiD_"

/* Error types returned by the linker */
#define ERROR_PARAMBEFOREOBJECT_VAL	1
#define ERROR_PARAMBEFOREOBJECT_FULL	"Options must be specified before objects name"
#define ERROR_INVALIDPARAM_VAL		2
#define ERROR_INVALIDPARAM_FULL		"Invalid option selected"
#define ERROR_UNABLETOALLOCMEM_VAL	3
#define ERROR_UNABLETOALLOCMEM_FULL	"Unable to allocate memory while processing object: "
#define ERROR_UNABLETOSEEK_VAL		4
#define ERROR_UNABLETOSEEK_FULL		"Unable to seek to specified offset in object: "
#define ERROR_UNABLETOREAD_VAL		5
#define ERROR_UNABLETOREAD_FULL		"Unable to read entire record in object: "
#define ERROR_FAILREGISTERSYMBOL_VAL	6
#define ERROR_FAILREGISTERSYMBOL_FULL	"Failed to register global symbol of object: "
#define ERROR_GLOBALDUPLICATE_VAL	7
#define ERROR_GLOBALDUPLICATE_FULL	"Cannot define twice the strong global: "
#define ERROR_UNABLETOOPEN_VAL		8
#define ERROR_UNABLETOOPEN_FULL		"Unable to open object file: "
#define ERROR_INVALIDOBJHEADER_VAL	9
#define ERROR_INVALIDOBJHEADER_FULL	"Invalid ELF32 object header in file: "
#define ERROR_CREATEOUTPUT_VAL		10
#define ERROR_CREATEOUTPUT_FULL		"Unable to create output file: "


typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned long dword;

typedef struct {
  byte c_ident[8];		/* core identification */
  dword c_checksum;		/* checksum */
  dword c_isize;		/* total size of the core */
  dword c_fsize;		/* size of part kept after init */
  dword c_offset;		/* offset the core was linked for */
  dword c_fcell;		/* ptr to first cell */
  dword c_drpt;			/* ptr to drp table */
} core_hdr;

typedef struct {
  void *parent_cell;		/* Pointer to parent cell */
  void *next_sorted_node;	/* Next node to be written in final binary */
  dword global_offset;		/* Final offset in generated binary */
  byte *sh_name;		/* Pointer to name in header string table */
  void *relocation_table;	/* Ptr to relocation data for this section */
  void *next_node;		/* Pointer to next node */
  void *sh_entry;		/* Pointer to entry in section header table */
  dword shndx;			/* Entry number, makes relocation etc easier */
} section_node;

typedef struct {
  void *parent_cell;
  void *next_sorted_node;
  dword global_offset;		/* global offset to use for linkup */
  byte signature[8];		/* _CeLLiD_ */
  dword size;			/* size of this cell, excluding drp */
  dword next_cell;		/* ptr to next cell information block */
  dword dlp_extern_abs;		/* extern DLP with absolute fixup */
  dword dlp_extern_rel;		/* extern DLP with relative fixup */
  dword dlp_global;		/* global DLP provided */
  dword name;			/* ptr to cell's name */
  
} cell_hdr_node;

typedef struct {
  byte signature[8];
  dword size;
  dword next_cell;
  dword dlp_extern_abs;
  dword dlp_extern_rel;
  dword dlp_global;
  dword name;
} cell_hdr;

typedef struct {
  void *next_node;
  void *sections;
  void *shtab;
  void *shstrtab;
  void *strtab;
  void *symtab;
  dword symtab_size;
  byte *filename;
  FILE *fp;
  dword shnum;
  void *cell_header;
  void *extern_dlp_abs;
  dword extern_dlp_abs_size;
  void *extern_dlp_rel;
  dword extern_dlp_rel_size;
  void *global_dlp;
  dword global_dlp_size;
  void *locals;
} cell_node;

typedef struct {
  void *next_node;
  byte *name;
  dword value;
  dword strength;
} global_node;

typedef struct {
  void *next_node;
  byte *name;
  dword value;
} local_node;

typedef struct {
  dword e_signature;
  byte e_class;
  byte e_data;
  byte e_hdrversion;
  byte e_ident[9];
  word e_type;			/* Identifies object file type */
  word e_machine;		/* Specifies required architecture */
  dword	e_version;		/* Identifies object file version */
  dword	e_entry;		/* Entry point virtual address */
  dword	e_phoff;		/* Program header table file offset */
  dword	e_shoff;		/* Section header table file offset */
  dword	e_flags;		/* Processor-specific flags */
  word e_ehsize;		/* ELF header size in bytes */
  word e_phentsize;		/* Program header table entry size */
  word e_phnum;			/* Program header table entry count */
  word e_shentsize;		/* Section header table entry size */
  word e_shnum;			/* Section header table entry count */
  word e_shstrndx;		/* Section header string table index */
} Elf32_hdr;

typedef struct {
  dword	sh_name;		/* Section name, index in string tbl */
  dword	sh_type;		/* Type of section */
  dword	sh_flags;		/* Miscellaneous section attributes */
  dword	sh_addr;		/* Section virtual addr at execution */
  dword	sh_offset;		/* Section file offset */
  dword	sh_size;		/* Size of section in bytes */
  dword	sh_link;		/* Index of another section */
  dword	sh_info;		/* Additional section information */
  dword	sh_addralign;		/* Section alignment */
  dword	sh_entsize;		/* Entry size if section holds table */
} Elf32_Shdr;

typedef struct {
  dword st_name;
  dword st_value;
  dword st_size;
  byte st_info;
  byte st_other;
  word st_shndx;
} Elf32_Sym;

typedef struct {
  dword r_offset;
  dword r_info;
} Elf32_Rel;

#endif /* _ELF2CORE_H */
