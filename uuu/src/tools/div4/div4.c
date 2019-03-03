#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
  FILE *fd_in=NULL, *fd_out=NULL;
  unsigned char c=0;

  if( argc != 3 )
  {
    fprintf(stderr,"Usage: div4 <inputfile> <outputfile>\n");
    return 1;
  }

  fd_in = fopen((char *)&argv[1][0], "rb");
  fd_out = fopen((char *)&argv[2][0], "wb");

  if( !fd_in || !fd_out )
  {
    if( !fd_in )
    {
      fprintf(stderr,"Unable to open specified input file: %s\n",&argv[1][0]);
    }
    if( !fd_out )
    {
      fprintf(stderr,"Unable to create specified output file: %s\n",&argv[2][0]);
    }
    return 1;
  }
  
  while( !feof(fd_in) )
  {
    if( fread(&c,1,1,fd_in) != 1) break;
    c >>= 2;
    if( fwrite(&c,1,1,fd_out) != 1){
      fprintf(stderr,"Output to file \"%s\" failed.\n",&argv[2][0]);
      fclose(fd_in);
      fclose(fd_out);
      return 1;
    }
  }
  fclose(fd_in);
  fclose(fd_out);
  return 0;
}
