#ifndef _SYS_ERRNO_H
#ifdef __cplusplus
extern "C" {
#endif
#define _SYS_ERRNO_H

/* --- from newlib's sys/errno.h --- */

#include <sys/reent.h>

#ifndef _REENT_ONLY
#define errno (*__errno())
extern int *__errno (void);
#endif


extern __IMPORT const char * const _sys_errlist[];
extern __IMPORT int _sys_nerr;

#define __errno_r(ptr) ((ptr)->_errno)

/* --------------------------------- */

#define __set_errno(x) (errno = (x))

#include <fiwix/errno.h>

#define ENOTSUP EOPNOTSUPP
#define EFTYPE		79	/* needed for newlib/libc/search/hash.c */

#ifdef __cplusplus
}
#endif
#endif	/* _SYS_ERRNO_H */
