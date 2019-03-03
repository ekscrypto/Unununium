/* Common Functions used in the Unununium Tool Set
 * Copyright (C) 2001-2002, Dave Poirier
 * Distributed under the modified BSD License
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <u3common.h>

u3_MEM		*u3common_allocated_memory_blocks	= NULL;
u3_FILE		*u3common_opened_files			= NULL;
unsigned int	u3common_highest_memory_usage		= 0,
  		u3common_memory_usage			= 0,
		u3common_memory_blocks			= 0,
		u3common_file_count			= 0,
		u3common_highest_file_count		= 0;
char		u3common_null_desc[]			= "",
  		u3common_filename_default[]		= ":unable_to_copy_filename:not_enough_memory:",
		u3common_desc_file_opened[]		= "u3_FILE by u3common_fopen",
		u3common_desc_file_desc[]		= "u3_FILE->desc by u3common_fopen";


void *u3common_malloc( size_t size, char *description )
{
  u3_MEM *buffer;

  buffer = (u3_MEM *)malloc(  size + sizeof(u3_MEM)  );
  if( !buffer )
  {
    fprintf( stderr, "Unable to allocate memory, requested size: %i\n", (int)size);
    fflush( stderr );
    return buffer;
  }

  buffer->next = u3common_allocated_memory_blocks;
  buffer->previous = NULL;
  buffer->size = size;
  buffer->desc = description;

  u3common_memory_blocks ++;

  u3common_memory_usage += size;
  if( u3common_memory_usage > u3common_highest_memory_usage )
    u3common_highest_memory_usage = u3common_memory_usage;

  if( u3common_allocated_memory_blocks )
    u3common_allocated_memory_blocks->previous = buffer;

  u3common_allocated_memory_blocks = buffer;
  return &buffer[1];
}


void u3common_free( void *buffer_provided )
{
  u3_MEM *buffer=buffer_provided;

  if( !u3common_validate_memory_block(buffer) )
  {
    fprintf( stderr, "INTERNAL ERROR: u3common_free called with invalid pointer: %p\n", buffer_provided);
    fflush( stderr );
    return;
  }

  buffer = &buffer[-1];
  u3common_memory_blocks --;
  u3common_memory_usage -= buffer->size;
  
  if( buffer->next )
    buffer->next->previous = buffer->previous;

  if( buffer->previous )
    buffer->previous->next = buffer->next;
  else
    u3common_allocated_memory_blocks = buffer->next;
  
  free( buffer );
  return;
}


void u3common_free_all( void )
{
  u3_MEM *buffer, *buffer_next;

  buffer = u3common_allocated_memory_blocks;
  while( buffer )
  {
    buffer_next = buffer->next;
    u3common_free( &buffer[1] );
    buffer = buffer_next;
  }
}


void *u3common_validate_memory_block( void *buffer_provided )
{
  u3_MEM *buffer=buffer_provided, *buffer_checker;

  if( !buffer ) return buffer;

  buffer = &buffer[-1];
  buffer_checker = u3common_allocated_memory_blocks;
  while( buffer_checker )
  {
    if( buffer_checker == buffer ) return buffer_provided;
    buffer_checker = buffer_checker->next;
  }

  return buffer_checker;
}

void *u3common_get_associated_memory_block( void *buffer_provided )
{
  u3_MEM *buffer_checker;
  unsigned char *buffer=buffer_provided;
  unsigned char *buffer_start,*buffer_end;

  if( !buffer ) return buffer;
  
  buffer_checker = u3common_allocated_memory_blocks;
  while( buffer_checker )
  {
    (u3_MEM *)buffer_start = &buffer_checker[1];
    buffer_end = &buffer_start[buffer_checker->size];
    if( (buffer >= buffer_start) &&  (buffer < buffer_end) )
      return buffer_start;

    buffer_checker = buffer_checker->next;
  }

  return buffer_checker;
}

unsigned int u3common_get_memory_block_size( void *buffer_provided )
{
  u3_MEM *buffer=buffer_provided;

  if( !u3common_validate_memory_block(buffer) )
    return 0;

  buffer = &buffer[-1];
  return buffer->size;
}

char *u3common_get_memory_block_description( void *buffer_provided )
{
  u3_MEM *buffer=buffer_provided;

  if( !u3common_validate_memory_block(buffer) )
    return u3common_null_desc;
  
  buffer = &buffer[-1];
  return buffer->desc;
}


unsigned int u3common_get_total_memory_usage( void )
{
  return u3common_memory_usage;
}


unsigned int u3common_get_total_memory_blocks( void )
{
  return u3common_memory_blocks;
}


unsigned int u3common_get_peak_memory_usage( void )
{
  return u3common_highest_memory_usage;
}


/*                        FILE SYSTEM FUNCTIONS                              */


u3_FILE *u3common_fopen( char *file, char *modes )
{
  u3_FILE *fp;
  int filename_length;

  filename_length = strlen(file) + 1;
  fp = (u3_FILE *)u3common_malloc(sizeof(u3_FILE), u3common_desc_file_opened);
  if( fp )
  {

    fp->fp = fopen( file, modes );
    if( fp->fp )
    {
      fp->desc = file;
      fp->next = u3common_opened_files;
      fp->previous = NULL;
      
      if( u3common_opened_files )
	u3common_opened_files->previous = fp;
      
      u3common_opened_files = fp;
      fp->desc = u3common_malloc(filename_length, u3common_desc_file_desc);
      if( fp->desc )
	while( filename_length-- )
	  fp->desc[filename_length] = file[filename_length];
      else
	fp->desc = u3common_filename_default;

      u3common_file_count++;
      if( u3common_file_count > u3common_highest_file_count )
	u3common_highest_file_count = u3common_file_count;

      return fp;
    }
    
    fprintf( stderr, "ERROR: Unable to open %s for modes %s\n", file, modes );
    fflush( stderr );
    u3common_free( fp );
    fp = NULL;
  }
  
  return fp;
}


void u3common_fclose(u3_FILE *fp)
{
  if( !u3common_validate_file( fp ) )
  {
    fprintf( stderr, "INTERNAL ERROR: u3common_fclose called with invalid fp: %p\n", fp );
    fflush( stderr );
    return;
  }

  u3common_file_count --;

  if( fp->fp )
    fclose( fp->fp );

  if( fp->desc
      && (fp->desc != u3common_filename_default) )
    u3common_free( fp->desc );

  if( fp->next )
    fp->next->previous = fp->previous;
  if( fp->previous )
    fp->previous->next = fp->next;
  else
    u3common_opened_files = fp->next;

  u3common_free( fp );

  return;
}


char *u3common_get_file_description(u3_FILE *fp)
{

  if( !u3common_validate_file( fp ) )
    return NULL;

  return fp->desc;
}


void u3common_fclose_all(void)
{
  u3_FILE *fp=u3common_opened_files, *fp_next;

  while( fp )
  {
    fp_next = fp->next;
    u3common_fclose( fp );
    fp = fp_next;
  }
}


unsigned int u3common_get_file_count(void)
{
  return u3common_file_count;
}


unsigned int u3common_get_highest_file_count(void)
{
  return u3common_highest_file_count;
}


u3_FILE *u3common_validate_file( u3_FILE *fp )
{
  u3_FILE *fp_checker=u3common_opened_files;

  while( fp_checker )
  {
    if( fp_checker == fp )
      break;

    fp_checker = fp_checker->next;
  }

  return fp_checker;
}


unsigned int u3common_fread( u3_FILE *fp, size_t offset, size_t size, size_t nmemb, void *buffer)
{
  if( !u3common_validate_file( fp ) )
  {
    fprintf( stderr, "INTERNAL ERROR: invalid file pointer given to u3common_fread: %p\n", fp);
    fflush( stderr );
    return 0;
  }

  if( fseek( fp->fp, offset, SEEK_SET ) ||
      (ftell( fp->fp ) != offset) )
  {
    fprintf( stderr, "ERROR: Unable to seek to desired offset: %i in file: %s\n", (int)offset, fp->desc);
    fflush( stderr );
    return 0;
  }

  if( fread( buffer, size, nmemb, fp->fp ) != nmemb )
  {
    fprintf( stderr, "ERROR: Unable to read some part of: %s\n", fp->desc);
    fflush( stderr );
    return 0;
  }

  return 1;
}



unsigned int u3common_fwrite( u3_FILE *fp, size_t offset, size_t size, size_t nmemb, void *buffer)
{
  if( !u3common_validate_file( fp ) )
  {
    fprintf( stderr, "INTERNAL ERROR: invalid file pointer given to u3common_fwrite: %p\n", fp);
    fflush( stderr );
    return 0;
  }

  if( offset != -1 )
  {
    if( fseek( fp->fp, offset, SEEK_SET ) ||
	(ftell( fp->fp ) != offset) )
    {
      fprintf( stderr, "ERROR: Unable to seek to desired offset: %i in file: %s\n", (int)offset, fp->desc);
      fflush( stderr );
      return 0;
    }
  }

  if( fwrite( buffer, size, nmemb, fp->fp ) != nmemb )
  {
    fprintf( stderr, "ERROR: Unable to write some part of: %s\n", fp->desc);
    fflush( stderr );
    return 0;
  }

  return 1;
}
