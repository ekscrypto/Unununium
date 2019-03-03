/* Unununium File System Development Bench
 * Copyright (C) 2001-2002, Dave Poirier
 * Distributed under the modified BSD License
 */

#include <stdlib.h>
#include <stdio.h>
#include <u3common.h>
#include <u3fsdb.h>
#include <u3fsdb_bridge.h>

char		u3fsdb_device[]		= "/home/eks/ext2.flp",
  		u3fsdb_mountpoint[]	= "/",
		u3fsdb_mount_requested	= 0,
		*u3fsdb_device_to_be_opened = NULL;

unsigned char	*guest_memory		= NULL,
		guest_memory_desc[]	= "guest system memory";
u3_FILE		*u3fsdb_device_fp	= NULL;

#define fsdbnil	0xF5DBF5DB






/*                          INTERNAL FUNCTIONS                          */







void u3fsdb_msg( char *msg, int val, char *other )
{
  if( val != fsdbnil)
    if( other )
      printf("U3FSDB: %s: %i: %s\n",msg,val,other);
    else
      printf("U3FSDB: %s: %i\n",msg,val);
  else
    if( other )
      printf("U3FSDB: %s: %s\n",msg,other);
    else
      printf("U3FSDB: %s\n",msg);

  fflush( stdout );
}

unsigned int u3fsdb_init_fs( void )
{
  unsigned int fs_type;

  // initializing guest fs cell
  u3fsdb_msg( "Initializing guest fs",fsdbnil,NULL);

  fs_type = u3fsdb_bridge_init_guest();  
  if( !fs_type )
  {
    u3fsdb_msg( "Initialization failed",fsdbnil,NULL);
    return 0;
  }
  
  u3fsdb_msg("Initialized with fs type", fs_type,NULL);
  return 1;
}


unsigned int u3fsdb_mount_fs( char *device, char *mountpoint )
{
  u3fsdb_msg("requesting fs mount",fsdbnil,NULL);
  u3fsdb_msg("device",fsdbnil,device);
  u3fsdb_msg("mountpoint",fsdbnil,mountpoint);

  u3fsdb_mount_requested++;
  u3fsdb_device_to_be_opened = device;
  u3fsdb_bridge_mount( device, mountpoint );

  if( u3fsdb_mount_requested )
  {
    u3fsdb_msg("ERROR: mountpoint registration never completed.",fsdbnil,NULL);
    u3fsdb_mount_requested = 0;
    return 0;
  }

  u3fsdb_msg("mountpoint registration completed.",fsdbnil,NULL);  
  return 1;
}





/*                                  MAIN                                */






int main( int argc, char **argv )
{

  printf( VERSION "\n" );

  if( u3fsdb_init_fs()
      && u3fsdb_mount_fs( u3fsdb_device, u3fsdb_mountpoint) )
    u3fsdb_msg("Guest fs tests successful.", fsdbnil, NULL);

  
  if( u3fsdb_device_fp )
  {
    fprintf( stderr, "Guest FS never closed the device.\n");
    fflush( stderr );
    u3common_fclose( u3fsdb_device_fp );
  }

  u3common_fclose_all();
  u3common_free_all();
  return 0;
}




/*                              BRIDGE FUNCTIONS                          */





void *u3fsdb_malloc( unsigned int size )
{
  void *buffer;

  size = (size+63) & ~63;

  printf("guest fs requested %i bytes of memory.\n", size);
  buffer = u3common_malloc( size + 63, guest_memory_desc );
  printf("memory allocated at: %p\n", buffer); 
  return buffer;
}


unsigned int u3fsdb_free( void *buffer_provided )
{
  unsigned char *buffer;
  buffer = u3common_get_associated_memory_block( buffer_provided );
  if( !u3common_validate_memory_block( buffer) )
  {
    u3fsdb_msg("catched invalid mem dealloc, signaling",(int)buffer_provided,NULL);
    return 1;
  }
  
  printf("guest fs frees memory block: %p, original size: %i\n",
      buffer,
      u3common_get_memory_block_size( buffer )-63 );
  u3common_free( buffer );
  return 0;
}


void u3fsdb_report(
    char *msg,
    unsigned int supplement_code,
    char *extra_info )
{
  if( msg )
    printf("BRIDGE(msg): %s\n", msg);

  if( supplement_code )
    printf("BRIDGE(code): %i\n", supplement_code );

  if( extra_info )
    printf("BRIDGE(extra): %s\n", extra_info );

  fflush( stdout );
}


void u3fsdb_urgent_exit(void)
{
  fprintf( stderr, "WARNING: urgent exit requested.\n");
  fflush( stderr );

  u3common_fclose_all();
  u3common_free_all();
  exit(1);
}



unsigned int u3fsdb_mountpoint_registration(char *mountpoint)
{
  if( u3fsdb_mount_requested )
  {
    printf("BRIDGE: registration received for: %s\n", mountpoint);
    u3fsdb_mount_requested --;
    return 0;
  }
  
  
  u3fsdb_msg("Unexpected mountpoint registration received from BRIDGE",fsdbnil, mountpoint);
  return 1;
}


unsigned int u3fsdb_fopen(char *filename)
{
  if( strcmp( u3fsdb_device_to_be_opened, filename ) )
  {
    u3fsdb_msg("ERROR: device to open is not the one provided.",fsdbnil,filename);
    return 1;
  }

  u3fsdb_msg("request to open device received and valid.",fsdbnil,filename);
  u3fsdb_device_fp = u3common_fopen(filename,"r+b");
  if( !u3fsdb_device_fp )
    u3fsdb_urgent_exit();
  
  return 0;
}


unsigned int u3fsdb_fclose( void )
{
  if( u3fsdb_device_fp )
  {
    u3fsdb_msg("request to close device received.",fsdbnil,NULL);
    u3common_fclose( u3fsdb_device_fp );
    u3fsdb_device_fp = NULL;
    return 0;
  }

  u3fsdb_msg("ERROR: request to close unopened device received.",fsdbnil,NULL);
  return 1;
}


unsigned int u3fsdb_fread( void *buffer, unsigned int sector, unsigned int count)
{
  u3fsdb_msg("received device read request",fsdbnil,NULL);
  u3fsdb_msg("\tsector",sector,NULL);
  u3fsdb_msg("\tcount",count,NULL);

  if( u3fsdb_device_fp 
      && u3common_fread(
	u3fsdb_device_fp,
	sector<<9,
	512,
	count,
	buffer) )
    return 0;

  u3fsdb_msg("ERROR: read failed, returning failure to bridge.",fsdbnil,NULL);
  return 1;
}

unsigned int u3fsdb_fwrite( void *buffer, unsigned int sector, unsigned int count)
{
  u3fsdb_msg("received device write request",fsdbnil,NULL);
  u3fsdb_msg("\tsector",sector,NULL);
  u3fsdb_msg("\tcount",count,NULL);

  if( u3fsdb_device_fp 
      && u3common_fwrite(
	u3fsdb_device_fp,
	sector<<9,
	512,
	count,
	buffer) )
    return 0;

  u3fsdb_msg("ERROR: write failed, returning failure to bridge.",fsdbnil,NULL);
  return 1;
}


void u3fsdb_call_trace(
    unsigned int r_edi,
    unsigned int r_esi,
    unsigned int r_ebp,
    unsigned int r_esp,
    unsigned int r_ebx,
    unsigned int r_edx,
    unsigned int r_ecx,
    unsigned int r_eax,
    char *function )
{
  printf("BRIDGE: call received: %s\n\tEAX: %08X EBX: %08X ECX: %08X EDX: %08X\n\tESI: %08X EDI: %08X ESP: %08X EBP: %08X\n",
      function, r_eax, r_ebx, r_ecx, r_edx, r_esi, r_edi, r_esp, r_ebp );
}

void u3fsdb_call_ltrace(
    unsigned int r_edi,
    unsigned int r_esi,
    unsigned int r_ebp,
    unsigned int r_esp,
    unsigned int r_ebx,
    unsigned int r_edx,
    unsigned int r_ecx,
    unsigned int r_eax,
    unsigned int cf )
{
  printf("BRIDGE: leaving function with: CF=%i\n\tEAX: %08X EBX: %08X ECX: %08X EDX: %08X\n\tESI: %08X EDI: %08X ESP: %08X EBP: %08X\n",
      cf, r_eax, r_ebx, r_ecx, r_edx, r_esi, r_edi, r_esp, r_ebp );
}
