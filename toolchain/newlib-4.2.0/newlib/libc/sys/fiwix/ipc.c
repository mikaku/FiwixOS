/*
 * fiwix/ipc.c
 *
 * Copyright 2022, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include "syscalls.h"

/*
 * The original version of the sys_ipc() system call in Linux 2.0 is:
 *
 * sys_ipc(uint call, int arg1, int arg2, int arg3, void *ptr, long arg5)
 *
 * That is a total of 6 arguments. Since the Fiwix kernel has a maximum
 * default number of 5 arguments per system call, we need to pack them
 * all into an structure to be able to pass them all up:
 *
 * struct sysvipc_args {
 *	int arg1;
 *	int arg2;
 *	int arg3;
 *	void *ptr;
 *	int arg5;
 * };
 */

int ipc(unsigned int, struct sysvipc_args *);

int semop(int semid, struct sembuf *sops, size_t nsops)
{
	struct sysvipc_args args;

	args.arg1 = semid;
	args.ptr = (void *)sops;
	args.arg2 = nsops;

	return ipc(SEMOP, &args);
}

int semget(key_t key, int nsems, int semflg)
{
	struct sysvipc_args args;

	args.arg1 = key;
	args.arg2 = nsems;
	args.arg3 = semflg;

	return ipc(SEMGET, &args);
}

int semctl(int semid, int semnum, int cmd, void *arg)
{
	struct sysvipc_args args;

	args.arg1 = semid;
	args.arg2 = semnum;
	args.arg3 = cmd;
	args.ptr = (void *)arg;

	return ipc(SEMCTL, &args);
}

int msgsnd(int msqid, const void *msgp, size_t msgsz, int msgflg)
{
	struct sysvipc_args args;

	args.arg1 = msqid;
	args.arg2 = (int)msgsz;
	args.arg3 = msgflg;
	args.ptr = (void *)msgp;

	return ipc(MSGSND, &args);
}

ssize_t msgrcv(int msqid, void *msgp, size_t msgsz, int msgtyp, int msgflg)
{
	struct sysvipc_args args;

	args.arg1 = msqid;
	args.arg2 = (int)msgsz;
	args.arg3 = msgtyp;
	args.ptr = msgp;
	args.arg5 = msgflg;

	return (ssize_t)ipc(MSGRCV, &args);
}

int msgget(key_t key, int msgflg)
{
	struct sysvipc_args args;

	args.arg1 = key;
	args.arg2 = msgflg;

	return ipc(MSGGET, &args);
}

int msgctl(int msqid, int cmd, struct msqid_ds *buf)
{
	struct sysvipc_args args;

	args.arg1 = msqid;
	args.arg2 = cmd;
	args.ptr = (void *)buf;

	return ipc(MSGCTL, &args);
}

void *shmat(int shmid, const void *shmaddr, int shmflg)
{
	struct sysvipc_args args;

	args.arg1 = shmid;
	args.ptr = (void *)shmaddr;
	args.arg2 = shmflg;

	return ipc(SHMAT, &args);
}

int shmdt(const void *shmaddr)
{
	struct sysvipc_args args;

	args.ptr = (void *)shmaddr;

	return ipc(SHMDT, &args);
}

int shmget(key_t key, size_t size, int shmflg)
{
	struct sysvipc_args args;

	args.arg1 = key;
	args.arg2 = size;
	args.arg3 = shmflg;

	return ipc(SHMGET, &args);
}

int shmctl(int shmid, int cmd, struct shmid_ds *buf)
{
	struct sysvipc_args args;

	args.arg1 = shmid;
	args.arg2 = cmd;
	args.ptr = (void *)buf;

	return ipc(SHMCTL, &args);
}
