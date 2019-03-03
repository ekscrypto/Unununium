#ifndef __U3COMMON_H__
#define __U3COMMON_H__

typedef struct u3common_mem_t {
  struct u3common_mem_t		*next, *previous;
  unsigned int			size;
  char				*desc;
} u3_MEM;

typedef struct u3common_file_t {
  struct u3common_file_t	*next, *previous;
  FILE				*fp;
  char				*desc;
} u3_FILE;
  

unsigned int u3common_get_peak_memory_usage( void );
unsigned int u3common_get_total_memory_blocks( void );
unsigned int u3common_get_total_memory_usage( void );
unsigned int u3common_get_memory_block_size( void *buffer_provided );
char *u3common_get_memory_block_description( void *buffer_provided );
void u3common_free_all( void );
void u3common_free( void *buffer_provided );
void *u3common_malloc( size_t size, char *description );
void *u3common_validate_memory_block( void *buffer_provided );
void *u3common_get_associated_memory_block( void *buffer_provided );
u3_FILE *u3common_fopen( char *file, char *modes );
void u3common_fclose( u3_FILE *fp );
void u3common_fclose_all( void );
char *u3common_get_file_description( u3_FILE *fp );
unsigned int u3common_get_file_count( void );
unsigned int u3common_get_highest_file_count( void );
u3_FILE *u3common_validate_file( u3_FILE *fp );
unsigned int u3common_fread( u3_FILE *fp, size_t offset, size_t size, size_t nmemb, void *buffer);
unsigned int u3common_fwrite( u3_FILE *fp, size_t offset, size_t size, size_t nmemb, void *buffer);

#endif /* __U3COMMON_H__ */
