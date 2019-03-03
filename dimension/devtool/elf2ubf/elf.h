typedef dword	Elf32_Addr;
typedef word	Elf32_Half;
typedef dword	Elf32_Off;
typedef int	Elf32_Sword;
typedef dword	Elf32_Word;

// ELF file types
#define ET_NONE		0	// No file type
#define ET_REL		1	// Relocatable file
#define ET_EXEC		2	// Executable file
#define ET_DYN		3	// Shared object file
#define ET_CORE		4	// Core file
#define ET_LOPROC	0xff00	// Processor-specific
#define ET_HIPROC	0xffff	// Processor-specific

// platforms
#define EM_NONE		0	// No machine
#define EM_M32		1	// AT&T WE 32100
#define EM_SPARC	2	// SPARC
#define EM_386		3	// Intel 80386
#define EM_68K		4	// Motorola 68000
#define EM_88K		5	// Motorola 88000
#define EM_860		7	// Intel 80860
#define EM_MIPS		8	// MIPS RS3000

// versions
#define EV_NONE		0	// Invalid version
#define EV_CURRENT	1	// Current version

// section numbers
#define SHN_UNDEF	0
#define SHN_LORESERVE	0xff00
#define SHN_LOPROC	0xff00
#define SHN_HIPROC	0xff1f
#define SHN_ABS		0xfff1
#define SHN_COMMON	0xfff2
#define SHN_HIRESERVE	0xffff

// section types
#define SHT_NULL	0
#define SHT_PROGBITS	1	// program defined
#define SHT_SYMTAB	2	// symbol table (there may be only one)
#define SHT_STRTAB	3	// string table
#define SHT_RELA	4	// relocations with explicit addends
#define SHT_HASH	5	// symbol hash table
#define SHT_DYNAMIC	6	// dynamic section, for dynamic linking
#define SHT_NOTE	7	// note section
#define SHT_NOBITS	8	// not in file, i.e. .bss
#define SHT_REL		9	// relocation entries w/o explicit addends
#define SHT_SHLIB	10	// reserved but invalid cuz ELF sux
#define SHT_DYNSYM	11	// dynamic symbol table (there may be only one)
#define SHT_LOPROC	0x70000000
#define SHT_HIPROC	0x7fffffff
#define SHT_LOUSER	0x80000000
#define SHT_HIUSER	0xffffffff

// relocation types
#define R_386_NONE	0
#define R_386_321	1
#define R_386_PC322	2
#define R_386_GOT323	3
#define R_386_PLT324	4
#define R_386_COPY5	5
#define R_386_GLOB_DAT	6
#define R_386_JMP_SLOT	7
#define R_386_RELATIVE	8
#define R_386_GOTOFF	9
#define R_386_GOTPC	10

// symbol types
#define ELF32_ST_BIND(i)	((i)>>4)
#define ELF32_ST_TYPE(i)	((i)&0xf)
#define ELF32_ST_INFO(b, t)	(((b)<<4)+((t)&0xf))

#define STB_LOCAL	0
#define STB_GLOBAL	1
#define STB_WEAK	2
#define STB_LOPROC	13
#define STB_HIPROC	15

#define STT_NOTYPE	0
#define STT_OBJECT	1
#define STT_FUNC	2
#define STT_SECTION	3
#define STT_FILE	4
#define STT_LOPROC	13
#define STT_HIPROC	15

// relocation types
#define ELF32_R_SYM(i)		((i)>>8)
#define ELF32_R_TYPE(i)		((unsigned char)(i))
#define ELF32_R_INFO(s, t)	((s)<<8+(unsigned char)(t))

// Name               Value          Field   Calculation
// ====               =====          =====   ===========
#define R_386_NONE	0	//   none    none
#define R_386_32	1	//   word32  S + A
#define R_386_PC32	2	//   word32  S + A - P
#define R_386_GOT32	3	//   word32  G + A - P
#define R_386_PLT32	4	//   word32  L + A - P
#define R_386_COPY	5	//   none    none
#define R_386_GLOB_DAT	6	//   word32  S
#define R_386_JMP_SLOT	7	//   word32  S
#define R_386_RELATIVE	8	//   word32  B + A
#define R_386_GOTOFF	9	//   word32  S + A - GOT
#define R_386_GOTPC	10	//   word32  GOT + A - P

// size of e_ident
#define EI_NIDENT	0x10

// ELF header
typedef struct {
	unsigned char       e_ident[EI_NIDENT];
	Elf32_Half          e_type;
	Elf32_Half          e_machine;
	Elf32_Word          e_version;
	Elf32_Addr          e_entry;
	Elf32_Off           e_phoff;
	Elf32_Off           e_shoff;		// section header offset
	Elf32_Word          e_flags;
	Elf32_Half          e_ehsize;
	Elf32_Half          e_phentsize;
	Elf32_Half          e_phnum;
	Elf32_Half          e_shentsize;	// section header entry size
	Elf32_Half          e_shnum;		// section header count
	Elf32_Half          e_shstrndx;		// section header string index
} Elf32_Ehdr;

// section table
typedef struct {
	Elf32_Word	sh_name;
	Elf32_Word	sh_type;
	Elf32_Word	sh_flags;
	Elf32_Addr	sh_addr;
	Elf32_Off	sh_offset;
	Elf32_Word	sh_size;
	Elf32_Word	sh_link;
	Elf32_Word	sh_info;
	Elf32_Word	sh_addralign;
	Elf32_Word	sh_entsize;
} Elf32_Shdr;

// symbol
typedef struct {
	Elf32_Word	st_name;
	Elf32_Addr	st_value;
	Elf32_Word	st_size;
	unsigned char	st_info;
	unsigned char	st_other;
	Elf32_Half	st_shndx;
} Elf32_Sym;

// relocation entries
typedef struct {
	Elf32_Addr	r_offset;
	Elf32_Word	r_info;
} Elf32_Rel;

typedef struct {
	Elf32_Addr	r_offset;
	Elf32_Word	r_info;
	Elf32_Sword	r_addend;
} Elf32_Rela;
