/* confdefs.h */
#define _NETBSD_SOURCE 1
#define __BSD_VISIBLE 1
#define _DARWIN_C_SOURCE 1
#define _PYTHONFRAMEWORK ""
#define _XOPEN_SOURCE 700
#define _XOPEN_SOURCE_EXTENDED 1
#define _POSIX_C_SOURCE 200809L
#define STDC_HEADERS 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_MEMORY_H 1
#define HAVE_STRINGS_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_UNISTD_H 1
#define __EXTENSIONS__ 1
#define _ALL_SOURCE 1
#define _GNU_SOURCE 1
#define _POSIX_PTHREAD_SEMANTICS 1
#define _TANDEM_SOURCE 1
/* end confdefs.h.  */

#include <stdio.h>
#include <pthread.h>

void* routine(void* p){return NULL;}

int main(){
  pthread_t p;
  if(pthread_create(&p,NULL,routine,NULL)!=0)
    return 1;
  (void)pthread_detach(p);
  return 0;
}

