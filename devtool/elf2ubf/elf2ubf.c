/*
 * $Header: /cvsroot/uuu/devtool/elf2ubf/elf2ubf.c,v 1.1.1.1 2002/11/29 23:48:14 instinc Exp $
 *
 * elf2ubf file converter
 *   reads in an ELF file and outputs a UBF that will do the same thing is one
 *   fouth the number of bytes
 *
 * Copyright (C) 2001 Phil Frost
 * This software is distributed under the BSD license,
 * see file "license" for details.
 *
 * for ELF specs see:
 *   http://www.muppetlabs.com/~breadbox/software/ELF.txt
 *
 * for UBF specs see:
 *   http://uuu.sf.net/docs/ubf.html
 *
 * status:
 * -------
 * conversion is a little stupid and not very true to the ELF spec, but it
 * works on every ELF nasm generates that I have tried. This is called bloat
 * syndrome, and it happens when something (in this case ELF) could possibly
 * take 21239 forms, but really one 1 of them is usefull.
 *
 * I have done my best to write some quality software, but well, it's C, and..
 * I hate it. I don't do a great job of checking return values for errors, and
 * there a few things (the elf_to_ubf_[sect|sym] arrays are all I can think of
 * atm) that work, usually, but if there is some irregularity in the ELF file
 * could cause very strange output without any errors.
 */

//#define _DEBUG_

//                                          -----------------------------------
//                                                                     typedefs
//=============================================================================

typedef unsigned char	byte;
typedef unsigned short	word;
typedef unsigned	dword;

//                                          -----------------------------------
//                                                                     includes
//=============================================================================

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "elf.h"
#include "ubf.h"

//                                          -----------------------------------
//                                                                       strucs
//=============================================================================

typedef struct hash_entry {
	struct hash_entry	*next;		// ptr to next entry
	byte	type;
	char			*string;	// the string
} hash_entry;

typedef struct ubf_sect_node {
	ubf_sect	sect;
	struct ubf_sect_node	*next;
} ubf_sect_node;

typedef struct dword_list_node {
	struct dword_list_node	*next;
	dword			val;
} dword_list_node;

typedef struct {
	dword_list_node	*top;
	dword		num;
} dword_list;

typedef struct reloc_list_node {
	struct reloc_list_node	*next;
	ubf_reloc		reloc;
} reloc_list_node;

typedef struct {
	reloc_list_node	*first;
	reloc_list_node	*last;
	dword		num;
} reloc_list;

typedef struct complex_reloc_list_node {
	struct complex_reloc_list_node	*next;
	ubf_sect_node	*sect;
	dword		offset;
	dword		value;
} complex_reloc_node;


//                                          -----------------------------------
//                                                                         data
//=============================================================================

FILE *input_file;
FILE *output_file;

// the header we will write to the output later
ubf_header	header = {0,0,0,0,0,0,0,0,0,0,0,0};

char		entry_defined = 0;	// set when we find the entry point

Elf32_Shdr	*section_table;
Elf32_Sym	*sym_table;
char		*section_str_table;
byte		*elf_to_ubf_sect;	// to convert ELF sections to ours
dword		*elf_to_ubf_sym;	// to convert ELF symbols to ours
byte		next_ubf_section = 0;
dword		next_ubf_sym = 0;
dword		global_sym_start;	// ELF sym index of first global sym
ubf_sect_node	*first_ubf_sect = NULL;
ubf_sect_node	*last_ubf_sect = NULL;
dword		symbol_table = 0;	// the last sym table we handled
complex_reloc_node	*complex_relocs = NULL;

dword		elf_num_sections;

dword_list	reloc_tables = { NULL, 0 };	// list of reloc tables to process later
reloc_list	abs_reloc = { NULL, NULL, 0 };	// abs. relocations to write to UBF later

hash_entry ss_cinit = { NULL, UBF_SHT_CINIT, ".c_init" };
hash_entry ss_cinfo = { NULL, UBF_SHT_CINFO, ".c_info" };
hash_entry ss_conetimeinit = { NULL, UBF_SHT_CONETIMEINIT, ".c_onetime_init" };
hash_entry ss_comment = { &ss_conetimeinit, UBF_SHT_TRASH, ".comment" };

// I know a hash table for this is a little excessive, but in the future there
// may be many more of these special sections and they may be definable at
// runtime
hash_entry	*special_sections[] = {
	NULL,		// 0
	NULL,		// 1
	&ss_cinit,	// 2
	NULL,		// 3
	NULL,		// 4
	NULL,		// 5
	NULL,		// 6
	NULL,		// 7
	NULL,		// 8
	NULL,		// 9
	NULL,		// A
	NULL,		// B
	NULL,		// C
	NULL,		// D
	&ss_comment,	// E
	&ss_cinfo	// F
};

//                                          -----------------------------------
//                                                                   prototypes
//=============================================================================

int read_input( void **buf, int size, dword loc );
int add_section( int i, byte type );
int process_sym_table( dword i );
int process_rel_table( dword i );
byte section_type( char *str );
dword hash( register byte *k, register dword);
ubf_sect_node *get_sect_node( byte i );
int process_section_table( );
int write_ubf_sect_table( );
int write_ubf_header( );
int free_sections( );
void apply_complex_relocs( void );

//                                          -----------------------------------
//                                                                       main()
//=============================================================================

int main(int argc, char *argv[]) {
	Elf32_Ehdr	*header;

	if( argc != 3 ) {
		fputs( "elf2ubf version $Revision: 1.1.1.1 $\nusage: elf2ubf INPUT OUTPUT\n", stderr );
		return 1;
	}
	
	// open the input and output files
	input_file = fopen( argv[1], "rb" );
	if(! input_file ) {
		fprintf( stderr, "unable to open input file: %s\n", argv[1] );
		return 1;
	}

	output_file = fopen( argv[2], "w+b" );
	if(! output_file ) {
		fprintf( stderr, "unable to open output file: %s\n", argv[2] );
		return 1;
	}
	fseek( output_file, sizeof( ubf_header ), SEEK_SET );

	// read in the ELF header
	read_input( (void*)&header, sizeof(Elf32_Ehdr), 0 );

	elf_num_sections = header->e_shnum;
#ifdef _DEBUG_
	printf( "input ELF has %u sections\n", elf_num_sections );
#endif

	// allocate space for elf->ubf section number conversion array
	elf_to_ubf_sect = malloc( header->e_shnum );
	if(! elf_to_ubf_sect ) {
		fputs( "unable to malloc for elf -> ubf section table\n", stderr );
		return 1;
	}
	memset( elf_to_ubf_sect, -1, header->e_shnum );

	// read in the section table
	if(! read_input((void*)&section_table,
			sizeof(Elf32_Shdr) * header->e_shnum,
			header->e_shoff
			) ) {
		fputs( "unable to read section table\n", stderr );
		return 1;
	}

	// read in the section string table
	if(! read_input((void*)&section_str_table,
			section_table[header->e_shstrndx].sh_size,
			section_table[header->e_shstrndx].sh_offset ) ) {
		return 1;
	}

	process_section_table( );

	write_ubf_sect_table();
	write_ubf_header();

	// let them know if they might have forgotten something...
	if( !entry_defined )
		fputs( "warning: no entry point (_start) defined\n", stderr );

#ifdef _DEBUG_
	puts( "closing files" );
#endif

	apply_complex_relocs();

	// close our files
	fclose( input_file );
	fclose( output_file );

#ifdef _DEBUG_
	puts( "freeing memory" );
#endif

	// free our memory
	free( header );
	free( section_table );
	free( section_str_table );
	free( elf_to_ubf_sect );
	free( elf_to_ubf_sym );
	if( sym_table ) free( sym_table );
#ifdef _DEBUG_
	puts( "freeing sections" );
#endif
	free_sections();
#ifdef _DEBUG_
	puts( "done" );
#endif
	return 0;
}

//                                          -----------------------------------
//                                                                 push_dword()
//=============================================================================
// pushes a dword onto a psudo-stack (FIFO)

int push_dword( dword val, dword_list *root ) {
	dword_list_node	*old_node;

	old_node = root->top;
	root->top = malloc( sizeof(dword_list_node) );
	if( !root->top )
		return 1;

	root->top->next = old_node;
	root->top->val = val;
	root->num++;
	return 0;
}

//                                          -----------------------------------
//                                                                  pop_dword()
//=============================================================================
// pops a dword off of the FIFO psudo-stack

int pop_dword( dword_list *root ) {
	dword		val;
	dword_list_node	*old_node;
	
	val = root->top->val;
	old_node = root->top;
	root->top = old_node->next;
	free( old_node );
	root->num--;
	return val;
}

//                                          -----------------------------------
//                                                                  put_reloc()
//=============================================================================
// puts a ubf_reloc into a FILO buffer
//
// this is used when going through the relocation tables because ELF puts all
// the relocs together and has a type for each, UBF has 2 seperate tables. So,
// we run through the ELF relocs and write one of the tables to the output file
// and put the others in the buffer. After we have gone through all of the
// relocs the buffer is written to the file.

int put_reloc( ubf_reloc reloc, reloc_list *root ) {
	reloc_list_node	*new_node;

	new_node = malloc( sizeof(reloc_list_node) );	
	if( !new_node )
		return 1;

	new_node->reloc = reloc;

	if( root->last )
		root->last->next = new_node;
	else
		root->first = new_node;
	root->last = new_node;

	root->num++;

	return 0;
}

//                                          -----------------------------------
//                                                                  get_reloc()
//=============================================================================
// gets a ubf_reloc from a FILO buffer, see put_reloc() above

ubf_reloc get_reloc( reloc_list *root ) {
	ubf_reloc	val;
	reloc_list_node	*old_node;
	
	old_node = root->first;
	val = old_node->reloc;
	root->first = old_node->next;
	free( old_node );
	if( !--root->num )
		root->last = NULL;

	return val;
}

//                                          -----------------------------------
//                                                       write_ubf_sect_table()
//=============================================================================
// writes the UBF section table to the output file and puts the pointer to it
// in the UBF header.

int write_ubf_sect_table() {
	ubf_sect_node	*cur = first_ubf_sect;

	if(!cur)
		header.section_table = -1;
	else
		header.section_table = ftell( output_file );
	
	while( cur ) {
		fwrite( &cur->sect, sizeof(cur->sect), 1, output_file );
		cur = cur->next;
	}
	return 0;
}

//                                          -----------------------------------
//                                                           write_ubf_header()
//=============================================================================
// writes the UBF header to the output file.
// 
// This is one of the last functions to get called; it is stored in memory and
// the various other functions fill out the fields, then it is written to the
// output file after just before it is closed.

int write_ubf_header() {
	rewind( output_file );
	header.magic = 0x4642557F;
	header.ubf_version = UBF_CUR_VERSION;
	fwrite( &header, sizeof(header), 1, output_file );
	return 0;
}

//                                          -----------------------------------
//                                                      process_section_table()
//=============================================================================
// processes the section table and calls the other appropiate functions.
//
// This function runs through each section. If it is a user-defined section it
// writes it to the file and puts the offset in the section table that is
// stored in memory (it hasn't been written to the file yet). When it finds
// a relocation table it pushes it onto a dword psudo-stack (see push_dword() )
// and processes it after all other sections have been processed. This is
// because in order to propperly generate the UBF symbols from the ELF symbols
// we need to know how many sections the output file will have, but we can't
// know that until we have run through all of the sections.

int process_section_table( ) {
	void		*sect_buf;
	unsigned	i;
	byte		type;

	// loop through the sections and handle them one by one
	for( i=1; i < elf_num_sections; i++ ) {
#ifdef _DEBUG_
		printf ( "processing section[%u]: \"%s\"\n", i, &section_str_table[ section_table[i].sh_name ] );
#endif
		if( section_table[i].sh_size == 0 ) {
			fprintf( stderr, "ignoring zero sized section \"%s\"\n", &section_str_table[ section_table[i].sh_name ] );
			continue;
		}
		switch( section_table[i].sh_type ) {
			case SHT_PROGBITS:
				if( (type = section_type(&section_str_table[ section_table[i].sh_name ]))
						== UBF_SHT_TRASH )
					break;
				add_section(i, type );
				read_input(&sect_buf, section_table[i].sh_size, section_table[i].sh_offset);
				fwrite( sect_buf, section_table[i].sh_size, 1, output_file );
				fseek( output_file, section_table[i].sh_size % 4, SEEK_CUR );	// align 4
				break;
			case SHT_SYMTAB:
				if( !symbol_table ) {
					process_sym_table( i );
					symbol_table = i;
				} else {
					fputs( "multiple symbol tables found", stderr );
					return 1;
				}
			case SHT_STRTAB:	// we can safely ignore string tables
				break;
			case SHT_RELA:
				fprintf( stderr,
					"found unsuported SHT_RELA relocation table \"%s\", ignoring",
					&section_str_table[ section_table[i].sh_name ] );
				break;
			case SHT_NOBITS:
				add_section(i, UBF_SHT_UNINIT_DATA );
				break;
			case SHT_REL:
				push_dword( i, &reloc_tables );
				break;
			default:
				fprintf( stderr,
					"unknown (probally useless) section type 0x%x in section \"%s\", skiping\n",
					section_table[i].sh_type,
					&section_str_table[ section_table[i].sh_name ] );
		}
	}
#ifdef _DEBUG_
	puts( "done processing section table; processing relocation tables..." );
#endif
	while( reloc_tables.num ) {
#ifdef _DEBUG_
		puts( "processing reloc table..." );
#endif
		process_rel_table( pop_dword(&reloc_tables) );
	}
	free( sect_buf );
	return 0;
}

//                                          -----------------------------------
//                                                                 read_input()
//=============================================================================
// This is a little function that allocates memory for a buffer, seeks to the
// propper location in the input file, and reads the file into the buffer.

int read_input( void **buf, int size, dword loc ) {
	*buf = malloc( size );
	if(! *buf ) return 0;
	if( fseek( input_file, loc, SEEK_SET ) ) return 0;
	return fread(*buf, size, 1, input_file );
}

//                                          -----------------------------------
//                                                              free_sections()
//=============================================================================
// This function frees all of the section table nodes stored in memory.

int free_sections() {
	ubf_sect_node	*cur = first_ubf_sect;
	ubf_sect_node	* next;

	while( cur ) {
#ifdef _DEBUG_
		printf( "freeing section at 0x%08x\n", (dword)cur );
#endif
		next = cur->next;
		free( cur );
		cur = next;
	}
	return 0;
}



//                                          -----------------------------------
//                                                          add_complex_reloc()
//=============================================================================
// This function records a modification to apply to the output ubf when all
// things are completed.
void add_complex_reloc( ubf_sect_node *sect, dword offset, dword value ) {
  complex_reloc_node *complex_reloc = malloc(sizeof(complex_reloc_node));

  complex_reloc->sect = sect;
  complex_reloc->offset = offset;
  complex_reloc->value = value;
  complex_reloc->next = complex_relocs;
  complex_relocs = complex_reloc;
}



//                                          -----------------------------------
//                                                                add_section()
//=============================================================================
// This function adds a section to the section tables stored in memory.

int add_section( int i, byte type ) {
	ubf_sect_node	*sect;

	// make an entry in the conversion table
	elf_to_ubf_sect[i] = next_ubf_section++;
	
	// allocate the section struc
	sect = malloc( sizeof( ubf_sect_node ) );
	if( !sect ) {
		perror( "elf2ubf" );
		return 1;
	}

	// link it up
	if( last_ubf_sect )
		last_ubf_sect->next = sect;
	else
		first_ubf_sect = sect;
	last_ubf_sect = sect;

	sect->sect.size = section_table[i].sh_size;
	sect->sect.loc = ftell( output_file );
	sect->sect.abs_num = 0;
	sect->sect.rel_num = 0;
	sect->sect.type = type;
	sect->next = NULL;

	header.num_sections++;
	next_ubf_sym++;
	
#ifdef _DEBUG_
	printf( "adding section: %s\n\t#: %u\n\ttype: %x\n\tsize: %u\n",
			&section_str_table[ section_table[i].sh_name ],
			elf_to_ubf_sect[i],
			sect->sect.type,
			sect->sect.size
			);
#endif
	return 0;
}

//                                          -----------------------------------
//                                                          process_sym_table()
//=============================================================================
// This function runs through the ELF symbol table and does stuff with it.
// First a scan is made for section symbols; then for globals (which are both
// global and extern functions in ELF-speak)

int process_sym_table( dword i ) {
	char		*str_t;
	dword		num_entries;
	unsigned	j;
	dword		vid;
	
	num_entries = section_table[i].sh_size / section_table[i].sh_entsize;
	
#ifdef _DEBUG_
	printf( "processing symbol table with %u entries\n", num_entries );
#endif

	elf_to_ubf_sym = malloc( sizeof(dword) * num_entries );
	if(! elf_to_ubf_sym )
		return 1;
	memset( elf_to_ubf_sym, -1, sizeof(dword) * num_entries );
	
	if(! read_input((void*)&str_t,
			section_table[section_table[i].sh_link].sh_size,
			section_table[section_table[i].sh_link].sh_offset ) ) {
		return 1;
	}

	if(! read_input((void*)&sym_table,
			section_table[i].sh_size,
			section_table[i].sh_offset ) ) {
		return 1;
	}

	header.extern_table = ftell(output_file);

	for( j = 0; j < section_table[i].sh_info; j++ ) {
		if( ELF32_ST_TYPE(sym_table[j].st_info) == STT_SECTION ) {
#ifdef _DEBUG_
			printf(
				"found section symbol[%u]: %s\n\tvalue:\t0x%x\n\tsize:\t%u\n\ttype:\t0x%x\n\tsect:\t0x%x\n",
				j,
				&str_t[sym_table[j].st_name],
				sym_table[j].st_value,
				sym_table[j].st_size,
				ELF32_ST_TYPE(sym_table[j].st_info),
				sym_table[j].st_shndx
			);
#endif
			if( sym_table[j].st_shndx < elf_num_sections ) {
#ifdef _DEBUG_
				printf( "elf_to_ubf_sym[%u] = %u\n", j,
						elf_to_ubf_sect[sym_table[j].st_shndx] );
#endif
				elf_to_ubf_sym[ j ] = elf_to_ubf_sect[sym_table[j].st_shndx];
			}
		}
	}
	
	for( j = section_table[i].sh_info; j < num_entries; j++ ) {
		if( ELF32_ST_BIND(sym_table[j].st_info) != STB_GLOBAL ) {
			fprintf( stderr,
				"binding of symbol \"%s\" is not global, skipping\n",
				&str_t[sym_table[j].st_name] );
			continue;
		}

		if(
			str_t[ sym_table[j].st_name ] == '_' &&
			str_t[ sym_table[j].st_name + 1 ] == 's' &&
			str_t[ sym_table[j].st_name + 2 ] == 't' &&
			str_t[ sym_table[j].st_name + 3 ] == 'a' &&
			str_t[ sym_table[j].st_name + 4 ] == 'r' &&
			str_t[ sym_table[j].st_name + 5 ] == 't' &&
			str_t[ sym_table[j].st_name + 6 ] == 0 ) {

#ifdef _DEBUG_
			puts( "found _start symbol" );
#endif
			if( entry_defined ) {
				fputs( "previous entry point (_start) already found; using first\n",
						stderr );
				continue;
			}
			header.entry_offset = sym_table[j].st_value;
			header.entry_sect = elf_to_ubf_sect[sym_table[j].st_shndx];
			entry_defined++;
			continue;
		}

		if( !(
			((str_t[ sym_table[j].st_name ] == '.' &&
			str_t[ sym_table[j].st_name + 1 ] == '.' &&
			str_t[ sym_table[j].st_name + 2 ] == '@' )
			                    ||
			(str_t[ sym_table[j].st_name ] == '_' &&
			str_t[ sym_table[j].st_name + 1 ] == '_' &&
			str_t[ sym_table[j].st_name + 2 ] == '_' )) &&
			
			str_t[ sym_table[j].st_name + 3 ] == 'V' &&
			str_t[ sym_table[j].st_name + 4 ] == 'O' &&
			str_t[ sym_table[j].st_name + 5 ] == 'i' &&
			str_t[ sym_table[j].st_name + 6 ] == 'D' ) ) {
			
			fprintf( stderr,
				"found non-VOiD global symbol \"%s\", skipping\n",
				&str_t[sym_table[j].st_name] );
			continue;
		}
		
		if(! sym_table[j].st_shndx ) {
#ifdef _DEBUG_
			printf(
				"found required symbol[%u]: %s\n\tvalue:\t0x%x\n\tsize:\t%u\n\ttype:\t0x%x\n\tsect:\t0x%x\n",
				j,
				&str_t[sym_table[j].st_name],
				sym_table[j].st_value,
				sym_table[j].st_size,
				ELF32_ST_TYPE(sym_table[j].st_info),
				sym_table[j].st_shndx
			);
#endif
			vid = atoi( &str_t[ sym_table[j].st_name + 7 ] );
#ifdef _DEBUG_
			printf( "elf_to_ubf_sym[%u] = %u\n", j, next_ubf_sym );
#endif
			header.num_externs++;
			elf_to_ubf_sym[ j ] = next_ubf_sym++;
			fwrite( &vid, sizeof(dword), 1, output_file );
		} else if( sym_table[j].st_shndx < SHT_LOPROC ) {
#ifdef _DEBUG_
			printf(
				"found global symbol[%u]: %s\n\tvalue:\t0x%x\n\tsize:\t%u\n\ttype:\t0x%x\n\tsect:\t0x%x\n",
				j,
				&str_t[sym_table[j].st_name],
				sym_table[j].st_value,
				sym_table[j].st_size,
				ELF32_ST_TYPE(sym_table[j].st_info),
				sym_table[j].st_shndx
			);
#endif
		} else {
			fprintf( stderr, "symbol \"%s\" has unsuported type, skiping\n",
					&str_t[sym_table[j].st_name] );
			continue;
		}
	}


	free( str_t );
//	free( sym_table );
	return 0;
}

//                                          -----------------------------------
//                                                          process_rel_table()
//=============================================================================
// This processes the relocation table and writes the UBF relocation table
// to the file. See put_reloc() for a description of just how it writes the
// tables to the output file.

int process_rel_table( dword i ) {
	Elf32_Rel	*reloc_table;
	dword		j;
	ubf_sect_node	*sect;
	ubf_reloc	reloc;
	
#ifdef _DEBUG_
	printf( "found reloc table \"%s\" for sect \"%s\" (UBF sect %u) with %u entries\n",
		&section_str_table[ section_table[i].sh_name ],
		&section_str_table[ section_table[ section_table[i].sh_info ].sh_name ],
		elf_to_ubf_sect[section_table[i].sh_info],
		section_table[i].sh_size / section_table[i].sh_entsize );
#endif

	if(! read_input((void*)&reloc_table,
			section_table[i].sh_size,
			section_table[i].sh_offset ) ) {
		return 1;
	}

	if( !symbol_table ) {
		process_sym_table( section_table[i].sh_link );
		symbol_table = section_table[i].sh_link;
	} else if( symbol_table != section_table[i].sh_link ) {
		fputs( "multiple symbol tables found", stderr );
		return 1;
	}

	sect = get_sect_node( elf_to_ubf_sect[section_table[i].sh_info] );
	sect->sect.rel_reloc = ftell( output_file );
	
	for( j=0; j < section_table[i].sh_size / section_table[i].sh_entsize; j++ ) {
		switch( ELF32_R_TYPE(reloc_table[j].r_info) ) {
			case R_386_32:
#ifdef _DEBUG_
				printf( "found abs relocation:\n\toffset: 0x%08x    sym: %3u\n",
					reloc_table[j].r_offset,
					ELF32_R_SYM(reloc_table[j].r_info) );
#endif
				reloc.target = reloc_table[j].r_offset;
				reloc.sym = elf_to_ubf_sym[ELF32_R_SYM(reloc_table[j].r_info)];
				if( reloc.sym == 0xFFFFFFFF )
				{
				  ubf_sect_node *sect_sym;
#ifdef _DEBUG_
				  fputs("\ttrying to resolve complex reloc\n", stdout);
#endif
				  if( sym_table[ELF32_R_SYM(reloc_table[j].r_info)].st_shndx == 0 )
				  {
				    fprintf(stderr,"ERROR: relying on external non-VOiD global symbol.\n");
				    break;
				  }
#ifdef _DEBUG_
				  fputs("\tmarked as complex\n",stdout);
#endif
				  reloc.sym = elf_to_ubf_sect[sym_table[ELF32_R_SYM(reloc_table[j].r_info)].st_shndx];
				  sect_sym = get_sect_node( reloc.sym );
				  add_complex_reloc( sect, reloc.target, sym_table[ELF32_R_SYM(reloc_table[j].r_info)].st_value );
				}

				put_reloc( reloc, &abs_reloc );
				sect->sect.abs_num++;
				break;
			case R_386_PC32:
#ifdef _DEBUG_
				printf( "found rel relocation:\n\toffset: 0x%08x    sym: %3u\n",
					reloc_table[j].r_offset,
					ELF32_R_SYM(reloc_table[j].r_info) );
#endif
				reloc.target = reloc_table[j].r_offset;
				reloc.sym = elf_to_ubf_sym[ELF32_R_SYM(reloc_table[j].r_info)];
				if( reloc.sym == 0xFFFFFFFF )
				{
				  ubf_sect_node *sect_sym;
#ifdef _DEBUG_
				  fputs("\ttrying to resolve complex reloc\n", stdout);
#endif
				  if( sym_table[ELF32_R_SYM(reloc_table[j].r_info)].st_shndx == 0 )
				  {
				    fprintf(stderr,"ERROR: relying on external non-VOiD global symbol.\n");
				    break;
				  }
#ifdef _DEBUG_
				  fputs("\tmarked as complex\n",stdout);
#endif
				  reloc.sym = elf_to_ubf_sect[sym_table[ELF32_R_SYM(reloc_table[j].r_info)].st_shndx];
				  sect_sym = get_sect_node( reloc.sym );
				  add_complex_reloc( sect, reloc.target, sym_table[ELF32_R_SYM(reloc_table[j].r_info)].st_value - reloc.target );
				  if( sect == sect_sym ) break;
				}
#ifdef _DEBUG_
				printf("\tubf sym: %u\n",reloc.sym);
#endif
				fwrite( &reloc, sizeof(reloc), 1, output_file );
				sect->sect.rel_num++;
				break;
			default:
				fputs( "unknown relocation type, ignoring\n", stderr );
				break;
		}
	}
	
	// now write the abs. relocations
	sect->sect.abs_reloc = ftell( output_file );
	while( abs_reloc.num ) {
		reloc = get_reloc(&abs_reloc);
		fwrite( &reloc, sizeof(reloc), 1, output_file );
	}

	free( reloc_table );
	return 0;
}

//                                          -----------------------------------
//                                                               section_type()
//=============================================================================
// This function takes a string and returns the coresponding UBF section type.

byte section_type( char *str ) {
	hash_entry	*cur;

#ifdef _DEBUG_
	printf( "looking up type of %s with hash %x\n", str, hash(str,strlen(str)) & 0xf );
#endif
	cur = special_sections[ hash(str,strlen(str)) & 0xf ];
	while( cur ) {
		if(! strcmp( str, cur->string ) )
			return cur->type;
		cur = cur->next;
	}
	return UBF_SHT_PROG;
}

//                                          -----------------------------------
//                                                              get_sect_node()
//=============================================================================
// This returns a pointer to the section node in memory of a given UBF section.

ubf_sect_node *get_sect_node( byte i ) {
	ubf_sect_node	*cur = first_ubf_sect;
	
	if( !i )
		return cur;
	
	while(i-- && cur) {
		cur = cur->next;
	}
	return cur;
}

//                                          -----------------------------------
//                                                                       hash()
//=============================================================================

/* this is an awesome hashing function from Bob Jenkins, 1996. Thanks Bob!
 * For a more complete discussion of the hash see
 * http://burtleburtle.net/bob/hash/doobs.html
 */

#define mix(a,b,c) \
{ \
  a -= b; a -= c; a ^= (c>>13); \
  b -= c; b -= a; b ^= (a<<8); \
  c -= a; c -= b; c ^= (b>>13); \
  a -= b; a -= c; a ^= (c>>12);  \
  b -= c; b -= a; b ^= (a<<16); \
  c -= a; c -= b; c ^= (b>>5); \
  a -= b; a -= c; a ^= (c>>3);  \
  b -= c; b -= a; b ^= (a<<10); \
  c -= a; c -= b; c ^= (b>>15); \
}

dword hash( register byte *k, register dword length)
{
   register dword a,b,c,len;

   /* Set up the internal state */
   len = length;
   a = b = c = 0x9e3779b9;  /* the golden ratio; an arbitrary value */

   /*---------------------------------------- handle most of the key */
   while (len >= 12)
   {
      a += (k[0] +((dword)k[1]<<8) +((dword)k[2]<<16) +((dword)k[3]<<24));
      b += (k[4] +((dword)k[5]<<8) +((dword)k[6]<<16) +((dword)k[7]<<24));
      c += (k[8] +((dword)k[9]<<8) +((dword)k[10]<<16)+((dword)k[11]<<24));
      mix(a,b,c);
      k += 12; len -= 12;
   }

   /*------------------------------------- handle the last 11 bytes */
   c += length;
   switch(len)              /* all the case statements fall through */
   {
   case 11: c+=((dword)k[10]<<24);
   case 10: c+=((dword)k[9]<<16);
   case 9 : c+=((dword)k[8]<<8);
      /* the first byte of c is reserved for the length */
   case 8 : b+=((dword)k[7]<<24);
   case 7 : b+=((dword)k[6]<<16);
   case 6 : b+=((dword)k[5]<<8);
   case 5 : b+=k[4];
   case 4 : a+=((dword)k[3]<<24);
   case 3 : a+=((dword)k[2]<<16);
   case 2 : a+=((dword)k[1]<<8);
   case 1 : a+=k[0];
     /* case 0: nothing left to add */
   }
   mix(a,b,c);
   /*-------------------------------------------- report the result */
   return c;
}



//                                          -----------------------------------
//                                                       apply_complex_relocs()
//=============================================================================
void apply_complex_relocs(void) {
  complex_reloc_node *next, *reloc;
  dword	value = 0;

#ifdef _DEBUG_
  fputs("applying complex relocs..\n",stdout);
#endif

  reloc = complex_relocs;
  while( reloc )
  {
#ifdef _DEBUG_
    printf("\toffset: %08X + %08X modifier: %08X\n", reloc->offset, reloc->sect->sect.loc, reloc->value);
#endif
    fseek( output_file, (reloc->sect->sect.loc + reloc->offset), SEEK_SET );
    fread( &value, sizeof(dword), 1, output_file );
#ifdef _DEBUG_
    printf("\tvalue was: %08X", value);
#endif
    value += reloc->value;
#ifdef _DEBUG_
    printf("\tvalue is : %08X\n", value);
#endif
    fseek( output_file, (reloc->sect->sect.loc + reloc->offset), SEEK_SET );
    fwrite( &value, sizeof(dword), 1, output_file );

    next = reloc->next;
    free( reloc );
    reloc = next;
  }
  fseek( output_file, 0, SEEK_END );
}
