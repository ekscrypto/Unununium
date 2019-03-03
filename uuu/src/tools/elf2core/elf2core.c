#include "elf2core.h"

//#define FULL_DEBUG
//#define DEBUG_MEMORY
#define FULL_ERROR_MESSAGES

#ifdef FULL_DEBUG
  #ifndef DEBUG_MEMORY
    #define DEBUG_MEMORY
  #endif

  #ifndef FULL_ERROR_MESSAGES
    #define FULL_ERROR_MESSAGES
  #endif
#endif


/******************************************************************************
 * FUNCTION PROTOTYPING
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* extern functions */
void free(void *p);
void *malloc(size_t size);
/* local standard functions */
void apply_relocation( byte *buffer, section_node *relocation_table, cell_node *cell , section_node *section);
void build_section_list( cell_node *cell );
void build_section_list_all( void );
void cmdline_parse( int argc, char **argv );
void cmdline_check_option( byte *option );
void display_help( void );
void elib_free( void *p );
void *elib_malloc( size_t size );
void free_all_structures(void);
section_node *gen_filler_section(dword alignment, section_node *last_node);
byte get_global_value( byte *name, dword *fix_point );
dword get_relocation_symbol_index( dword info );
byte get_relocation_type( dword info );
dword get_section_global_offset( cell_node *cell, dword shndx );
byte *get_section_name(cell_node *cell, dword sh_name);
byte get_symbol_binding( byte info );
byte *get_symbol_name( cell_node *cell, dword st_name );
byte get_symbol_type( byte info );
dword get_symbol_value_by_index( cell_node *cell, dword symndx);
section_node *include_all_sections( byte *section_name, dword alignment, section_node *last_section);
void load_sys_sections( cell_node *cell );
void load_sys_sections_all(void);
void obj_open(byte *filename);
void prepare_relocation_tables(void);
void *read_cell( cell_node *cell, size_t offset, size_t size );
void read_global_offset( byte *hex_offset);
void register_global_symbol( byte *name, dword value, dword strength );
void register_local_symbol( byte *name, dword value, cell_node *cell );
byte section_is_excluded( byte *name );
void sort_sections(void);
void update_symtab_all(void);
void update_symtab_cell(cell_node *cell, dword phase);
byte write_block( size_t size, void *buffer );
byte write_core_header(void);
void write_all_sections(void);

#ifdef DEBUG_MEMORY
void debug_display_dword( dword );
void debug_display_word( word );
void debug_display_byte( byte );
void debug_dump_cell_all( void );
void debug_dump_cell_node( cell_node *cell );
void debug_dump_sections_list( section_node *section );
void debug_dump_sorted_sections_list( void );
void debug_dump_global_node( global_node *global );
#endif

#ifdef FULL_ERROR_MESSAGES
  #define disp_error(message) fprintf( stderr, message);
  #define disp_error2(message,supplement) fprintf( stderr, message, supplement);
#else
  #define disp_error(error_code) fprintf( stderr, "ERROR: %i", error_code);
#endif


/******************************************************************************
 * Static data definition
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
static byte copyrights[]= "Elf2Core Linker version 0.4.3\
Copyrights (C) 2001, Dave Poirier\n\
Distributed under the BSD License.\n";

/* the following 3 sections must perfectly match each other */
static byte *option_names[2+OPT_COUNT] = {
	"abort-warning",
	"fixed",
	"help",
	"silent-warning",
	"trace-to-stdout",
	"version" };
static byte option_values[2+OPT_COUNT] = {
	OPT_ABORTWARNING,
	OPT_FIXEDLOCATION,
	254,
	OPT_SILENTWARNING,
	OPT_TRACEOUTPUT,
	255 };
static byte *option_descriptions[2+OPT_COUNT] = {
	"\tabort linking process on any warning",
	"\t\texclude DRP information from output",
	"\t\tdisplay this help",
	"do not display warning",
	"display all linking process information",
	"\tdisplay version and copyrights" };

static byte str_usage[]="Syntax: elf2core [options] offset [core] cells\n\
Where:\n\
\n\
	[]		indicate this field is optional\n\
	core		is the elf object containing the core sections\n\
	cells		is a list of elf object, space separated, that will\n\
			  be included in the core.\n\
	offset		hexadecimal value (8 chars) of default loading offset\n\
	options		is one or combination of the following\n\n";

static byte str_moreinformation[]="\n\
\n\
More information is available on our website at: http://uuu.wox.org\n\
or by email at: uuu-info@uuu.wox.org\n\
";

/* the 2 following sections must perfectly match each other */
static byte *section_names[SECT_COUNT] = {
	"core_preinit",
	"core_postinit",
	"cell_initonce",
	"cell_init",
	"extern_dlp_abs",
	"extern_dlp_rel",
	"global_dlp",
	".data",
	".rodata",
	".shstrtab",
	".symtab",
	".strtab" };
static byte section_values[SECT_COUNT] = {
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	60,
	60,
	0,
	254,
	253 };

#ifdef DEBUG_MEMORY
static byte hex_conversion[16]="0123456789ABCDEF";
#endif

static byte output_file[]="core.bin";

static byte filler_section[]=".SPECiAL.FiLLER.";


/******************************************************************************
 * Read/write public variables
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
dword warnings=0, errors=0, linker_options=OPT_FIXEDLOCATION, global_offset=0xFFFFFFFF;
cell_node *root_cell=NULL;
global_node *globals;
section_node *root_section=NULL;

FILE *output_fp=NULL;
core_hdr core_header={ CORESIGN,0,sizeof(core_hdr),0,0,0,0 };



/******************************************************************************
 * Program Entry Point
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
int main ( int argc, char **argv ) {

  /* Parse command line, open up each file as you find them */
  cmdline_parse( argc, argv );
  if( errors ) goto quick_exit;
  if( warnings && (linker_options & OPT_ABORTWARNING) != 0 ) goto quick_exit;

  /* Load the various system sections of all the objects found */
  load_sys_sections_all();
  if( errors ) goto quick_exit;
  if( warnings && (linker_options & OPT_ABORTWARNING) != 0 ) goto quick_exit;
  
  /* Build a complete list of all the sections in all the object files */
  build_section_list_all();
  if( errors ) goto quick_exit;
  if( warnings && (linker_options & OPT_ABORTWARNING) != 0 ) goto quick_exit;
  
  /* Relink relocation table with their respective sections */
  prepare_relocation_tables();
  if( errors ) goto quick_exit;
  if( warnings && (linker_options & OPT_ABORTWARNING) != 0 ) goto quick_exit;

  /* Sort section order as they will appear in the core.bin file */
  sort_sections();
  if( errors ) goto quick_exit;
  if( warnings && (linker_options & OPT_ABORTWARNING) != 0 ) goto quick_exit;
  
  /* Recalculate all symbols tables */
  update_symtab_all();
  if( errors ) goto quick_exit;
  if( warnings && (linker_options & OPT_ABORTWARNING) != 0 ) goto quick_exit;

  /* Write the core header */
  if( write_core_header() ) goto quick_exit;
  if( warnings && (linker_options & OPT_ABORTWARNING) != 0 ) goto quick_exit;

  /* Read sections from objects, apply relocation tables, and write them in
   * the core.bin output file
   */
  write_all_sections();
  fclose(output_fp);

  if( errors || (warnings && (linker_options * OPT_ABORTWARNING)!=0))
    remove(output_file);

quick_exit:
  free_all_structures();
  if( (linker_options & OPT_ABORTWARNING) != 0) return errors+warnings+40;
  return errors;
}


/******************************************************************************
 * Apply relocation information on section buffer
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void apply_relocation( byte *buffer, section_node  *relocation_table,  cell_node *cell, section_node *section) {
  Elf32_Rel *rel, *rel_backup;
  Elf32_Shdr *e_sh;
  dword i;
  byte type;
  dword symndx;
  byte *modif;

  e_sh = relocation_table->sh_entry;
  if( !e_sh) {
    fprintf( stdout, "WE ARE IN SHIT!\n");
    return;
  }

  if( (e_sh->sh_size % sizeof(Elf32_Rel)) != 0 ) {
    fprintf( stdout, "relocation table [ %s ] in object [ %s ] isn't a relocation entry multiple\n", relocation_table->sh_name, cell->filename);
    errors++;
    return;
  }

  
  rel = read_cell( cell, e_sh->sh_offset, e_sh->sh_size);
  if( !rel ) {
    fprintf( stdout, "Can't read relocation data in object: %s\n", cell->filename);
    errors++;
    return;
  }

  i = e_sh->sh_size / sizeof(Elf32_Rel);
  rel_backup = rel;
  while(i--) {
    type = get_relocation_type(rel->r_info);
    symndx = get_relocation_symbol_index(rel->r_info);
    switch( type ) {
      case( R_386_32 ):
	modif = buffer + rel->r_offset;	//modif = (void *)buffer + rel->r_offset;
	*(dword *)modif += get_symbol_value_by_index(cell, symndx);
	break; 
      case( R_386_PC32 ):
	modif = buffer + rel->r_offset;		//modif = (void *)buffer + rel->r_offset;
	*(dword *)modif += (get_symbol_value_by_index(cell, symndx) - (rel->r_offset + section->global_offset));
	break;
    } 
/*    fprintf( stdout, "[r] r_offset:[");
    debug_display_dword(rel->r_offset);
    fprintf( stdout, "] rel.type:[");
    debug_display_byte(type);
    fprintf( stdout, "] rel.symbol_index:[");
    debug_display_dword(symndx);
    fprintf( stdout, "]\n"); */
    rel++;
  }
  elib_free(rel_backup);
}


/******************************************************************************
 * Build a list of all sections of a specific cell to include
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void build_section_list( cell_node *cell ) {
  section_node *section=NULL;
  dword shnum=0;
  Elf32_Shdr *e_sh=NULL;

  shnum = cell->shnum;
  e_sh = cell->shtab;
  
  while( shnum-- ) {
    if( e_sh->sh_type == 1 || e_sh->sh_type == 9 ) {
      if( strcmp(get_section_name(cell,e_sh->sh_name), ".comment") != 0) {
        section = (section_node *)elib_malloc( sizeof(section_node) );
        if( !section ) return;
        section->next_node = cell->sections;
        cell->sections = section;
        section->next_sorted_node = NULL;
        section->sh_name = get_section_name( cell, e_sh->sh_name );
        section->relocation_table = NULL;
        section->parent_cell = cell;
        section->sh_entry = e_sh;
        section->global_offset = 0;
	section->shndx = cell->shnum-shnum - 1;
      }
    }
    e_sh++;
  }
}



/******************************************************************************
 * Build a list of all sections to include
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void build_section_list_all(void) {
  cell_node *cell;

  cell = root_cell;
  while( cell ) {
    build_section_list( cell );
    cell = cell->next_node;
  }
}



/******************************************************************************
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void cmdline_check_option(unsigned char *option) {
  register unsigned char i;

  if( root_cell ) {
#ifdef FULL_ERROR_MESSAGES
    disp_error( ERROR_PARAMBEFOREOBJECT_FULL );
#else
    disp_error( ERROR_PARAMBEFOREOBJECT_VAL );
#endif
    return;
  }

  i=OPT_COUNT + 3;
  while( --i ) {
    if( strcmp( option, option_names[i-1] ) == 0) break;
  }
  if( i-- ) {
    switch( option_values[i] ) {
    case( 255 ):
      fprintf( stdout, copyrights );
      linker_options = linker_options | OPT_QUIT;
      break;
    case( 254 ):
      display_help();
      linker_options = linker_options | OPT_QUIT;
      break;
    default:
      linker_options = linker_options | option_values[i];
      break;
    }
  } else {
#ifdef FULL_ERROR_MESSAGES
    disp_error2( ERROR_INVALIDPARAM_FULL "%s\n", option );
#else
    disp_error( ERROR_INVALIDPARAM_VAL );
#endif
  }
}


/******************************************************************************
 * Parse for command line parameters
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void cmdline_parse(int argc, char **argv) {
  while( --argc ) {
    argv++;
    if( argv[0][0]=='-' && argv[0][1]=='-' ) {
      argv[0] += 2;
      cmdline_check_option( argv[0] );
    }
    else {
      if( global_offset == 0xFFFFFFFF ) read_global_offset( argv[0] );
      else obj_open( argv[0] );
    }
    if( linker_options & OPT_QUIT ) break;
  }
}



/******************************************************************************
 * Display help on stdout
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void display_help( void ) {
  register unsigned char i;

  fprintf( stdout, str_usage );
  i = OPT_COUNT+2;
  while( i-- )
    fprintf( stdout, "\t--%s\t%s\n", option_names[i], option_descriptions[i] );

  fprintf( stdout, str_moreinformation );
}


/******************************************************************************
 * Local free memory function, allow for debugging output and tracing
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void elib_free( void *p ) {

#ifdef DEBUG_MEMORY
  fprintf( stdout, "[m] freeing: " );
  debug_display_dword( (dword)p );
  fprintf( stdout, "\n" );
#endif

  free( p );
}


/******************************************************************************
 *
 * local function of malloc(), allow us to trace back memory allocations
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void * elib_malloc( size_t size ) {
  void *p;

#ifdef DEBUG_MEMORY
  fprintf( stdout, "[m] req: " );
  debug_display_dword( (dword)size );
  fprintf( stdout, "\tresult: " );
#endif
  
  p = malloc( size );

#ifdef DEBUG_MEMORY
  if( !p ) fprintf( stdout, "FAILED\n" );
  else {
    debug_display_dword( (dword)p );
    fprintf( stdout, "\n" );
  }
#endif

  return p;
}


/******************************************************************************
 * Free all memory structures allocated
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void free_all_structures(void) {
  cell_node *cell, *next_cell;
  section_node *section, *next_section;
  global_node *global, *next_global;

  cell = root_cell;
  while( cell ) {
    next_cell = cell->next_node;
    
    section = cell->sections;
    while( section ) {
      next_section = section->next_node;
      if( section->relocation_table) elib_free( section->relocation_table );
      elib_free( section );
      section = next_section;
    }
    
    if( cell->shtab ) elib_free( cell->shtab );
    if( cell->shstrtab ) elib_free( cell->shstrtab );
    if( cell->strtab ) elib_free( cell->strtab );
    if( cell->symtab ) elib_free( cell->symtab );
    if( cell->cell_header ) elib_free( cell->cell_header );
    if( cell->extern_dlp_abs ) elib_free( cell->extern_dlp_abs );
    if( cell->extern_dlp_rel ) elib_free( cell->extern_dlp_rel );
    if( cell->global_dlp ) elib_free( cell->global_dlp );
    fclose( cell->fp );

    elib_free( cell );
    cell = next_cell;
  }

  global = globals;
  while( global ) {
    next_global = global->next_node;
    elib_free( global );
    global = next_global;
  }
}


/******************************************************************************
 * Generate filling section so as to keep data alignment
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
section_node *gen_filler_section(dword alignment, section_node *last_node ) {
  dword size=0;
  byte *filler;

/*  fprintf( stdout, "[a] current core size:[");
  debug_display_dword(core_header.c_isize);
  fprintf( stdout, "] alignment requested:[");
  debug_display_dword(alignment);
  fprintf( stdout, "]\n"); */

  size = (core_header.c_isize % alignment);
  if( !size ) return last_node;

  size = alignment - size;
  last_node->next_sorted_node=(section_node *)elib_malloc( sizeof(section_node)+size);
  if( !last_node->next_sorted_node ) {
    fprintf( stdout, "Unable to create filler section, memory allocation failed.\n");
    errors++;
    return last_node;
  }
  last_node = last_node->next_sorted_node;

  last_node->parent_cell = NULL;
  last_node->next_sorted_node = NULL;
  last_node->global_offset = size;
  last_node->sh_name = filler_section;
  last_node->relocation_table = NULL;
  last_node->next_node = NULL;
  last_node->shndx = 0;
  last_node->sh_entry = NULL;
  core_header.c_isize += size;

/*  fprintf( stdout, "[a] filling required:[");
  debug_display_dword( size );
  fprintf( stdout, "] ["); */
  
  (dword)filler = (dword)&last_node->shndx + (dword)sizeof(last_node->shndx);
  while( size--) {
/*    fprintf( stdout, "."); */
    *filler = 0;
    filler++;
  }

/*  fprintf( stdout, "] completed\n"); */

  return last_node;
}

/******************************************************************************
 * try to retrieve the value associated with a global (if such exist) and fix
 * the value at pointer provided.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte get_global_value( byte *name, dword *fix_point ) {
  global_node *global;

  global = globals;

  while(global) {
    if( strcmp( global->name, name ) == 0 ) {
      *fix_point = global->value;
      return 0;
    }
    global = global->next_node;
  }
  return 1;
}



/******************************************************************************
 * Get the symbol index out of the info value found in relocation struct
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
dword get_relocation_symbol_index( dword info ) {
  return info >> 8;
}

/******************************************************************************
 * Get the type out of the info value found in the relocation struct
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte get_relocation_type( dword info ) {
  return (byte)info;
}


/******************************************************************************
 * Get the global offset associated with a section shndx
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
dword get_section_global_offset( cell_node *cell, dword shndx ) {
  section_node *section;

  section = cell->sections;
  while( section ){
    if( section->shndx == shndx ) return section->global_offset;
    section = section->next_node;
  }
  fprintf( stdout, "oops\n");
  return (dword)NULL;
}


/******************************************************************************
 * Get the internal type associated with a specific section
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte get_section_internal_type( byte *name ) {
  byte i = 0;

  i = SECT_COUNT;
  while( i--) {
    if( strcmp( section_names[i], name ) == 0 ) break;
  }
  
  if( i == 255) return 0;
  return section_values[i];
}


/******************************************************************************
 * Get the pointer to a string identifying a particular section
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte *get_section_name( cell_node *cell, dword sh_name ) {
  byte *name;

  name = cell->shstrtab;
  if( !name ) return name;

  return (byte *)(name + sh_name);
}



/******************************************************************************
 * Get the Binding information out of the info found in the symbol struct
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte get_symbol_binding( byte info ) {
  return info >> 4;
}



/******************************************************************************
 * Get the Type out of the info found in the symbol struct
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte get_symbol_type( byte info ) {
  return info & 0x0F;
}


/******************************************************************************
 * Get the pointer to a string identifying the symbol
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte *get_symbol_name( cell_node *cell, dword st_name ) {
  byte *name;

  name = cell->strtab;

  if( !name ) return name;

  return (byte *)(name + st_name);
}

/******************************************************************************
 * Get the value of a specified (by index) symbol
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
dword get_symbol_value_by_index( cell_node *cell, dword symndx) {
  Elf32_Sym *sym;

  sym = cell->symtab;
  if( !sym ) return (dword)NULL;

  if( (symndx * sizeof(Elf32_Sym)) > cell->symtab_size) return (dword)NULL;

  sym += symndx;
  return sym->st_value;
}



/******************************************************************************
 * Include in the sorted section list all the sections matching this name in
 * the order the objects were specified on the command line.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
section_node *include_all_sections( byte *section_name, dword alignment, section_node *last_section ) {
  cell_node *cell=NULL;
  section_node *section=NULL;
  Elf32_Shdr *e_sh=NULL;

  cell = root_cell;
  while( cell ) {
    section = cell->sections;
    while( section ) {
      if( strcmp( section_name, section->sh_name ) == 0 ) {
        if( !last_section ) {
	  last_section = section;
	  root_section = section;
	} else {
	  last_section->next_sorted_node = section;
	  last_section = section;
	}
	section->global_offset = global_offset + core_header.c_isize;
	section->next_sorted_node = NULL;
	e_sh = section->sh_entry;
	core_header.c_isize += e_sh->sh_size;
	if( alignment > 1) last_section = gen_filler_section(alignment, last_section);
      }
      section = section->next_node;
    }
    cell = cell->next_node;
  }
  return last_section;
}



/******************************************************************************
 * Load all sections containing information for the linker of a specified
 * object
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void load_sys_sections( cell_node *cell ) {
  Elf32_Shdr *e_sh;
  dword shnum;

  e_sh = cell->shtab;
  shnum = cell->shnum;
  e_sh++;
  while( --shnum ) {
    switch( e_sh->sh_type ) {
      case( 1):
	switch(get_section_internal_type(get_section_name(cell, e_sh->sh_name))) {
          case( 5 ):
	    cell->extern_dlp_abs = read_cell( cell, e_sh->sh_offset, e_sh->sh_size);
	    cell->extern_dlp_abs_size = e_sh->sh_size;
	    break;
	  case( 6 ):
	    cell->extern_dlp_rel = read_cell( cell, e_sh->sh_offset, e_sh->sh_size);
	    cell->extern_dlp_rel_size = e_sh->sh_size;
	    break;
	  case( 7 ):
	    cell->global_dlp = read_cell( cell, e_sh->sh_offset, e_sh->sh_size);
	    cell->global_dlp_size = e_sh->sh_size;
	    break;
	}
	break;
      case( 2 ):
        cell->symtab = read_cell( cell, e_sh->sh_offset, e_sh->sh_size );
	cell->symtab_size = e_sh->sh_size;
	break;
      case( 3 ):
	if( strcmp( get_section_name( cell, e_sh->sh_name), ".strtab") != 0 ) break;
	cell->strtab = read_cell( cell, e_sh->sh_offset, e_sh->sh_size );
	break;
    }	    
    e_sh++;
  }
}


/******************************************************************************
 * Load all sections containing information for the linker of all objects
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void load_sys_sections_all( void ) {
  cell_node *cell;

  cell = root_cell;
  while( cell ) {
    load_sys_sections( cell );
    cell = cell->next_node;
  }
}



/******************************************************************************
 *
 * Verify the header of an object file, testing the validity and compatibility
 * of the ELF header.  It checks particularly for 80386 compatibility issues.
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
unsigned char obj_check_header( Elf32_hdr *e_hdr ) {
  /* Checking Elf32_Ehdr.e_ident[magic] - ELF object's signature */
  if( e_hdr->e_signature != ELFMAGIC ) return 0;

  /* Checking Elf32_Ehdr.e_ident[e_ident] - class of object */
  if( e_hdr->e_class != ELFCLASS32) return 0;

  
  /* Checking Elf32_Ehdr.e_ident[ELFDATA] - Data ordering format */
  if( e_hdr->e_data != ELFDATA2LSB) return 0;

  /* Checking Elf32_Ehdr.e_ident[Version] - header version number */
  if( e_hdr->e_hdrversion != EV_VERSION) return 0;
  
  /* Checking Elf32_Ehdr.e_type - Object file type */
  if( e_hdr->e_type != ET_REL) return 0;
  
  /* Checking Elf32_Ehdr.e_machine - Required architecture */
  if( e_hdr->e_machine != EM_386 ) return 0;
  
  /* Checking Elf32_Ehdr.e_version - Object file version */
  if( e_hdr->e_version != EV_VERSION) return 0;

  /* Checking Elf32_Ehdr.e_entry - Entry point virtual offset */
  if( e_hdr->e_entry != 0 &&  ( linker_options & OPT_SILENTWARNING ) == 0 )
    warnings++;

  /* Checking Elf32_Ehdr.e_phoff - Program header table file offset */
  if( e_hdr->e_phoff != 0 && ( linker_options & OPT_SILENTWARNING ) == 0 )
    warnings++;

  /* Making sure object contain a header string table */
  if( e_hdr->e_shoff == 0 ) return 0;
  if( e_hdr->e_shstrndx == 0 ) return 0;
  
  return 1;
}

/******************************************************************************
 * Open an ELF32 Object specified in filename
 *
 * also:
 * - call a function to verify the validity of the header
 * - load the header string table containing section names
 * - load the section table containing section definition.
 * - link the validated object in the cell linked list as being the last
 *   object in the chain.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void obj_open( byte *filename) {
  cell_node *cell=NULL,*cell_browser=NULL;
  Elf32_hdr *e_hdr=NULL;
  void *p=NULL;

  cell = (cell_node *)elib_malloc( sizeof(cell_node) );
  if( !cell ) {
#ifdef FULL_ERROR_MESSAGES
    disp_error2( ERROR_UNABLETOALLOCMEM_FULL "%s\n", filename );
#else
    disp_error( ERROR_UNABLETOALLOCMEM_VAL );
#endif
    errors++;
    return;
  }

  cell->filename = filename;
  cell->fp = fopen( filename, "rb" );
  if( !cell->fp ) {
    fprintf( stdout, ERROR_UNABLETOOPEN_FULL "%s\n", filename );
    elib_free( cell );
    errors++;
    return;
  }

  cell->next_node = NULL;
  cell->sections = NULL;
  cell->strtab = NULL;
  cell->symtab = NULL;
  cell->cell_header = NULL;
  cell->extern_dlp_abs = NULL;
  cell->extern_dlp_rel = NULL;
  cell->global_dlp = NULL;
  e_hdr = read_cell( cell, 0, sizeof(Elf32_hdr) ); 
  if( obj_check_header( e_hdr ) ) {
    cell->shnum = (dword)e_hdr->e_shnum;
    cell->shtab = read_cell( cell,
		    e_hdr->e_shoff,
		    (e_hdr->e_shnum * e_hdr->e_shentsize) );

    if(!cell->shtab) return;
    (unsigned long)p = (unsigned long)cell->shtab + (e_hdr->e_shstrndx * e_hdr->e_shentsize);
    cell->shstrtab = read_cell( cell,
		    *(dword *)((unsigned long)p + 16),
		    *(dword *)((unsigned long)p + 20) );	
/*	p = (unsigned long *)cell->shtab + (e_hdr->e_shstrndx * e_hdr->e_shentsize);
    cell->shstrtab = read_cell( cell,
		    *(dword *)((unsigned long)p + 16),
		    *(dword *)((unsigned long)p + 20) );*/

    elib_free( e_hdr );
    cell_browser = root_cell;
    if( !cell_browser ) {
      root_cell = cell;
      return;
    }
    while( cell_browser->next_node ) cell_browser = cell_browser->next_node;
    cell_browser->next_node = cell;
    return;
  }

#ifdef FULL_ERROR_MESSAGES
  disp_error2( ERROR_INVALIDOBJHEADER_FULL "%s\n", filename );
#else
  disp_error( ERROR_INVALIDOBJHEADER_VAL );
#endif 
  elib_free(e_hdr);
  fclose(cell->fp);
  elib_free(cell);
}


/******************************************************************************
 * Relink relocation tables
 *
 * alright, seeing how many level of indentation there is, I think a little
 * explanation is due ;)
 *
 * This function will search for any section starting with the name '.rel.',
 * if it finds any, it will search for the section that is associated with it
 * which should match the remaining of the name.
 *
 * example: ".rel.data"  goes with ".data"
 *
 * Once he found a match, it will link the .rel section as being the
 * relocation table for match found, and will unlink the .rel table from the
 * section linked list.
 *
 * A little trickery was required after the section was removed in order to
 * proceed to the real next section and not forget one or something like that,
 * that is the part where the label 'bypass_pointer_change' comes into play.
 *
 * Well, have fun with this ;)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void prepare_relocation_tables(void) {
  cell_node *cell;
  section_node *section,*section_browser;

  cell = root_cell;
  while(cell) {
    section = cell->sections;
    while(section) {
      if( *(dword *)section->sh_name==0x6C65722E) {
        section_browser = cell->sections;
	while( section_browser ) {
	  if( strcmp( (byte *)(section->sh_name + 4), section_browser->sh_name) == 0) {
	    section_browser->relocation_table = section;
	    if( cell->sections == section ) {
              cell->sections = section->next_node;
	      section->next_node = NULL;
	      section = cell->sections;
	      goto bypass_pointer_change;
	    }
	    else {
              section_browser = cell->sections;
	      while(section_browser) {
	        if( section_browser->next_node == section ) break;
		section_browser = section_browser->next_node;
	      }
	      section_browser->next_node = section->next_node;
              section->next_node = NULL;
	      section = section_browser;
              break;
	    }
	  }
	  section_browser = section_browser->next_node;
	}
      }
      section = section->next_node;
bypass_pointer_change:
	  ;
    }
    cell = cell->next_node;
  }
}


/******************************************************************************
 * Read data in file associated with a cell, from offset for size.  Note that
 * it will also allocate the required memory and return pointer to buffer.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void *read_cell( cell_node *cell, size_t offset, size_t size ) {
  void *p;

  if( fseek( cell->fp, offset, SEEK_SET ) ) {
#ifdef FULL_ERROR_MESSAGES
    disp_error2( ERROR_UNABLETOSEEK_FULL "%s\n", cell->filename );
#else
    disp_error( ERROR_UNABLETOSEEK_VAL );
#endif
    errors++;
    return NULL;
  }
  
  p = elib_malloc( size );
  if( !p ) {
#ifdef FULL_ERROR_MESSAGES
    disp_error2( ERROR_UNABLETOALLOCMEM_FULL "%s\n", cell->filename );
#else
    disp_error( ERROR_UNABLETOALLOCMEM_VAL );
#endif
    errors++;
    return p;
  }

  if( fread( p, size, 1, cell->fp ) != 1 ) {
#ifdef FULL_ERROR_MESSAGES
    disp_error2( ERROR_UNABLETOREAD_FULL "%s\n", cell->filename );
#else
    disp_error( ERROR_UNABLETOREAD_VAL );
#endif
    elib_free( p );
    errors++;
    return NULL;
  }

  return p;
}



void read_global_offset( byte *hex_offset ) {
  dword offset=0;
  byte value, i;

  for(i=0; i<8;i++) {
    value = *hex_offset;
    if( value < '0' || (value < 'A' && value > '9') || value > 'F' ) {
invalid_hex_offset:
      fprintf( stdout, "Offset should be 8 character wide, composed of symbols from 0-9 and A-F.\n");
      errors++;
      return;
    }
    value -= 0x30;
    if( value > 9 ) value -= 7;
    offset = (offset << 4) + value;
    hex_offset++;
  }
  if( *hex_offset != 0 ) goto invalid_hex_offset;

  global_offset = offset;
  return;
}



/******************************************************************************
 * Register a global symbol to be shared with the whole system
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void register_global_symbol( byte *name, dword value, dword strength ) {
  global_node *global;

  global = globals;
  if( !global ) {
    globals = (global_node *)elib_malloc( sizeof(global_node) );
    if( !globals ) goto failed_mem;

    globals->next_node = NULL;
    goto fill_global;
  }

  while( global ) {
    if( strcmp( name, global->name ) == 0 ) {
      if( (word)strength < global->strength ) {
	global->value = value;
	global->strength = strength;
	return;
      }
      
      if( strength > STB_GLOBAL ) return;

      /* and some homebrewed non-compliant check...
       * if the value of both global are the same, go away silently..
       **/
      if( value == global->value ) return;
#ifdef FULL_ERROR_MESSAGES
      disp_error2( ERROR_GLOBALDUPLICATE_FULL "%s\n", name);
#else
      disp_error( ERROR_GLOBALDUPLICATE_VAL );
#endif
      return;
    }
    global = global->next_node;
  }

  global = (global_node *)elib_malloc( sizeof(global_node) );
  if( !global ) goto failed_mem;
  
  global->next_node = globals;
  globals = global;
  
fill_global:
/*  fprintf( stdout, "GLOBAL:[ %s ] value:[", name);
  debug_display_dword( value );
  fprintf( stdout, "]\n"); */
  globals->name = name;
  globals->value = value;
  globals->strength = strength;
  return;
  
failed_mem:  
#ifdef FULL_ERROR_MESSAGES
  disp_error( ERROR_FAILREGISTERSYMBOL_FULL "\n"  );
#else
  disp_error( ERROR_FAILREGISTERSYMBOL_VAL );
#endif
  return;
}



/******************************************************************************
 * Register a known symbol values/name combination as being local to a cell
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void register_local_symbol( byte *name, dword value, cell_node *cell ) {
  local_node *local;

  local = (local_node *)elib_malloc( sizeof(local_node) );
  if( !local ) {
    fprintf( stdout, "Unable to create local symbol, memory allocation failed.\n");
    errors++;
    return;
  }

  local->next_node = cell->locals;
  cell->locals = local;

  
/*  fprintf( stdout, "LOCAL:[ %s ] value:[", name);
  debug_display_dword( value );
  fprintf( stdout, "] in object:[ %s ]\n", cell->filename); */
  local->name = name;
  local->value = value;
}




/******************************************************************************
 * Test to see if the section was one already included and thus should be
 * excluded from the future sort
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte section_is_excluded( byte *name ) {

  if( strcmp( name, "core_preinit" ) == 0 ) return 1;
  if( strcmp( name, "core_postinit" ) == 0 ) return 1;
  if( strcmp( name, "cell_initonce" ) == 0 ) return 1;
  if( strcmp( name, "cell_init" ) == 0 ) return 1;
  if( strcmp( name, "drp" ) == 0 ) return 1;
  return 0;
}


/******************************************************************************
 * Sort the order in which the sections are going to be included in the final
 * binary output (core).
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void sort_sections(void) {
  dword offset_before=0;
  cell_node *cell=NULL;
  cell_hdr_node *cell_header=NULL, *last_cell_header=NULL;
  section_node *last_node=NULL, *section=NULL;
  Elf32_Shdr *e_sh=NULL;


  last_node = root_section;
  last_node = include_all_sections("core_preinit", 1, last_node);
  last_node = include_all_sections("cell_initonce", 1, last_node);
  last_node = include_all_sections("cell_init", 1, last_node);
  last_node = include_all_sections("core_postinit", 1, last_node);
  if( !last_node ) {
	  fprintf( stdout, "No \'cell_init\', \'cell_initonce\', \'core_postinit\' or \'core_preinit\' section found.\nRefusing to build core.\n");
	  errors++;
	  return;
  }
  offset_before = core_header.c_isize;
  last_node = gen_filler_section(4, last_node);
  last_node = include_all_sections("drp", 4, last_node);
  if( offset_before != core_header.c_isize )
	  core_header.c_drpt = offset_before;
 
  last_node = gen_filler_section(16, last_node);


  cell = root_cell;
  while( cell ) {
    cell_header = NULL;
    section = cell->sections;
    while( section ) {
      if( !section_is_excluded( section->sh_name ) ) {

        /* check if it's the first section to be included for this cell and
	 * if so, create the cell header
	 */
        if( !cell_header ) {

          /* Allocate memory for cell header ---- */
	  cell_header = (cell_hdr_node *)elib_malloc( sizeof(cell_hdr_node) );
	  if( !cell_header ) {
	    fprintf( stdout, "Unable to allocate memory to create cell header for object: %s\n", cell->filename );
	    errors++;
	    return;
	  }

	  /* Initialize default value for the cell header */
	  cell_header->parent_cell = cell;
	  cell_header->next_sorted_node = NULL;
	  cell_header->global_offset = core_header.c_isize + global_offset;
	  *(dword *)cell_header->signature = 0x4C65435F;
	  *(dword *)(cell_header->signature+4) = 0x5F44694C;
	  cell_header->size = sizeof(cell_hdr);
	  cell_header->next_cell = 0xFFFFFFFF;
	  cell_header->dlp_extern_abs = 0xFFFFFFFF;
	  cell_header->dlp_extern_rel = 0xFFFFFFFF;
	  cell_header->dlp_global = 0xFFFFFFFF;
	  cell_header->name = 0xFFFFFFFF;
	  
	  /* Add cell header size to the total size of the core binary */
	  core_header.c_isize += sizeof(cell_hdr);

	  /* Link the cell header with the last sorted section */
	  last_node->next_sorted_node = cell_header;
	  last_node = (section_node *)cell_header;

	  /* Modify core header or previous cell header */
	  if( !last_cell_header ) 
		  core_header.c_fcell = cell_header->global_offset;
	  else
		  last_cell_header->next_cell = cell_header->global_offset;
	  last_cell_header = cell_header;

	  /* Indicate in object header that we have some memory to free up
	   * after..
	   */
	  cell->cell_header = cell_header;
	}

	/* Link up section in the sorted section list */
	last_node->next_sorted_node = section;

/*	switch( get_section_type(section->sh_name) ) {
          default:*/
		/* section isn't one of the specially linked one of the
		 * cell header, so just link it up
		 */
		e_sh = section->sh_entry;
		last_node->next_sorted_node = section;
		section->global_offset = core_header.c_isize + global_offset;
		core_header.c_isize += e_sh->sh_size;
		cell_header->size += e_sh->sh_size;
		last_node = gen_filler_section(16, section);
		
	      /* alright, gotta go to bed, this part here is pretty simple,
	       * or should I say similar to what you did above in include_al..
	       *
	       * you basically have to get the global offset, fix it, then add
	       * the section size to the global size and also to the cell size.
	       *
	       * link yourself up with the last_node pointer and you are done.
	       * good night!
	       */
#ifdef FULL_DEBUG	      
	      fprintf( stdout,
			      "[s] including:[ %s ] of object:[ %s ]\n",
			      section->sh_name,
			      cell->filename );
#endif
      }
      section = section->next_node;
    }
    cell = cell->next_node;
  }
  
}


/******************************************************************************
 * Update the symtab information of all cells using newly sorted node data
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void update_symtab_all(void) {
  cell_node *cell;

  cell = root_cell;
  while( cell ) {
    update_symtab_cell( cell, 1 );
    cell = cell->next_node;
  }

  cell = root_cell;
  while( cell ) {
    update_symtab_cell( cell, 2 );
    cell = cell->next_node;
  }
}


/******************************************************************************
 * Update the symtab information of a specified cell using its newly acquired
 * sorted data (global_offset)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void update_symtab_cell(cell_node *cell, dword phase) {
  Elf32_Sym *sym, *sym_backup;
  dword i,i_backup;
  byte binding;

  sym = cell->symtab;
  if( !sym ) return;
  sym++;

  if( cell->symtab_size % sizeof(Elf32_Sym) != 0 ){
    fprintf( stdout, "Symbol table size isn't a multiple of a symbol's size in object: %s\n", cell->filename);
    errors++;
    return;
  }

  i = (cell->symtab_size / sizeof(Elf32_Sym)) - 1;
#ifdef FULL_DEBUG
  fprintf( stdout, "listing symbols for object: %s with %ld symbols\n", cell->filename, i); 
#endif
  
  sym_backup = sym;
  i_backup = i;

  switch( phase) {
    case( 1 ):
      /* recalculate symbols that are dependant on section's offsets */
      while(i--) {
#ifdef FULL_DEBUG
        fprintf( stdout, ">");
        debug_display_dword( sym->st_name);
        fprintf( stdout, " ");
        debug_display_dword( sym->st_value);
        fprintf( stdout, " ");
	debug_display_dword( sym->st_size);
	fprintf( stdout, " ");
	debug_display_byte( sym->st_info);
	fprintf( stdout, " ");
	debug_display_byte( sym->st_other);
	fprintf( stdout, " ");
	debug_display_word( sym->st_shndx );
	fprintf( stdout, "\n"); 
#endif

	if( sym->st_shndx != 0 && sym->st_shndx < SHN_ABSOLUTE)
	sym->st_value += get_section_global_offset(cell, sym->st_shndx);
	sym++;
      }

      i = i_backup;
      sym = sym_backup;
      
      /* searching/registering any global found */
      while(i--) {
#ifdef FULL_DEBUG
        fprintf( stdout, ">>");
        debug_display_dword( sym->st_name);
        fprintf( stdout, " ");
        debug_display_dword( sym->st_value);
        fprintf( stdout, " ");
        debug_display_dword( sym->st_size);
        fprintf( stdout, " ");
        debug_display_byte( sym->st_info);
        fprintf( stdout, " ");
        debug_display_byte( sym->st_other);
        fprintf( stdout, " ");
        debug_display_word( sym->st_shndx );
        fprintf( stdout, "\n"); 
#endif

        binding = get_symbol_binding( sym->st_info );
        if( (binding == STB_WEAK || binding == STB_GLOBAL) && sym->st_shndx != 0 )
          register_global_symbol( get_symbol_name(cell,sym->st_name), sym->st_value, binding );

        sym++;
      }
      break;
    case( 2):
      while( i-- ) {
        if( sym->st_shndx != SHN_UNDEF ) {
          sym++;
          continue;
	}

	if( get_global_value( get_symbol_name(cell, sym->st_name), &sym->st_value) == 1) {
	  fprintf( stdout, "Unknown symbol [ %s ] required by object [ %s ]\n", get_symbol_name(cell, sym->st_name), cell->filename);
	  sym++;
	  errors++;
	  continue;
	}

#ifdef FULL_DEBUG
	fprintf( stdout, "found the value of: %s\n", get_symbol_name(cell, sym->st_name) ); 
#endif

	sym->st_shndx = SHN_ABSOLUTE;
	sym->st_info = STT_NOTYPE + (STB_GLOBAL << 4);
	sym++;
      }
#ifdef FULL_DEBUG
      i = i_backup;
      sym = sym_backup;

      while( i--) {
        fprintf( stdout, ">");
        debug_display_dword( sym->st_name);
        fprintf( stdout, " ");
        debug_display_dword( sym->st_value);
        fprintf( stdout, " ");
	debug_display_dword( sym->st_size);
	fprintf( stdout, " ");
	debug_display_byte( sym->st_info);
	fprintf( stdout, " ");
	debug_display_byte( sym->st_other);
	fprintf( stdout, " ");
	debug_display_word( sym->st_shndx );
	fprintf( stdout, "\n");
	sym++;
      }
#endif
      break;
  }
}

/******************************************************************************
 * Write a block of data on the output file
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte write_block( size_t size, void *buffer ) {

  if( fwrite( buffer, size, 1, output_fp) != 1 ) return 1;
/*  fprintf( stdout, "[o] block of size [%ld] located at [%p] properly written\n", (dword)size, buffer); */
  return 0;
}

/******************************************************************************
 * Write the header of the core, it will also try to first open the output
 * file.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
byte write_core_header( void ) {

  output_fp = fopen( output_file, "wb" );
  if( !output_fp ) {
#ifdef FULL_ERROR_MESSAGES
    disp_error2( ERROR_CREATEOUTPUT_FULL "%s\n", output_file );
#else
    disp_error( ERROR_CREATEOUTPUT_VAL );
#endif
    return 0;
  }

  core_header.c_offset = global_offset;
  if( write_block( sizeof(core_hdr), &core_header ) ) {
    fclose( output_fp );
    return 1;
  }

  return 0;
}


/******************************************************************************
 * Read, relocate/fixup/recalculate and write all sorted sections.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void write_all_sections(void) {
  section_node *section=NULL;
  void *buffer=NULL;
  Elf32_Shdr *e_sh=NULL;
  cell_node *cell=NULL;

  section = root_section;
  while( section ) {
    if( !section->parent_cell ) {
      /* Just fell upon a .SPECiAL.FiLLER. section! */
      if( write_block( section->global_offset, (&section->shndx + 4) ) ) break;
	  //if( write_block( section->global_offset, ((void *)&section->shndx + 4) ) ) break;
      buffer = section;
      section = section->next_sorted_node;
      elib_free(buffer);
      continue;
    }
    if( (dword)(section->sh_name)==0x4C65435F && (dword)(section->relocation_table)==0x5F44694C ){
	    /* we have a cell header here ! treat it gently */
	    if( write_block( sizeof(cell_hdr), &section->sh_name) ) break;
    } else {
      e_sh = section->sh_entry;
      if( e_sh->sh_size == 0 )
	      printf("bypassing zero size section: %s in object: %s\n", section->sh_name, cell->filename);
      else {
        buffer = read_cell( section->parent_cell, e_sh->sh_offset, e_sh->sh_size );
        if( !buffer ) {
          cell = section->parent_cell;
          fprintf( stdout,
                "Error reading section [ %s ] of object [ %s ]\n",
	        section->sh_name,
	        cell->filename );
          errors++;
          break;
        }
      
        /* apply relocation entry of the section if such exist */
        if( section->relocation_table ) {
          cell = section->parent_cell;
    	  apply_relocation( buffer, section->relocation_table, cell, section );
        }
      
        if( write_block( e_sh->sh_size, buffer) ) {
          elib_free(buffer);
          break;
        }
      }
      elib_free(buffer);
    }
    section = section->next_sorted_node;
  }
}


/******************************************************************************
 * ************************************************************************** *
 *
 * DEBUG FUNCTIONS
 *
 * ************************************************************************** *
 *****************************************************************************/
#ifdef DEBUG_MEMORY

/******************************************************************************
 * display a byte on stdout in hexadecimal form (unsigned char)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void debug_display_byte( byte value ) {
  fprintf( stdout, "%c%c", hex_conversion[value / 16], hex_conversion[value % 16] );
}

/******************************************************************************
 * display a word on stdout in hexadecimal form (unsigned short)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void debug_display_word( word value ) {
  debug_display_byte( (byte)(value >> 8) );
  debug_display_byte( (byte)value );
}

/******************************************************************************
 * display a dword on stdout in hexadecimal form (unsigned long)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void debug_display_dword( dword value ) {
  debug_display_byte( (byte)(value >> 24) );
  debug_display_byte( (byte)(value >> 16) );
  debug_display_byte( (byte)(value >> 8) );
  debug_display_byte( (byte)value );
}

/******************************************************************************
 * Dumps all information of all cell, including their various sections, etc.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void debug_dump_cell_all(void) {
  cell_node *cell;

  cell = root_cell;
  while( cell ) {
    debug_dump_cell_node( cell );
    cell = cell->next_node;
  }
}

/******************************************************************************
 * Dumps all information related to a cell
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void debug_dump_cell_node( cell_node *cell) {
  fprintf( stdout, "CELL NODE:[ %s ] USING ID:[ ", cell->filename );
  debug_display_dword( (dword)cell );
  fprintf( stdout, " ]\nnextnode shtab    shstrtab strtab   symtab   shnum    sections e_dlpabs s_dlpabs e_dlprel s_dlprel g_dlp    s_g_dlp\n");
  debug_display_dword( (dword)cell->next_node );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->shtab );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->shstrtab );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->strtab );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->symtab );
  fprintf( stdout, " ");
  debug_display_dword( cell->shnum );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->sections );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->extern_dlp_abs );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->extern_dlp_abs_size );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->extern_dlp_rel );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->extern_dlp_rel_size );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->global_dlp );
  fprintf( stdout, " ");
  debug_display_dword( (dword)cell->global_dlp_size );
  fprintf( stdout, "\n" );
  debug_dump_sections_list( cell->sections );
}


/******************************************************************************
 * Dumps the information of all sections of a linked list, starting at the
 * specified one.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
void debug_dump_sections_list( section_node *section ) {

  while( section ) {
    fprintf( stdout, "SECTION NODE:[ %s ] USING ID:[ ", section->sh_name);
    debug_display_dword( (dword)section );
    fprintf( stdout, " ]\nnextnode nextsort reloctab parent_c sh_entry g_offset shndx\n");
    debug_display_dword( (dword)section->next_node );
    fprintf( stdout, " ");
    debug_display_dword( (dword)section->next_sorted_node );
    fprintf( stdout, " ");
    debug_display_dword( (dword)section->relocation_table );
    fprintf( stdout, " ");
    debug_display_dword( (dword)section->parent_cell );
    fprintf( stdout, " ");
    debug_display_dword( (dword)section->sh_entry );
    fprintf( stdout, " ");
    debug_display_dword( section->global_offset );
    fprintf( stdout, " ");
    debug_display_dword( section->shndx );
    fprintf( stdout, "\n");
    section = section->next_node;
  }
}

void debug_dump_sorted_sections_list( void ) {
  section_node *section;
  cell_node *cell;

  fprintf( stdout, "SORTED SECTIONS LIST\n");
  section = root_section;
  while( section ) {
    if( !section->parent_cell ) {
	    fprintf( stdout, "[-filler-] of size [");
	    debug_display_dword( section->global_offset );
	    fprintf( stdout, "]\n");
    }
    else {
      fprintf(stdout, "[");
      debug_display_dword(section->global_offset);
      if( (dword)(section->sh_name)==0x4C65435F && (dword)(section->relocation_table)==0x5F44694C ){
        cell = section->parent_cell;
        fprintf( stdout, "] cell header for object [ %s ]\n", cell->filename);
      } else {
        cell = section->parent_cell;
        fprintf( stdout, "] section [ %s ] of object: [ %s ]\n", section->sh_name, cell->filename);
      }
    } 
    section = section->next_sorted_node;
  }
}
#endif
