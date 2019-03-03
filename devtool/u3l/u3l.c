/* U3l >> Unununium Linker << -remastered-
 * Copyright (C) 2001-2002, Dave Poirier
 * Distributed under the modified BSD License
 *
 *
 * Note:
 *
 *   Many functions actually starts with u3l_, those are front-end to system
 *   functions which double-check to make sure we didn't screw anything up,
 *   like leaving a file open or not deallocating a memory block.  They also
 *   provides basic error messages so that we don't have to paste "Not enough
 *   memory" all over the linker.
 *
 * General Core Layout
 *
 *  o Core Header
 *  o .c_info redirectors (based on ID)
 *  o Packed cell sections
 *  o .c_init sections
 *  o Object wrapper code and data
 *  o Encoded init sequence
 *  o .c_onetime_init sections
 *  o .c_info data
 *
 * Encoded init sequence
 *
 *  It details what to do with the core, where the various cell sections begin
 *  and end, where to move them, which parts of memory should be zeroized,
 *  which offset to call in which sequence, etc.  This sequence is to be read
 *  and interpreted by the wrapper, IT IS NOT EXECUTABLE CODE.
 *
 *  The sequence is preceeded by a small header, indicating how many of each
 *  operation should be carried out.
 *
 *  o Number of blocks to move and register
 *  o Number of .c_onetime_init sections to initialize
 *  o Number of blocks to zeroize and register
 *  o Number of .c_init sections to initialize
 *
 *  Following this header, are all the operations to be carried out, by type
 *  of operation.  So you have:
 *
 *  o All the blocks to be moved
 *
 *  The format for the blocks to be moved is:
 *  
 *     <ID><SOURCE><DEST><SIZE>
 *
 *     where:
 *
 *        o 'ID' is a byte that indicate for which cell the work is being
 *          carried out.
 *        o 'SOURCE' is a dword memory pointer, that points somewhere in the
 *           core 'Packed cell sections' section to the data to source.
 *        o 'DEST' is a dword memory pointer to the location in memory where
 *           the data should go.
 *        o 'SIZE' is the number of DWORD to move.
 *
 *  o All the .c_onetime_init entry points
 *
 *  The format for the .c_onetime_init entry points is:
 *
 *     <ID><ENTRY POINT>
 *
 *     where:
 *
 *        o 'ID' is a byte that indicate for which cell the work is being
 *          carried out.
 *        o 'ENTRY POINT' is a dword memory pointer to some code located in
 *          the '.c_onetime_init sections' section of the core.
 *
 *  o All the blocks to zeroize
 *
 *  The format for them is:
 *
 *      <ID><DEST><SIZE>
 *
 *      where:
 *      
 *        o 'ID' is a byte that indicate for which cell the work is being
 *          carried out.
 *        o 'DEST' is a dword memory pointer to the location in memory where
 *           the data should go.
 *        o 'SIZE' is the number of DWORD to move.
 *
 *  o All the .c_init entry points
 *
 *      <ID><ENTRY POINT>
 *      
 *     where:
 *
 *        o 'ID' is a byte that indicate for which cell the work is being
 *          carried out.
 *        o 'ENTRY POINT' is a dword memory pointer to some code located in
 *          the '.c_onetime_init sections' section of the core.
 *
 * CELLS .c_onetime_init and .c_init
 *
 *   Each .c_onetime_init and .c_init are to be called by the wrapper.  A
 *   'RETN' instruction was encoded at the end of the init sequence to
 *   automatically return to the wrapper once the initialization is completed.
 *
 *   When returning to the caller, the 'Carry Flag' contains the initialization
 *   status, where CF=1 means error and CF=0 means success.  Further to that
 *   is the EAX register which in the event of an error contains the error
 *   code.
 *
 *   Both .c_onetime_init and .c_init sections can be deallocated from memory
 *   once they have been executed.
 *
 *  TODO:
 *  --exclude-vid=a,b...y,z
 *  --multiple-wrapper
 *  --strip-cell-info
 *  --vid-name-file=file
 *  support for new init
 *  --init-from-file=file
 *  support for ubf
 *  --ubf-only
 *  --elf-only
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <u3common.h>
#include <u3l.h>

//#define __DEBUG_STEPS__
#define __HIDE_CLEANOUTS__
//#define __VERBOSE_VALIDATING__
#define __VERBOSE_PREPARING__

const char	default_output[]	=DEFAULT_OUTPUT,
		default_vid_listing[]	=DEFAULT_VID_LISTING,
		default_core_map[]	=DEFAULT_CORE_MAP,
		*options[OPT_COUNT]	= {
		  	"abort-on-warning",
			"allow-hybrid-objects",
			"allow-redefinitions",
			"cell-alignment=",
			"dont-warn-misalignment",
			"exclude-dlp",
			"exclude-drp",
			"flat-binary",
			"generate-core-map!",
			"generate-vid-listing!",
			"global-offset=",
			"help",
			"ignore-warnings",
			"include-dlp",
			"include-drp",
			"init-alignment=",
			"no-core-map",
			"no-vid-listing",
			"prohibit-hybrid-objects",
			"prohibit-redefinitions",
			"section-alignment=",
			"section-spacing=",
			"stack-location=",
			"version",
			"warn-misalignment",
			"vid-name-file=",
			"quiet",
			"verbosity=" },
		*options_name[]		= {
		  	"abort on warning",
		  	"hybrid objects",
		  	"redefinitions",
		  	"misalignment warning",
		  	"dlp",
		  	"drp",
		  	"core map",
			"vid listing",
			"flat binary" },
		msg_help[]		="\
u3l [options] +ofile1 [+ofile2 [+ofile3...]] [output_filename]\n\
Where:\n\
\n\
[options] may be one of the following:\n\
--abort-on-warning                    Return error code and abort linking on\n\
                                      any warning\n\
--allow-hybrid-objects                Disable warnings when the same object\n\
                                      contains osw and cell informations\n\
--allow-redefinitions                 Disable warning of multiple globals\n\
--cell-alignment=00000000             Override default cell alignment of 64\n\
--dont-warn-misalignment              No warning will be generated if a\n\
                                      misalignement is detected\n\
--exclude-dlp                         Force Dynamic Link Point data exclusion\n\
--exclude-drp                         Force Dynamic Recalculation Points\n\
                                      exclusion\n\
--exclude-zero-size-sections          Exclude empty sections from output\n\
--flat-binary                         Generate a flat binary as output\n\
--generate-core-map[=file]            Tell the linker to generate a map of\n\
                                      all the data/code sections in the core.\n\
                                      By default, file is \"u3core.map\"\n\
--generate-vid-listing[=file]         Tell the linker to generate a list of\n\
                                      all the VOiD globals and their ID numbers\n\
                                      it detected. Default file is functions.txt\n\
--global-offset=00000000              Specifies the global offset to use\n\
--help                                Display this help\n\
--include-dlp                         Force inclusion of all Dynamic Linking\n\
                                      Points\n\
--include-drp                         Force the linker to include all Dynamic\n\
                                      Recalculation Points\n\
--include-zero-size-sections          Disable warning about zero size sections\n\
--init-alignment=00000000             Override default init alignment of 4\n\
--no-core-map                         Forces the linker to discard the core map\n\
--no-vid-listing                      Forces the linker to discard the vid\n\
                                      listing\n\
--prohibit-hybrid-objects             Do not accept hybrid objects\n\
--prohibit-redefinitions              Do not accept symbol redefinition\n\
                                      defined with the same value\n\
--quiet                               Reduces the verbosity level to minimum\n\
                                      same as --verbose=0\n\
--section-alignment=00000000          Override default section alignment of 64\n\
--section-spacing=00000000            Override default section spacing of 32\n\
--stack-location=00000000             Override default stack location of the\n\
                                      multiboot entry point.  Default is just\n\
                                      under the core loading address\n\
--verbose=level                       Select a verbosity level from 0 to 4\n\
--version                             Displays current linker version\n\
--vid-name-file=file                  Indicate a file containing a list of vid\n\
                                      and their associated name\n\
--warn-misalignment                   Generates warning if the linker detects\n\
                                      any misaligned section in the objects\n\
\n\
All values are given in hexadecimal, without leading 0x or trailing h\n\
\n\
+o<file>                              Indicate to add this object in the core.\n\
                                      At least one object must be specified\n\
\n\
[output_filename]                     Override the default core file name:\n\
                                      \"u3core.bin\"\n\n",
		*pre_defined_globals[PRE_DEFINED_GLOBALS]= {
		  "__CORE_HEADER__",
		  "__STACK_LOCATION__",
		  "__INFO_REDIRECTOR_TABLE__",
		  "__INIT_SEQUENCE_LOCATION__",
		  "__CORE_SIZE__",
		  "__CELL_COUNT__",
		  "__VID_COUNT__",
		  "__END_OF_EXPORT__",
		  "__SYMBOLS_LINKAGE__" };

u3l_VID_DEP	*pre_defined_globals_dep[PRE_DEFINED_GLOBALS]={
  			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
				      



FILE	*fp_output			=NULL,
  	*fp_core_map			=NULL;

char	*output_filename		=(char *)default_output,
  	*coremap_filename		=(char *)default_core_map,
	*vid_listing_filename		=(char *)default_vid_listing,
	*vid_name_file			=NULL,
	null_name[]			="";

unsigned int	linker_options		=0,
		global_offset		=DEFAULT_GLOBAL_OFFSET,
		section_alignment	=DEFAULT_SECTION_ALIGNMENT,
		section_spacing		=DEFAULT_SECTION_SPACING,
		init_alignment		=DEFAULT_INIT_ALIGNMENT,
		cell_alignment		=DEFAULT_CELL_ALIGNMENT,
		c_info_alignment	=DEFAULT_C_INFO_ALIGNMENT,
		stack_override		=DEFAULT_STACK_OVERRIDE,
		verbose_level		=DEFAULT_VERBOSE_LEVEL,

		errors			=0,
		warnings		=0,
		debug_step		=0,
		init_count		=0,
  		onetime_init_count	=0,
		cell_sections_count	=0,
		info_count		=0,
		bss_sections_count	=0,
		memory_used		=0,
		largest_memory_used	=0,
		total_vid_dep_count	=0,
		total_vid_prov_count	=0,
		total_vid_count		=0,
		total_cell_count	=0,
		total_rel_count		=0,
		core_offset_to_globals	=0,
		final_core_size		=0,
		exported_system_size	=0,
		largest_cell_section	=0,
		wrapper_entry_section	=0xFFFFFFFF,
		init_sequence_location	=0,
		end_of_export		=0,
		wrapper_bss_size	=0;

unsigned char	abort_linking		=0,
  		first_option		=1;

u3l_OBJ		*objects_to_link	=NULL,
  		*wrapper_object		=NULL;

u3l_SECT	*sections_to_link	=NULL,
		*head_init		=NULL,
		*head_onetime_init	=NULL,
		*head_info		=NULL,
		*head_cells		=NULL,
		*head_wrapper		=NULL;

u3l_VID		*registered_vids	=NULL;
u3l_named_VID	*registered_named_vids	=NULL;



//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void add_named_vid( unsigned int vid, char *name )
{
  u3l_named_VID *named_vid;
  int name_length;

  if( verbose_level >= VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering add_named_vid(%i,%s)\n",debug_step,vid,name);
    fflush(stdout);
  }
  
  // Make sure this particular VID is not already present
  named_vid = registered_named_vids;
  while( named_vid )
  {
    if( named_vid->id == vid )
    {
      display_warning("Declaration of named vid conflict with previous vid registration",name);
      return;
    }

    named_vid = named_vid->next;
  }

  // Get name length and make sure it's not bigger than 47 chars
  name_length = strlen(name);
  if(name_length > 47)
  {
    display_warning("Vid name length is above maximum limit of 47 characters",name);
    return;
  }

  // Allocate memory for the vid entry
  named_vid = (u3l_named_VID *)u3common_malloc(sizeof(u3l_named_VID),"named vid");
  if( !named_vid ) return;

  named_vid->id = vid;
  while( name_length-- )
    named_vid->name[name_length] = name[name_length];

  named_vid->next = registered_named_vids;
  registered_named_vids = named_vid;

  if( verbose_level >= VERBOSE_LEVEL_HIGH )
    printf("VID: %i will now be assigned name: %s\n",named_vid->id,named_vid->name);

  if( verbose_level >= VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving add_named_vid()\n",debug_step);
    fflush(stdout);
  }
  return;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void add_obj( char *name )
{
  static u3l_OBJ *obj=NULL;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering add_obj(%s)\n",debug_step,name);
    fflush(stdout);
  }

  if( !obj )
  {
    obj = (u3l_OBJ *)u3common_malloc(sizeof(u3l_OBJ),name);
    if( !obj ) return;
    objects_to_link = obj;
  }
  else
  {
    obj->next = (u3l_OBJ *)u3common_malloc(sizeof(u3l_OBJ),name);
    if( !obj->next ) return;

    obj = obj->next;
  }

  obj->next		= NULL;
  obj->filename		= name;
  obj->shstr		= NULL;
  obj->strtab		= NULL;
  obj->param_count	= 0;
  obj->params		= NULL;
  obj->param_array_offset = 0;
  obj->param_array_size	= 0;
  obj->id		= 0;
  obj->fp		= NULL;
  obj->shstrndx		= 0;
  obj->shnum		= 0;
  obj->shentsize	= 0;
  obj->shoff		= 0;
  obj->symtab_size	= 0;
  obj->relcount		= 0;
  obj->shtab		= NULL;
  obj->symtab		= NULL;
  obj->reltabs		= NULL;
  obj->c_info		= NULL;
  obj->bss		= NULL;
  

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving add_obj()\n", debug_step);
    fflush(stdout);
  }
}






//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





void add_vid_dep( unsigned int vid, Elf32_Sym *sym, u3l_OBJ *obj )
{
  u3l_VID *vid_entry;
  u3l_VID_DEP *vid_dep;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering add_vid_dep(%i,%p,%p)\n",debug_step,vid,sym,obj);
    fflush(stdout);
  }

  if( (vid & PRE_DEFINED_GLOBAL_MASK) )
  {
    vid &= ~PRE_DEFINED_GLOBAL_MASK;

    vid_dep = (u3l_VID_DEP *)u3common_malloc(sizeof(u3l_VID_DEP),"pre-defined vid user");
    if( vid_dep )
    {
      vid_dep->sym = sym;
      vid_dep->obj = obj;
      vid_dep->vid = NULL;
      vid_dep->next = pre_defined_globals_dep[vid];
      pre_defined_globals_dep[vid] = vid_dep;
    }
    else
    {
      errors++;
      abort_linking = 1;
    }
  }
  else
  {
    
    vid_entry = get_vid_entry(vid);
    if( vid_entry )
    {
      vid_dep = vid_entry->users;
      while( vid_dep )
      {
	if( vid_dep->obj == obj )
	{
	  display_error("Trying to register twice a symbol dependency in object",obj->filename);
	  break;
	}
	
	vid_dep = vid_dep->next;
      }
      
      if( !vid_dep )
      {
	total_vid_dep_count++;
	vid_dep = (u3l_VID_DEP *)u3common_malloc(sizeof(u3l_VID_DEP),"vid user");
	if( vid_dep )
	{      
	  vid_dep->sym = sym;
	  vid_dep->obj = obj;
	  vid_dep->vid = (void *)vid_entry;
	  vid_dep->next = vid_entry->users;
	  vid_entry->users = vid_dep;
	}
	else
	{
	  errors++;
	  abort_linking = 1;
	}
      }
    }
  }


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving add_vid_dep()\n", debug_step);
    fflush(stdout);
  }
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





void add_vid_prov( unsigned int vid, Elf32_Sym *sym, u3l_OBJ *obj )
{
  u3l_VID *vid_entry;
  u3l_VID_DEP *vid_prov;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering add_vid_prov(%i,%p,%p)\n", debug_step,vid,sym,obj);
    fflush(stdout);
  }


  vid_entry = get_vid_entry(vid);
  if( !vid_entry ) return;

  vid_prov = vid_entry->providers;
  while( vid_prov )
  {
    if( vid_prov->obj == obj )
    {
      display_error("Trying to register twice as vid provider for object",obj->filename);
      return;
    }

    vid_prov = vid_prov->next;
  }

  total_vid_prov_count++;
  vid_prov = (u3l_VID_DEP *)u3common_malloc(sizeof(u3l_VID_DEP),"vid provider");
  if( !vid_prov ) return;

  vid_prov->obj = obj;
  vid_prov->sym = sym;
  vid_prov->next = vid_entry->providers;
  vid_entry->prov_count++;
  vid_entry->providers = vid_prov;


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving add_vid_prov()\n", debug_step);
    fflush(stdout);
  }
}






//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void add_vid_rel( unsigned int vid, unsigned int offset, u3l_SECT *sect )
{
  u3l_VID *vid_entry;
  u3l_REL *rel;

  vid_entry = registered_vids;
  while( vid_entry )
  {
    if( vid_entry->id == vid )
    {
      rel = (u3l_REL *)u3common_malloc(sizeof(u3l_REL),"rel");
      if( rel )
      {
	rel->next = vid_entry->rels;
	rel->offset = offset;
	rel->sect = sect;
	vid_entry->user_count++;
	total_rel_count++;
	vid_entry->rels = rel;
      }
      else
	display_error("Unable to allocate memory for relocation entry",NULL);

      break;
    }

    vid_entry =  vid_entry->next;
  }

  return;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




u3l_SECT *alloc_u3l_SECT(
    unsigned int shndx,
    char *name,
    u3l_OBJ *obj,
    Elf32_Shdr *sh_entry )
{
  u3l_SECT *sect;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering alloc_u3l_SECT(%i,%s,%p,%p)\n",debug_step,shndx,name,obj,sh_entry);
    fflush(stdout);
  }


  sect = (u3l_SECT *)u3common_malloc(sizeof(u3l_SECT),name);
  if( sect )
  {
    sect->next			=NULL;
    sect->reltab		=NULL;
    sect->global_offset		=0;
    sect->offset_in_core	=0;
    sect->size_in_core		=0;
    sect->size_in_mem		=0;
    sect->entry_point		=0;
    sect->shndx			=shndx;
    sect->sh_name		=name;
    sect->sh_entry		=sh_entry;
    sect->obj			=obj;

    if( (obj != NULL)
	&& (obj->sections != NULL)
	&& (shndx != 0))
      obj->sections[shndx-1] = sect;
  }


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving alloc_u3l_SECT(), returning %p\n", debug_step, sect);
    fflush(stdout);
  }
  return sect;
}






//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





unsigned int analyze_relocs( void )
{
  u3l_OBJ *obj;
  u3l_SECT *sect;
  Elf32_Sym *sym;
  unsigned int i, rel_count;
  unsigned int vid;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering analyze_relocs()\n",debug_step);
    fflush(stdout);
  }

  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 6\t\t:\tAnalyzing relocations\n");

  obj = objects_to_link;
  while( obj )
  {
    if( verbose_level >= VERBOSE_LEVEL_HIGH )
      printf("\t%s\n",obj->filename);

    for(i=0;i<obj->shnum;i++)
    {
      sect = obj->sections[i];
      if( (sect != NULL)
	  && (sect->reltab != NULL) )
      {
	sect->reltab_data = (Elf32_Rel *)u3common_malloc(sect->reltab->sh_entry->sh_size, "reltab data");
	if( u3common_fread(
	      obj->fp,
	      sect->reltab->sh_entry->sh_offset,
	      sect->reltab->sh_entry->sh_size,
	      1,
	      sect->reltab_data ) == 1 )
	{
	  if( (strcmp(sect->sh_name,".c_info") != 0)
	      && (strcmp(sect->sh_name,".c_init") != 0)
	      && (strcmp(sect->sh_name,".c_onetime_init") != 0)
	      && (obj != wrapper_object ) )
	  {
	    rel_count = sect->reltab->sh_entry->sh_size / sizeof(Elf32_Rel);
	    while( rel_count-- )
	    {
	      sym = &obj->symtab[ELF32_R_SYM((sect->reltab_data[rel_count]).r_info)];
	      vid = 0xFFFFFFFF;
	      if( (sym->st_shndx == 0)
		  && ( sscanf(&obj->strtab[sym->st_name],"..@VOiD%i",&vid)
		    || sscanf(&obj->strtab[sym->st_name],"___VOiD%i",&vid))
		  && (vid != 0xFFFFFFFF))
	      {
		add_vid_rel(vid, sect->reltab_data[rel_count].r_offset, sect);
		obj->relcount++;
	      }
	    }
	  }
	}
	else
	{
	  u3common_free(sect->reltab_data);
	  sect->reltab_data = NULL;
	  errors++;
	  abort_linking = 1;
	}
      }
    }
    obj = obj->next;
  }

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving analyze_relocs(), returning %i\n",debug_step,abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





unsigned int apply_relocs( u3l_SECT *sect, unsigned char *buffer )
{
  u3l_OBJ *obj;
  Elf32_Sym *sym;
  void *tmp_ptr;
  unsigned int *loc;
  int rel_count;

  if( sect->reltab )
  {
    obj = sect->obj;
    if( verbose_level == VERBOSE_LEVEL_DEBUG )
      printf("applying relocations on section %s of object %s\n", sect->sh_name, obj->filename);

    rel_count = sect->reltab->sh_entry->sh_size / sizeof(Elf32_Rel);
    while( rel_count-- )
    {
      sym = &obj->symtab[ELF32_R_SYM(sect->reltab_data[rel_count].r_info)];
      tmp_ptr = &buffer[ sect->reltab_data[ rel_count ].r_offset ];
      loc = tmp_ptr;
      switch( ELF32_R_TYPE(sect->reltab_data[rel_count].r_info) )
      {
	case R_386_32:
	  *loc += sym->st_value;
	  break;
	case R_386_PC32:
	  *loc += sym->st_value - (sect->reltab_data[rel_count].r_offset + sect->global_offset);
	  break;
	default:
	  display_error("Unknown relocation type requested in object",obj->filename);
      }
    }
  }
  return abort_linking;
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void cmdline_check_option( char *option )
{
  unsigned int i = OPT_COUNT + 1, option_len=0;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering cmdline_check_option(%s)\n",debug_step,option);
    fflush(stdout);
  }

  while( (option[option_len] != 0) && (option[option_len] != '=') )
    option_len++;

  if( option[option_len] == 0 )
  {
    while( --i )
      if( (strncmp( option, options[i-1], option_len ) == 0)
	  && ((options[i-1][option_len] == 0)
	    || (options[i-1][option_len] == '!')) )
	break;
  }
  else
  {
    while( --i )
      if( (strncmp( option, options[i-1], option_len ) == 0)
	  && ((options[i-1][option_len] == '=')
	    || (options[i-1][option_len] == '!')) )
	break;
  }


  if( i )
  {
    if( option[option_len] == 0)
    {
      // all options that do not take parameters or can survive without one..
      switch( i )
      {
	case OPT_FLAT_BINARY:
	  linker_options |= OPT_MASK_FLAT_BINARY;
	  break;
	case OPT_ABORT_ON_WARNING:
	  linker_options |= OPT_MASK_ABORT_WARNING;
	  break;
	case OPT_ALLOW_HYBRID_OBJECTS:
	  linker_options |= OPT_MASK_HYBRID_OBJECTS;
	  break;
	case OPT_ALLOW_REDEFINITIONS:
	  linker_options |= OPT_MASK_REDEFINITION;
	  break;
	case OPT_DONT_WARN_MISALIGNMENT:
	  linker_options &= ~OPT_MASK_WARN_MISALIGNMENTS;
	  break;
	case OPT_EXCLUDE_DLP:
	  linker_options &= ~OPT_MASK_INCLUDE_DLP;
	  break;
	case OPT_EXCLUDE_DRP:
	  linker_options &= ~OPT_MASK_INCLUDE_DRP;
	  break;
	case OPT_GENERATE_CORE_MAP:
	  linker_options |= OPT_MASK_GEN_COREMAP;
	  break;
	case OPT_GENERATE_VID_LISTING:
	  linker_options |= OPT_MASK_GEN_VIDLISTING;
	  break;
	case OPT_IGNORE_WARNINGS:
	  linker_options &= ~OPT_MASK_ABORT_WARNING;
	  break;
	case OPT_INCLUDE_DLP:
	  linker_options |= OPT_MASK_INCLUDE_DLP;
	  break;
	case OPT_INCLUDE_DRP:
	  linker_options |= OPT_MASK_INCLUDE_DRP;
	  break;
	case OPT_NO_CORE_MAP:
	  linker_options &= ~OPT_MASK_GEN_COREMAP;
	  break;
	case OPT_NO_VID_LISTING:
	  linker_options &= ~OPT_MASK_GEN_VIDLISTING;
	  break;
	case OPT_PROHIBIT_HYBRID_OBJECTS:
	  linker_options &= ~OPT_MASK_HYBRID_OBJECTS;
	  break;
	case OPT_PROHIBIT_REDEFINITIONS:
	  linker_options &= ~OPT_MASK_REDEFINITION;
	  break;
	case OPT_WARN_MISALIGNMENT:
	  linker_options |= OPT_MASK_WARN_MISALIGNMENTS;
	  break;
	case OPT_HELP:
	  printf(msg_help);
	  abort_linking = 1;
	  // help also shows the version :)
	case OPT_VERSION:
	  printf("U3L " VERSION "\n" COPYRIGHTS "\n");
	  abort_linking = 1;
	  break;
	case OPT_QUIET:
	  verbose_level = VERBOSE_LEVEL_QUIET;
	  break;
	default:
	  fprintf(stderr,"INTERNAL ERROR: unknown option %i: %s\n",i,option);
	  abort_linking = 1;
	  errors++;
      }
    }
    else
    {
      // all options that absolutely requires a parameter.
      switch( i )
      {
	case OPT_GENERATE_CORE_MAP:
	  coremap_filename = &option[option_len+1];
	  linker_options |= OPT_MASK_GEN_COREMAP;
	  break;
	case OPT_GENERATE_VID_LISTING:
	  vid_listing_filename = &option[option_len+1];
	  linker_options |= OPT_MASK_GEN_VIDLISTING;
	  break;
	case OPT_GLOBAL_OFFSET:
	  sscanf(&option[option_len+1],"%x",&global_offset);
	  break;
	case OPT_STACK_LOCATION:
	  sscanf(&option[option_len+1],"%x",&stack_override);
	  break;
	case OPT_VID_NAME_FILE:
	  vid_name_file = &option[option_len+1];
	  break;
	case OPT_VERBOSITY:
	  sscanf(&option[option_len+1],"%i",&verbose_level);
	  break;
	case OPT_SECTION_SPACING:
	  sscanf(&option[option_len+1],"%x",&section_spacing);
	  break;
	case OPT_SECTION_ALIGNMENT:
	  sscanf(&option[option_len+1],"%x",&section_alignment);
	  break;
	case OPT_CELL_ALIGNMENT:
	  sscanf(&option[option_len+1],"%x",&cell_alignment);
	  break;
	default:
	  printf("options with parameters is not yet supported, sorry!\n");
      }
    }  
  }
  else
  {
    fprintf(stderr,"ERROR: Unknown option: --%s\n",option);
    abort_linking = 1;
    errors++;
  }


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving cmdline_check_option()\n",debug_step);
    fflush(stdout);
  }
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





unsigned int cmdline_parse( int argc, char **argv )
{
  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering cmdline_parse(%i,%p)\n",debug_step,argc,argv);
    fflush(stdout);
  }

  while( --argc )
  {
    argv++;

    if( (argv[0][0]=='-') && (argv[0][1]=='-') )
    {
      cmdline_check_option( &argv[0][2] );
      continue;
    }
    if( argv[0][0]=='+' )
    {
      add_obj( &argv[0][1] );
      continue;
    }

    output_filename = &argv[0][0];
  }

  if( (verbose_level >= VERBOSE_LEVEL_NORMAL) && !abort_linking)
  {
    printf("enabled options\t:\t");
    first_option = 1;
    if( (linker_options & OPT_MASK_ABORT_WARNING) )
      print_option((char *)options_name[OPT_NAME_ABORT_WARNING]);
    if( (linker_options & OPT_MASK_GEN_COREMAP) )
      print_option((char *)options_name[OPT_NAME_COREMAP]);
    if( (linker_options & OPT_MASK_INCLUDE_DLP) )
      print_option((char *)options_name[OPT_NAME_DLP]);
    if( (linker_options & OPT_MASK_INCLUDE_DRP) )
      print_option((char *)options_name[OPT_NAME_DRP]);
    if( (linker_options & OPT_MASK_FLAT_BINARY) )
      print_option((char *)options_name[OPT_NAME_FLAT_BINARY]);
    if( (linker_options & OPT_MASK_HYBRID_OBJECTS) )
      print_option((char *)options_name[OPT_NAME_HYBRID_OBJECTS]);
    if( (linker_options & OPT_MASK_WARN_MISALIGNMENTS) )
      print_option((char *)options_name[OPT_NAME_WARN_MISALIGNMENT]);
    if( (linker_options & OPT_MASK_REDEFINITION) )
      print_option((char *)options_name[OPT_NAME_REDEFINITION]);
    if( (linker_options & OPT_MASK_GEN_VIDLISTING) )
      print_option((char *)options_name[OPT_NAME_VIDLISTING]);
    if( first_option ) printf("none");

    printf("\ndisabled options:\t");
    first_option = 1;
    if( !(linker_options & OPT_MASK_ABORT_WARNING) )
      print_option((char *)options_name[OPT_NAME_ABORT_WARNING]);
    if( !(linker_options & OPT_MASK_GEN_COREMAP) )
      print_option((char *)options_name[OPT_NAME_COREMAP]);
    if( !(linker_options & OPT_MASK_INCLUDE_DLP) )
      print_option((char *)options_name[OPT_NAME_DLP]);
    if( !(linker_options & OPT_MASK_INCLUDE_DRP) )
      print_option((char *)options_name[OPT_NAME_DRP]);
    if( !(linker_options & OPT_MASK_FLAT_BINARY) )
      print_option((char *)options_name[OPT_NAME_FLAT_BINARY]);
    if( !(linker_options & OPT_MASK_HYBRID_OBJECTS) )
      print_option((char *)options_name[OPT_NAME_HYBRID_OBJECTS]);
    if( !(linker_options & OPT_MASK_WARN_MISALIGNMENTS) )
      print_option((char *)options_name[OPT_NAME_WARN_MISALIGNMENT]);
    if( !(linker_options & OPT_MASK_REDEFINITION) )
      print_option((char *)options_name[OPT_NAME_REDEFINITION]);
    if( !(linker_options & OPT_MASK_GEN_VIDLISTING) )
      print_option((char *)options_name[OPT_NAME_VIDLISTING]);
    if( first_option ) printf("none");
    printf("\n");

    if( (linker_options & OPT_MASK_GEN_COREMAP) )
      printf("core map name\t:\t%s\n", coremap_filename);
    
    if( (linker_options & OPT_MASK_GEN_VIDLISTING) )
      printf("vid listing\t:\t%s\n", vid_listing_filename);
    
    if( (linker_options & OPT_MASK_FLAT_BINARY) )
      printf("flat binary\t:\t%s\n", output_filename);
    else
      printf("u3core output\t:\t%s\n", output_filename);
    
    if( vid_name_file )
      printf("vid name file\t:\t%s\n", vid_name_file);
    else
      printf("vid name file\t:\tnone\n");

    printf("core offset\t:\t%08X\n", global_offset);
    printf("stack location\t:\t%08X\n", stack_override);
  }

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving cmdline_parse(), returning %i\n",debug_step,abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




unsigned int compute_offsets(void)
{
  unsigned int init_seq_size;
  unsigned int info_redirector_table_size, offset, core_offset;
  u3l_OBJ *obj=NULL;
  u3l_SECT *sect;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering compute_offsets()\n",debug_step);
    fflush(stdout);
  }

  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 7\t\t:\tComputing offsets\n");
  
  sect = wrapper_object->bss;
  while( sect )
  {
    bss_sections_count --;
    sect = sect->next;
  }

  /*
   *   o Compute some already known values:
   *       o initialization sequence size
   *       o info redirector table size
   *
   */
  init_seq_size =
    sizeof(core_init_hdr)
    + (cell_sections_count * sizeof(core_init_move))
    + (bss_sections_count * sizeof(core_init_zeroize))
    + ((onetime_init_count+init_count) * sizeof(core_init_call));

  info_redirector_table_size = info_count * 4;

  if( verbose_level == VERBOSE_LEVEL_HIGH )
  {
    printf("cell sections count: %i\nbss sections count: %i\nonetime init count: %i\ninit count: %i\n", cell_sections_count, bss_sections_count, onetime_init_count, init_count);
    printf("init sequence size including header: %i\n", init_seq_size);
  }

  /*
   *   o Starts the computation with the core, as defined by --global-offset
   *
   */
  offset = global_offset;
  core_offset = 0;

  if( verbose_level == VERBOSE_LEVEL_HIGH )
    printf("core header:\n\tin core:\t%08X\n\tin memory:\t%08X\n", core_offset, offset);

  /*
   *   o Compute the location of the info redirector table
   *
   */
  offset += sizeof(hdr_core);
  core_offset += sizeof(hdr_core);

  if( verbose_level == VERBOSE_LEVEL_HIGH )
    printf("info redirectors:\n\tin core:\t%08X\n\tin memory:\t%08X\n", core_offset, offset);

  offset += info_redirector_table_size;
  core_offset += info_redirector_table_size;


  /*
   *   o Computing the location of the sections IN CORE, the location in memory
   *     will be done in a later phase.
   *
   */
  if( verbose_level == VERBOSE_LEVEL_HIGH )
    printf("cells data section:\n\tin core:\t%08X\n\tin memory:\t%08X\n\t-detailed-\n", core_offset, offset);;

  sect = head_cells;
  while( sect )
  {
    sect->offset_in_core = core_offset;
    sect->size_in_core = (sect->sh_entry->sh_size + 3) & ~3;
    sect->size_in_mem = (sect->size_in_core + section_alignment -1) & ~(section_alignment-1);
   
    offset += sect->size_in_core;
    core_offset += sect->size_in_core;

    sect = sect->next;
  }


  /*
   *   o Compute the location within the core were each .c_init will be
   *     inserted.
   *
   */
  sect = head_init;
  if( verbose_level == VERBOSE_LEVEL_HIGH )
    printf("init data:\n\tin core:\t%08X\n\tin memory:\t%08X\n\t-detailed-\n",
	core_offset, offset );
  while( sect )
  {
    obj = sect->obj;
    sect->global_offset = offset;
    sect->offset_in_core = core_offset;
    sect->size_in_core = sect->sh_entry->sh_size;
    sect->size_in_mem = sect->size_in_core;

    offset += sect->size_in_core;
    core_offset += sect->size_in_core;

    if( verbose_level == VERBOSE_LEVEL_HIGH )
    {
      printf("\t.c_init of %s:\n",obj->filename);
      printf("\t\tin core:\t%08X for\t%08X\n\t\tin memory:\t%08X for\t%08X\n",
	  sect->offset_in_core,
	  sect->size_in_core,
	  sect->global_offset,
	  sect->size_in_mem );
    }

    sect = sect->next;
  }


  /*
   *  o Compute the location of the various wrapper sections
   *
   */
  core_offset = (core_offset + 3) & ~3;
  offset = (offset + 3) & ~3;

  if( verbose_level == VERBOSE_LEVEL_HIGH )
    printf("wrapper:\n\tin core:\t%08X\n\tin memory:\t%08X\n\t-detailed-\n",
	core_offset, offset );
  
  sect = head_wrapper;
  while( sect )
  {
    obj = sect->obj;
    sect->global_offset = offset;
    sect->offset_in_core = core_offset;
    sect->size_in_core = (sect->sh_entry->sh_size +3) & ~3;
    sect->size_in_mem = sect->size_in_core;

    if( verbose_level == VERBOSE_LEVEL_HIGH )
      printf("\t%s:\n\t\tin core:\t%08X for\t%08X\n\t\tin memory:\t%08X for\t%08X\n",
	  sect->sh_name,
	  sect->offset_in_core,
	  sect->size_in_core,
	  sect->global_offset,
	  sect->size_in_mem );
  
    offset += sect->size_in_core;
    core_offset += sect->size_in_core;

    sect = sect->next;
  }

  /*
   *   o Register the location of where the init sequence will be located in
   *     the core.
   *
   */
  if( verbose_level == VERBOSE_LEVEL_HIGH )
    printf("init sequence:\n\tin core:\t%08X for\t%08X\n\tin memory:\t%08X for\t%08X\n",
      core_offset,
      init_seq_size,
      offset,
      init_seq_size );
  init_sequence_location = offset;

  offset += init_seq_size;
  core_offset += init_seq_size;

  /*
   *
   *    o Compute the location of the .c_onetime_init sections within the core
   *
   */
  sect = head_onetime_init;
  if( verbose_level == VERBOSE_LEVEL_HIGH )
    printf(".c_onetime_init sections:\n\tin core:\t%08X\n\tin memory:\t%08X\n\t-detailed-\n",
      core_offset, offset );

  while( sect )
  {
    obj = sect->obj;
    sect->size_in_core = sect->sh_entry->sh_size;
    sect->size_in_mem = sect->size_in_core;
    sect->global_offset = offset;
    sect->offset_in_core = core_offset;

    offset += sect->size_in_core;
    core_offset += sect->size_in_core;

    if( verbose_level == VERBOSE_LEVEL_HIGH )
      printf("\t.c_onetime_init of %s:\n\t\tin core:\t%08X for\t%08X\n\t\tin memory:\t%08X for\t%08X\n",
	  obj->filename,
	  sect->offset_in_core,
	  sect->size_in_core,
	  sect->global_offset,
	  sect->size_in_mem );
    
    sect = sect->next;
  }


  /*
   *   o Compute the location of the .c_info for each cell
   *
   */
  core_offset = (core_offset + 3) & ~3;
  offset = (offset + 3) & ~3;
  if( verbose_level == VERBOSE_LEVEL_HIGH )  
    printf(".c_info data:\n\tin core:\t%08X\n\tin memory:\t%08X\n",
      core_offset, offset );
  obj = objects_to_link;
  while( obj )
  {
    if( obj != wrapper_object )
    {
      obj->c_info->offset_in_core = core_offset;
      obj->c_info->global_offset = offset;
      if( obj->c_info->shndx == 0 )
	obj->c_info->size_in_core = sizeof(u3l_INFO);
      else
      {
	obj->c_info->size_in_core = (obj->c_info->sh_entry->sh_size + 3) & ~3;
      }
      obj->c_info->size_in_mem = obj->c_info->size_in_core;
      core_offset += obj->c_info->size_in_core;
      offset += obj->c_info->size_in_core;

      if( verbose_level == VERBOSE_LEVEL_HIGH )
	printf("\t%s\n\t\tin core:\t%08X for\t%08X\n\t\tin memory:\t%08X for\t%08X\n",obj->filename,obj->c_info->offset_in_core,obj->c_info->size_in_core,obj->c_info->global_offset,obj->c_info->size_in_mem);
    }

    obj = obj->next;
  }


  /*
   *   o Compute the Total size taken by the VOiD globals
   *
   */
  core_offset_to_globals = core_offset;
  final_core_size = core_offset + (total_rel_count * 4) + (total_vid_prov_count * 4) + (total_vid_count * sizeof(core_vid)) + 4;
  if( verbose_level >= VERBOSE_LEVEL_HIGH )
    printf("VOiD globals:\n\tin core:\t%08X\n\tin memory:\t%08X\n",
	core_offset_to_globals, offset );

  /* 
   *
   * compute total .bss size required by the wrapper 
   *
   * */
  sect = wrapper_object->bss;
  while( sect )
  {
    sect->global_offset = offset;
    offset += sect->sh_entry->sh_size;
    wrapper_bss_size += sect->sh_entry->sh_size;
    sect = sect->next;
  }

  
  /*
   *   o Computing the cells exported sections final location in memory
   *
   */
  offset = ((final_core_size + global_offset + section_alignment - 1) & ~(section_alignment - 1)) + section_spacing;
  sect = head_cells;
  while( sect )
  {
    sect->global_offset = offset;
    offset += sect->size_in_mem + section_spacing;
    if( verbose_level >= VERBOSE_LEVEL_HIGH )
      printf("+ %s (%s)\n\t\tcore\t: %08X\tsize\t: %08X\n\t\tmemory\t: %08X\tsize\t: %08X\n\t\texported: %08X\tsize\t: %08X\n",
	  sect->sh_name,
	  sect->obj->filename,
	  sect->offset_in_core,
	  sect->size_in_core,
	  sect->offset_in_core + global_offset,
	  sect->size_in_core,
	  sect->global_offset,
	  sect->size_in_mem);

    exported_system_size += sect->size_in_mem;

    if( sect->next == NULL || sect->next->obj != sect->obj ) {

      u3l_SECT *bss=sect->obj->bss;
      while( bss )
      {
	bss->global_offset = offset;
	bss->size_in_mem = (bss->sh_entry->sh_size + section_alignment -1) & ~(section_alignment - 1);
	offset += bss->size_in_mem + section_spacing;
	if( verbose_level >= VERBOSE_LEVEL_HIGH )
	  printf("+ .bss (%s)\n\t\tcore:\t: %08X\tsize\t: %08X\n\t\tmemory\t: %08X\tsize\t: %08X\n\t\texported: %08X\tsize\t: %08X\n",
	      sect->obj->filename,
	      0,
	      0,
	      0,
	      0,
	      bss->global_offset,
	      bss->size_in_mem);
	bss = bss->next;
      }
    }
    sect = sect->next;
  }


  end_of_export = offset;

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving compute_offsets(), returning %i\n",debug_step,abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void display_error( char *text, char *filename )
{
  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering display_error(%s,%s)\n",debug_step,text,filename);
  }
  
  fflush(stdout);

  if( filename )
    fprintf( stderr, "ERROR: %s: %s\n", filename, text );
  else
    fprintf( stderr, "ERROR: %s\n", text);

  fflush(stderr);

  errors++;
  abort_linking = 1;

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving display_error()\n", debug_step);
    fflush(stdout);
  }
  return;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





void display_summary(void)
{

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering display_summary()\n", debug_step);
    fflush(stdout);
  }

  printf("cell wrapper\t:\t%s\n",wrapper_object->filename);
  printf("cell count\t:\t%9i\n",total_cell_count);
  printf("VOiD globals\t:\t%9i\n",total_vid_count);
  printf("relocations\t:\t%9i\n",total_rel_count);
  printf("core size\t:\t%9i bytes\n",final_core_size);
  printf("exported system\t:\t%9i bytes\n",exported_system_size);
  printf("export gain\t:\t%9i bytes\n",final_core_size-exported_system_size);
  printf("errors\t\t:\t%9i\n",errors);
  printf("warnings\t:\t%9i\n",warnings);
  printf("final result\t:\t  Success\n");
  printf("linker memory\t:\t%9i bytes\n",u3common_get_peak_memory_usage());

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving display_summary()\n",debug_step);
    fflush(stdout);
  }
}






//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void display_warning( char *text, char *filename )
{

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering display_warning(%s)\n",debug_step, text);
  }

  fflush(stdout);

  if( filename )
      fprintf( stderr, "warning: %s: %s\n", filename, text);
  else
      fprintf( stderr, "warning: %s\n", text );

  fflush(stderr);

  warnings++;

  if( (linker_options & OPT_MASK_ABORT_WARNING) )
    abort_linking = 1;


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving display_warning()\n",debug_step);
    fflush(stdout);
  }
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void flush_sections()
{

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering flush_sections()\n", debug_step);
    fflush(stdout);
  }
  
  flush_linked_sections( head_init );
  flush_linked_sections( head_onetime_init );
  flush_linked_sections( head_cells );
  flush_linked_sections( head_info );
  flush_linked_sections( head_wrapper );
  flush_linked_sections( sections_to_link );

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving flush_sections()\n", debug_step);
    fflush(stdout);
  }
}

void flush_linked_sections(u3l_SECT *sect)
{
  u3l_SECT *next_sect;
  u3l_OBJ *obj=NULL;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering flush_linked_sections(%p)\n",debug_step, sect);
    fflush(stdout);
  }


  while( sect )
  {
    obj = sect->obj;
#ifndef __HIDE_CLEANOUTS__
    printf("flushing section: %s of object: %s\n", sect->sh_name, obj->filename);
    fflush(stdout);
#endif

    if( obj->c_info == sect )
      obj->c_info = NULL;

    obj->sections[sect->shndx-1] = NULL;
    if( sect->reltab )
    {
#ifndef __HIDE_CLEANOUTS__
      printf("\tand associated reltab.\n");
      fflush(stdout);
#endif
      obj->sections[sect->reltab->shndx-1] = NULL;
      u3common_free( sect->reltab );
    }
    next_sect = sect->next;
    u3common_free( sect );
    sect = next_sect;
  }

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving flush_linked_sections()\n", debug_step);
    fflush(stdout);
  }
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -






unsigned int generate_core(void)
{
  u3l_OBJ *obj;
  u3l_SECT *sect;
  hdr_core hdr = {
    "CoRE",				/* signature */
    2,					/* revision */
    0,					/* reserved */
    total_cell_count,			/* cell_count */
    end_of_export,			/* last memory address used */
    final_core_size,			/* core_size */
    0,					/* core_checksum */
    0x1badb002,				/* mboot_magic */
    0x10000,				/* mboot_flags */
    -(0x10000+0x1badb002),		/* mboot_checksum */
    					/* mboot_header_addr */
    global_offset + ((char *)&hdr.mboot_magic - (char *)&hdr),
    global_offset,
    global_offset + final_core_size,	/* mboot_load_end_addr */
    global_offset+final_core_size+wrapper_bss_size,/* mboot_bss_end_addr */
    					/* mboot_entry */
    global_offset + ((char *)&hdr.mov_esp - (char *)&hdr),
    0,
    0xBC,
    stack_override,
    {0xFF,0x25},
    global_offset + ((char *)&hdr.osw_entry - (char *)&hdr),
  };
  u3_FILE *core_fp = u3common_fopen( output_filename, "w+b" );
  u3_FILE *coremap_fp = NULL;
  unsigned int exit=0, step=0, offset=0;
  unsigned char *buffer =
    (unsigned char *)u3common_malloc((largest_cell_section+section_alignment-1)& ~(section_alignment -1),"cell sections buffer");
  core_init_hdr init_hdr;
  u3l_INFO dummy_c_info = {
    0,
    0,
    0,
    0,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFFFFF };
  u3l_VID 	*vid	= registered_vids;
  u3l_VID_DEP	*vid_dep= NULL;
  u3l_REL	*rel	= NULL;
  core_vid	cvid;

  if( (linker_options & OPT_MASK_GEN_COREMAP) )
  {
    coremap_fp = u3common_fopen( coremap_filename, "w" );
    if( !coremap_fp )
      display_warning("coremap could not be created", coremap_filename );
    else
      fprintf(coremap_fp->fp,"location size\t  description\n-------- -------- -----------\n");
  }

  if( wrapper_entry_section == 0xFFFFFFFF )
    hdr.osw_entry = head_wrapper->global_offset + head_wrapper->entry_point;
  else
    hdr.osw_entry = wrapper_object->sections[wrapper_entry_section]->global_offset + wrapper_object->sections[wrapper_entry_section]->entry_point;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering generate_core()\n",debug_step);
    fflush(stdout);
  }
  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 9\t\t:\tGenerating core\n");

  if( !core_fp )
    display_error("Failed to open core",output_filename);
  if( !buffer )
    display_error("Buffer allocation failed",NULL);
  
  while( (abort_linking == 0) && (exit == 0) )
  {
    switch( step )
    {
      case 0:
	/* write core header */
	if( coremap_fp )
	  fprintf(coremap_fp->fp,"%08X %08X core header\n", offset, (unsigned int)(sizeof(hdr_core)));

	if( u3common_fwrite(
	      core_fp,
	      0,
	      sizeof(hdr_core),
	      1,
	      &hdr ) != 1 )
	  display_error("Failed to write core header",NULL);
	offset += sizeof(hdr_core);
	break;
      case 1:
	/* write info redirector table */

	obj = objects_to_link;
	while( obj )
	{
	  if( obj != wrapper_object )
	  {
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"%08X 00000004 .c_info redirector of: %s\n",offset,obj->filename);

	    if( u3common_fwrite(
		  core_fp,
		  offset,
		  4,
		  1,
		  &obj->c_info->global_offset ) != 1 )
	      display_error("Failed to write part of the .c_info redirector table",NULL);
	    offset += 4;
	  }
	  obj = obj->next;
	}
	break;
      case 2:
	/* cells packed data sections */

	sect = head_cells;
	while( sect )
	{
	  obj = sect->obj;
	  if( coremap_fp )
	    fprintf(coremap_fp->fp,"%08X %08X cell: %s section: %s\n", offset, sect->size_in_core, obj->filename, sect->sh_name);

	  if( offset != sect->offset_in_core )
	  {
	    fflush(stdout);
	    fprintf(stderr,"INTERNAL ERROR: core offset alignments unmatching\noffset: %08X\t sect->offset_in_core: %08X\nsection: %s\n", offset, sect->offset_in_core, sect->sh_name);
	    fflush(stderr);
	    errors++;
	    abort_linking = 1;
	  }

	  if( (u3common_fread(
		obj->fp,
		sect->sh_entry->sh_offset,
		sect->sh_entry->sh_size,
		1,
		buffer ) != 1)
	      || (apply_relocs( sect, buffer ) != 0)
	      || (u3common_fwrite(
		  core_fp,
		  sect->offset_in_core,
		  sect->size_in_core,
		  1,
		  buffer ) != 1) )
	    display_error("Failed to process a section of object",obj->filename);
	  offset += sect->size_in_core;
	  sect = sect->next;
	}
	break;
      case 3:
	/* writing all the .c_init */

	sect = head_init;
	while( sect )
	{
	  obj = sect->obj;
	  if( coremap_fp )
	    fprintf(coremap_fp->fp,"%08X %08X .c_init: %s\n", offset, sect->size_in_core, obj->filename);

	  if( offset != sect->offset_in_core )
	  {
	    fflush(stdout);
	    fprintf(stderr,"INTERNAL ERROR: core offset alignments unmatching\noffset: %08X\t sect->offset_in_core: %08X\nsection: %s\n", offset, sect->offset_in_core, sect->sh_name);
	    fflush(stderr);
	    errors++;
	    abort_linking = 1;
	  }

	  if( (u3common_fread(
		  obj->fp,
		  sect->sh_entry->sh_offset,
		  sect->sh_entry->sh_size,
		  1,
		  buffer ) != 1)
	      || (apply_relocs( sect, buffer ) != 0 )
	      || (u3common_fwrite(
		  core_fp,
		  sect->offset_in_core,
		  sect->size_in_core,
		  1,
		  buffer ) != 1) )
	    display_error("Failed to process some parts of object",obj->filename);
	  offset += sect->size_in_core;
	  sect = sect->next;
	}
	break;
      case 4:
	/* writing wrapper sections */
	offset = (offset + 3) & ~3;

	sect = head_wrapper;
	while( sect )
	{
	  obj = sect->obj;
	  if( coremap_fp )
	    fprintf(coremap_fp->fp,"%08X %08X wrapper: %s section: %s\n",offset, sect->size_in_core, obj->filename, sect->sh_name);

	  if( offset != sect->offset_in_core )
	  {
	    fflush(stdout);
	    fprintf(stderr,"INTERNAL ERROR: core offset alignments unmatching\noffset: %08X\t sect->offset_in_core: %08X\nsection: %s\n", offset, sect->offset_in_core, sect->sh_name);
	    fflush(stderr);
	    errors++;
	    abort_linking = 1;
	  }

	  if( (u3common_fread(
		  obj->fp,
		  sect->sh_entry->sh_offset,
		  sect->sh_entry->sh_size,
		  1,
		  buffer ) != 1 )
	      || (apply_relocs( sect, buffer ) != 0)
	      || (u3common_fwrite(
		  core_fp,
		  sect->offset_in_core,
		  sect->size_in_core,
		  1,
		  buffer) != 1) )
	    display_error("Failed processing some part of object", obj->filename);
	  offset += sect->size_in_core;
	  sect = sect->next;
	}
	break;

      case 5:
	/* writing init sequence
	 *  o All the blocks to move
	 *  o All the calls to the .c_onetime_init
	 *  o All the zeroize
	 *  o All the .c_init and run
	 */

	if( coremap_fp )
	  fprintf(coremap_fp->fp,"%08X %08X init sequence header\n", offset, (unsigned int)sizeof(core_init_hdr));

	init_hdr.move_count = cell_sections_count;
	init_hdr.call_count_phase1 = onetime_init_count;
	init_hdr.zeroize_count = bss_sections_count;
	init_hdr.call_count_phase2 = init_count;

	if( u3common_fwrite(
	      core_fp,
	      offset,
	      sizeof(core_init_hdr),
	      1,
	      &init_hdr ) == 1 )
	{
	  core_init_move move_info;
	  core_init_call call_info;
	  core_init_zeroize zeroize_info;
	  
	  offset += sizeof(core_init_hdr);

	  /* moves */
	  sect = head_cells;
	  while( sect )
	  {
	    obj = sect->obj;
	    move_info.id = (unsigned short)(obj->id);
	    move_info.source = sect->offset_in_core + global_offset;
	    move_info.destination = sect->global_offset;
	    move_info.size = sect->size_in_mem / 4;
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"%08X %08X init sequence 'move': %08X->%08X expanding from %08X to %08X for cell %i\n", offset, (unsigned int)sizeof(core_init_move), move_info.source, move_info.destination, sect->size_in_core, sect->size_in_mem,obj->id);
	    
	    if( u3common_fwrite(
		    core_fp,
		    offset,
		    sizeof(core_init_move),
		    1,
		    &move_info ) != 1 )
	      display_error("Failed to write a part of the initialization sequence",NULL);
	    offset += sizeof(core_init_move);
	    sect = sect->next;
	  }

	  /* calls phase 1 */
	  sect = head_onetime_init;
	  while( sect )
	  {
	    obj = sect->obj;
	    call_info.id = (unsigned short)(obj->id);
	    call_info.entry_point = sect->entry_point + sect->global_offset;
	    call_info.parameter_count = 0;
	    call_info.parameter_array = 0;
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"%08X %08X init sequence 'call phase 1': %08X for cell %i\n", offset, (unsigned int)sizeof(core_init_call), call_info.entry_point, obj->id);
	    
	    if( u3common_fwrite(
		  core_fp,
		  offset,
		  sizeof(core_init_call),
		  1,
		  &call_info ) != 1 )
	      display_error("Failed to write a part of the initialization sequence",NULL);
	    offset += sizeof(core_init_call);
	    sect = sect->next;
	  }

	  /* zeroizes */
	  obj = objects_to_link;
	  while( obj )
	  {
	    sect = obj->bss;
	    while( (obj != wrapper_object ) && (sect != NULL) )
	    {
	      zeroize_info.id = (unsigned short)(obj->id);
	      zeroize_info.destination = sect->global_offset;
	      zeroize_info.size = sect->size_in_mem / 4;
	      if( coremap_fp )
		fprintf(coremap_fp->fp,"%08X %08X init sequence 'zeroize': %08X %08X long for cell %i\n", offset, (unsigned int)sizeof(core_init_zeroize), zeroize_info.destination, sect->size_in_mem, obj->id);
	      
	      if( u3common_fwrite(
		    core_fp,
		    offset,
		    sizeof( core_init_zeroize ),
		    1,
		    &zeroize_info) != 1)
		display_error("Failed to write a part of the initialization sequence",NULL);
	      offset += sizeof( core_init_zeroize );
	      sect = sect->next;
	    }
	    obj = obj->next;
	  }

	  /* calls phase 2 */
	  sect = head_init;
	  while( sect )
	  {
	    obj = sect->obj;
	    call_info.id = (unsigned short)obj->id;
	    call_info.entry_point = sect->entry_point + sect->global_offset;
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"%08X %08X init sequence 'call phase 2': %08X part of cell %i\n", offset, (unsigned int)sizeof(core_init_call), call_info.entry_point, obj->id);

	    if( u3common_fwrite(
		  core_fp,
		  offset,
		  sizeof(call_info),
		  1,
		  &call_info ) != 1 )
	      display_error("Failed to write a part of the initialization sequence",NULL);
	      
	    offset += sizeof(call_info);
	    sect = sect->next;
	  }
	}
	break;
      case 6:
	/* .c_onetime_init sections */
	sect = head_onetime_init;
	while( sect )
	{
	  obj = sect->obj;
	  if( coremap_fp )
	    fprintf(coremap_fp->fp,"%08X %08X .c_onetime_init: %s\n", offset, sect->size_in_core, obj->filename);

	  if( offset != sect->offset_in_core )
	  {
	    fflush(stdout);
	    fprintf(stderr,"INTERNAL ERROR: core offset alignments unmatching\nX offset: %08X\t sect->offset_in_core: %08X\nX section: %s\n", offset, sect->offset_in_core, sect->sh_name);
	    fflush(stderr);
	    errors++;
	    abort_linking = 1;
	  }

	  if( (u3common_fread(
		  obj->fp,
		  sect->sh_entry->sh_offset,
		  sect->sh_entry->sh_size,
		  1,
		  buffer ) != 1 )
	      || (apply_relocs( sect, buffer ) != 0)
	      || (u3common_fwrite(
		  core_fp,
		  sect->offset_in_core,
		  sect->size_in_core,
		  1,
		  buffer) != 1) )
	    display_error("Failed processing some part of object", obj->filename);
	  offset += sect->size_in_core;
	  sect = sect->next;
	}
	break;
      case 7:
	/* .c_info data .. we are almost done :)) */
	offset = (offset + 3) & ~3;
	
	obj = objects_to_link;
	while( obj )
	{
	  if( obj == wrapper_object )
	  {
	    obj = obj->next;
	    continue;
	  }

	  if( obj->c_info->shndx == 0 )
	  {
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"%08X %08X .c_info: %s\n",offset, (unsigned int)sizeof(u3l_INFO),obj->filename );
	    /* there's no .c_info, we give the dummy one */
	    if( u3common_fwrite(
		  core_fp,
		  obj->c_info->offset_in_core,
		  sizeof(u3l_INFO),
		  1,
		  &dummy_c_info ) != 1)
	      display_error("Failed to write .c_info of object",obj->filename);
	    offset += sizeof(u3l_INFO);
	  }
	  else
	  {
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"%08X %08X .c_info: %s\n",offset, obj->c_info->size_in_core,obj->filename );
	    if( (u3common_fread(
		      obj->fp,
		      obj->c_info->sh_entry->sh_offset,
		      obj->c_info->sh_entry->sh_size,
		      1,
		      buffer ) != 1)
		  || (apply_relocs( obj->c_info, buffer ) != 0)
		  || (u3common_fwrite(
		      core_fp,
		      obj->c_info->offset_in_core,
		      obj->c_info->size_in_core,
		      1,
		      buffer ) != 1) )
	      display_error("Failed to write .c_info of object",obj->filename);
	    offset += obj->c_info->size_in_core;
	  }

	  obj = obj->next;
	}
	break;
      case 8:
	/* VOiD Symbols and their dependencies */
	offset 		= (offset + 3) & ~3;
	if( u3common_fwrite(
	      core_fp,
	      offset,
	      4,
	      1,
	      &total_vid_count ) != 1)
	{
	  display_error("Failed to write part of the vid table.",NULL);
	  break;
	}
	offset += 4;
	
	while( vid )
	{
	  cvid.vid = vid->id;
	  cvid.users_count = vid->user_count;
	  cvid.providers_count = vid->prov_count;
	  if( coremap_fp )
	    fprintf(coremap_fp->fp,"%08X %08X vid: %i\tuser count: %i\tprovider count %i\n",offset, (unsigned int)sizeof(core_vid)+(vid->user_count*4)+(vid->prov_count*4),vid->id, vid->user_count, vid->prov_count );
	  if( u3common_fwrite(
		core_fp,
		offset,
		sizeof(core_vid),
		1,
		&cvid ) != 1 )
	  {
	    display_error("Failed to write part of the vid table.",NULL);
	    break;
	  }
	  offset += sizeof(core_vid);

	  vid_dep = vid->providers;
	  while( vid_dep )
	  {
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"\tprovider: %08X\n", vid_dep->sym->st_value);
	    if( u3common_fwrite(
		  core_fp,
		  offset,
		  4,
		  1,
		  &vid_dep->sym->st_value ) != 1 )
	    {
	      display_error("Failed to write parts of the vid table.",NULL);
	      break;
	    }
	    offset += 4;
	    vid_dep = vid_dep->next;
	  }
	  
	  rel = vid->rels;
	  while( rel )
	  {
	    rel->offset += rel->sect->global_offset;
	    if( coremap_fp )
	      fprintf(coremap_fp->fp,"\tuser: %08X\n", rel->offset);
	    if( u3common_fwrite(
		  core_fp,
		  offset,
		  4,
		  1,
		  &rel->offset ) != 1 )
	    {
	      display_error("Failed to write parts of the vid table.",NULL);
	      break;
	    }
	    offset += 4;
	    rel = rel->next;
	  } /* while( vid_dep ) */
	  vid = vid->next;
	} /* while( vid ) */
	break;
      default:
	if( coremap_fp )
	  fprintf(coremap_fp->fp,"%08X final core size\n", offset);
	if( offset != final_core_size )
	  display_warning("expected core size and final core size do not match",NULL);
	exit = 1;
    }
    step++;
  }

  if( abort_linking )
    display_error("Core generation failed.",NULL);
  if( buffer )
    u3common_free( buffer );
  if( core_fp )
    u3common_fclose( core_fp );
  if( coremap_fp )
    u3common_fclose( coremap_fp );

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving generate_core(), returning %i\n",debug_step,abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




u3l_VID *get_vid_entry( unsigned int vid )
{
  u3l_VID *vid_entry;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering get_vid_entry(%i)\n", debug_step,vid);
    fflush( stdout );
  }



  vid_entry = registered_vids;
  while( vid_entry )
  {
    if( vid_entry->id == vid ) return vid_entry;

    vid_entry = vid_entry->next;
  }

  vid_entry = (u3l_VID *)u3common_malloc(sizeof(u3l_VID), "vid entry");
  if( vid_entry )
  {
    total_vid_count++;
    vid_entry->value = 0;
    vid_entry->id = vid;
    vid_entry->prov_count = 0;
    vid_entry->user_count = 0;
    vid_entry->name = get_vid_name( vid );
    vid_entry->providers = NULL;
    vid_entry->users = NULL;
    vid_entry->rels = NULL;
    vid_entry->next = registered_vids;
    registered_vids = vid_entry;
  }


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving get_vid_entry(), returning %p\n", debug_step,vid_entry);
    fflush(stdout);
  }
  return vid_entry;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





char *get_vid_name( unsigned int vid )
{
  u3l_named_VID *named_vid;

  named_vid = registered_named_vids;
  while( named_vid )
  {
    if( named_vid->id == vid )
      return &named_vid->name[0];

    named_vid = named_vid->next;
  }

  return null_name;
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




/* harvest_symbols()
 *
 *  o Goes through each object's symbol table and register any VID
 *  o Compute how many DLP and DRP will be required for each cell
 *
 */
unsigned int harvest_symbols()
{
  u3l_OBJ *obj;
  unsigned int i,j, vid;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_HIGH )
  {
    printf("%i:entering harvest_symbols()\n",debug_step);
    fflush(stdout);
  }

  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 4\t\t:\tHarvesting symbols\n");

  obj = objects_to_link;
  while( obj )
  {
    if( verbose_level >= VERBOSE_LEVEL_HIGH )
      printf("\t%s:\n", obj->filename);

    if( obj->symtab && obj->strtab )
    {
      for(i=0;i< (obj->symtab_size/sizeof(Elf32_Sym)) ; i++)
      {
	if( verbose_level == VERBOSE_LEVEL_DEBUG )
	  printf("\t\tsymbol:\n\t\t\tst_name: %s\n\t\t\tst_value: %i\n\t\t\tst_size: %i\n\t\t\tst_info: %i\n\t\t\tst_other: %i\n\t\t\tst_shndx: %i\n",
	      &obj->strtab[obj->symtab[i].st_name],
	      obj->symtab[i].st_value,
	      obj->symtab[i].st_size,
	      obj->symtab[i].st_info,
	      obj->symtab[i].st_other,
	      obj->symtab[i].st_shndx );

	vid = 0xFFFFFFFF;
	if( (sscanf(&obj->strtab[obj->symtab[i].st_name],"..@VOiD%i",&vid)
	      || sscanf(&obj->strtab[obj->symtab[i].st_name],"___VOiD%i",&vid))
	    && vid != 0xFFFFFFFF)
	{
	  if( !obj->symtab[i].st_shndx )
	    add_vid_dep( vid, &obj->symtab[i], obj );
	  else
	    add_vid_prov( vid, &obj->symtab[i], obj );
	}
	else
	{
	  /* Symbol does not match ..@VOiD%i nor ___VOiD%i */
	  if( ((ELF32_ST_BIND(obj->symtab[i].st_info) != STB_LOCAL)
		|| (obj->symtab[i].st_shndx == SHN_UNDEF))
	      && (obj->symtab[i].st_name != 0) )
	  {
	    if( strcmp( &obj->strtab[obj->symtab[i].st_name], "_start") != 0 )
	    {
	      if( obj != wrapper_object )
		display_error("Non-wrapper object tried to define/import a non-VOiD global",obj->filename);
	      else
	      {
		// wrapper object either importing or exporting a symbol
		if( (obj->symtab[i].st_shndx == SHN_UNDEF) )
		{
		  /* importing.. look if it is a known value */
		  for(j=0;j<PRE_DEFINED_GLOBALS;j++)
		  {
		    if( strcmp( &obj->strtab[obj->symtab[i].st_name], pre_defined_globals[j]) == 0 ) break;
		  }

		  if( j == PRE_DEFINED_GLOBALS )
		  {
		    /* nope it's not a known value */
		    display_error("Wrapper object is trying to access an undefined non-VOiD global", &obj->strtab[obj->symtab[i].st_name] );
		  }
		  else
		  {
		    /* pre-defined global access are allowed :) */
		    add_vid_dep(
			j | PRE_DEFINED_GLOBAL_MASK,
			&obj->symtab[i],
			obj);
		  }
		}
		else
		{
		  /* exporting symbol..tststst */
		  display_warning("this linker version does not allow wrapper to define non-VOiD globals",NULL);
		}
	      }
	    }
	    else
	    {
	      /* symbol name is _start */
	      if( obj == wrapper_object )
		wrapper_entry_section = obj->symtab[i].st_shndx-1;
	      obj->sections[obj->symtab[i].st_shndx-1]->entry_point =
		obj->symtab[i].st_value;
	    }
	  }
	}
      }
    }

    obj = obj->next;
  }

  if( !abort_linking )
  {
    // verifying that all dependencies are fulfilled
    u3l_VID *vid;

    vid = registered_vids;
    while( vid )
    {
      if( (vid->users != NULL)
	  && (vid->providers == NULL) )
      {
	fprintf(stderr,"ERROR: VOiD %i %s is required by at least %s but found no provider.\n",vid->id, vid->name, vid->users->obj->filename);
	fflush(stderr);
	errors++;
	abort_linking = 1;
      }
      vid = vid->next;
    }
  }

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving harvest_symbols(), returning %i\n", debug_step, abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





void hex_dump(void *buf, size_t size)
{
  unsigned char *buffer = buf;

  while( size-- )
  {
    printf("%p: %02X\n",buffer,buffer[0]);
    buffer++;
  }
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




void list_vid(void)
{
  u3l_VID *vid_entry;
  u3l_VID_DEP *vid_dep;

  vid_entry = registered_vids;
  while( vid_entry )
  {
    printf("VID: %i %s\n\tvalue: %08X\n\tProviders:\n",vid_entry->id, vid_entry->name,vid_entry->value);
    vid_dep = vid_entry->providers;
    while( vid_dep )
    {
      printf("\t%s\n", vid_dep->obj->filename );
      vid_dep = vid_dep->next;
    }
    printf("\tUsers:\n");
    vid_dep = vid_entry->users;
    while( vid_dep )
    {
      printf("\t%s\n", vid_dep->obj->filename );
      vid_dep = vid_dep->next;
    }
    vid_entry = vid_entry->next;
  }
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




unsigned int load_vid_names(void)
{
  u3_FILE *fp;
  char buffer[80], *line;
  char name[80];
  unsigned int vid;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering load_vid_names()\n",debug_step);
    fflush(stdout);
  }

  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 1\t\t:\tTrying to load vid names\n");

  if( vid_name_file )
  {
    fp = u3common_fopen( vid_name_file, "r");
    if( !fp )
    {
      display_error("Unable to open vid names file: %s\n", vid_name_file);
    }
    else
    {
      while( (line = fgets( buffer, 80, fp->fp )) == buffer )
      {
	if( sscanf(line, "%i %s\n", &vid, name) != 2 )
	{
	  display_error("Invalid vid name file format",vid_name_file);
	  break;
	}
	else
	{
	  add_named_vid( vid, name );
	}
      }
      u3common_fclose( fp );
    }
  }


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving load_vid_names(), returning %i\n",debug_step,abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





unsigned int order_sections()
{

  u3l_SECT	*p_unsorted		= sections_to_link,
		*p_init			=NULL,
		*p_onetime_init		=NULL,
		*p_info			=NULL,
		*p_cells		=NULL,
		*p_wrapper		=NULL;
  u3l_OBJ	*obj;


  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering order_objects()\n", debug_step);
    fflush(stdout);
  }

  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 5\t\t:\tOrdering/sorting sections\n");

  sections_to_link = NULL;

  while( p_unsorted )
  {
    if( strcmp(p_unsorted->sh_name, ".c_init") == 0 )
    {
      if( p_init )
	p_init->next = p_unsorted;

      p_init = p_unsorted;

      if( !head_init )
	head_init = p_init;

      p_unsorted = p_unsorted->next;
      init_count++;
      continue;
    }

    if( strcmp(p_unsorted->sh_name, ".c_onetime_init") == 0 )
    {
      if( p_onetime_init )
	p_onetime_init->next = p_unsorted;

      p_onetime_init = p_unsorted;

      if( !head_onetime_init )
	head_onetime_init = p_onetime_init;

      p_unsorted = p_unsorted->next;
      onetime_init_count++;
      continue;
    }

    if( p_unsorted->obj == wrapper_object )
    {
      if( p_wrapper )
	p_wrapper->next = p_unsorted;

      p_wrapper = p_unsorted;

      if( !head_wrapper )
	head_wrapper = p_wrapper;

      p_unsorted = p_unsorted->next;
      continue;
    }

    if( p_cells )
      p_cells->next = p_unsorted;

    p_cells = p_unsorted;
    
    if( !head_cells )
      head_cells = p_cells;

    p_unsorted = p_unsorted->next;
    cell_sections_count++;
  }

  obj = objects_to_link;
  while( obj )
  {
    if( obj->c_info )
    {
      if( p_info )
	p_info->next = obj->c_info;
      
      p_info = obj->c_info;
      
      if( !head_info )
	head_info = p_info;

      obj->id = ++info_count;
    }

    obj = obj->next;
  }

  if( p_info )
    p_info->next = NULL;
  if( p_cells )
    p_cells->next = NULL;
  if( p_wrapper )
    p_wrapper->next = NULL;
  if( p_init )
    p_init->next = NULL;
  if( p_onetime_init )
    p_onetime_init->next = NULL;

  if( verbose_level >= VERBOSE_LEVEL_HIGH )
  {
    printf("onetime inits are:\n");
    p_unsorted = head_onetime_init;
    while( p_unsorted )
    {
      obj = p_unsorted->obj;
      printf("\t%s\n",obj->filename);
      p_unsorted= p_unsorted->next;
    }

    printf("inits are:\n");
    p_unsorted = head_init;
    while( p_unsorted )
    {
      obj = p_unsorted->obj;
      printf("\t%s\n",obj->filename);
      p_unsorted= p_unsorted->next;
    }
    
    printf("cells info are:\n");
    p_unsorted = head_info;
    while( p_unsorted )
    {
      obj = p_unsorted->obj;
      printf("\t%s\n",obj->filename);
      p_unsorted= p_unsorted->next;
    }
    
    printf("wrapper sections are:\n");
    p_unsorted = head_wrapper;
    while( p_unsorted )
    {
      obj = p_unsorted->obj;
      printf("\t%s of %s\n", p_unsorted->sh_name,obj->filename);
      p_unsorted= p_unsorted->next;
    }

    printf("all other cell sections are:\n");
    p_unsorted = head_cells;
    while( p_unsorted )
    {
      obj = p_unsorted->obj;
      printf("\t%s of %s\n",p_unsorted->sh_name, obj->filename);
      p_unsorted= p_unsorted->next;
    }
  }

  
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving order_objects(), returning %i\n", debug_step, abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



/* prepare_objects()
 *
 *  The varios objects to link are already opened and some basic information is
 *  known about them.  Here, we will do the following:
 *
 *    o Load the Section Header table
 *    o Load the Section Headter String table
 *    o Load the Symbol table
 *    o Load the Symbol String table
 *    o Load the Relocation Table for each section
 *    o Register all found sections
 *    o Associate the loaded Relocation Table with its sections
 *    o Filter out .comment and .note sections
 *    o Detect which objects are cells and which are wrappers
 *    o Generate .c_info for cells which doesn't have them
 */
unsigned int prepare_objects()
{
  u3l_OBJ *obj;
  u3l_SECT *sect, *unsorted=NULL, *unsorted_objhead;
  unsigned int read_size = 0, object_loaded, i;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering prepare_objects()\n", debug_step);
    fflush(stdout);
  }

  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 3\t\t:\tPreparing objects\n");

  obj = objects_to_link;
  while( obj )
  {
    // filter out init classes
    if( obj->filename[0] == ':' )
    {
      obj=obj->next;
      continue;
    }
 
    if( verbose_level >= VERBOSE_LEVEL_HIGH )
      printf("\t%s: \n", obj->filename);

    object_loaded = 0;
    unsorted_objhead = NULL;

    // loading section header table
    read_size = obj->shentsize * obj->shnum;
    obj->shtab = (Elf32_Shdr *)u3common_malloc( read_size,"shtab" );
    if( obj->shtab 
	&& (u3common_fread( obj->fp, obj->shoff+obj->shentsize, read_size, 1, obj->shtab) == 1)
	&& (obj->sections = (u3l_SECT **)u3common_malloc(sizeof(u3l_SECT *)*obj->shnum,"obj->sections")) )
    {
      if( verbose_level >= VERBOSE_LEVEL_HIGH )
	printf("\t\tshtab:\tloaded\n");

      obj->shstr = (char *)u3common_malloc( obj->shtab[obj->shstrndx-1].sh_size, "shstr" );
      if( obj->shstr
	  && u3common_fread(
	    obj->fp,
	    obj->shtab[obj->shstrndx-1].sh_offset,
	    obj->shtab[obj->shstrndx-1].sh_size,
	    1,
	    obj->shstr ) )
      {
	if( verbose_level >= VERBOSE_LEVEL_HIGH )
	  printf("\t\tshstr:\tloaded\n");

	object_loaded = 1;
	for(i=0; i< obj->shnum; i++)
	{
	  obj->sections[i] = NULL;
	  if( (obj->shtab[i].sh_type == SHT_PROGBITS)
	      && (obj->shtab[i].sh_size != 0)
	      && strcmp( ".comment", &obj->shstr[obj->shtab[i].sh_name])
	      && strcmp( ".note", &obj->shstr[obj->shtab[i].sh_name]) )
	  {
	    sect = (u3l_SECT *)u3common_malloc(sizeof(u3l_SECT),"obj section");
	    sect = alloc_u3l_SECT(
		i+1,
		&obj->shstr[obj->shtab[i].sh_name],
		obj,
		&obj->shtab[i] );
	    if( sect )
	    {
	      obj->sections[i] = sect;
	      if( sect->sh_entry->sh_size > largest_cell_section )
		largest_cell_section = sect->sh_entry->sh_size;

	      if( strcmp( sect->sh_name, ".c_info" ) )
	      {
		if( !unsorted_objhead )
		  unsorted_objhead = sect;
		
		if( !sections_to_link )
		  sections_to_link = sect;
		
		if( unsorted )
		  unsorted->next = sect;
		
		unsorted = sect;
	      }
	      else
	      {
		obj->c_info = sect;
	      }
	    }
	  }
	  if( (obj->shtab[i].sh_type == SHT_REL) )
	  {
	    /* Relocation table */
	    sect = alloc_u3l_SECT(
		i+1,
		&obj->shstr[obj->shtab[i].sh_name],
		obj,
		&obj->shtab[i] );
	    if( sect )
	    {
	      sect->next = obj->reltabs;
	      obj->reltabs = sect;
	    }
	  }
	  if( (obj->shtab[i].sh_type == SHT_SYMTAB) )
	  {
	    /* Symbol Table */
	    obj->symtab_size = obj->shtab[i].sh_size;
	    obj->symtab = (Elf32_Sym *)u3common_malloc(obj->symtab_size,"symtab");
	    if( !u3common_fread(
		  obj->fp,
		  obj->shtab[i].sh_offset,
		  obj->symtab_size,
		  1,
		  obj->symtab ))
	    {
	      if( verbose_level >= VERBOSE_LEVEL_HIGH)
		printf("\t\tsymtab:\tfailed\n");

	      object_loaded = 0;
	    }
	    else
	    {
	      if( verbose_level >= VERBOSE_LEVEL_HIGH )
		printf("\t\tsymtab:\tloaded\n");

	      obj->strtab = (char *)u3common_malloc(obj->shtab[obj->shtab[i].sh_link-1].sh_size,"strtab");
	      if( obj->strtab 
		  && u3common_fread(
		    obj->fp,
		    obj->shtab[obj->shtab[i].sh_link-1].sh_offset,
		    obj->shtab[obj->shtab[i].sh_link-1].sh_size,
		    1,
		    obj->strtab ) )
	      {
		if( verbose_level >= VERBOSE_LEVEL_HIGH )
		  printf("\t\tstrtab:\tloaded\n");
	      }
	      else
	      {
		if( verbose_level >= VERBOSE_LEVEL_HIGH )
		  printf("\t\tstrtab:\tfailed\n");

		object_loaded = 0;
	      }
	    }
	  }
	  if( (obj->shtab[i].sh_type == SHT_NOBITS) )
	  {
	    /* .bss section */
	    sect = alloc_u3l_SECT(
		i+1,
		&obj->shstr[obj->shtab[i].sh_name],
		obj,
		&obj->shtab[i] );
	    if( sect )
	    {
	      bss_sections_count++;
	      sect->next = obj->bss;
	      obj->bss = sect;
	      if( verbose_level >= VERBOSE_LEVEL_HIGH )
		printf("\t\tbss:\t%i bytes\n", sect->sh_entry->sh_size);
	    }
	    else
	    {
	      if( verbose_level >= VERBOSE_LEVEL_HIGH )
		printf("\t\tbss:\tfailed\n");
	      object_loaded = 0;
	    }
	  }
	}
      }
      else
      {
	if( verbose_level >= VERBOSE_LEVEL_HIGH )
	  printf("\t\tshstr: failed\n");
      }
    }
    else
    {
      if( verbose_level >= VERBOSE_LEVEL_HIGH )
	printf("\t\tshstr: failed\n");
    }

    if( !object_loaded )
      display_error("Unable to read some parts of the object.",obj->filename);
    else
    {
      u3l_SECT *sect_objbrowser;

      if( verbose_level >= VERBOSE_LEVEL_HIGH)
	printf("ok\n");

      // making sure at least one section exists for each object
      sect = unsorted_objhead;
      if( verbose_level >= VERBOSE_LEVEL_HIGH )
	printf("\t\tsections to load:\n");

      first_option = 1;
      while( sect )
      {
	first_option = 0;
	if( verbose_level >= VERBOSE_LEVEL_HIGH )
	  printf("\t\t\t%s\n", sect->sh_name);

	sect = sect->next;
      }
      if( first_option )
      {
	if( verbose_level >= VERBOSE_LEVEL_HIGH )
	  printf("\t\t\t-none-\n");
	display_warning("Object does not contain any loadable section.", obj->filename);
      }
      else
      {

	/* Linking relocation tables with their associated section */
	sect = obj->reltabs;
	while( sect )
	{
	  
	  sect_objbrowser = obj->sections[sect->sh_entry->sh_info-1];

	  /* check if we found a match */
	  if( !sect_objbrowser )
	    display_error("relocation information found for an invalid section index in object.", obj->filename);
	  else
	  {
	    if( sect_objbrowser->reltab )
	      display_error("Two relocation tables associated to the same section.", obj->filename);
	    else
	    {
	      sect_objbrowser->reltab = sect;
	    }
	  }
	  
	  sect = sect->next;
	}
	
	/* check object type, determine if it is a wrapper or a cell */
	if( !obj->c_info )
	{
	  unsigned char found_c_init=0, found_c_onetime_init=0;
	  
	  /* search for any .c_init or .c_onetime_init usage.. */
	  sect = unsorted_objhead;
	  while( sect )
	  {
	    if( strcmp( sect->sh_name, ".c_init" ) == 0 )
	      found_c_init = 1;
	    else
	    {
	      if( strcmp( sect->sh_name, ".c_onetime_init" ) == 0 )
		found_c_onetime_init = 1;
	    }
	    
	    sect = sect->next;
	  }
	  
	  if( found_c_init || found_c_onetime_init )
	  {
	    /* warn that .c_info should be used */
	    display_warning("object is a cell but does not contain a .c_info section", obj->filename);
	    obj->c_info = alloc_u3l_SECT( 0, ".c_info", obj, NULL );
	    total_cell_count++;
	  }
	  else
	  {
	    if( wrapper_object )
	    {
	      fprintf( stderr, "ERROR: object %s is concurrencing object %s as cell wrapper.\n", obj->filename, wrapper_object->filename);
	      errors++;
	      abort_linking = 1;
	    }
	    else
	    {
	      wrapper_object = obj;
	    }
	  }
	}
	else
	{
	  total_cell_count++;
	}
      }
    }

    obj = obj->next;
  }

  if( !wrapper_object )
    display_error("all objects identified as cells, you also require a wrapper object.", NULL);


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving prepare_objects(), returning %i\n", debug_step, abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





void print_option( char *name )
{

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering print_option(%s)\n", debug_step, name);
    fflush(stdout);
  }

  
  if( first_option )
    printf(name);
  else
    printf(", %s", name);

  first_option = 0;

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving print_option()\n", debug_step);
    fflush(stdout);
  }
}





//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




unsigned int update_symbols(void)
{
  u3l_OBJ	*obj;
  unsigned int	sym_count;
  u3l_VID	*vid;
  u3l_VID_DEP	*vid_dep;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering update_symbols()\n",debug_step);
    fflush(stdout);
  }

  if( verbose_level >= VERBOSE_LEVEL_LOW )
    printf("Phase 8\t\t:\tUpdating Symbols\n");
  
  obj = objects_to_link;
  while( obj )
  {
    sym_count = obj->symtab_size/sizeof(Elf32_Sym);
    while( sym_count-- )
    {
      if( (obj->symtab[sym_count].st_shndx != 0)
	  && (obj->symtab[sym_count].st_shndx <= obj->shnum)
	  && (obj->sections[obj->symtab[sym_count].st_shndx-1] != NULL) )
	obj->symtab[sym_count].st_value += obj->sections[obj->symtab[sym_count].st_shndx-1]->global_offset;
    }
    obj = obj->next;
  }


  vid = registered_vids;
  while( vid )
  {
    vid->value = vid->providers->sym->st_value;
    vid_dep = vid->users;
    while( vid_dep )
    {
      vid_dep->sym->st_value = vid->value;
      vid_dep = vid_dep->next;
    }
    vid = vid->next;
  }

  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_CORE_HEADER],
      global_offset );
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_INIT_SEQUENCE_LOC],
      init_sequence_location );
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_STACK_LOCATION],
      stack_override);
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_INFO_REDIRECTION_TABLE],
      sizeof(hdr_core) + global_offset);
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_CORE_SIZE],
      final_core_size );
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_CELL_COUNT],
      total_cell_count );
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_VID_COUNT],
      total_vid_count );
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_END_OF_EXPORT],
      end_of_export );
  update_symbol_chain(
      pre_defined_globals_dep[PRE_DEF_SYMBOLS_LINKAGE],
      core_offset_to_globals + global_offset );

  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving update_symbols(), returning %i\n",debug_step, abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





void update_symbol_chain( u3l_VID_DEP *dep_chain, unsigned int value )
{
  while( dep_chain )
  {
    dep_chain->sym->st_value += value;
    dep_chain = dep_chain->next;
  }
}






//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





unsigned int validate_objects(void)
{
  u3l_OBJ* obj;
  Elf32_hdr* elf_hdr;

  debug_step++;
  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:entering validate_objects()\n",debug_step);
    fflush(stdout);
  }

  if( objects_to_link )
  {
    elf_hdr = (Elf32_hdr *)u3common_malloc(sizeof(Elf32_hdr),"elf header");
    if( elf_hdr )
    {
      if( verbose_level >= VERBOSE_LEVEL_LOW )
	printf("Phase 2\t\t:\tValidating objects\n");

      obj = objects_to_link;
      while( obj )
      {

	// filter out init classes
	if( obj->filename[0] == ':' )
	{
	  obj = obj->next;
	  continue;
	}

	if( verbose_level >= VERBOSE_LEVEL_HIGH )
	  printf("\t%s: ",obj->filename);
	
	// Open, check if it is a valid ELF for i386
	 obj->fp = u3common_fopen(obj->filename, "rb");
	if( obj->fp 
	    && u3common_fread( obj->fp, 0, sizeof(Elf32_hdr), 1, elf_hdr)
	    && elf_hdr->e_signature == ELFMAGIC
	    && elf_hdr->e_class == ELFCLASS32
	    && elf_hdr->e_data == ELFDATA2LSB
	    && elf_hdr->e_hdrversion == EV_VERSION
	    && elf_hdr->e_type == ET_REL
	    && elf_hdr->e_machine == EM_386
	    && elf_hdr->e_version == EV_VERSION
	    && elf_hdr->e_shoff != 0
	    && elf_hdr->e_shstrndx != 0)
	{
	  if( verbose_level >= VERBOSE_LEVEL_HIGH )
	    printf("ok\n");

	  if( elf_hdr->e_entry != 0 )
	    display_warning("file contained a specified entry point and it will be ignored.", obj->filename);
	  if( elf_hdr->e_phoff != 0 )
	    display_warning("file contained a set program header table and it will be ignored.", obj->filename);
	  
	  obj->shnum = elf_hdr->e_shnum;
	  obj->shoff = elf_hdr->e_shoff;
	  obj->shstrndx = elf_hdr->e_shstrndx;
	  obj->shentsize = elf_hdr->e_shentsize;
	  if( verbose_level >= VERBOSE_LEVEL_HIGH )
	    printf("\t\tnumber of sections: %i\n\t\tsection header offset: %i\n\t\tsection header string index: %i\n\t\tsection header entry size: %i\n", obj->shnum, obj->shoff, obj->shstrndx, obj->shentsize);
	}
	else
	{
	  if( verbose_level >= VERBOSE_LEVEL_HIGH )
	    printf("failed\n");
	}
	
	obj = obj->next;
      }

      u3common_free( elf_hdr );
    }
  }
  else
    display_error("No object specified for linking, can't link anti-matter yet!", NULL);


  if( verbose_level == VERBOSE_LEVEL_DEBUG )
  {
    printf("%i:leaving validate_objects(), returning %i\n",debug_step,abort_linking);
    fflush(stdout);
  }
  return abort_linking;
}




//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -






int main( int argc, char **argv )
{

  if( !cmdline_parse( argc, argv )
      && !load_vid_names()
      && !validate_objects()
      && !prepare_objects()
      && !harvest_symbols()
      && !order_sections()
      && !analyze_relocs()
      && !compute_offsets()
      && !update_symbols()
      && !generate_core() )
  {
    if( verbose_level >= VERBOSE_LEVEL_NORMAL )
      display_summary();
    if( verbose_level == VERBOSE_LEVEL_LOW )
      printf(
	  "Linking successful.\tErrors: %i\tWarnings: %i\n",
	  errors,
	  warnings);
  }
  else
  {
    if( (verbose_level >= VERBOSE_LEVEL_LOW) && (errors + warnings) )
      printf(
	  "Linking failed.\tErrors: %i\tWarnings: %i\n",
	  errors,
	  warnings);
  }

  flush_sections();
  u3common_fclose_all();
  u3common_free_all();

  return abort_linking;
}



