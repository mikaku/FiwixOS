#ifndef _SYS_SOCKET_H
#define	_SYS_SOCKET_H

#include <sys/types.h>
#include <netdb.h>

typedef unsigned int socklen_t;
typedef unsigned short int sa_family_t;

/* address families */
#define	AF_UNSPEC	0		/* unspecified */
#define	AF_UNIX		1		/* UNIX domain socket */
#define	AF_LOCAL	AF_UNIX
#define	AF_FILE		AF_UNIX
#define	AF_INET		2		/* Internet: UDP, TCP, ... */

/* protocol families */
#define	PF_UNSPEC	AF_UNSPEC
#define	PF_UNIX		AF_UNIX
#define	PF_LOCAL	AF_UNIX
#define	PF_FILE		AF_UNIX
#define	PF_INET		AF_INET

/* types */
#define	SOCK_STREAM	1		/* stream socket */
#define	SOCK_DGRAM	2		/* datagram socket */

/* flags */
#define	SO_ACCEPTCONN	0x0002		/* socket has had listen() */
#define	SO_REUSEADDR	0x0004		/* allow local address reuse */


/* generic socket address structure */
struct sockaddr {
	sa_family_t sa_family;		/* address family: AF_xxx */
	char sa_data[14];		/* protocol specific address */
};

#define	SOCK_MAXADDRLEN	255		/* longest possible addresses */

/* maximum queue length specifiable by listen() */
#ifndef	SOMAXCONN
#define	SOMAXCONN	128
#endif

/*
 * Message header for recvmsg and sendmsg calls.
 * Used value-result for recvmsg, value only for sendmsg.
 */
struct msghdr {
	void		*msg_name;		/* optional address */
	socklen_t	 msg_namelen;		/* size of address */
	struct iovec	*msg_iov;		/* scatter/gather array */
	int		 msg_iovlen;		/* # elements in msg_iov */
	void		*msg_control;		/* ancillary data, see below */
	socklen_t	 msg_controllen;	/* ancillary data buffer len */
	int		 msg_flags;		/* flags on received message */
};

#define	MSG_PEEK	0x2		/* peek at incoming message */
#define	MSG_DONTWAIT	0x80		/* this message should be nonblocking */

/* arguments for shutdown(2) */
#define	SHUT_RD		0		/* shut down the reading side */
#define	SHUT_WR		1		/* shut down the writing side */
#define	SHUT_RDWR	2		/* shut down both sides */

__BEGIN_DECLS
int	socket(int, int, int);
int	bind(int, const struct sockaddr *, socklen_t);
int	connect(int, const struct sockaddr *, socklen_t);
int	listen(int, int);
int	accept(int, struct sockaddr *, socklen_t *);
int	getsockname(int, struct sockaddr *, socklen_t *);
int	getpeername(int, struct sockaddr *, socklen_t *);
int	socketpair(int, int, int, int *);
ssize_t	send(int, const void *, size_t, int);
ssize_t	recv(int, void *, size_t, int);
ssize_t	sendto(int, const void *, size_t, int, const struct sockaddr *, socklen_t);
ssize_t	recvfrom(int, void *, size_t, int, struct sockaddr *, socklen_t *);
int	shutdown(int, int);
int	setsockopt(int, int, int, const void *, socklen_t);
int	getsockopt(int, int, int, void *, socklen_t *);
__END_DECLS

#endif /* _SYS_SOCKET_H */
