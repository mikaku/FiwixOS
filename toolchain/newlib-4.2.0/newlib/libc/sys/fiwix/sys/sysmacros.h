#ifndef _SYS_SYSMACROS_H
#define _SYS_SYSMACROS_H

#include <sys/types.h>

#define major(__dev)	(((dev_t) (__dev)) >> 8)
#define minor(__dev)	(((dev_t) (__dev)) & 0xFF)

dev_t makedev(unsigned int, unsigned int);

#endif /* _SYS_SYSMACROS_H */
