/*
 * fiwix/wrappers.c
 *
 * Copyright 2018-2022, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <errno.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/ustat.h>
#include <sys/utsname.h>
#include <unistd.h>

#include <fiwix/limits.h>

#if !defined(PAGE_SIZE)
#define PAGE_SIZE      4096
#endif

static void *curr_brk = NULL;

#ifdef __cplusplus
extern "C" {
#endif

inline int MIN(int a, int b)
{
	return (a < b ? a : b);
}

inline int MAX(int a, int b)
{
	return (a > b ? a : b); 
}

int open(const char *pathname, int flags, ...)
{
	va_list args;
	int mode, retval;

	va_start(args, flags);
	if(flags & O_CREAT) {
		mode = va_arg(args, int);
	}
	va_end(args);
	return __open(pathname, flags, mode);
}

#ifndef HAVE_NANOSLEEP
/* posix/sleep.c includes already the sleep() function */
unsigned int sleep(unsigned int seconds)
{
	struct timespec req, rem;
	int retval;

	req.tv_sec = seconds;
	req.tv_nsec = 0;
	if(!nanosleep(&req, &rem)) {
		retval = 0;
	} else {
		retval = -1;
	}
	if(errno == EINTR) {
		retval = rem.tv_sec;
	}
	return retval;
}
#endif

/* not needed, is in 'libc/posix/usleep.c'
int usleep(useconds_t usec)
{
	struct timespec req, rem;
	int retval;

	req.tv_sec = usec / 1000000;
	req.tv_nsec = (usec & 1000000) * 1000;
	if(!nanosleep(&req, &rem)) {
		retval = 0;
	} else {
		retval = -1;
	}
	if(errno == EINTR) {
		retval = rem.tv_sec;
	}
	return retval;
}
*/

int mkfifo(const char *pathname, mode_t mode)
{
	return mknod(pathname, mode | S_IFIFO, 0);
}

void *mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset)
{
	struct mmap mmap;

	mmap.start = (unsigned int)addr;
	mmap.length = len;
	mmap.prot = prot;
	mmap.flags = flags;
	mmap.fd = fd;
	mmap.offset = offset;

	return (void *)old_mmap(&mmap);
}

int brk(void *addr)
{
	void *new_brk;

	new_brk = (void *)__brk(addr);
	if(new_brk != addr) {
		errno = ENOMEM;
		return -1;
	}
	curr_brk = new_brk;
	return 0;
}

void *sbrk(ptrdiff_t increment)
{
	void *old_brk, *new_brk;

	if(!curr_brk) {
		curr_brk = (void *)__brk(NULL);
	}
	new_brk = (void *)__brk(curr_brk + increment);
	if(new_brk != (curr_brk + increment)) {
		errno = ENOMEM;
		return (void *)-1;
	}
	old_brk = curr_brk;
	curr_brk = new_brk;
	return old_brk;
}

int fcntl(int fd, int cmd, ...)
{
	va_list args;
	int arg;

	va_start(args, cmd);
	switch(cmd) {
		case F_DUPFD:
		case F_SETFD:
		case F_SETFL:
		case F_SETOWN:
		case F_GETLK:
		case F_SETLK:
			arg = va_arg(args, int);
			break;
		default:
			arg = 0;
			break;
	}
	va_end(args);
	return __fcntl(fd, cmd, arg);
}

pid_t wait(int *status)
{
	waitpid(-1, status, 0);
}

int sysconf(int name)
{
	switch(name) {
		case _SC_ARG_MAX:
#ifdef ARG_MAX
			return ARG_MAX * 4096;
#endif
			break;
		case _SC_CHILD_MAX:
#ifdef CHILD_MAX
			return CHILD_MAX;
#endif
			break;
		case _SC_OPEN_MAX:
#ifdef OPEN_MAX
			return OPEN_MAX;
#endif
			break;
		case _SC_PAGESIZE:
#ifdef PAGE_SIZE
			return PAGE_SIZE;
#endif
			break;
		default:
			errno = EINVAL;
			break;
	}
	return -1;
}

int getpagesize(void)
{
	return PAGE_SIZE;
}

dev_t makedev(unsigned int __major, unsigned int __minor)
{
	dev_t __dev;

	__dev = ((dev_t)__major << 8) & 0xFF00;
	__dev |= (dev_t)__minor & 0x00FF;
	return __dev;
}

int _rename(const char *old, const char *new)
{
	return __rename(old, new);
}

int seteuid(uid_t __uid)
{
	return setreuid(-1, __uid);
}

int setegid(gid_t __gid)
{
	return setregid(-1, __gid);
}

long fpathconf(int fd, int name)
{
	return -ENOSYS;
}
long pathconf(const char *path, int name)
{
	return -ENOSYS;
}

int gethostname(char *name, size_t len)
{
	struct utsname buf;
	size_t node_len;
	int errno;

	if((errno = uname(&buf))) {
		return errno;
	}

	node_len = strlen(buf.nodename) + 1;
	memcpy(name, buf.nodename, MIN(len, node_len));
	if(node_len > len) {
		return -ENAMETOOLONG;
	}
	return 0;
}

int sigmask(int signum)
{
	return 1 << signum;
}

int sigblock(int mask)
{
	return ssetmask(mask | sgetmask());
}

int sigsetmask(int newmask)
{
	ssetmask(newmask);
}

unsigned int htonl(unsigned int hostlong)
{
	unsigned char tmp[4];
	unsigned int result;

	tmp[0] = (unsigned char)((hostlong >> 24) & 0xFF);
	tmp[1] = (unsigned char)((hostlong >> 16) & 0xFF);
	tmp[2] = (unsigned char)((hostlong >> 8) & 0xFF);
	tmp[3] = (unsigned char)(hostlong & 0xFF);

	memcpy(&result, tmp, sizeof(tmp));
	return result;
}

unsigned int ntohl(unsigned int hostlong)
{
	return htonl(hostlong);
}
 
unsigned short htons(unsigned short hostshort)
{
	unsigned char tmp[2];
	unsigned short result;

	tmp[0] = (unsigned char)((hostshort >> 8) & 0xFF);
	tmp[1] = (unsigned char)(hostshort & 0xFF);

	memcpy(&result, tmp, sizeof(tmp));
	return result;
}

unsigned short ntohs(unsigned short hostshort)
{
	return htons(hostshort);
}

int issetugid(void)
{
	if(getuid() != geteuid()) {
		return 1;
	}

	if(getgid() != getegid()) {
		return 1;
	}
}

 
#ifdef __cplusplus
}
#endif
