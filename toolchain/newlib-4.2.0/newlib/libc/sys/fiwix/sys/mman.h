#ifndef MMAN_H
#define MMAN_H

#ifdef __cplusplus
extern "C" {
#endif

#define PROT_READ	0x1		/* page can be read */
#define PROT_WRITE	0x2		/* page can be written */
#define PROT_EXEC	0x4		/* page can be executed */
#define PROT_NONE	0x0		/* page cannot be accessed */

#define MAP_SHARED	0x01		/* share changes */
#define MAP_PRIVATE	0x02		/* changes are private */
#define MAP_TYPE	0x0f		/* mask for type of mapping */
#define MAP_FIXED	0x10		/* interpret address exactly */
#define MAP_ANONYMOUS	0x20		/* don't use the file descriptor */

#define MAP_GROWSDOWN	0x0100		/* stack-like segment */
#define MAP_DENYWRITE	0x0800		/* -ETXTBSY */
#define MAP_EXECUTABLE	0x1000		/* mark it as a executable */
#define MAP_LOCKED	0x2000		/* pages are locked */

#define ZERO_PAGE	0x80000000	/* this page must be zero-filled */

#define MS_ASYNC	1		/* sync memory asynchronously */
#define MS_INVALIDATE	2		/* invalidate the caches */
#define MS_SYNC		4		/* synchronous memory sync */

#define MCL_CURRENT	1		/* lock all current mappings */
#define MCL_FUTURE	2		/* lock all future mappings */

/* compatibility flags */
#define MAP_ANON	MAP_ANONYMOUS
#define MAP_FILE	0

/* Return value of `mmap' in case of an error.  */
#if !defined(MAP_FAILED)
#define MAP_FAILED	((void *) -1)
#endif

struct mmap {
	unsigned int start;
	unsigned int length;
	unsigned int prot;
	unsigned int flags;
	int fd;
	unsigned int offset;
};

extern void *mmap (void *__addr, size_t __len, int __prot, int __flags, int __fd, __off_t __offset);
extern int munmap (void *__addr, size_t __len);
extern int mprotect (void *__addr, size_t __len, int __prot);

extern void *mmap2(void *__addr, size_t __len, int __prot, int __flags, int __fd, __off_t __offset);

#ifdef __cplusplus
}
#endif

#endif /* MMAN_H */
