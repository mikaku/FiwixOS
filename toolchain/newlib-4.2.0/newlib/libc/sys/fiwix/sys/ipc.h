#ifndef _SYS_IPC_H
#define _SYS_IPC_H

#include <sys/types.h>

#define IPC_CREAT	01000		/* create if key doesn't exist */
#define IPC_EXCL	02000		/* fail if key exists */
#define IPC_NOWAIT	04000		/* return error on wait */

#define IPC_PRIVATE	((key_t)0)	/* private key */

#define IPC_RMID	0		/* remove identifier */
#define IPC_SET		1		/* set options */
#define IPC_STAT	2		/* get options */
#define IPC_INFO	3		/* get system-wide limits */

#define SEMOP		1
#define SEMGET		2
#define SEMCTL		3
#define MSGSND		11
#define MSGRCV		12
#define MSGGET		13
#define MSGCTL		14
#define SHMAT		21
#define SHMDT		22
#define SHMGET		23
#define SHMCTL		24

/* IPC data structure */
struct ipc_perm {
	key_t key;			/* key */
	__uid_t uid;			/* effective UID of owner */
	__gid_t gid;			/* effective UID of owner */
	__uid_t cuid;			/* effective UID of creator */
	__gid_t cgid;			/* effective UID of creator */
	unsigned short int mode;	/* access modes */
	unsigned short int seq;		/* slot sequence number */
};

#endif /* _SYS_IPC_H */
