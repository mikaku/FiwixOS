#ifndef _FIWIX_SHM_H
#define _FIWIX_SHM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/ipc.h>

#define	SHM_RDONLY	010000		/* attach a read-only segment */
#define	SHM_RND		020000		/* round attach address to SHMLBA */
#define	SHM_REMAP	040000		/* take-over region on attach */

/* super user shmctl commands */
#define SHM_LOCK 	11
#define SHM_UNLOCK 	12

#define SHM_STAT 	13
#define SHM_INFO 	14

struct shmid_ds {
	struct ipc_perm shm_perm;	/* access permissions */
	__size_t shm_segsz;		/* size of segment (in bytes) */
	__time_t shm_atime;		/* time of the last shmat() */
	__time_t shm_dtime;		/* time of the last shmdt() */
	__time_t shm_ctime;		/* time of the last change time */
	unsigned short shm_cpid;	/* pid of creator */
	unsigned short shm_lpid;	/* pid of last shmop */
	unsigned short shm_nattch;	/* num. of current attaches */
	unsigned short shm_unused1;
	void *shm_unused2;
	void *shm_unused3;
};

struct shminfo {
	int shmmax;
	int shmmin;
	int shmmni;
	int shmseg;
	int shmall;
};

struct shm_info {
	int used_ids;
	unsigned int shm_tot;	/* total allocated shm */
	unsigned int shm_rss;	/* total resident shm */
	unsigned int shm_swp;	/* total swapped shm */
	unsigned int swap_attempts;
	unsigned int swap_successes;
};

extern void *shmat(int, const void *, int);
extern int shmdt(const void *);
extern int shmget(key_t, __size_t, int);
extern int shmctl(int, int, struct shmid_ds *);

#ifdef __cplusplus
}
#endif

#endif /* _FIWIX_SHM_H */
