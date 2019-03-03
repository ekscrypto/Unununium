/*
 * $Header: /cvsroot/uuu/dimension/devtool/elf2ubf/ubfdump.c,v 1.1 2002/01/17 04:41:08 instinc Exp $
 *
 * ubfdump UBF file infomation dumper
 *   reads in a UBF file and prints all sorts of goodies on it to stdout
 *
 * Copyright (C) 2001 Phil Frost
 * This software is distributed under the BSD license,
 * see file "license" for details.
 *
 * for UBF specs see:
 *   http://uuu.sf.net/docs/ubf.html
 *
 * status:
 * -------
 * quite simple program; I don't think there are any bugs and there's really
 * nothing to do (except maybe do a better job of checking for failed mallocs
 * and such)
 */

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
#include "elf.h"
#include "ubf.h"

//                                          -----------------------------------
//                                                                         data
//=============================================================================

FILE *input_file;

int dump_extern_table( dword table_loc, dword num_externs, byte num_sections );
int dump_section_table( dword table_loc, byte num_sections );

//                                          -----------------------------------
//                                                                   prototypes
//=============================================================================

int read_input( void **buf, int size, dword loc );

//                                          -----------------------------------
//                                                                       main()
//=============================================================================

int main( int argc, char *argv[] ) {
	ubf_header	*header;
	
	if( argc != 2 ) {
		fputs( "ubfdump version $Revision: 1.1 $\nusage: test INPUT\n", stderr );
		return 1;
	}
	
	input_file = fopen( argv[1], "rb" );
	if(! input_file ) {
		fprintf( stderr, "unable to open input file: %s\n", argv[1] );
		return 1;
	}

	read_input( (void*)&header, sizeof(ubf_header), 0 );
	if( header->magic != 0x4642557F ) {
		fputs( "file is not a valid UBF file\n", stderr );
		return 1;
	}

	printf( "UBF version %u file\n  required features: 0x%08x\n  stack size: %u bytes\n  cpu required: %u\n  entry offset 0x%x in section %u\n\n",
			header->ubf_version,
			header->required_features,
			1<<(header->stack_size),
			header->required_cpu,
			header->entry_offset,
			header->entry_sect
	      );
	
	dump_extern_table( header->extern_table, header->num_externs, header->num_sections );
	dump_section_table( header->section_table, header->num_sections );
	
	free( header );
	fclose( input_file );
	return 0;
}




int dump_extern_table( dword table_loc, dword num_externs, byte num_sections ) {
	dword		*ext;
	dword		i;

	printf( "extern table at 0x%x; %u externs defined\n", table_loc, num_externs );

	read_input( (void*)&ext, num_externs*sizeof(dword), table_loc );

	for( i=0; i < num_sections; i++) {
		printf( "  [%3u] section: %u (implied)\n", i, i );
	}
	
	for( i=0; i < num_externs; i++ ) {
		printf( "  [%3u] VID: %u\n", i+num_sections, ext[i] );
	}
	puts( "" );

	free( ext );
	return 0;
}




int dump_reloc_table( dword table_loc, byte num_relocs ) {
	dword		i;
	ubf_reloc	*reloc;

	printf( "reloc table at 0x%x; %u entries\n", table_loc, num_relocs );
	
	read_input( (void*)&reloc, num_relocs*sizeof(ubf_reloc), table_loc );

	for( i=0; i < num_relocs; i++ ) {
		printf( "  target: 0x%08x  sym: %u\n", reloc[i].target, reloc[i].sym );
	}
	puts ("");

	free( reloc );
	return 0;
}




int dump_section_table( dword table_loc, byte num_sections ) {
	ubf_sect	*sect;
	dword		i;

	printf( "section table at 0x%x; %u sections defined\n\n", table_loc, num_sections );

	read_input( (void*)&sect, num_sections*sizeof(ubf_sect), table_loc );

	for( i=0; i < num_sections; i++ ) {
		printf( "===========================] section %u [===========================\nlocation: 0x%x\nsize: %u bytes\ntype: %u\n\n",
				i,
				sect[i].loc,
				sect[i].size,
				sect[i].type
		      );
		printf( "  rel " );
		dump_reloc_table( sect[i].rel_reloc, sect[i].rel_num );

		printf( "  abs " );
		dump_reloc_table( sect[i].abs_reloc, sect[i].abs_num );
	}
	
	free( sect );
	return 0;
}

//                                          -----------------------------------
//                                                                 read_input()
//=============================================================================

int read_input( void **buf, int size, dword loc ) {
	*buf = malloc( size );
	if(! *buf ) return(0);
	if( fseek( input_file, loc, SEEK_SET ) ) return(0);
	fread(*buf, size, 1, input_file );
	return 0;
}
