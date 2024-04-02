#ifndef _SYS_UN_H
#define _SYS_UN_H

#include <sys/socket.h>

/* structure describing the address of an AF_UNIX socket */
struct sockaddr_un {
	sa_family_t sun_family;
	char sun_path[108];
};

/* evaluate to actual length of the 'sockaddr_un' structure */
#define SUN_LEN(ptr)	((size_t) (((struct sockaddr_un *) 0)->sun_path) + strlen ((ptr)->sun_path))

#endif /* _SYS_UN_H */
