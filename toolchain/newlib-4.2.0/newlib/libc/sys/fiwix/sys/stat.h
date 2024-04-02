#ifndef _SYS_STAT_H
#ifdef __cplusplus
extern "C" {
#endif
#define _SYS_STAT_H

#include <sys/types.h>

struct old_stat {
	unsigned short int st_dev;
	unsigned short int st_ino;
	unsigned short int st_mode;
	unsigned short int st_nlink;
	uid_t st_uid;
	gid_t st_gid;
	unsigned short int st_rdev;
	unsigned int st_size;
	time_t st_atime;
	time_t st_mtime;
	time_t st_ctime;
};

struct stat {
	unsigned short int st_dev;
	unsigned short int __pad1;
	unsigned int st_ino;
	unsigned short int st_mode;
	unsigned short int st_nlink;
	uid_t st_uid;
	gid_t st_gid;
	unsigned short int st_rdev;
	unsigned short int __pad2;
	unsigned int st_size;
	unsigned int st_blksize;
	unsigned int st_blocks;
	time_t st_atime;
	unsigned int __unused1;
	time_t st_mtime;
	unsigned int __unused2;
	time_t st_ctime;
	unsigned int __unused3;
	unsigned int __unused4;
	unsigned int __unused5;
};

/* 64bit structure for i386 */
struct stat64 {
	unsigned long long int st_dev;
	int __st_dev_padding;
	int __st_ino_truncated;
	unsigned int st_mode;
	unsigned int st_nlink;
	unsigned int st_uid;
	unsigned int st_gid;
	unsigned long long int st_rdev;
	int __st_rdev_padding;
	long long int st_size;
	int st_blksize;
	long long int st_blocks;
	int st_atime;
	int st_atime_nsec;
	int st_mtime;
	int st_mtime_nsec;
	int st_ctime;
	int st_ctime_nsec;
	unsigned long long int st_ino;
};

/* Encoding of the file mode.  These are the standard Unix values,
   but POSIX.1 does not specify what values should be used.  */

#define S_IFMT		0170000		/* Type of file mask */

/* File types.  */
#define S_IFIFO		0010000		/* Named pipe (fifo) */
#define S_IFCHR		0020000		/* Character special */
#define S_IFDIR		0040000		/* Directory */
#define S_IFBLK		0060000		/* Block special */
#define S_IFREG		0100000		/* Regular */
#define S_IFLNK		0120000		/* Symbolic link */
#define S_IFSOCK 	0140000		/* Socket */

/* Protection bits.  */
#define S_IXUSR		00100		/* USER   --x------ */
#define S_IWUSR		00200		/* USER   -w------- */
#define S_IRUSR		00400		/* USER   r-------- */
#define S_IRWXU		00700		/* USER   rwx------ */

#define S_IXGRP		00010		/* GROUP  -----x--- */
#define S_IWGRP		00020		/* GROUP  ----w---- */
#define S_IRGRP		00040		/* GROUP  ---r----- */
#define S_IRWXG		00070		/* GROUP  ---rwx--- */

#define S_IXOTH		00001		/* OTHERS --------x */
#define S_IWOTH		00002		/* OTHERS -------w- */
#define S_IROTH		00004		/* OTHERS ------r-- */
#define S_IRWXO		00007		/* OTHERS ------rwx */

#define S_ISUID		0004000		/* set user id on execution */
#define S_ISGID		0002000		/* set group id on execution */
#define S_ISVTX		0001000		/* sticky bit */

#define S_IREAD		S_IRUSR		/* Read by owner.  */
#define S_IWRITE	S_IWUSR		/* Write by owner.  */
#define S_IEXEC		S_IXUSR		/* Execute by owner.  */

#define S_ISFIFO(m)	(((m) & S_IFMT) == S_IFIFO)
#define S_ISCHR(m)	(((m) & S_IFMT) == S_IFCHR)
#define S_ISDIR(m)	(((m) & S_IFMT) == S_IFDIR)
#define S_ISBLK(m)	(((m) & S_IFMT) == S_IFBLK)
#define S_ISREG(m)	(((m) & S_IFMT) == S_IFREG)
#define S_ISLNK(m)	(((m) & S_IFMT) == S_IFLNK)
#define S_ISSOCK(m) 	(((m) & S_IFMT) == S_IFSOCK)

#define R_OK		4		/* test for read permission */
#define W_OK		2		/* test for write permission */
#define X_OK		1		/* test for execute permission */

int	fstat( int __fd, struct stat *__sbuf );
int	mkdir( const char *_path, mode_t __mode );
int	mkfifo( const char *__path, mode_t __mode );
int	stat( const char * __path, struct stat * __sbuf );
mode_t	umask( mode_t __mask );
int	lstat(const char * __path, struct stat * __buf);

/* 64bit functions for i386 */
int	stat64(const char *, struct stat64 *);
int	lstat64(const char *, struct stat64 *);
int	fstat64(unsigned int, struct stat64 *);

#ifdef __cplusplus
}
#endif
#endif /* _SYS_STAT_H */
