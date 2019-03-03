// section types
#define UBF_SHT_PROG		0	// program defined (.text, .data, *)
#define UBF_SHT_CINIT		1	// cell init (.c_init)
#define UBF_SHT_CONETIMEINIT	2	// cell onetime init (.c_onetime_init)
#define UBF_SHT_CINFO		3	// cell info (.c_info)
#define UBF_SHT_UNINIT_DATA	4	// uninit'ed data (.bss)
#define UBF_SHT_TRASH		0xFF	// sections that don't go in memory and mean nothing (.comment)

#define UBF_CUR_VERSION		0

typedef struct {
	dword	magic;
	dword	checksum;
	dword	required_features;
	dword	section_table;
	dword	num_externs;
	dword	extern_table;
	dword	stack_size;
	dword	entry_offset;
	byte	entry_sect;
	byte	ubf_version;
	byte	required_cpu;
	byte	num_sections;
} ubf_header;

typedef struct {
	dword	target;		// offset within section to dword we are modifying
	dword	sym;		// index of symbol to add in extern table
} ubf_reloc;

typedef struct {
	dword	loc;		// location in file, void if type = UBF_SHT_UNINIT_DATA
	dword	size;		// size in file and mem, filesize=0 if type = UBF_SHT_UNINIT_DATA
	dword	abs_num;	// number of absloute relocations
	dword	abs_reloc;	// ptr to absloute relocation table
	dword	rel_num;	// number of rel. relocations
	dword	rel_reloc;	// ptr to rel. reloc. table
	byte	type;
	byte	reserved[3];	// padding
} ubf_sect;
