#ifndef __U3FSDB_H__
#define __U3FSDB_H__


#define VERSION		"Unununium File System Development Bench v1.0-dev"

void *u3fsdb_malloc(unsigned int size);
unsigned int u3fsdb_free(void *buffer);
void u3fsdb_report(char *msg, unsigned int supplement_code, char *extra_info);
void u3fsdb_urgen_exit(void);
unsigned int u3fsdb_mountpoint_registration(char *mountpoint);
unsigned int u3fsdb_fopen( char *filename );
unsigned int u3fsdb_fclose( void );
void u3fsdb_call_trace(
    unsigned int r_edi,
    unsigned int r_esi,
    unsigned int r_ebp,
    unsigned int r_esp,
    unsigned int r_ebx,
    unsigned int r_edx,
    unsigned int r_ecx,
    unsigned int r_eax,
    char *function );
void u3fsdb_call_ltrace(
    unsigned int r_edi,
    unsigned int r_esi,
    unsigned int r_ebp,
    unsigned int r_esp,
    unsigned int r_ebx,
    unsigned int r_edx,
    unsigned int r_ecx,
    unsigned int r_eax,
    unsigned int cf );



#endif /* __U3FSDB_H__ */
