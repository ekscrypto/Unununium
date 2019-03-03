/* U3L >> Unununium Linker <<
 * Copyright (C) 2001, Dave Poirier
 * Distributed under the BSD License
 */


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "u3l.h"

//#define __DEBUG__

#define VERSION "($Revision: 1.38 $)"
#define COPYRIGHTS "Copyright (C) 2001, Dave Poirier\nDistributed under the BSD License"

#define MAX_ALIGNMENT	512

//----------------------------------------------------------------------------
//                        INITIALIZED DATA SECTION
//----------------------------------------------------------------------------
static char	default_output[]	="u3core.bin";
static char	default_vid_listing[]	="functions.txt";
static char	default_core_map[]	="u3core.map";
static char	section_filler[]	=".s_filler";
byte		*section_filler_buffer	=NULL;

FILE		*fp_output		=NULL;
FILE		*fp_core_map		=NULL;
char		*output_filename	=default_output;
char		*coremap_filename	=default_core_map;
char		*vid_listing_filename 	=default_vid_listing;

word		linker_options		=0;
#define		OPT_MASK_DRP			0x0001
#define		OPT_MASK_ABORT_WARNING		0x0002
#define		OPT_MASK_GEN_VIDLISTING		0x0004
#define		OPT_MASK_HYBRID_OBJECTS		0x0008
#define		OPT_MASK_ZERO_SIZE_SECTIONS	0x0010
#define		OPT_MASK_WARN_MISALIGNMENTS	0x0020
#define		OPT_MASK_EXCLUDE_DLP		0x0040
#define		OPT_MASK_REDEFINITION		0x0080
#define		OPT_MASK_GEN_COREMAP		0x0100

dword		global_offset		=0x00008000,
		section_alignment	=16,
		section_alignment_data	=0,
		init_alignment		=1,
		init_alignment_data	=0x90,
		cell_alignment		=64,
		cell_alignment_data	=0,
		c_info_alignment	=4,
		c_info_alignment_data	=0,
		errors			=0,
		warnings		=0,
		stack_override		=0;

node_obj	*root_obj		=NULL,
		*last_obj		=NULL;

node_section	*root_sorted_sections	=NULL;
node_section	*osw_pre_init		=NULL;
node_obj	*osw_pre_init_obj	=NULL;
node_section	*osw_inter_init		=NULL;
node_obj	*osw_inter_init_obj	=NULL;
node_section	*osw_post_init		=NULL;
node_obj	*osw_post_init_obj	=NULL;
node_section	*first_non_init_section	=NULL;

node_cell	*root_cell		=NULL;

hdr_core	core_header={ 0x45526F43,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 };

node_gsymbol	*root_globals		=NULL;
node_function	*root_functions		=NULL;
node_drp	*root_drp		=NULL;
node_dlp	*root_dlp_rel		=NULL;
node_dlp	*root_dlp_abs		=NULL;


#define OPT_COUNT 0x13
static char *options[OPT_COUNT] = {
  "offset",				// 0x01
  "include-drp\0",			// 0x02
  "help\0",				// 0x03
  "abort-on-warning\0",			// 0x04
  "generate-vid-listing",		// 0x05
  "hybrid-objects\0",			// 0x06
  "include-zero-size-sections\0",	// 0x07
  "section-alignment" ,			// 0x08
  "section-alignment-data",		// 0x09
  "init-alignment",			// 0x0A
  "init-alignment-data",		// 0x0B
  "warn-misalignments\0",		// 0x0C
  "cell-alignment",			// 0x0D
  "cell-alignment-data",		// 0x0E
  "exclude-dlp\0",			// 0x0F
  "version\0" ,				// 0x10
  "redefinition-allowed\0",		// 0x11
  "stack-location",			// 0x12
  "generate-core-map" };		// 0x13
static char options_length[OPT_COUNT] = {
  6, 12, 5, 17, 20, 15, 27, 17, 22, 14,
  19, 19, 14, 19, 12, 8, 21, 14, 17 };
//static char options_values[OPT_COUNT] = {
//  0x01,  0x02,  0x03,  0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,
//  0x0B };

static char str_help[]="\
u3l [options] +ofile1 [+ofile2 [+ofile3...]] [output_filename]\n\
Where:\n\
\n\
[options] may be one of the following:\n\
--abort-on-warning                    Return error code and abort linking on\n\
                                      any warning\n\
--cell-alignment=00000000             Modify the default cell alignment\n\
--cell-alignment-data=00000000        Modify the default data value used to\n\
                                      fill misaligned cells. Default value: 0\n\
--exclude-dlp                         Force Dynamic Link Point data exclusion\n\
--generate-core-map[=file]            Tell the linker to generate a map of\n\
                                      all the data/code sections in the core.\n\
                                      By default, file is \"u3core.map\"\n\
--generate-vid-listing[=file]         Tell the linker to generate a list of\n\
                                      all the VOiD globals and their ID numbers\n\
                                      it detected. Default file is functions.txt\n\
--help                                Display this help\n\
--hybrid-objects                      Disable warnings when the same object\n\
                                      contains osw and cell informations\n\
--include-drp                         Force the linker to include all Dynamic\n\
                                      Recalculation Points\n\
--include-zero-size-sections          Disable warning about zero size sections\n\
--init-alignment=00000000             Alignment to apply to initialization\n\
                                      sections.  Default alignment is 1\n\
--init-alignment-value=00000000       Modify default data value used for the\n\
                                      alignment of initialization sections.\n\
                                      Default value: 90h (NOP)\n\
--offset=00000000                     Override default offset of 00008000h\n\
--redefinition-allowed                Disable warning of multiple globals\n\
                                      defined with the same value\n\
--section-alignment=00000000          Allow to override default section\n\
                                      alignment of 16\n\
--section-alignment-data=00000000     Modify default data value used for the\n\
                                      alignment of non-specific sections.\n\
                                      Default value: 0\n\
--stack-location=00000000             Override default stack location of the\n\
                                      multiboot entry point.  Default is just\n\
                                      under the core loading address\n\
--version                             Displays current linker version\n\
--warn-misalignments                  Generates warning if the linker detects\n\
                                      any misaligned section\n\
\n\
All values are given in hexadecimal, without leading 0x or trailing h\n\
\n\
+o<file>                              Indicate to add this object in the core.\n\
                                      At least one object must be specified\n\
\n\
[output_filename]                     Override the default core file name:\n\
                                      \"u3core.bin\"\n\n";
				      

static char str_out_of_mem[]="Error: Out of memory\n";

#ifdef __DEBUG__
int elib_memblocks_allocated=0;
int elib_memblocks_deallocated=0;
#endif

//----------------------------------------------------------------------------
//                     DATA TO BE INITIALIZED BEFORE USAGE
//----------------------------------------------------------------------------
hdr_core	core_header;



//----------------------------------------------------------------------------
//                          FUNCTION PROTOTYPING
//----------------------------------------------------------------------------
int add_dlp_abs_point( byte *name, dword fix_point, node_obj *o );
int add_dlp_rel_point( byte *name, dword fix_point, node_obj *o );
int add_drp_point( dword fix_point );
int add_global( byte *name, dword value, Elf32_Sym *sym, dword strength, node_obj *o );
int add_local( byte *name, dword value, node_obj *o );
void add_obj( byte *filename );
int apply_reloc( Elf32_Rel *rel, dword reltab_size, Elf32_Sym *symtab, byte *buffer, node_obj *o, node_section *s );
int calculate_global_offsets( void );
void cmdline_check_option( char *option );
int cmdline_parse( int argc, char **argv );
int create_ordered_section_list( void );
int elib_fread( FILE *fp, void **buffer, size_t size, size_t offset, char *name );
void elib_free( void *p );
int elib_fwrite( FILE *fp, void *buffer, size_t size, size_t offset, char *name );
void *elib_malloc( size_t size );
int flush_node_sections( void );
void free(void *ptr);
void free_allocated_structures( void );
int generate_core( void );
int generate_function_list( void );
int get_function_details( byte *name, dword *vid, dword *value );
int get_global_value( byte *cell, byte *name, dword *value );
dword get_offset( byte *hexstring );
int get_section_global_offset( dword *value, dword shndx, node_obj *o);
int is_global_function( byte *name );
int open_objects( void );
int produces_vid_listing( void );
int update_symtables( void );
int validate_elf_header( Elf32_hdr *elf_header, char *filename);


//----------------------------------------------------------------------------
int main (int argc, char **argv) {
//----------------------------------------------------------------------------

#ifdef __DEBUG__
  fprintf( stderr, "main() parsing command line options\n");
#endif
  // Parse command line for options and objects
  if( cmdline_parse( argc, argv ) ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
	  goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() command line parsed, opening up all specified objects\n");
#endif

  // Open up all specified objects
  if( open_objects() ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
	  goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() objects properly opened, creating ordered section list\n");
#endif
  // Now, we got all the objects, opened, with the following loaded:
  // shtab
  // shstrtab
  // symtab
  // strtab
  // and the file is opened with a pointer in node_obj->fp
  //
  // also, all the information concerning the progbits sections has already
  // been loaded, allowing us to do the size calculation right away.

  if( create_ordered_section_list() ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
    goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() ordered section list created, flushing out all node_section of the node_obj");
#endif

  if( flush_node_sections() ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
    goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() node_section flushed, proceeding to global offset adjustments\n");
#endif

  if( calculate_global_offsets() ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
    goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() global offset recalculations completed, recalculating symbol tables\n");
#endif

  if( update_symtables() ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
    goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() symbol tables updated. Generating provided function list\n");
#endif

  if( generate_function_list() ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
    goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() function list generated, now proceeding to core generation\n");
#endif

  if( generate_core() ) goto quick_exit;
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
    goto quick_exit;

#ifdef __DEBUG__
  fprintf( stderr, "main() core generated\n");
#endif

  if( (linker_options & OPT_MASK_GEN_VIDLISTING) ) produces_vid_listing();

quick_exit:
  free_allocated_structures();
#ifdef __DEBUG__
  fprintf( stderr, "main() ready to exit, total memory blocks allocated: %i, total memory blocks de-allocated: %i\n", elib_memblocks_allocated, elib_memblocks_deallocated);
  fprintf( stderr, "main() terminating with %i error(s) and %i warning(s)\n", (int)errors, (int)warnings);
#endif
  if( warnings && (linker_options & OPT_MASK_ABORT_WARNING) != 0)
    return errors+warnings;
  return errors;
}

//----------------------------------------------------------------------------
int add_dlp_abs_point( byte *name, dword fix_point, node_obj *o ) {
//----------------------------------------------------------------------------

  node_dlp *dlp;

#ifdef __DEBUG__
  fprintf( stderr, "add_dlp_abs_point([%s], [%p], [%p]) called\n", name, (void *)fix_point, o);
#endif

  dlp = (node_dlp *)elib_malloc(sizeof(node_dlp));
  if( !dlp ) return 1;

  dlp->fix_point	= fix_point;
  dlp->parent_obj	= o;
  if( !get_function_details(
	name,
	(dword *)&dlp->vid,
	NULL )
      ) {
    dlp->next_node = root_dlp_abs;
    root_dlp_abs = dlp;
#ifdef __DEBUG__
    fprintf( stderr, "add_dlp_abs_point() completed, dlp allocated at [%p]\n", dlp);
#endif
    return 0;
  }

  elib_free( dlp );
#ifdef __DEBUG__
  fprintf( stderr, "add_dlp_abs_point() failed\n");
#endif
  return 1;
}

//----------------------------------------------------------------------------
int add_dlp_rel_point( byte *name, dword fix_point, node_obj *o ) {
//----------------------------------------------------------------------------

  node_dlp *dlp;

#ifdef __DEBUG__
  fprintf( stderr, "add_dlp_rel_point([%s], [%p], [%p]) called\n", name, (void *)fix_point, o);
#endif

  dlp = (node_dlp *)elib_malloc(sizeof(node_dlp));
  if( !dlp ) return 1;

  dlp->fix_point	= fix_point;
  dlp->parent_obj	= o;
  if( !get_function_details(
	name,
	&dlp->vid,
	NULL )
      ) {
    dlp->next_node = root_dlp_rel;
    root_dlp_rel = dlp;
#ifdef __DEBUG__
    fprintf( stderr, "add_dlp_rel_point() completed, dlp allocated at [%p]\n", dlp);
#endif
    return 0;
  }

  elib_free( dlp );
#ifdef __DEBUG__
  fprintf( stderr, "add_dlp_rel_point() failed\n");
#endif
  return 1;
}

//----------------------------------------------------------------------------
int add_drp( dword fix_point ) {
//----------------------------------------------------------------------------

  node_drp *drp;

#ifdef __DEBUG__
  fprintf( stderr, "add_drp(%p) called\n", (void *)fix_point);
#endif

  drp = (node_drp *)elib_malloc(sizeof(node_drp));
  if( !drp ) return 1;

  drp->next_node = root_drp;
  root_drp = drp;
  drp->fix_point = fix_point;

#ifdef __DEBUG__
  fprintf( stderr, "add_drp() completed, point created at [%p]\n", drp);
#endif
  return 0;
}

//----------------------------------------------------------------------------
int add_global( byte *name, dword value, Elf32_Sym *sym, dword strength, node_obj *o ) {
//----------------------------------------------------------------------------
  node_gsymbol *gsym;

#ifdef __DEBUG__
  fprintf( stderr, "add_global([%s], [%p], [%lu], [%p]) called\n", name, (void *)value, strength, o);
#endif

  gsym = root_globals;
  // Make sure no global exist with the same name
  while( gsym ) {
    if( !strcmp( name, gsym->name ) ) break;
    gsym = gsym->next_node;
  }

  if( !gsym ) {
    // global with this name doesn't exist yet, simply add it
    gsym = (node_gsymbol *)elib_malloc(sizeof(node_gsymbol));
    if( !gsym ) return 1;

    gsym->next_node		= root_globals;
    root_globals		= gsym;
    gsym->name			= name;
    gsym->value			= value;
    gsym->strength		= strength;
    gsym->parent_obj		= o;
    gsym->sym			= sym;
#ifdef __DEBUG__
    fprintf( stderr, "add_global() symbol created at [%p] with given attributes\n", gsym);
#endif
    return 0;
  }

  if( gsym->strength == strength ) {
    if( strength == 0 ) {
#ifdef __DEBUG__
      fprintf( stderr, "add_global() symbol with same strength [weak] found, discarding registration\n");
#endif
      return 0;
    }

    if( gsym->value == value ) {
      if( !(linker_options & OPT_MASK_REDEFINITION)) {
      fprintf( stderr, "Warning: Global symbol [%s] redefined in object [%s]\n",name, o->filename);
      warnings++;
      return 0;
      }
    }
    else {
      fprintf( stderr, "Error: Global symbol [%s] defined in object [%s] conflict with symbol already defined in object [%s]\n", name, o->filename, ((node_obj *)gsym->parent_obj)->filename);
      errors++;
      return 1;
    }
  }

  if( strength == 1 ) {
    gsym->value			= value;
    gsym->strength		= strength;
    gsym->parent_obj		= o;
    gsym->sym			= sym;
#ifdef __DEBUG__
    fprintf( stderr, "add_global() global replacing old weak definition at [%p]\n", gsym);
#endif
  }

#ifdef __DEBUG__
  fprintf( stderr, "add_global() returning\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
int add_local( byte *name, dword value, node_obj *o ) {
//----------------------------------------------------------------------------
  node_lsymbol *lsym;

#ifdef __DEBUG__
  fprintf( stderr, "add_local( [%s], [%p], [%p] ) called\n", name, (void *)value, o);
#endif

  if( !strcmp( name, "__CELL_START__" ) ||
      !strcmp( name, "__CELL_END__" ) ||
      !strcmp( name, "__CELL_SIZE__" ) ||
      !strcmp( name, "__CORE_HEADER__" ) ||
      !strcmp( name, "__LINKED_OFFSET__" ) ) {
    fprintf( stderr, "Warning: Reserved symbol [%s] defined in object [%s]\n", name, o->filename);
    warnings++;
  }

  lsym = o->locals;
  while( lsym ) {
    if( !strcmp( name, lsym->name ) ) break;
    lsym = lsym->next_node;
  }

  if( !lsym ) {
    lsym = (node_lsymbol *)elib_malloc(sizeof(node_lsymbol));
    if( !lsym ) return 1;

    lsym->next_node	= o->locals;
    o->locals		= lsym;
    lsym->name		= name;
    lsym->value		= value;
#ifdef __DEBUG__
    fprintf( stderr, "add_local() symbol created at [%p] with given attributse\n", lsym);
#endif
    return 0;
  }

  fprintf( stderr, "Error: Local symbol [%s] defined twice in object [%s]\n", name, o->filename);
  errors++;
  return 1;
}

//----------------------------------------------------------------------------
void add_obj( byte *filename ) {
//----------------------------------------------------------------------------
  node_obj *elf_object;

#ifdef __DEBUG__
  fprintf( stderr, "add_obj(%s) called\n", filename);
#endif
  elf_object = (node_obj *)elib_malloc(sizeof(node_obj));
  if( !elf_object ) return;

  if( !root_obj ) {
#ifdef __DEBUG__
    fprintf( stderr, "add_obj() Linking up allocated node_obj [%p] of object [%s] as root\n", elf_object, filename);
#endif
    root_obj = elf_object;
    last_obj = elf_object;
  }
  else {
#ifdef __DEBUG__
    fprintf( stderr, "add_obj() Linking up allocated node_obj [%p] of object [%s] as child of [%p]\n", elf_object, filename, last_obj);
#endif
    last_obj->next_node = elf_object;
    last_obj = elf_object;
  }

  elf_object->next_node		= NULL;
  elf_object->sections		= NULL;
  elf_object->shtab		= NULL;
  elf_object->shstrtab		= NULL;
  elf_object->strtab		= NULL;
  elf_object->symtab		= NULL;
  elf_object->symtab_size	= 0;
  elf_object->filename		= filename;
  elf_object->fp		= NULL;
  elf_object->shnum		= 0;
  elf_object->cell_header	= NULL;
  elf_object->locals		= NULL;

#ifdef __DEBUG__
  fprintf( stderr, "add_obj() node_obj [%p] of object [%s] allocated\n", elf_object, filename);
  fprintf( stderr, "add_obj() completed\n");
#endif

}

//----------------------------------------------------------------------------
int apply_reloc( Elf32_Rel *rel, dword reltab_size, Elf32_Sym *symtab, byte *buffer, node_obj *o, node_section *s ) {
//----------------------------------------------------------------------------
  int i;
  Elf32_Sym *sym;
  node_gsymbol *gsym;

#ifdef __DEBUG__
  fprintf( stderr, "apply_reloc( [%p], [%lu], [%p], [%p], [%p] ) called\n", rel, reltab_size, symtab, buffer, o);
#endif

  i = reltab_size / sizeof(Elf32_Rel);
  while( i-- ) {
    sym = &symtab[ELF32_R_SYM(rel->r_info)];
    switch( ELF32_R_TYPE(rel->r_info) ) {
      case( R_386_32 ):
#ifdef __DEBUG__
	fprintf( stderr, "apply_reloc() applying R_386_32 relocation at offset [%p] using symbol [%lu] of value [%p]\n\told value: %p\n", (void *)rel->r_offset, ELF32_R_SYM(rel->r_info), (void *)symtab[ELF32_R_SYM(rel->r_info)].st_value, (dword *)(*(dword *)((dword)buffer + rel->r_offset)));
#endif
	*(dword *)((dword)buffer + rel->r_offset) += sym->st_value;
#ifdef __DEBUG__
	fprintf( stderr, "\tnew value: %p\n", (dword *)(*(dword *)((dword)buffer + rel->r_offset)));
#endif

	// TODO: ADD DRP/DLP_ABS in CORE_DRP/CORE_DLP_ABS list
	if( is_global_function( &o->strtab[sym->st_name] ) ) {
#ifdef __DEBUG__
	    fprintf( stderr, "apply_reloc() global dlp abs detected: %s\n", &o->strtab[sym->st_name] );
#endif
	    if( add_dlp_abs_point( &o->strtab[sym->st_name], rel->r_offset + s->global_offset, o) ) return 1;
	}
	else {
	  // check if symbol is local, if so, check if it's dependant on a
	  // section then register it.
	  if( ELF32_ST_TYPE(sym->st_info) == STT_SECTION ||
	      ( ELF32_ST_TYPE(sym->st_info) == STT_NOTYPE &&
		sym->st_shndx > 0 && sym->st_shndx < SHN_ABSOLUTE ) ) {
	    if( add_drp( rel->r_offset + s->global_offset ) ) return 1;
	  }
	  else {
	    // if symbol isn't undefined, no need to check for globals
	    if( sym->st_shndx != 0 ) break;

	    if( !strcmp( &o->strtab[sym->st_name], "__CORE_HEADER__" )) {
	      if( add_drp( rel->r_offset + s->global_offset ) ) return 1;
	      break;
	    }
			    
	    gsym = root_globals;
	    while( gsym ) {
	      if( !strcmp( gsym->name, &o->strtab[sym->st_name]) ) break;
	      gsym = gsym->next_node;
	    }
	    if( !gsym ) {
	      fprintf( stderr, "Error: Internal Error, required global seems to have suddenly dissappeared! [%s]\n", &o->strtab[sym->st_name] );
	      errors++;
	      return 1;
	    }

	    sym = gsym->sym;
	    if( !(ELF32_ST_BIND(sym->st_info) == STB_GLOBAL ||
		  ELF32_ST_BIND(sym->st_info) == STB_WEAK ) ) {
	      fprintf( stderr, "Error: Internal Error, somehow a global has been associated with something not a global or weak symbol: %s\n", gsym->name);
	      errors++;
	      return 1;
	    }
	
	    // sym == either a global or weak that provides current global
	    if( sym->st_shndx > 0 && sym->st_shndx < SHN_ABSOLUTE ) {
	      if( add_drp( rel->r_offset + s->global_offset ) ) return 1;
	    }
	  }
	}
	break;

      case( R_386_PC32 ):
#ifdef __DEBUG__
	fprintf( stderr, "apply_reloc() applying R_386_PC32 relocation at offset [%p] of section [%s] with global offset of [%p] using symbol [%lu] of value [%p]\n\told value: %p\n", (void *)rel->r_offset, s->sh_name, (void *)s->global_offset, ELF32_R_SYM(rel->r_info), (void *)symtab[ELF32_R_SYM(rel->r_info)].st_value, (dword *)(*(dword *)((dword)buffer + rel->r_offset)));
#endif
	*(dword *)((dword)buffer + rel->r_offset) +=
	  symtab[ELF32_R_SYM(rel->r_info)].st_value -
	  (rel->r_offset + s->global_offset);
#ifdef __DEBUG__
	fprintf( stderr, "\tnew value: %p\n", (dword *)(*(dword *)((dword)buffer + rel->r_offset)));
#endif

	if( is_global_function(
	      &o->strtab[symtab[ELF32_R_SYM(rel->r_info)].st_name] )
	    ) {
#ifdef __DEBUG__
	  fprintf( stderr, "apply_reloc() global dlp rel detected: %s\n", &o->strtab[symtab[ELF32_R_SYM(rel->r_info)].st_name] );
#endif
	  if( add_dlp_rel_point( &o->strtab[sym->st_name], rel->r_offset + s->global_offset, o ) ) return 1;
	}
	break;

      default:
	fprintf( stderr, "Error: Type of relocation requested in object [%s] is currently unsupported. Please contact UUU development with code: %lu\n", o->filename, ELF32_R_TYPE(rel->r_info));
    }
    rel++;
  }

#ifdef __DEBUG__
  fprintf( stderr, "apply_reloc() completed\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
int calculate_global_offsets( void ) {
//----------------------------------------------------------------------------
  dword offset = 0, size=0, misalignment=0;
  node_cell *c=NULL;
  node_section *s=NULL, *ns=NULL, *ls=NULL;

#ifdef __DEBUG__
  fprintf( stderr, "calculate_global_offset() started\n");
#endif

  offset = global_offset + sizeof(hdr_core) +
    (core_header.cell_count * sizeof(hdr_cell));


  c = root_cell;
  while( c ){
    if( c->c_info ) {
      misalignment = offset % c_info_alignment;
      if( misalignment ) {
	misalignment = c_info_alignment - misalignment;
#ifdef __DEBUG__
	fprintf( stderr, "calculate_global_offsets().phase1 misalignment of [%i/%i] detected while processing .c_info of object [%s] bytes are inserted\n", (int)misalignment, (int)c_info_alignment, ((node_obj *)c->parent_obj)->filename);
#endif
	((node_section *)c->c_info)->next_node =
	  (node_section *)elib_malloc(sizeof(node_section));
	if( !((node_section *)c->c_info)->next_node ) return 1;

	((node_section *)((node_section *)c->c_info)->next_node)->next_node =
	  NULL;
	((node_section *)((node_section *)c->c_info)->next_node)->global_offset=
	  misalignment;
	((node_section *)((node_section *)c->c_info)->next_node)->sh_name =
	  section_filler;
	((node_section *)((node_section *)c->c_info)->next_node)->shndx =
	  c_info_alignment_data;
	offset += misalignment;
      }
#ifdef __DEBUG__
      fprintf( stderr, "calculate_global_offset() c_info of object [%s]'s offset fixed at [%x]\n", ((node_obj *)c->parent_obj)->filename, (int)offset);
#endif
      c->final_hdr.c_info = offset;
      ((node_section *)c->c_info)->global_offset = offset;
      size = ((Elf32_Shdr *)((node_section *)c->c_info)->sh_entry)->sh_size;
      offset += size;
    }
    c = c->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "calculate_global_offsets() phase I completed, end of header+.c_info offset fixed to [%p], proceeding to phase II: fixing offsets of init sections\n", (void *)offset);
#endif

  s = root_sorted_sections;
  ls = NULL;
  while( s ) {
    misalignment = offset % init_alignment;
    if( misalignment ) {
      misalignment = init_alignment - misalignment;
      ns = (node_section *)elib_malloc(sizeof(node_section));
      if( !ns ) return 1;
      ns->next_node = s;
      ns->global_offset = misalignment;
      ns->sh_name = section_filler;
      ns->shndx = init_alignment_data;
      if( !ls )
	root_sorted_sections = ns;
      else
	ls->next_node = ns;
      offset += misalignment;
      ls = ns;
#ifdef __DEBUG__
      fprintf( stderr, "calculate_global_offsets().phase2 alignement is required before including section [%s] of object [%s], total bytes inserted [%i/%i]\n", s->sh_name, ((node_obj *)s->parent_obj)->filename, (int)misalignment, (int)init_alignment);
#endif
    }
#ifdef __DEBUG__
    fprintf( stderr, "calculate_global_offsets().phase2 section [%s] of object [%s]'s offset fixed at [%p]\n", s->sh_name, ((node_obj *)s->parent_obj)->filename, (void *)offset);
#endif
    s->global_offset = offset;
    offset += ((Elf32_Shdr *)s->sh_entry)->sh_size;
    ls = s;
    s = s->next_node;
    if( s == first_non_init_section ) break;
  }

#ifdef __DEBUG__
  fprintf( stderr, "calculate_global_offsets() phase II completed, proceeding to phase III: calculating global offsets of regular sections\n");
#endif

  if( !s ) return 0;

  if( cell_alignment < section_alignment ) {
    fprintf( stderr, "Warning: cell alignment value is set lower than section alignment value\n");
    warnings++;
  }


  c = root_cell;
  while( c ) {
    if( c->parent_obj != s->parent_obj ) {
      fprintf( stderr, "Warning: Object file [%s] contains [.c_info] section but cell itself is empty\n", ((node_obj *)c->parent_obj)->filename);
      warnings++;
      c = c->next_node;
      continue;
    }

    misalignment = offset % cell_alignment;
    if( misalignment ) {
      misalignment = cell_alignment - misalignment;
      ns = (node_section *)elib_malloc(sizeof(node_section));
      if( !ns ) return 1;
      ns->next_node		= s;
      ns->global_offset		= misalignment;
      ns->sh_name		= section_filler;
      ns->shndx			= cell_alignment_data;
      if( !ls )
	root_sorted_sections	= ns;
      else
	ls->next_node		= ns;
      offset			+= misalignment;
      ls			= ns;
#ifdef __DEBUG__
      fprintf( stderr, "calculate_global_offsets().phase3 alignment required and inserted before section [%s] of object [%s], total bytes inserted [%i/%i]\n", s->sh_name, ((node_obj *)s->parent_obj)->filename, (int)misalignment, (int)cell_alignment);
#endif
    }
    c->final_hdr.c_start = offset;
    while( s && c->parent_obj == s->parent_obj ) {

      misalignment = offset % section_alignment;
      if( misalignment ) {
        misalignment = section_alignment - misalignment;
        ns = (node_section *)elib_malloc(sizeof(node_section));
        if( !ns ) return 1;
        ns->next_node		= s;
        ns->global_offset	= misalignment;
        ns->sh_name		= section_filler;
        ns->shndx 		= section_alignment_data;
	if( !ls )
	  root_sorted_sections	= ns;
	else
	  ls->next_node		= ns;
        offset			+= misalignment;
        ls			= ns;
#ifdef __DEBUG__
        fprintf( stderr, "calculate_global_offsets().phase3 alignment is required before including section [%s] of object [%s], total bytes inserted [%i/%i]\n", s->sh_name, ((node_obj *)s->parent_obj)->filename, (int)misalignment, (int)section_alignment);
#endif
      }
#ifdef __DEBUG__
      fprintf( stderr, "calculate_global_offsets().phase3 section [%s] of object [%s]'s offset fixed at [%p]\n", s->sh_name, ((node_obj *)s->parent_obj)->filename, (void *)offset);
#endif
      s->global_offset = offset;
      offset += ((Elf32_Shdr *)s->sh_entry)->sh_size;
      ls = s;
      s = s->next_node;
    }
    // the newly loaded section 's' is either (Nil) or isn't part of the same
    // object file (different cell).

    // this is not an error, we re-align the offset so as to have a cell size
    // aligned on a minimum cell boundary.  There could be a little improvement
    // in taking one of these two alignments (this one and the first one for
    // the start) but for now that should work.
    misalignment = offset % cell_alignment;
    if( misalignment ) {
      misalignment = cell_alignment - misalignment;
      ns = (node_section *)elib_malloc(sizeof(node_section));
      if( !ns ) return 1;
      ns->next_node		= s;
      ns->global_offset		= misalignment;
      ns->sh_name		= section_filler;
      ns->shndx			= cell_alignment_data;
      ls->next_node		= ns;
      offset			+= misalignment;
      ls			= ns;
#ifdef __DEBUG__
      fprintf( stderr, "calculate_global_offsets().phase3 re-alignment required for proper cell size in object [%s], total bytes inserted [%i/%i]\n", ((node_obj *)c->parent_obj)->filename, (int)misalignment, (int)cell_alignment);
#endif
      c->final_hdr.c_size = offset - c->final_hdr.c_start;
    }

    if( !s ) {
      if( !c->next_node ) break;
      fprintf( stderr, "Error: Internal error occured, we are out of sections but not out of cell nodes.  Call UUU project leader and give him a beating\n");
      errors++;
      return 1;
    }

    c = c->next_node;
  }

  if( s ) {
    fprintf( stderr, "Error: Internal error occured, we are out of cell nodes but not out of sections.  Call UUU project leader and really kick him **hard**\n");
    errors++;
    return 1;
  }


#ifdef __DEBUG__
  fprintf( stderr, "calculate_global_offset() returning\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
void cmdline_check_option( char *option ) {
//----------------------------------------------------------------------------
  int i=OPT_COUNT + 1;
  dword tmp_value=0;

  while( --i )
    if( strncmp( option, options[i-1], options_length[i-1] ) == 0) break;

  if( i ) {
    switch( i ) {

	// --offset=
      case( 0x01 ):
	if( option[6] != '=' ) {
	  if( option[6] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'offset\' option must be followed by = and an offset in hex\ni.e.: --offset=002B1EED\n");
	  errors++;
	  break;
	}

	global_offset = get_offset( &option[7] );
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() global offset set to: %x\n", (unsigned int)global_offset);
#endif
	break;

	// --include-drp
      case( 0x02 ):
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() enabled drp table generation\n");
#endif
	linker_options |= OPT_MASK_DRP;
	break;

	// --help
      case( 0x03 ):
	printf(str_help);
	free_allocated_structures();
	exit(0);

	// --abort-on-warning
      case( 0x04 ):
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() enabled abort on warning\n");
#endif
	linker_options |= OPT_MASK_ABORT_WARNING;
	break;

	// --generate-vid-listing[=file]
      case( 0x05 ):
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() enabled VID listing\n");
#endif
	linker_options |= OPT_MASK_GEN_VIDLISTING;
	if( option[20] == '=' ) {
#ifdef __DEBUG__
	  fprintf( stderr, "cmdline_check_option() vid listing filename set to: %s\n", &option[21]);
#endif
	  vid_listing_filename = &option[21];
	  break;
	}
	if( option[20] == '\0' ) break;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() user added too many chars to option, masking off vid listing\n");
#endif
	linker_options &= 0xFFFF - OPT_MASK_GEN_VIDLISTING;
	goto unknown_option;

	// --hybrid-objects
      case( 0x06 ):
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() user selected hybrid objects\n");
#endif
	linker_options |= OPT_MASK_HYBRID_OBJECTS;
	break;

	// --include-zero-size-sections
      case( 0x07 ):
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() user requested zero size sections to be included\n");
#endif
	linker_options |= OPT_MASK_ZERO_SIZE_SECTIONS;
	break;

	// --section-alignment
      case( 0x08 ):
	if( option[17] != '=' ) {
	  if( option[17] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'section-alignment\' option must be followed by = and an offset in hex\ni.e.: --section-alignment=002B1EED\n");
	  errors++;
	  break;
	}

	tmp_value = get_offset( &option[18] );
	if( tmp_value == 0 || tmp_value > MAX_ALIGNMENT ) {
	  fprintf( stderr, "Error: Value passed to \'section-alignment\' is outside compiled allowable range of 1-%i\n", MAX_ALIGNMENT);
	  errors++;
	  break;
	}

	section_alignment = tmp_value;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() section_alignment set to [%i]\n", (int)tmp_value);
#endif
	break;
	
	// --section-alignment-data
      case( 0x09 ):
	if( option[22] != '=' ) {
	  if( option[22] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'section-alignment-data' option must be followed by = and an offset in hex\ni.e.: --section-alignment-data=002B1EED\n");
	  errors++;
	  break;
	}

	tmp_value = get_offset( &option[23] );
	if( tmp_value > 256 ) {
	  fprintf( stderr, "Error: value passed to \'section-alignment-data\' is above 256\n");
	  errors++;
	  break;
	}

	section_alignment_data = tmp_value;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() section-alignment-data set to [%i]\n", (int)tmp_value);
#endif
	break;
	
	// --init-alignment
      case( 0x0A ):
	if( option[14] != '=' ) {
	  if( option[14] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'init-alignment\' option must be followed by = and an offset in hex\ni.e.: --init-alignment=002B1EED\n");
	  errors++;
	  break;
	}

	tmp_value = get_offset( &option[15] );
	if( tmp_value == 0 || tmp_value > MAX_ALIGNMENT ) {
	  fprintf( stderr, "Error: Value passed to \'init-alignment\' is outside compiled allowable range 1-%i.\n", MAX_ALIGNMENT);
	  errors++;
	  break;
	}

	init_alignment = tmp_value;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() init-alignment set to [%i]\n", (int)tmp_value);
#endif
	break;

	// --init-aligment-data
      case( 0x0B ):
	if( option[19] != '=' ) {
	  if( option[19] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'init-alignment-data\' option must be followed by = and an offset in hex\ni.e.: --init-alignment-data=002B1EED\n");
	  errors++;
	  break;
	}

	tmp_value = get_offset ( &option[20] );
	if( tmp_value > 256 ) {
	  fprintf( stderr, "Error: Value passed to \'init-alignment-data\' is above 256\n");
	  errors++;
	  break;
	}

	init_alignment_data = tmp_value;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() init-alignment-data value set to [%i]\n", (int)tmp_value);
#endif
	break;
	
	// --warn-misalignments
      case( 0x0C ):
	linker_options |= OPT_MASK_WARN_MISALIGNMENTS;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() warning enabled on section misalignment\n");
#endif
	break;
	
	// --cell-alignment
      case( 0x0D ):
	if( option[14] != '=' ) {
	  if( option[14] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'cell-alignment\' option must be followed by = and an offset in hex\ni.e.: --cell-alignment=002B1EED\n");
	  errors++;
	  break;
	}

	tmp_value = get_offset( &option[15] );
	if( tmp_value == 0 || tmp_value > MAX_ALIGNMENT ) {
	  fprintf( stderr, "Error: value passed as argument to \'cell-alignment\' is outside compiled allowable range 1-%i\n", MAX_ALIGNMENT);
	  errors++;
	  break;
	}
	
	cell_alignment = tmp_value;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() cell-alignment value set to %i\n", (int)cell_alignment);
#endif
	break;

	// --cell-alignment-data
      case( 0x0E ):
	if( option[19] != '=' ) {
	  if( option[19] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'cell-alignment-data\' option must be followed by = and an offset in hex\ni.e.: --cell-alignment-data=002B1EED\n");
	  errors++;
	  break;
	}

	tmp_value = get_offset( &option[20] );
	if( tmp_value > 256 ) {
	  fprintf( stderr, "Error: value passed as argument to \'cell-alignment-data\' is above maximum tolerable value of 256\n");
	  errors++;
	  break;
	}
	cell_alignment_data = tmp_value;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() cell-alignment-data value set to %i\n", (int)cell_alignment_data);
#endif
	break;

	// --exclude-dlp
      case( 0x0F ):
	linker_options |= OPT_MASK_EXCLUDE_DLP;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() excluding dlp information\n");
#endif
	break;

      case( 0x10 ):
	printf("U3Linker version " VERSION "\n" COPYRIGHTS "\n");
	free_allocated_structures();
	exit(0);

      case( 0x11 ):
	linker_options |= OPT_MASK_REDEFINITION;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_options() ignoring redefinitions\n");
#endif
	break;

      case( 0x12 ):
	if( option[14] != '=' ) {
	  if( option[14] != 0 ) goto unknown_option;
	  fprintf( stderr, "Error: \'stack-location' option must be followed by = and an offset in hex\ni.e.: --stack-location=002B1EED\n");
	  errors++;
	  break;
	}

	tmp_value = get_offset( &option[15] );
	if( tmp_value < 100 ) {
	  fprintf( stderr, "Error: value passed as argument to \'stack-location\' is below minimum threshold value of 100\n");
	  errors++;
	  break;
	}

	stack_override = tmp_value;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_options() stack location fixed to %p\n",(void *)stack_override );
#endif
	break;
	
	// --generate-core-map[=file]
      case( 0x13 ):
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() generating core map\n");
#endif
	linker_options |= OPT_MASK_GEN_COREMAP;
	if( option[17] == '=' ) {
#ifdef __DEBUG__
	  fprintf( stderr, "cmdline_check_option() core map set to: %s\n", &option[18]);
#endif
	  coremap_filename = &option[18];
	  break;
	}
	if( option[17] == '\0' ) break;
#ifdef __DEBUG__
	fprintf( stderr, "cmdline_check_option() user added too many chars to option, masking off core generation\n");
#endif
	linker_options &= 0xFFFF - OPT_MASK_GEN_COREMAP;
	goto unknown_option;

      default:
	fprintf( stderr, "Internal error while processing: %s\n", option);
	errors++;
    }
  }
  else {
unknown_option:
    fprintf( stderr, "Error: Unknown option: %s\n", option);
    errors++;
  }
}


//----------------------------------------------------------------------------
int cmdline_parse( int argc, char **argv ) {
//----------------------------------------------------------------------------
  while( --argc ) {
    argv++;

    if( argv[0][0]=='-' && argv[0][1]=='-' ) {
      cmdline_check_option( &argv[0][2] );
      continue;
    }
    if( argv[0][0]=='+' ) {
      add_obj( &argv[0][1] );
      continue;
    }

    if( (byte *)output_filename != (byte *)default_output ) {
      fprintf( stderr, "Warning: Output filename set more than once\n");
      warnings++;
    }
#ifdef __DEBUG__
    fprintf( stderr, "cmdline_parse() output_filename set to: %s\n", &argv[0][0]);
#endif
    output_filename = &argv[0][0];
  }
#ifdef __DEBUG__
  fprintf( stderr, "cmdline_parse() completed\n");
#endif
  return errors;
}


//----------------------------------------------------------------------------
int create_ordered_section_list( void ) {
//----------------------------------------------------------------------------
  node_section *s=NULL, *ss=NULL;
  node_obj *o=NULL;
  node_cell *c=NULL;
  byte insert=0;


#ifdef __DEBUG__
  fprintf( stderr, "create_ordered_section_list() called, starting Phase I: searching for osw specific sections\n");
#endif

  // First pass, search for a unique section named ".osw_pre_init"
  o = root_obj;
  while( o ) {
    if( !o->sections ) {
      fprintf( stderr, "Warning: this file contain no supported section: %s\n", o->filename);
      warnings++;
      o = o->next_node;
      continue;
    }

    s = o->sections;
    while( s ) {
      if( strcmp( ".osw_pre_init", s->sh_name ) == 0 ) {
	if( osw_pre_init ) {
	  fprintf( stderr, "Warning: extra \".osw_pre_init\" section ignored in object: %s\n", o->filename);
	  warnings++;
	  goto bypass_osw_pre_init_section;
	}
	if( ((Elf32_Shdr *)s->sh_entry)->sh_size == 0 ) {
	  fprintf( stderr, "Warning: zero size \".osw_pre_init\" section ignored in object: %s\n", o->filename);
	  warnings++;
	  goto bypass_osw_pre_init_section;
	}
#ifdef __DEBUG__
	fprintf( stderr, "create_ordered_section_list().phase1 allocating space for global .osw_pre_init section\n");
#endif
	osw_pre_init = (node_section *)elib_malloc(sizeof(node_section));
	if( !osw_pre_init ) return errors;

	osw_pre_init->next_node		= NULL;
	osw_pre_init->parent_obj	= o;
	osw_pre_init->global_offset	= 0;	// unknown yet
	osw_pre_init->sh_name		= s->sh_name;
	osw_pre_init->reltab		= s->reltab;
	osw_pre_init->reltab_size	= s->reltab_size;
	osw_pre_init->sh_entry		= s->sh_entry;
	osw_pre_init->shndx		= s->shndx;
	ss 				= osw_pre_init;
	osw_pre_init_obj		= o;
	root_sorted_sections		= ss;
	s->shndx = 0;		// help control bypass later on
bypass_osw_pre_init_section:
#ifdef __DEBUG__
	fprintf( stderr, "create_ordered_section_list().phase1 moving from section [%p] to [%p]\n", s, s->next_node);
#endif
        s = s->next_node;
        continue;
      }
      if( strcmp( ".osw_post_init", s->sh_name ) == 0 ) {
	if( osw_post_init ) {
	  fprintf( stderr, "Warning: extra \".osw_post_init\" section ignored in object: %s\n", o->filename);
	  warnings++;
	  goto bypass_osw_post_init_section;
	}
	if( ((Elf32_Shdr *)s->sh_entry)->sh_size == 0 ) {
	  fprintf( stderr, "Warning: zero size \".osw_post_init\" section ignored in object: %s\n", o->filename);
	  warnings++;
	  goto bypass_osw_post_init_section;
	}
#ifdef __DEBUG__
	fprintf( stderr, "create_ordered_section_list().phase1 allocating space for global .osw_post_init section\n");
#endif
	osw_post_init = (node_section *)elib_malloc(sizeof(node_section));
	if( !osw_post_init ) return errors;

	osw_post_init->next_node	= NULL;
	osw_post_init->parent_obj	= o;
	osw_post_init->global_offset	= 0;	// unknown yet
	osw_post_init->sh_name		= s->sh_name;
	osw_post_init->reltab		= s->reltab;
	osw_post_init->reltab_size	= s->reltab_size;
	osw_post_init->sh_entry		= s->sh_entry;
	osw_post_init->shndx		= s->shndx;
	osw_post_init_obj		= o;
	s->shndx = 0;		// help control bypass later on
bypass_osw_post_init_section:
#ifdef __DEBUG__
	fprintf( stderr, "create_ordered_section_list().phase1, moving from section [%p] to [%p]\n", s, s->next_node);
#endif
	s = s->next_node;
	continue;	
      }
      if( strcmp( ".osw_inter_init", s->sh_name ) == 0 ) {
	if( osw_inter_init ) {
	  fprintf( stderr, "Warning: extra \".osw_inter_init\" section ignored in object: %s\n", o->filename);
	  warnings++;
	  goto bypass_inter_init_section;
	}
	if( ((Elf32_Shdr *)s->sh_entry)->sh_size == 0 ) {
	  fprintf( stderr, "Warning: zero size \".osw_inter_init\" section ignored in object: %s\n", o->filename);
	  warnings++;
	  goto bypass_inter_init_section;
	}
#ifdef __DEBUG__
	fprintf( stderr, "create_ordered_section_list().phase1 allocating space for global .osw_inter_init section\n");
#endif
	osw_inter_init = (node_section *)elib_malloc(sizeof(node_section));
	if( !osw_inter_init ) return errors;

	osw_inter_init->next_node	= NULL;
	osw_inter_init->parent_obj	= o;
	osw_inter_init->global_offset	= 0;	// unknown yet
	osw_inter_init->sh_name		= s->sh_name;
	osw_inter_init->reltab		= s->reltab;
	osw_inter_init->reltab_size	= s->reltab_size;
	osw_inter_init->sh_entry	= s->sh_entry;
	osw_inter_init->shndx		= s->shndx;
	osw_inter_init_obj		= o;
	s->shndx = 0;		// help control bypass later on
bypass_inter_init_section:
#ifdef __DEBUG__
	fprintf( stderr, "create_ordered_section_list().phase1 moving from section [%p] to [%p]\n", s, s->next_node);
#endif
	s = s->next_node;
	continue;
      }
#ifdef __DEBUG__
      fprintf( stderr, "create_ordered_section_list().phase1, section [%s] bypassed, moving from [%p] to [%p]\n", s->sh_name, s, s->next_node);
#endif
      s = s->next_node;
    }
#ifdef __DEBUG__
    fprintf( stderr, "create_ordered_section_list().phase1 moving from object [%p] to [%p]\n", o, o->next_node);
#endif
    o = o->next_node;
  }

  if( !osw_pre_init ) {
    fprintf( stderr, "Warning: no \".osw_pre_init\" section found\n");
    warnings++;
  }
  if( !osw_post_init ) {
    fprintf( stderr, "Warning: no \".osw_post_init\" section found\n");
    warnings++;
  }

#ifdef __DEBUG__
  fprintf( stderr, "create_ordered_section_list() osw related sections harvested, Phase I completed.\ncreate_ordered_section_list() phase I completed, starting Phase II: searching for .c_onetime_init and .c_init sections\n");
#endif

  o = root_obj;
  insert=0;
  while( o ) {
    s = o->sections;
    while( s ) {
      if( (s->shndx != 0) && ((strcmp(".c_onetime_init", s->sh_name) == 0) ||
	    (strcmp(".c_init", s->sh_name) == 0)) ) {
#ifdef __DEBUG__
        fprintf( stderr, "create_ordered_section_list().phase2 [%s] section found at [%p] while processing object [%s]\n", s->sh_name, s, o->filename);
#endif
	if( insert && osw_inter_init ) {
	  ss->next_node = (node_section *)elib_malloc(sizeof(node_section));
	  if( !ss->next_node ) return 1;

#ifdef __DEBUG__
	  fprintf( stderr, "create_ordered_section_list().phase2 appending osw_inter_init section [%p] as alias [%p] after [%p] named [%s] in object [%s]\n", osw_inter_init, ss->next_node, ss, ss->sh_name, ((node_obj *)ss->parent_obj)->filename);
#endif
	  ss = ss->next_node;
	  ss->next_node		= NULL;
	  ss->parent_obj	= osw_inter_init->parent_obj;
	  ss->global_offset	= 0;
	  ss->sh_name		= osw_inter_init->sh_name;
	  ss->reltab		= osw_inter_init->reltab;
	  ss->reltab_size	= osw_inter_init->reltab_size;
	  ss->sh_entry		= osw_inter_init->sh_entry;
	  ss->shndx		= osw_inter_init->shndx;
	}
	if( !ss ) {
	  ss = (node_section *)elib_malloc(sizeof(node_section));
	  if( !ss ) return 1;
	  root_sorted_sections = ss;
#ifdef __DEBUG__
	  fprintf( stderr, "create_ordered_section_list().phase2 root_sorted_sections initialized to [%p], section found is [%s] of object [%s]\n", ss, s->sh_name, o->filename);
#endif
	}
	else {
	  ss->next_node = (node_section *)elib_malloc(sizeof(node_section));
	  if( !ss->next_node ) return 1;
#ifdef __DEBUG__
	  fprintf( stderr, "create_ordered_section_list().phase2 appending section [%s] at [%p] under alias [%p] after section [%p]\n", s->sh_name, s, ss->next_node, ss);
#endif
	  ss = ss->next_node;
	}
	
	ss->next_node		= NULL;
	ss->parent_obj		= o;
	ss->global_offset	= 0;
	ss->sh_name		= s->sh_name;
	ss->reltab		= s->reltab;
	ss->reltab_size		= s->reltab_size;
	ss->sh_entry		= s->sh_entry;
	ss->shndx		= s->shndx;
	
	s->shndx		= 0;

	insert = 1;
      }
      s = s->next_node;
    }
    o = o->next_node;
  }

  if( osw_post_init ) {
    if( !ss ) {
      fprintf(stderr, "Warning: Reached section [.osw_post_init] without discovering any [.c_init] or [.c_onetime_init] section.\n");
      ss = (node_section *)elib_malloc(sizeof(node_section));
      if( !ss ) return 1;
      root_sorted_sections = ss;
      ss->next_node		= ss;
    }
    else {
      ss->next_node = (node_section *)elib_malloc(sizeof(node_section));
      if( !ss->next_node ) return 1;
    }
    ss = ss->next_node;
    ss->next_node		= NULL;
    ss->parent_obj		= osw_post_init->parent_obj;
    ss->global_offset		= 0;
    ss->sh_name			= osw_post_init->sh_name;
    ss->reltab			= osw_post_init->reltab;
    ss->reltab_size		= osw_post_init->reltab_size;
    ss->sh_entry		= osw_post_init->sh_entry;
    ss->shndx			= osw_post_init->shndx;
#ifdef __DEBUG__
    fprintf( stderr, "create_ordered_section_list().phase2 appended osw_post_init under alias [%p]\n", ss);
#endif
  }


#ifdef __DEBUG__
  fprintf( stderr, "create_ordered_section_list() phase II completed, starting phase: creating cell list\n");
#endif


  o = root_obj;
  c = NULL;
  while( o ) {
    insert = 0;
    s = o->sections;
    if( c ) c->next_node = NULL;
    while( s ) {
      if( s->shndx != 0 ) {
	if( ((Elf32_Shdr *)s->sh_entry)->sh_size == 0 &&
	    !(linker_options & OPT_MASK_ZERO_SIZE_SECTIONS) ) {
	  warnings++;
	  fprintf( stderr, "Warning: Bypassing zero size section [%s] contained in object [%s]\n", s->sh_name, o->filename);
	  s = s->next_node;
	  continue;
	}
	if( !c || !c->next_node ) {
	  if( !(linker_options & OPT_MASK_HYBRID_OBJECTS) ) {
	    if( o == osw_pre_init_obj ) {
	      warnings++;
	      fprintf( stderr, "Warning: Object [%s] containing [.osw_pre_init] section also contains [%s] and a cell header is being generated\n", o->filename, s->sh_name);
	    }
	    if( o == osw_post_init_obj ) {
	      warnings++;
	      fprintf( stderr, "Warning: Object [%s] containing [.osw_post_init] section also contains [%s] and a cell header is being generated\n", o->filename, s->sh_name);
	    }
	    if( o == osw_inter_init_obj ) {
	      warnings++;
	      fprintf( stderr, "Warning: Object [%s] containing [.osw_inter_init] section also contains [%s] and a cell header is being generated\n", o->filename, s->sh_name);
	    }
	  }
	  if( !c ) {
	    c = (node_cell *)elib_malloc(sizeof(node_cell));
	    if( !c ) return 1;

	    c->next_node	= c;
	    root_cell		= c;
#ifdef __DEBUG__
	    fprintf( stderr, "create_ordered_section_list().phase3 root_cell created at [%p] while processing object [%s] after finding section [%s]\n", c, o->filename, s->sh_name);
#endif
	  }
	  else if( !c->next_node ) {
	    c->next_node = (node_cell *)elib_malloc(sizeof(node_cell));
	    if( !c->next_node ) return 1;
#ifdef __DEBUG__
	    fprintf( stderr, "create_ordered_section_list().phase3 node_cell [%p] created and linked after [%p], initialized after finding section [%s] in object [%s]\n", c->next_node, c, s->sh_name, o->filename);
#endif
	  }
	  ((node_cell *)c->next_node)->parent_obj		= o;
	  ((node_cell *)c->next_node)->c_info			= NULL;
	  ((node_cell *)c->next_node)->final_hdr.c_start	= 0;
	  ((node_cell *)c->next_node)->final_hdr.c_size		= 0;
	  ((node_cell *)c->next_node)->final_hdr.c_info		= 0;
	  core_header.cell_count++;
	}
	if( strcmp(".c_info", s->sh_name) == 0) {
	  ((node_cell *)c->next_node)->c_info = (node_section *)elib_malloc(sizeof(node_section));
	  if( !((node_cell *)c->next_node)->c_info ) return 1;

	  ((node_section *)((node_cell *)c->next_node)->c_info)->next_node = NULL;
	  ((node_section *)((node_cell *)c->next_node)->c_info)->parent_obj = o;
	  ((node_section *)((node_cell *)c->next_node)->c_info)->global_offset = 0;
	  ((node_section *)((node_cell *)c->next_node)->c_info)->sh_name = s->sh_name;
	  ((node_section *)((node_cell *)c->next_node)->c_info)->reltab = s->reltab;
	  ((node_section *)((node_cell *)c->next_node)->c_info)->reltab_size= s->reltab_size;
	  ((node_section *)((node_cell *)c->next_node)->c_info)->sh_entry = s->sh_entry;
	  ((node_section *)((node_cell *)c->next_node)->c_info)->shndx = s->shndx;
#ifdef __DEBUG__
	  fprintf( stderr, "create_ordered_section_list().phase3 [.c_info] of object [%s] created at [%p]\n", o->filename, ((node_cell *)c->next_node)->c_info);
#endif
	  s->shndx = 0;
	}
	else {
	  if( !ss ) {
	    ss = (node_section *)elib_malloc(sizeof(node_section));
	    if( !ss ) return 1;

	    root_sorted_sections = ss;
	    ss->next_node = ss;
	  }
	  else {
	    ss->next_node = (node_section *)elib_malloc(sizeof(node_section));
	    if( !ss->next_node ) return 1;

	  }

	  ((node_section *)ss->next_node)->next_node 		= NULL;
	  ((node_section *)ss->next_node)->parent_obj		= o;
	  ((node_section *)ss->next_node)->global_offset	= 0;
	  ((node_section *)ss->next_node)->sh_name		= s->sh_name;
	  ((node_section *)ss->next_node)->reltab		= s->reltab;
	  ((node_section *)ss->next_node)->reltab_size		= s->reltab_size;
	  ((node_section *)ss->next_node)->sh_entry		= s->sh_entry;
	  ((node_section *)ss->next_node)->shndx		= s->shndx;
#ifdef __DEBUG__
	  fprintf( stderr, "create_ordered_section_list().phase3 section [%s] appended to sorted section list, from object [%s], node is located at [%p]\n", s->sh_name, o->filename, ss->next_node);
#endif
	  ss	= ss->next_node;
	  if( !first_non_init_section ) first_non_init_section = ss;
	}
      }
      s = s->next_node;
    }
    if( c && c->next_node ) {
      c = c->next_node;
      c->next_node = NULL;
    }
    o = o->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "create_ordered_section_list() completed\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
int elib_fread( FILE *fp, void **buffer, size_t size, size_t offset, char *name) {
//----------------------------------------------------------------------------
#ifdef __DEBUG__
  fprintf( stderr, "elib_fread([%p], [%p], [%i], [%i]", fp, buffer, size, offset);
  fprintf( stderr, ", [%s]) called\n", name);
#endif

  if( fseek( fp, offset, SEEK_SET ) ) {
    fprintf( stderr, "Error: Unable to seek to proper location in file: %s\n", name);
    return ++errors;
  }

  *buffer = elib_malloc(size);
  if( !*buffer ) {
    fprintf( stderr, "Error: Unable to allocate memory to read file part in: %s\n", name);
    return ++errors;
  }

  if( fread( *buffer, size, 1, fp ) != 1 ) {
    fprintf( stderr, "Error: Unable to read part of %s\n", name);
    elib_free(*buffer);
    *buffer = NULL;
    return ++errors;
  }

#ifdef __DEBUG__
  fprintf( stderr, "elib_fread() completed\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
void elib_free( void *p ) {
//----------------------------------------------------------------------------
#ifdef __DEBUG__
  fprintf( stderr, "elib_free(%p) called\n", p);
#endif

  free(p);

#ifdef __DEBUG__
  fprintf( stderr, "elib_free() completed\n");
  elib_memblocks_deallocated++;
#endif
}



//----------------------------------------------------------------------------
int elib_fwrite( FILE *fp, void *buffer, size_t size, size_t offset, char *name ) {
//----------------------------------------------------------------------------

#ifdef __DEBUG__
  fprintf( stderr, "elib_fwrite( [%p], [%p], [%lu], [%p], [%s] ) called\n", fp, buffer, (dword)size, (void *)offset, name);
#endif

  if( !fp ) {
    fprintf( stderr, "Error: Internal error, trying to write to a closed file: %s\n", name);
    errors++;
    return 1;
  }

  if( fseek( fp, offset, SEEK_SET ) ) {
    fprintf( stderr, "Error: Can't seek to proper location in output file: %s\n", name);
    errors++;
    return 1;
  }

  if( fwrite( buffer, size, 1, fp ) != 1 ) {
    fprintf( stderr, "Error: Unable to write to output file: %s\n", name);
    errors++;
    return 1;
  }

#ifdef __DEBUG__
  fprintf( stderr, "elib_fwrite() completed succesfully\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
void *elib_malloc( size_t size ) {
//----------------------------------------------------------------------------
  register void *p;

#ifdef __DEBUG__
  fprintf( stderr, "elib_malloc(%i) called\n", size);
#endif

  p = malloc(size);
  if( p ) {
#ifdef __DEBUG__
    fprintf( stderr, "elib_malloc() allocated %p\n", p);
    elib_memblocks_allocated++;
#endif
    return p;
  }

  fprintf( stderr, str_out_of_mem );
  errors++;
  return p;
}


//----------------------------------------------------------------------------
int flush_node_sections( void ) {
//----------------------------------------------------------------------------
  node_section *s, *ns;
  node_obj *o;

#ifdef __DEBUG__
  fprintf( stderr, "flush_node_sections() started\n");
#endif


  o = root_obj;
  while( o ) {
    s = o->sections;
    while( s ) {
      ns = s->next_node;
      elib_free( s );
      s = ns;
    }
    o->sections = NULL;
    o = o->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "flush_node_sections() completed\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
void free_allocated_structures( void ) {
//----------------------------------------------------------------------------
  node_obj *elf_object, *next_object;
  node_section *s, *ns;
  node_cell *c, *nc;
  node_gsymbol *gsym, *ngsym;
  node_lsymbol *lsym, *nlsym;
  node_function *f, *nf;
  node_drp *drp, *ndrp;
  node_dlp *dlp, *ndlp;
  byte reltab_freed = 0, reltab_oswinterinit=0;

#ifdef __DEBUG__
  fprintf( stderr, "free_allocated_structures() called\n");
#endif

  f = root_functions;
  while( f ) {
    nf = f->next_node;
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase0 freeing up function [%s] at [%p]\n", f->name, f);
#endif
    elib_free( f );
    f = nf;
  }

  c = root_cell;
  while( c ) {
    nc = c->next_node;
    if( c->c_info ) {
      if( ((node_section *)c->c_info)->next_node ) {
#ifdef __DEBUG__
	fprintf( stderr, "free_allocated_structures().phase1 freeing up [.c_info|alias: %p] misalignment section [%p]\n", (node_section *)c->c_info, ((node_section *)c->c_info)->next_node);
#endif
	elib_free( ((node_section *)c->c_info)->next_node );
      }
      if( ((node_section *)c->c_info)->reltab ) {
#ifdef __DEBUG__
	fprintf( stderr, "free_allocated_structures().phase1 freeing up relocation table of [.c_info|alias: %p] located at [%p]\n", (node_section *)c->c_info, ((node_section *)c->c_info)->reltab);
#endif
	elib_free( ((node_section *)c->c_info)->reltab );
      }
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase1 freeing up c_info [%p] of node_cell [%p]\n", c->c_info, c);
#endif
      elib_free( c->c_info );
    }
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase1 freeing up node_cell [%p] associated with object [%s]\n", c, ((node_obj *)c->parent_obj)->filename);
#endif
    elib_free( c );
    c = nc;
  }

#ifdef __DEBUG__
  fprintf( stderr, "free_allocated_structures() phase I completed, proceeding to phase II: freeing up node_obj\n");
#endif

  elf_object = root_obj;
  while( elf_object ) {
    next_object = elf_object->next_node;


#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase2 processing object [%s]\n", elf_object->filename);
#endif

    s = elf_object->sections;
    while( s ) {
      if( s->reltab ) {
#ifdef __DEBUG__
	fprintf( stderr, "free_allocated_structures().phase2 freeing up relocation table of section [%s] located at [%p]\n", s->sh_name, s->reltab);
#endif
	elib_free( s->reltab );
	reltab_freed = 1;
      }
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 freeing up section [%s] located at [%p]\n", s->sh_name, s);
#endif
      ns = s->next_node;
      elib_free( s );
      s = ns;
    }

    lsym = elf_object->locals;
    while( lsym ) {
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 freeing up local [%s] located at [%p]\n", lsym->name, lsym);
#endif
      nlsym = lsym->next_node;
      elib_free( lsym );
      lsym = nlsym;
    }

    if( elf_object->shtab ) {
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 freeing up ->shtab [%p]\n", elf_object->shtab);
#endif
      elib_free( elf_object->shtab );
    }

    if( elf_object->shstrtab ) {
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 freeing up ->shstrtab [%p]\n", elf_object->shstrtab);
#endif
      elib_free( elf_object->shstrtab );
    }

    if( elf_object->strtab ) {
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 freeing up ->strtab [%p]\n", elf_object->strtab);
#endif
      elib_free( elf_object->strtab );
    }

    if( elf_object->symtab ) {
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 freeing up ->symtab [%p]\n", elf_object->symtab);
#endif
      elib_free( elf_object->symtab );
    }

    if( elf_object->fp ) {
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 closing up file [%p]\n", elf_object->fp );
#endif
      fclose( elf_object->fp );
    }

    if( elf_object->cell_header ) {
#ifdef __DEBUG__
      fprintf( stderr, "free_allocated_structures().phase2 freeing up ->cell_header [%p]\n", elf_object->cell_header );
#endif
      elib_free( elf_object->cell_header );
    }

    // TODO: free up all extern_dlp and global_dlp chained tables
    // TODO: free up all locals

#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase2 freeing up node_obj [%p] of object [%s]\n", elf_object, elf_object->filename);
#endif
    elib_free( elf_object );

    elf_object = next_object;
  }

#ifdef __DEBUG__
  fprintf( stderr, "free_allocated_structures() phase II completed, proceeding to phase III: freeing node_section\n");
#endif

  s = root_sorted_sections;
  while( s ) {
    ns = s->next_node;
    if( !reltab_freed &&
	s->reltab &&
	(byte *)s->sh_name != (byte *)section_filler
	) {
      if( !reltab_oswinterinit &&
	  osw_inter_init &&
	  (byte *)s->sh_name == (byte *)osw_inter_init->sh_name ) {
	reltab_oswinterinit = 1;
#ifdef __DEBUG__
	fprintf( stderr, "free_allocated_structures().phase3 freeing up relocation table of .osw_inter_init section [%p] at [%p]\n", s, s->reltab);
#endif
	elib_free( s->reltab );
      }
      else {
	if( !osw_inter_init ||
	    (osw_inter_init && (byte *)s->sh_name != (byte *)osw_inter_init->sh_name)
	    ) {
#ifdef __DEBUG__
            fprintf( stderr, "free_allocated_structures().phase3 freeing up relocation table of sorted section [%p] at [%p]\n", s, s->reltab);
#endif
	  elib_free( s->reltab );
	}
      }
    }
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase3 freeing up sorted section [%p], preparing to move to sorted section [%p]\n", s, ns);
#endif
    if( s == osw_pre_init ) osw_pre_init = NULL;
    if( s == osw_inter_init ) osw_inter_init = NULL;
    if( s == osw_post_init ) osw_post_init = NULL;
    elib_free( s );
    s = ns;
  }

  if( osw_pre_init ) {
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase3 freeing up osw_pre_init [%p]\n", osw_pre_init);
#endif
    elib_free( osw_pre_init );
  }

  if( osw_post_init ) {
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase3 freeing up osw_post_init [%p]\n", osw_post_init);
#endif
    elib_free( osw_post_init );
  }

  if( osw_inter_init && osw_inter_init->parent_obj ) {
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase3 freeing up osw_inter_init [%p]\n", osw_inter_init);
#endif
    elib_free( osw_inter_init );
  }

#ifdef __DEBUG__
  fprintf( stderr, "free_allocated_structures() phase III completed, proceeding to phase IV: freeing globals\n");
#endif

  gsym = root_globals;
  while( gsym ) {
    ngsym = gsym->next_node;
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase4 freeing up global [%p]\n", gsym);
#endif
    elib_free( gsym );
    gsym = ngsym;
  }

#ifdef __DEBUG__
  fprintf( stderr, "free_allocated_structures() phase IV completed, proceeding to phase V: miscellaneous structures and pointers\n");
#endif

  if( fp_output ) {
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase5 output file detected to be left open, closing\n");
#endif
    fclose( fp_output );
  }

  if( section_filler_buffer ) {
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase5 section filler buffer, present, freeing\n");
#endif
    elib_free( section_filler_buffer );
  }

  drp = root_drp;
  while( drp ) {
    ndrp = drp->next_node;
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase5 freeing drp [%p]\n", drp);
#endif
    elib_free( drp );
    drp = ndrp;
  }

  dlp = root_dlp_rel;
  while( dlp ) {
    ndlp = dlp->next_node;
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase5 freeing dlp_rel [%p]\n", dlp);
#endif
    elib_free( dlp );
    dlp = ndlp;
  }

  dlp = root_dlp_abs;
  while( dlp ) {
    ndlp = dlp->next_node;
#ifdef __DEBUG__
    fprintf( stderr, "free_allocated_structures().phase5 freeing dlp_abs [%p]\n", dlp);
#endif
    elib_free( dlp );
    dlp = ndlp;
  }

  if( fp_core_map ) fclose(fp_core_map);
#ifdef __DEBUG__
  fprintf( stderr, "free_allocated_structures() completed\n");
#endif
}


//----------------------------------------------------------------------------
int generate_core( void ) {
//----------------------------------------------------------------------------
  node_cell *c=NULL;
  node_section *s=NULL;
  dword core_size = 0;
  dword misalignment = 0;
  int i;
  byte *buffer=NULL;
  node_drp *drp=NULL;
  node_dlp *dlp=NULL;
  unsigned long checksum;
  unsigned long checksum_data;

#ifdef __DEBUG__
  fprintf( stderr, "generate_core() started\n");
#endif

  section_filler_buffer = (byte *)elib_malloc(MAX_ALIGNMENT);

  fp_output = fopen ( output_filename, "wb" );
  if( !fp_output ) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
  {
	  fp_core_map = fopen ( coremap_filename, "w" );
	  if( !fp_core_map ) return 1;
	  fprintf( fp_core_map, "Map of what will be found in memory at runtime\nGlobal Offset: %8x\n\n", (unsigned int)global_offset);
  }
  

#ifdef __DEBUG__
  fprintf( stderr, "generate_core() core_size is now: %p\n", (void *)core_size);
  fprintf( stderr, "generate_core() writing up core header\n");
#endif

  // Finding OSW entry point
  s = root_sorted_sections;
  while( (byte *)s->sh_name == (byte *)section_filler )
    s = s->next_node;
  core_header.osw_entry = s->global_offset;

  // Fixing global_offset used during linkage
  core_header.core_offset = global_offset;

  // Writing core header
  if( elib_fwrite(
	fp_output,		// FILE *fp
	&core_header,		// void *buffer
	sizeof(hdr_core),	// size_t size
	core_size,		// size_t offset
	output_filename)	// char *name
      ) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
	  fprintf( fp_core_map, "%8x:%8x\n\tlinker generated\n\tcore header\n",(unsigned int)(core_size+global_offset), (unsigned int)(core_size+sizeof(hdr_core)+global_offset-1));
  core_size += sizeof(hdr_core);

#ifdef __DEBUG__
  fprintf( stderr, "generate_core() core_size is now: %p\n", (void *)core_size);
#endif
  c = root_cell;
  while( c ) {
#ifdef __DEBUG__
    fprintf( stderr, "generate_core() writing up cell header for object [%s]\n", ((node_obj *)c->parent_obj)->filename);
#endif
    if( elib_fwrite(
	  fp_output,
	  &c->final_hdr,
	  sizeof(hdr_cell),
	  core_size,
	  output_filename)
	) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
	  fprintf( fp_core_map, "%8x:%8x\n\tlinker generated\n\tcell header of %s\n", (unsigned int)(core_size+global_offset), (unsigned int)(core_size+sizeof(hdr_cell)+global_offset-1), ((node_obj *)c->parent_obj)->filename);
    c = c->next_node;
    core_size += sizeof(hdr_cell);
#ifdef __DEBUG__
    fprintf( stderr, "generate_core() core_size is now: %p\n", (void *)core_size);
#endif
  }

  c = root_cell;
  while( c ) {
    if( c->c_info ) {
      if( ((node_section *)c->c_info)->next_node ) {
#ifdef __DEBUG__
	fprintf( stderr, "generate_core() writing up section [%s]\n\tfilling up for: %lu bytes\n\tusing value: %p\n",
	    section_filler,
	    ((node_section *)((node_section *)c->c_info)->next_node)->global_offset,
	    (void *)((node_section *)((node_section *)c->c_info)->next_node)->shndx );
#endif
	for(i=0; i< ((node_section *)((node_section *)c->c_info)->next_node)->global_offset; i++)
	  section_filler_buffer[i] = (byte)((node_section *)((node_section *)c->c_info)->next_node)->shndx;
	
	if( elib_fwrite(
	      fp_output,
	      section_filler_buffer,
	      ((node_section *)((node_section *)c->c_info)->next_node)->global_offset,
	      core_size,
	      output_filename)
	    ) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
	  fprintf(  fp_core_map,"%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size+global_offset),(unsigned int)((((node_section *)((node_section *)c->c_info)->next_node)->global_offset)+core_size+global_offset-1));
	core_size += ((node_section *)((node_section *)c->c_info)->next_node)->global_offset;
#ifdef __DEBUG__
        fprintf( stderr, "generate_core() core_size is now: %p\n", (void *)core_size);
#endif
      }
#ifdef __DEBUG__
      fprintf( stderr, "generate_core() writing up c_info for object [%s]\n\tsize: %p\n", ((node_obj *)c->parent_obj)->filename, (void *)((Elf32_Shdr *)((node_section *)c->c_info)->sh_entry)->sh_size);
#endif

      if( elib_fread(
	    ((node_obj *)c->parent_obj)->fp,
	    (void *)&buffer,
	    ((Elf32_Shdr *)((node_section *)c->c_info)->sh_entry)->sh_size,
	    ((Elf32_Shdr *)((node_section *)c->c_info)->sh_entry)->sh_offset,
	    ((node_obj *)c->parent_obj)->filename )
	  ) return 1;
      if( ((node_section *)c->c_info)->reltab &&
	  apply_reloc(
	    ((node_section *)c->c_info)->reltab,
	    ((node_section *)c->c_info)->reltab_size,
	    ((node_obj *)c->parent_obj)->symtab,
	    buffer,
	    c->parent_obj,
	    c->c_info )
	  ) {
	elib_free( buffer );
	return 1;
      }
      if( elib_fwrite(
	    fp_output,
	    buffer,
	    ((Elf32_Shdr *)((node_section *)c->c_info)->sh_entry)->sh_size,
	    core_size,
	    output_filename)
	  ) {
	elib_free( buffer );
	return 1;
      }
  if( linker_options & OPT_MASK_GEN_COREMAP)
	  fprintf(fp_core_map, "%8x:%8x\n\t%s\n\t.c_info\n", (unsigned int)(core_size+global_offset), (unsigned int)(((Elf32_Shdr *)((node_section *)c->c_info)->sh_entry)->sh_size+global_offset+core_size-1), ((node_obj *)c->parent_obj)->filename);
      elib_free( buffer );
      core_size += ((Elf32_Shdr *)((node_section *)c->c_info)->sh_entry)->sh_size;
#ifdef __DEBUG__
      fprintf( stderr, "generate_core() core_size is now: %p\n", (void *)core_size);
#endif
    }
    c = c->next_node;
  }

  s = root_sorted_sections;
  while( s ) {
#ifdef __DEBUG__
    fprintf( stderr, "generate_core() writing up section [%s]\n", s->sh_name);
#endif
    if( (byte *)s->sh_name == (byte *)section_filler ) {
#ifdef __DEBUG__
      fprintf( stderr, "\tfilling up for: %lu bytes\n\tusing value: %p\n",
	  s->global_offset,
	  (void *)s->shndx );
#endif
      for(i=0; i< s->global_offset; i++)
	section_filler_buffer[i] = s->shndx;
      if( elib_fwrite(
	    fp_output,
	    section_filler_buffer,
	    s->global_offset,
	    core_size,
	    output_filename)
	  ) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
	  fprintf(fp_core_map, "%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size + global_offset),(unsigned int)(s->global_offset+core_size+global_offset-1));
      core_size += s->global_offset;
    }
    else {
#ifdef __DEBUG__
      fprintf( stderr, "\tglobal core_size: %p\n\tsize: %p\n\tin object: %s\n",
	  (void *)s->global_offset,
	  (void *)((Elf32_Shdr *)s->sh_entry)->sh_size,
	  ((node_obj *)s->parent_obj)->filename
	  );
#endif
      if( elib_fread(
	    ((node_obj *)s->parent_obj)->fp,
	    (void *)&buffer,
	    ((Elf32_Shdr *)s->sh_entry)->sh_size,
	    ((Elf32_Shdr *)s->sh_entry)->sh_offset,
	    ((node_obj *)s->parent_obj)->filename)
	  ) return 1;
      if( s->reltab &&
	  apply_reloc(
	    s->reltab,
	    s->reltab_size,
	    ((node_obj *)s->parent_obj)->symtab,
	    buffer,
	    s->parent_obj,
	    s )
	  ) {
	elib_free( buffer );
	return 1;
      }
      if( elib_fwrite(
	    fp_output,
	    buffer,
	    ((Elf32_Shdr *)s->sh_entry)->sh_size,
	    core_size,
	    output_filename)
	  ) {
	elib_free( buffer );
	return 1;
      }
  if( linker_options & OPT_MASK_GEN_COREMAP)
	  fprintf(fp_core_map,"%8x:%8x\n\t%s\n\t%s\n",(unsigned int)(core_size+global_offset),(unsigned int)(((Elf32_Shdr *)s->sh_entry)->sh_size+global_offset+core_size-1),((node_obj *)s->parent_obj)->filename, s->sh_name);
      elib_free( buffer );
      core_size += ((Elf32_Shdr *)s->sh_entry)->sh_size;
    }
    s = s->next_node;
#ifdef __DEBUG__
    fprintf( stderr, "generate_core() core_size is now: %p\n", (void *)core_size);
#endif
  }

  // Make sure any DRP or DLP tables are on a 4 bytes boundary
  *(dword *)section_filler_buffer = 0;
  misalignment = core_size % 4;
  if( misalignment ) {
    misalignment = 4-misalignment;
    if( elib_fwrite(
	  fp_output,
	  section_filler_buffer,
	  misalignment,
	  core_size,
	  output_filename )
	) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
    fprintf(fp_core_map, "%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size + global_offset), (unsigned int)(core_size + global_offset+misalignment -1));
    core_size += misalignment;
  }

  // Include DRP ?
  if( (linker_options & OPT_MASK_DRP) && root_drp ) {
    core_header.drp = global_offset + core_size;
fprintf(stderr, "global_offset = %x, core_size = %x\n", (unsigned int)global_offset, (unsigned int)core_size);
fprintf(stderr, "core_header.drp fixed to: 0x%8x\n", (unsigned int)core_header.drp);

  if( linker_options & OPT_MASK_GEN_COREMAP)
    fprintf(fp_core_map,"%8x:...\n\tlinker generated\n\tDynamic Recalculation Points\n",(unsigned int)(core_size+global_offset));
    drp = root_drp;
    while( drp ) {
      if( elib_fwrite(
	    fp_output,
	    &drp->fix_point,
	    4,
	    core_size,
	    output_filename )
	  ) return 1;
      core_size += 4;
      drp = drp->next_node;
    }
    if( elib_fwrite(
	  fp_output,
	  section_filler_buffer,
	  4,
	  core_size,
	  output_filename )
	) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
    fprintf(fp_core_map, "%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size + global_offset), (unsigned int)(core_size + global_offset + 3));
    core_size += 4;
  }

  // include any DLP ?
  if( !(linker_options & OPT_MASK_EXCLUDE_DLP) ) {
    if( root_dlp_rel ) {
      core_header.dlp_rel = global_offset + core_size;

  if( linker_options & OPT_MASK_GEN_COREMAP)
      fprintf(fp_core_map, "%8x:...\n\tlinker generated\n\tDynamic Linking Points (relative)\n",(unsigned int)(core_size + global_offset));
      dlp = root_dlp_rel;
      while( dlp ) {
	if( elib_fwrite(
	      fp_output,
	      &dlp->vid,
	      12,
	      core_size,
	      output_filename )
	    ) return 1;
	core_size += 12;
	dlp = dlp->next_node;
      }
      if( elib_fwrite(
	    fp_output,
	    section_filler_buffer,
	    4,
	    core_size,
	    output_filename )
	  ) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
      fprintf(fp_core_map, "%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size + global_offset),(unsigned int)(core_size+global_offset+3));
      core_size += 4;
    }

    if( root_dlp_abs ) {
      core_header.dlp_abs = global_offset + core_size;

  if( linker_options & OPT_MASK_GEN_COREMAP)
      fprintf(fp_core_map, "%8x:...\n\tlinker generated\n\tDynamic Linking Points (absolute)\n",(unsigned int)(core_size + global_offset));
      dlp = root_dlp_abs;
      while( dlp ) {
	if( elib_fwrite(
	      fp_output,
	      &dlp->vid,
	      12,
	      core_size,
	      output_filename )
	    ) return 1;
	core_size += 12;
	dlp = dlp->next_node;
      }
      if( elib_fwrite(
	    fp_output,
	    section_filler_buffer,
	    4,
	    core_size,
	    output_filename )
	  ) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
      fprintf(fp_core_map, "%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size + global_offset),(unsigned int)(core_size+global_offset+3));
      core_size += 4;
    }

    if( root_functions ) {
      core_header.dlp_provided = global_offset + core_size;

  if( linker_options & OPT_MASK_GEN_COREMAP)
      fprintf(fp_core_map, "%8x:...\n\tlinker generated\n\tDynamic Linking Points (globalfunc)\n",(unsigned int)(core_size + global_offset));
      (node_function *)dlp = root_functions;
      while( dlp ) {
	if( elib_fwrite(
	      fp_output,
	      (void *)&((node_function *)dlp)->vid,
	      12,
	      core_size,
	      output_filename )
	    ) return 1;
	core_size += 12;
	dlp = ((node_function *)dlp)->next_node;
      }
      if( elib_fwrite(
	    fp_output,
	    section_filler_buffer,
	    4,
	    core_size,
	    output_filename )
	  ) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
      fprintf(fp_core_map, "%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size + global_offset),(unsigned int)(core_size+global_offset+3));
      core_size += 4;
    }
  }

  // Final core image must be 64bytes aligned
  *(dword *)section_filler_buffer = 0;
  misalignment = core_size % 64;
  if( misalignment ) {
    misalignment = 64-misalignment;
    if( elib_fwrite(
	  fp_output,
	  section_filler_buffer,
	  misalignment,
	  core_size,
	  output_filename )
	) return 1;
  if( linker_options & OPT_MASK_GEN_COREMAP)
      fprintf(fp_core_map, "%8x:%8x\n\tlinker generated\n\tsection filler\n",(unsigned int)(core_size + global_offset),(unsigned int)(core_size+global_offset+misalignment - 1));
    core_size += misalignment;
  }

  // Update core header
  core_header.core_size = core_size;

  // init core_header multiboot parameters
  core_header.mboot_magic = 0x1badb002;
  core_header.mboot_flags = 0x10000; // address fields are correct, nothing more
  core_header.mboot_checksum = 0 - core_header.mboot_magic - core_header.mboot_flags;
  core_header.mboot_header_addr = core_header.core_offset + ((char *)&core_header.mboot_magic - (char *)&core_header);
  core_header.mboot_load_end_addr = core_header.core_offset + core_size - 1;
  core_header.mboot_bss_end_addr = core_header.mboot_load_end_addr;
  core_header.mboot_entry = core_header.core_offset + ((char *)&core_header.mov_esp - (char *)&core_header);

  // create code section for multiboot startup
  core_header.mov_esp = 0xBC; // mov esp, imm32
  if(stack_override) core_header.esp_value = stack_override;
  else core_header.esp_value = core_header.core_offset;
  core_header.jmp_rel_esp[0] = 0xFF; // jmp near [core_header + byte osw_entry]
  core_header.jmp_rel_esp[1] = 0x25;
  core_header.jmp_rel_off =  core_header.core_offset + ((char *)&core_header.osw_entry - (char *)&core_header);
  // berkus: omg...this sucks... --

  core_header.core_checksum = 0;

  if( elib_fwrite(
	fp_output,
	&core_header,
	sizeof(hdr_core),
	0,
	output_filename ) ||
      fseek( fp_output, 0, SEEK_END)
      ) return 1;


  if( linker_options & OPT_MASK_GEN_COREMAP)
  {
	  fclose(fp_core_map);
	  fp_core_map = NULL;
  }

  // completed, now do a second phase to compute the core checksum
  fclose( fp_output );
  fp_output = NULL;

  fp_output = fopen( output_filename, "r+b" );
  if( !fp_output )
  {
	  fprintf( stderr, "Failed re-opening output file for checksum calculations\n");
	  errors++;
	  return 1;
  }

  checksum = 0;
  while( 1 )
  {
	  // note, we are re-using 'misalignment' as data buffer >:}
    if( !fread( &checksum_data, sizeof(unsigned long), 1, fp_output))
    {
      if( feof(fp_output) ) break;

      fclose(fp_output);
      fp_output=NULL;

      fprintf(stderr, "Some parts of the generated core was unreadable while generating checksum\n");
      errors++;
      return(1);
    }
    checksum+=checksum_data;
  }

  printf("Checksum is: %08X negated value is: %08X\n", (unsigned int)checksum, (unsigned int)(checksum^0xFFFFFFFF));
  checksum = (checksum^0xFFFFFFFF)+1;
  if( fseek( fp_output, (long)((byte *)&core_header.core_checksum - (byte *)&core_header), SEEK_SET))
  {
    fprintf( stderr, "Unable to seek to checksum location in generated core image\n");
    errors++;
  }
  else if( !fwrite( &checksum, sizeof(unsigned int), 1, fp_output ) )
  {
    fprintf( stderr, "Unable to write checksum into generated core image\n");
    errors++;
  }
//  fseek( fp_output, 0, SEEK_END );
  fclose(fp_output);
  fp_output = NULL;

#ifdef __DEBUG__
  fprintf( stderr, "generate_core() completed\n");
#endif
  return 0;

}


//----------------------------------------------------------------------------
int generate_function_list( void ) {
//----------------------------------------------------------------------------
  node_function *f;
  node_gsymbol *gsym=NULL;
  dword vid;

#ifdef __DEBUG__
  fprintf( stderr, "generate_function_list() started\n");
#endif

  gsym = root_globals;
  while( gsym ) {
    if( gsym->name[0] == '.'
        && gsym->name[1] == '.'
        && gsym->name[2] == '@'
	&& gsym->name[3] == 'V'
	&& gsym->name[4] == 'O'
	&& gsym->name[5] == 'i'
	&& gsym->name[6] == 'D'
	&& gsym->name[7] != 0
       ) {
      vid = atoi( &gsym->name[7] );
#ifdef __DEBUG__
      fprintf( stderr, "generate_function_list() global starting with ..@VOiD detected: %s (%lu)\n", gsym->name, vid);
#endif

      f = (node_function *)elib_malloc(sizeof(node_function));
      f->next_node = root_functions;
      root_functions = f;
      f->name = gsym->name;
      f->vid = vid;
      f->value = gsym->value;
      f->parent_obj = gsym->parent_obj;
#ifdef __DEBUG__
	fprintf( stderr, "generate_function_list() VID (aka function) created at [%08X] with value [%08X]\n", (unsigned int)f, (unsigned int)f->value);
#endif
    }
    gsym = gsym->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "generate_function_list() completed\n");
#endif
  return errors;
}

//----------------------------------------------------------------------------
int get_function_details( byte *name, dword *vid, dword *value ) {
//----------------------------------------------------------------------------
  node_function *f;

#ifdef __DEBUG__
  fprintf( stderr, "get_function_details([%s], [%p], [%p]) called\n", name, vid, value);
#endif

  f = root_functions;
  while( f ) {
    if( !strcmp( name, f->name ) ) {
      if( vid ) *vid = f->vid;
      if( value ) *value = f->value;
#ifdef __DEBUG__
      fprintf( stderr, "get_function_details() function found with VID [%lu], and pointer [%lu]\n", f->vid, f->value);
#endif
      return 0;
    }
    f = f->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "get_function_details() function not found\n");
#endif
  return 1;
}

//----------------------------------------------------------------------------
int get_global_value( byte *cell, byte *name, dword *value ) {
//----------------------------------------------------------------------------
  node_gsymbol *gsym;

#ifdef __DEBUG__
  fprintf( stderr, "get_global_offset( [%s], [%p] ) called\n", name, value);
#endif

  if( !strcmp( name, "__CORE_HEADER__" ) ) {
	  *value = global_offset;
#ifdef __DEBUG__
	  fprintf( stderr, "get_global_offset() value of [%p] found for __CORE_HEADER__\n", (void *)global_offset);
#endif
	  return 0;
  }
  
  gsym = root_globals;
  while( gsym ) {
    if( !strcmp( name, gsym->name ) ) {
#ifdef __DEBUG__
      fprintf( stderr, "get_global_offset() value of [%p] found for global [%s]\n", (void *)gsym->value, gsym->name);
#endif
      *value = gsym->value;
      return 0;
    }
    gsym = gsym->next_node;
  }

  fprintf( stderr, "Error: [%s] requires symbol [%s] which could not be found\n", cell, name);
  errors++;
  return 1;
}

//----------------------------------------------------------------------------
dword get_offset( byte *hexstring ) {
//----------------------------------------------------------------------------

  dword tmp=0;

  while( hexstring[0] ) {
    if( (hexstring[0] >= '0'   &&
	  hexstring[0] <= '9' ) ||
	( hexstring[0] >= 'A'  &&
	  hexstring[0] <= 'F' ) ||
	( hexstring[0] >= 'a'  &&
	  hexstring[0] <= 'f' ) ) {

      hexstring[0] |= 0x20;
      hexstring[0] -= 0x30;
      if(hexstring[0] > 0x09) hexstring[0]-= 0x27;

      if( tmp & 0xF0000000 ) {
	fprintf( stderr, "Error: offset overflow, a maximum value of FFFFFFFF can be specified\n");
	errors++;
	break;
      }
      tmp = (tmp << 4 ) + hexstring[0];
    }
    else {
      fprintf( stderr, "Error: Invalid character \'%c\' encountered in specified offset\n", hexstring[0]);
      errors++;
    }
    hexstring++;
  }
  return tmp;
}

//----------------------------------------------------------------------------
int get_section_global_offset( dword *value, dword shndx, node_obj *o) {
//----------------------------------------------------------------------------
  node_section *s=NULL;
  node_cell *c=NULL;

#ifdef __DEBUG__
  fprintf( stderr, "get_section_global_offset([%p], [%lu], [%p]) called\n", value, shndx, o);
#endif

  s = root_sorted_sections;
  while( s ) {
    if( s->parent_obj == o && s->shndx == shndx ) {
      *value += s->global_offset;
#ifdef __DEBUG__
      fprintf( stderr, "get_section_global_offset() associated with section [%s]\n", s->sh_name);
#endif
      return 0;
    }
    s = s->next_node;
  }

  c = root_cell;
  while( c ) {
    if( c->parent_obj == o &&
	c->c_info &&
	((node_section *)c->c_info)->shndx == shndx ) {
      *value += ((node_section *)c->c_info)->global_offset;
#ifdef __DEBUG__
      fprintf( stderr, "get_section_global_offsets() associated with section [.c_info]\n");
#endif
      return 0;
    }
    c = c->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "get_section_global_offset() couldn't resolve, die\n");
#endif
  return 1;
}

//----------------------------------------------------------------------------
int is_global_function( byte *name ) {
//----------------------------------------------------------------------------

  node_function *f;

#ifdef __DEBUG__
  fprintf( stderr, "is_global_function(%s) called\n", name);
#endif

  f = root_functions;
  while( f ) {
    if( !strcmp( name, f->name) ) {
#ifdef __DEBUG__
      fprintf( stderr, "is_global_function() YES\n");
#endif
      return 1;
    }
    f = f->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "is_global_function() NO\n");
#endif
  return 0;
}


//----------------------------------------------------------------------------
int open_objects( void ) {
//----------------------------------------------------------------------------

  node_obj *elf_object=NULL;
  node_section *elf_section=NULL;
  Elf32_hdr *elf_header=NULL;
  int i=0;

#ifdef __DEBUG__
  fprintf( stderr, "open_objects() called\n");
#endif

  if( !root_obj ) {
    fprintf( stderr, "Error: no object specified, can't link anti-matter yet\n");
    errors++;
    return errors;
  }

  // This is the main loop here, it goes thru all the objects
  // Note: if a problem occur while trying load open or read a part of an
  // object, it will simply skip to tne next object
  //
  // This is so that the user can fix the various bad pointers in one shot and
  // not have to rerun the command line 30 times
  elf_object = root_obj;
  while( elf_object ) {
#ifdef __DEBUG__
    fprintf( stderr, "open_objects() processing [%s] with node_obj [%p]\n", elf_object->filename, elf_object);
#endif

    elf_section = NULL;

    // Try to open up the file and see where it goes :)
    elf_object->fp = fopen(elf_object->filename, "rb");
    if( !elf_object->fp ) {
      fprintf(stderr, "Error: Unable to open file: %s\n", elf_object->filename);
      errors++;
      goto load_next_object;
    }
#ifdef __DEBUG__
    fprintf( stderr, "open_objects() file open for \"rb\" using file pointer [%p], allocating memory to load elf object header\n", elf_object->fp);
#endif

    // File opened, good
    // Now trying to read the elf header
    if( elib_fread(
	  elf_object->fp,
	  (void *)&elf_header,
	  sizeof(Elf32_hdr),
	  0,
	  elf_object->filename) )
      goto load_next_object;

    // Seems to go sweet, elf header read, now validating..
#ifdef __DEBUG__
    fprintf( stderr, "open_objects() verifying elf header [%p] validity/compatibility\n", elf_header);
#endif
    if( validate_elf_header( elf_header, elf_object->filename ) )
      goto dealloc_elf_header;

#ifdef __DEBUG__
    fprintf( stderr, "open_objects() elf header [%p] validated, loading up shtab\n", elf_header);
#endif

    // Header validated, loading up the shtab
    elf_object->shnum = elf_header->e_shnum;

    if( elib_fread(
	  elf_object->fp,
	  (void *)&elf_object->shtab,
	  elf_header->e_shentsize * elf_header->e_shnum,
	  elf_header->e_shoff, elf_object->filename) )
      goto dealloc_elf_header;

#ifdef __DEBUG__
    fprintf( stderr, "open_objects() shtab of [%s] loaded at [%p], loading shstrtab\n", elf_object->filename, elf_object->shtab);
#endif

    // now get ready for that one baby :P
    // that 4th argument is doing the following:
    // -- use the pointer that we have to the loaded shtab
    // -- find the right entry in this table using the Elf32_Shr entry size
    //    and the index found in the elf_header e_shstrndx
    // -- in this Elf32_Shdr entry, we want the .sh_offset value
    // -- and we typecast all that to a dword, TADA!
    if( elib_fread(
	  elf_object->fp,
	  (void *)&elf_object->shstrtab,
	  (dword)((Elf32_Shdr *)(elf_object->shtab[(elf_header->e_shstrndx)]).sh_size),
	  (dword)((Elf32_Shdr *)(elf_object->shtab[(elf_header->e_shstrndx)]).sh_offset),
	  elf_object->filename) ) {
      errors++;
      goto dealloc_elf_header;
    }

#ifdef __DEBUG__
    fprintf( stderr, "open_objects() shstrtab of [%s] loaded at [%p]\n", elf_object->filename, elf_object->shtab);
#endif


    for(i = 1; i <= elf_object->shnum; i++) {

      if((dword)((Elf32_Shdr *)(elf_object->shtab[i]).sh_type) == SHT_PROGBITS){

	if( strcmp( ".comment",
	      &elf_object->shstrtab[(dword)((Elf32_Shdr *)(elf_object->shtab[i]).sh_name)] ) == 0 ) {
#ifdef __DEBUG__
	  fprintf( stderr, "open_objects() bypassing .comment section\n");
#endif
	  continue;
	}
	
	if( !elf_section ) {
	  elf_section = (node_section *)elib_malloc(sizeof(node_section));
	  elf_object->sections = elf_section;
	  if( !elf_section ) break;
	}
	else {
	  elf_section->next_node =
	    (node_section *)elib_malloc(sizeof(node_section));
	  if( !elf_section ) break;
	  elf_section = elf_section->next_node;
	}
	elf_section->parent_obj		= elf_object;
	elf_section->sh_name		= &elf_object->shstrtab[(dword)((Elf32_Shdr *)(elf_object->shtab[i]).sh_name)];
	elf_section->shndx		= i;
	elf_section->sh_entry		= (Elf32_Shdr *)&elf_object->shtab[i];
	elf_section->next_node		= NULL;
	elf_section->reltab		= NULL;
#ifdef __DEBUG__
	fprintf( stderr, "open_objects() section of name [%s] registered at [%p]\n", elf_section->sh_name, elf_section);
#endif
      }

      if( (dword)((Elf32_Shdr *)(elf_object->shtab[i]).sh_type) == SHT_SYMTAB){
  // Found the symbol table
  // the 4th Argument in the elib_fread call is similar to what we did above,
  // except that we are now using the index number i instead of shstrndx
	
	if( elf_object->symtab ) {
	  fprintf( stderr, "Warning: Support for multiple symbol table not yet implemented.\n+Detected in file: %s, loading lastest table found\n", elf_object->filename);
	  warnings++;
	}
	
	elf_object->symtab_size = (dword)((Elf32_Shdr *)(elf_object->shtab[i]).sh_size);
	if( elib_fread(
	      elf_object->fp,
	      (void *)&elf_object->symtab,
	      elf_object->symtab_size,
	      (dword)((Elf32_Shdr *)(elf_object->shtab[i]).sh_offset),
	      elf_object->filename) ) {
	  errors++;
	  break;
	}

#ifdef __DEBUG__
	fprintf( stderr, "open_objects() found symtab at index: %i\n", i);
#endif

    // Now you guys will really hate me :P
    // I use the Index found in the Elf32_Shdr entry of the symtab above, this
    // value is currently located at param 4 of elib_read but chanign the
    // .sh_offset to .sh_info
    //
    // So, the whole line is similar as what we just did above, except replace
    // the 'i' by the whole line above with .sh_info
    //
    // anyway, here it is:
#ifdef __DEBUG__
        if( elib_fread(
	    elf_object->fp,
	    (void *)&elf_object->strtab,
	    (dword)((Elf32_Shdr *)(elf_object->shtab[(dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_link]).sh_size),
	    (dword)((Elf32_Shdr *)(elf_object->shtab[(dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_link]).sh_offset),
	    elf_object->filename) ) break;
	fprintf( stderr, "open_objects() strtab loaded at [%p]\n", elf_object->strtab);
#else
        elib_fread(
	    elf_object->fp,
	    (void *)&elf_object->strtab,
	    (dword)((Elf32_Shdr *)(elf_object->shtab[(dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_link]).sh_size),
	    (dword)((Elf32_Shdr *)(elf_object->shtab[(dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_link]).sh_offset),
	    elf_object->filename);
#endif
      }
    }


    for(i = 1; i <= elf_object->shnum; i++) {
      if((dword)((Elf32_Shdr *)(elf_object->shtab[i]).sh_type) == SHT_REL) {
	elf_section = elf_object->sections;
	while( elf_section ) {
	  if( elf_section->shndx ==
	      (dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_info ) break;
	  elf_section = elf_section->next_node;
	}
	if( !elf_section ) {
	  fprintf( stderr, "Error: Found relocation table in object [%s] but matching section isn't included or is invalid.\n", elf_object->filename);
	  errors++;
	  break;
	}

	if( elib_fread(
	      elf_object->fp,
	      (void *)&elf_section->reltab,
	      (dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_size,
	      (dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_offset,
	      elf_object->filename) ) break;
	elf_section->reltab_size = (dword)(Elf32_Shdr *)(elf_object->shtab[i]).sh_size;
#ifdef __DEBUG__
	fprintf( stderr, "open_objects() relocation table of section [%s] loaded at [%p]\n", elf_section->sh_name, elf_section->reltab);
#endif
      }
    }

dealloc_elf_header:
#ifdef __DEBUG__
    fprintf( stderr, "open_objects() deallocating elf_header memory [%p]\n", elf_header);
#endif
    elib_free( elf_header );

load_next_object:
#ifdef __DEBUG__
    fprintf( stderr, "open_objects() node_obj [%p] processed, loading up next node_obj [%p]\n", elf_object, elf_object->next_node);
#endif
    elf_object = elf_object->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "open_objects() completed\n");
#endif
  return errors;
}


//----------------------------------------------------------------------------
int produces_vid_listing( void ) {
//----------------------------------------------------------------------------
  node_obj *o=NULL;
  dword vid;
  dword val;
  Elf32_Sym *sym;
  int i;

#ifdef __DEBUG__
  fprintf( stderr, "produces_vid_listing() called\n");
#endif

  fp_output = fopen( vid_listing_filename, "w" );
  if( !fp_output ) return 1;

  o = root_obj;
  while( o ) {
    fprintf( fp_output, "object: %s\n", o->filename);
    i = o->symtab_size / sizeof(Elf32_Sym);
    sym = o->symtab;
    while( --i ) {
      sym++;
      if( is_global_function( &o->strtab[sym->st_name] ) &&
	  sym->st_shndx == SHN_UNDEF ) {
	get_function_details( &o->strtab[sym->st_name], &vid, &val);
	fprintf(
	    fp_output,
	    "\tr: %8lu, %08X, %s\n",
	    vid,
	    (unsigned int)val,
	    &o->strtab[sym->st_name+7]);	// +7 = ..@VOiD
      }
    }
    i = o->symtab_size / sizeof(Elf32_Sym);
    sym = o->symtab;
    while( --i ) {
      sym++;
      if( is_global_function( &o->strtab[sym->st_name] ) &&
	  sym->st_shndx != SHN_UNDEF &&
	  (ELF32_ST_BIND(sym->st_info) == STB_GLOBAL ||
	   ELF32_ST_BIND(sym->st_info) == STB_WEAK) ) {
	get_function_details( &o->strtab[sym->st_name], &vid, &val);
	fprintf(
	    fp_output,
	    "\tp: %8lu, %08X, %s\n",
	    vid,
	    (unsigned int)val,
	    &o->strtab[sym->st_name+7]);	// +7 = ..@VOiD
      }
    }
    fprintf( fp_output, "\n");
    o = o->next_node;
  }


#ifdef __DEBUG__
  fprintf( stderr, "produces_vid_listing() completed\n");
#endif
  fclose( fp_output );
  fp_output = NULL;
  return 0;
}

//----------------------------------------------------------------------------
int update_symtables( void ) {
//----------------------------------------------------------------------------
  node_obj *o=NULL;
  Elf32_Sym *sym=NULL;
  int i;

#ifdef __DEBUG__
  fprintf( stderr, "update_symtables() started\n");
#endif

  o = root_obj;
  while( o ) {
    i = o->symtab_size / sizeof(Elf32_Sym);
    sym = o->symtab;
#ifdef __DEBUG__
    fprintf( stderr, "update_symtables().phase1 processing object: %s\n", o->filename);
#endif

    while( --i ) {
      sym++;
#ifdef __DEBUG__
      fprintf( stderr, "update_symtables().phase1 symbol: %s\n\ttype: %lu\n\tvalue: %p\n\tshndx: %lu\n", &o->strtab[sym->st_name], (unsigned long)ELF32_ST_TYPE(sym->st_info), (void *)sym->st_value, (unsigned long)sym->st_shndx);
#endif
      if( (sym->st_shndx > 0 && sym->st_shndx < SHN_ABSOLUTE) &&
	  get_section_global_offset(
	    &sym->st_value,
	    sym->st_shndx,
	    o )
	  ) {
	if( !(osw_inter_init->parent_obj == o &&
	    sym->st_shndx == osw_inter_init->shndx)
	    ) {
	  errors++;
	  fprintf( stderr, "Error: Weird section assignment in symbol table of object: %s\n", o->filename);
	  return 1;
	}
	warnings++;
	fprintf( stderr, "Warning: .osw_inter_init section defined but unused due to lack of .c_init or .c_onetime_init sections\n");
      }
#ifdef __DEBUG__
      fprintf( stderr, "\tnew value: %p\n", (void *)sym->st_value);
#endif
    }
    o = o->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "update_symtables() phase I completed, proceeding to phase II: local and global registration\n");
#endif
  // Even if the function name isn't perfectly appropriate, this is also where
  // we register the chained list of local symbols and global symbols.  We will
  // also have to check for undefined symbols and see if all required ones are
  // there.
  o = root_obj;
  while( o ) {
    i = o->symtab_size / sizeof(Elf32_Sym);
    sym = o->symtab;
#ifdef __DEBUG__
    fprintf( stderr, "update_symtables().phase2 processing object: %s\n", o->filename);
#endif

    while( --i ) {
      sym++;
#ifdef __DEBUG__
      fprintf( stderr, "update_symtables().phase2 symbol: %s\n\ttype: %lu\n\tbinding: %lu\n\tvalue: %p\n\tshndx: %lu\n", &o->strtab[sym->st_name], (unsigned long)ELF32_ST_TYPE(sym->st_info), (unsigned long)ELF32_ST_BIND(sym->st_info), (void *)sym->st_value, (unsigned long)sym->st_shndx);
#endif
      if( sym->st_shndx == 0 ) continue;
      switch( ELF32_ST_BIND(sym->st_info) ) {
	case( STB_LOCAL ):
//	  if( ELF32_ST_TYPE(sym->st_info) != STT_NOTYPE ) break;
//#ifdef __DEBUG__
//	  fprintf( stderr, "\tsymbol identified as local, registering\n");
//#endif
//	  if( add_local(
//		&o->strtab[sym->st_name],
//		sym->st_value,
//		o ) )
//	    return 1;
	  break;
	case( STB_GLOBAL ):
#ifdef __DEBUG__
	  fprintf( stderr, "\tsymbol identified as global with strong attributes, registering\n");
#endif
	  if( add_global(
		&o->strtab[sym->st_name],
		sym->st_value,
		sym,
		1,
		o ) )
	    return 1;
	  break;
	case( STB_WEAK ):
#ifdef __DEBUG__
	  fprintf( stderr, "\tsymbol identified as global with weak attributes, trying registration\n");
#endif
	  if( add_global(
		&o->strtab[sym->st_name],
		sym->st_value,
		sym,
		0,
		o ) )
	    return 1;
	  break;
	default:
	  fprintf( stderr, "Warning: Symbol binding is of unsupported type, please contact UUU development team.  Creating a tarball of all the objects + indicating the command line used would be appreciated.\n");
	  warnings++;
	  break;
      }
    }
    o = o->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "update_symtables() phase II completed, starting phase III, importation of extern symbols\n");
#endif

  o = root_obj;
  while( o ) {
    i = o->symtab_size / sizeof(Elf32_Sym);
    sym = o->symtab;
#ifdef __DEBUG__
    fprintf( stderr, "update_symtables().phase3 processing object: %s\n", o->filename);
#endif
    while( --i ) {
      sym++;

      if( sym->st_shndx != 0 ) continue;
#ifdef __DEBUG__
      fprintf( stderr, "update_symtables().phase3 trying to import undefined symbol: %s\n", &o->strtab[sym->st_name]);
      if( get_global_value(
	    o->filename,
	    &o->strtab[sym->st_name],
	    &sym->st_value )
	  ) continue;
      fprintf( stderr, "update_symtables().phase3 value fixed to [%p]\n", (void *)sym->st_value);
#else
      get_global_value( o->filename, &o->strtab[sym->st_name], &sym->st_value );
#endif
    }
    o = o->next_node;
  }

#ifdef __DEBUG__
  fprintf( stderr, "update_symtables() completed\n");
#endif
  return 0;
}

//----------------------------------------------------------------------------
int validate_elf_header( Elf32_hdr *elf_header, char *filename ) {
//----------------------------------------------------------------------------
#ifdef __DEBUG__
  fprintf( stderr, "validate_elf_header( [%p], [%s]) called\n", elf_header, filename);
#endif
  if( (elf_header->e_signature != ELFMAGIC) ||
      (elf_header->e_class != ELFCLASS32) ||
      (elf_header->e_data != ELFDATA2LSB) ||
      (elf_header->e_hdrversion != EV_VERSION) ||
      (elf_header->e_type != ET_REL) ||
      (elf_header->e_machine != EM_386) ||
      (elf_header->e_version != EV_VERSION) ) {
    fprintf( stderr, "Error: Invalid or unsupported ELF object header in file: %s\n", filename);
    return ++errors;
  }

  if( elf_header->e_shoff == 0 ) {
    fprintf( stderr, "Error: ELF object contain no section definition: %s\n", filename);
    return ++errors;
  }

  if( elf_header->e_shstrndx == 0 ) {
    fprintf( stderr, "Error: ELF object contain section definitions but no string table associated with it: %s\n", filename);
    return ++errors;
  }

  if( elf_header->e_entry != 0 ) {
    fprintf( stderr, "Warning: Ignoring ELF object specified entry point: %x in file: %s\n", (int)elf_header->e_entry, filename);
    warnings++;
  }

  if( elf_header->e_phoff != 0 ) {
    fprintf( stderr, "Warning: Ignoring ELF object set Program Header Table in file: %s\n", filename);
    warnings++;
  }

#ifdef __DEBUG__
  fprintf( stderr, "validate_elf_header() completed\n");
#endif
  return 0;
}

