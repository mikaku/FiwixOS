#ifndef _SYS_MSG_H
#define _SYS_MSG_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/ipc.h>

#define MSG_NOERROR	010000		/* no error if message is too big */

#define MSG_STAT	11
#define MSG_INFO	12

struct msqid_ds {
	struct ipc_perm msg_perm;	/* access permissions */
	struct msg *msg_first;		/* ptr to the first message in queue */
	struct msg *msg_last;		/* ptr to the last message in queue */
	__time_t msg_stime;		/* time of the last msgsnd() */
	__time_t msg_rtime;		/* time of the last msgrcv() */
	__time_t msg_ctime;		/* time of the last change time */
	unsigned int unused1;
	unsigned int unused2;
	unsigned short int msg_cbytes;	/* number of bytes in queue */
	unsigned short int msg_qnum;	/* number of messages in queue */
	unsigned short int msg_qbytes;	/* max. number of bytes in queue */
	unsigned short int msg_lspid;	/* PID of last msgsnd() */
	unsigned short int msg_lrpid;	/* PID of last msgrcv() */
};

/* buffer for msgctl() with IPC_INFO and MSG_INFO commands */
struct msginfo {
	int msgpool;
	int msgmap;
	int msgmax;			/* MSGMAX */
	int msgmnb;			/* MSGMNB */
	int msgmni;			/* MSGMNI */
	int msgssz;
	int msgtql;			/* MSGTQL */
	unsigned short int msgseg;
};

extern int msgsnd(int, const void *, size_t, int);
extern ssize_t msgrcv(int, void *, size_t, int, int);
extern int msgget(key_t, int);
extern int msgctl(int, int, struct msqid_ds *);

#ifdef __cplusplus
}
#endif

#endif /* _SYS_MSG_H */
