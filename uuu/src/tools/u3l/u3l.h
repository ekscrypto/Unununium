#ifdef __BORLANDC__			// Patchwork Fix for non-GCC compiler
	#define patchwork			// by amd
#else
	#define patchwork __attribute__((packed));
#endif							// ends

#ifndef __U3L_H__
  #define __U3L_H__

#define S_OTHER			0x00
#define S_OSW_PRE_INIT		0x01
#define S_OSW_INTERINIT_CODE	0x02
#define S_OSW_POST_INIT		0x03
#define S_C_INITONCE		0x21
#define S_C_INIT		0x22
#define S_C_INFO		0x23
#define S_C_DLP_ABS		0x24
#define S_C_DLP_REL		0x25

#ifndef dword
  typedef unsigned long dword;
#endif
#ifndef word
  typedef unsigned short word;
#endif
#ifndef byte
  typedef unsigned char byte;
#endif

/* ELF Header verification constants */
#define ELFMAGIC	0x464C457F
#define ELFCLASS32	0x01
#define ELFDATA2LSB	0x01
#define EV_VERSION	0x01
#define ET_REL		0x0001
#define EM_386		0x0003
/* ELF-Section Header constants */
#define SHT_PROGBITS	0x0001
#define SHT_SYMTAB      0x0002
#define SHT_STRTAB      0x0003
#define SHT_REL		0x0009

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

#define ELF32_ST_TYPE(i)	((i)&0x0F)
#define ELF32_ST_BIND(i)	((i)>>4)
#define ELF32_R_TYPE(i)		((i)&0xFF)
#define ELF32_R_SYM(i)		((i)>>8)


typedef struct {
  dword e_signature;
  byte e_class;
  byte e_data;
  byte e_hdrversion;
  byte e_ident[9];
  word e_type;                  /* Identifies object file type */
  word e_machine;               /* Specifies required architecture */
  dword e_version;              /* Identifies object file version */
  dword e_entry;                /* Entry point virtual address */
  dword e_phoff;                /* Program header table file offset */
  dword e_shoff;                /* Section header table file offset */
  dword e_flags;                /* Processor-specific flags */
  word e_ehsize;                /* ELF header size in bytes */
  word e_phentsize;             /* Program header table entry size */
  word e_phnum;                 /* Program header table entry count */
  word e_shentsize;             /* Section header table entry size */
  word e_shnum;                 /* Section header table entry count */
  word e_shstrndx;              /* Section header string table index */
} Elf32_hdr;

typedef struct {
  dword sh_name;                /* Section name, index in string tbl */
  dword sh_type;                /* Type of section */
  dword sh_flags;               /* Miscellaneous section attributes */
  dword sh_addr;                /* Section virtual addr at execution */
  dword sh_offset;              /* Section file offset */
  dword sh_size;                /* Size of section in bytes */
  dword sh_link;                /* Index of another section */
  dword sh_info;                /* Additional section information */
  dword sh_addralign;           /* Section alignment */
  dword sh_entsize;             /* Entry size if section holds table */
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

typedef struct {
  dword signature;
  byte  revision;
  byte  reserved;
  word  cell_count;
  dword core_size;
  dword core_checksum;
// multiboot header, in first 8 kb, 4 bytes aligned
  dword mboot_magic;
  dword mboot_flags;
  dword mboot_checksum;
  dword mboot_header_addr;   // physical address of multiboot magic (for syncing)
  dword core_offset;         // physical address of .text
  dword mboot_load_end_addr; // physical address of .data end
  dword mboot_bss_end_addr;  // physical address of .bss end
  dword mboot_entry;         // physical address of special entry point that sets esp
// end of multiboot header
  dword osw_entry;
  dword drp;
  dword dlp_abs;
  dword dlp_rel;
  dword dlp_provided;
  // code patchwork (yes, its ugly)
  byte  mov_esp    patchwork;
  dword esp_value	 patchwork;
  byte  jmp_rel_esp[2] patchwork;
  dword  jmp_rel_off	patchwork;
  byte dword_align;

  // instances of hdr_cell follows
} hdr_core;

typedef struct {
  dword c_start;
  dword c_size;
  dword c_info;
} hdr_cell;

typedef struct {
  void		*next_node;
  void		*parent_obj;
  void		*c_info;
  hdr_cell	final_hdr;
} node_cell;

typedef struct {
  void		*next_node;
  dword		vid;
  dword		fix_point;
  void		*parent_obj;
} node_dlp;

typedef struct {
  void		*next_node;
  dword		fix_point;
} node_drp;

typedef struct {
  void		*next_node;
  byte		*name;
  dword		vid;
  dword		value;
  void		*parent_obj;
  dword		symbol_index;
} node_function;

typedef struct {
  void		*next_node;
  byte		*name;
  void		*parent_obj;
  dword		value;
  dword		strength;
    void		*sym;
} node_gsymbol;

typedef struct {
  void		*next_node;
  byte		*name;
  dword		value;
} node_lsymbol;

typedef struct {
  void		*next_node;
  void		*parent_obj;
  dword 	global_offset;
  byte		*sh_name;
  Elf32_Rel	*reltab;
  dword		reltab_size;
  Elf32_Shdr	*sh_entry;
  dword		shndx;
} node_section;

typedef struct {
  void		*next_node;
  node_section	*sections;
  Elf32_Shdr	*shtab;
  byte		*shstrtab;
  byte		*strtab;
  Elf32_Sym	*symtab;
  dword		symtab_size;
  byte		*filename;
  FILE		*fp;
  dword		shnum;
  node_cell	*cell_header;
  node_lsymbol	*locals;
} node_obj;

#endif /* __U3L_H__ */
