#ifndef _SYS_DIRENT_H
#define _SYS_DIRENT_H

#include <sys/types.h>

struct dirent {
	ino_t d_ino;			/* inode number */
	off_t d_off;			/* offset to next dirent */
	unsigned short int d_reclen;	/* length of this dirent */
	char d_name[255 + 1];		/* file name (null-terminated) */
};

typedef struct {
    int dd_fd;		/* directory file */
    int dd_loc;		/* position in buffer */
    int dd_seek;
    char *dd_buf;	/* buffer */
    int dd_len;		/* buffer length */
    int dd_size;	/* amount of data in buffer */
} DIR;

#ifdef __LARGE64_FILES
struct dirent64 {
	__ino64_t d_ino;		/* inode number */
	_loff_t d_off;			/* offset to next dirent */
	unsigned short d_reclen;	/* length of this dirent */
	unsigned char d_type;		/* file type */
	char d_name[];			/* file name (null-terminated) */
};

/*
 * Fiwix don't supports 'd_type' in dirent structure and it seems
 * that DT_UNKNOWN forces to have this element.
 *
#define DT_UNKNOWN 0
 */

#define DT_FIFO 1
#define DT_CHR 2
#define DT_DIR 4
#define DT_BLK 6
#define DT_REG 8
#define DT_LNK 10
#define DT_SOCK 12
#define DT_WHT 14

ssize_t getdents64 (unsigned int, struct dirent64 *, unsigned int);
#endif /* __LARGE64_FILES */

#define __dirfd(dir) (dir)->dd_fd

/* --- redundant ---

DIR *opendir(const char *);
struct dirent *readdir(DIR *);
int readdir_r(DIR *__restrict, struct dirent *__restrict,
              struct dirent **__restrict);
void rewinddir(DIR *);
int closedir(DIR *);
*/

/* internal prototype */
void _seekdir(DIR *dir, long offset);
DIR *_opendir(const char *);

#ifndef _POSIX_SOURCE
long telldir (DIR *);
void seekdir (DIR *, off_t loc);

int scandir (const char *__dir,
             struct dirent ***__namelist,
             int (*select) (const struct dirent *),
             int (*compar) (const struct dirent **, const struct dirent **));

int alphasort (const struct dirent **__a, const struct dirent **__b);
#endif /* _POSIX_SOURCE */

#endif /* _SYS_DIRENT_H */
