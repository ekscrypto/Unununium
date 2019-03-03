#include <stdlib.h>
#include <stdio.h>


int main( int argc, char **argv ) {

  FILE *boot;
  unsigned int i,j = 0;
  unsigned char buffer[512];


  if( argc != 2 ) {
    fprintf(stderr,"Boot2h by EKS - Dave Poirier\nUsage: boot2h /path/to/boot/record > boot.h\n");
    return 0;
  }

  boot = fopen(argv[1],"rb");
  if( !boot ) {
    fprintf(stderr,"Unable to open specified boot record: %s\n",argv[1]);
    return 0;
  }

  if( fread(&buffer,512,1,boot) != 1 ) {
    fprintf(stderr,"Warning: reading 512 bytes failed!");
  }
  fclose(boot);

  if( buffer[510] != 0x55 || buffer[511] != 0xAA ) {
    fprintf(stderr,"Warning: boot signature not found!");
  }

  printf("/* Generated using boot2h */\nunsigned char boot_record[512] = {\n");
  for(i=0; i<511; i++)
  {
    printf("0x%02X,",buffer[i]);
    j++;
    if( j == 10 ) {
      j = 0; printf("\n");
    }
  }
  printf("0x%02X };\n",buffer[511]);
  return 0;
}
