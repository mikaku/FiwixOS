/*
 * fiwix/syscalls.c
 *
 * Copyright 2018-2022, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <sys/errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <sys/times.h>
#include <sys/time.h>
#include <sys/timeb.h>
#include <sys/resource.h>
#include <sys/mman.h>
#include <sys/dirent.h>
#include <sys/ustat.h>
#include <sys/utime.h>
#include <sys/utsname.h>
#include <sys/statfs.h>
#include <sys/select.h>
#include <sys/sysinfo.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <signal.h>
#include <stdio.h>
 
#include "syscalls.h"
#include "sockops.h"

char **environ;
char **__argv;
char *__progname;

SYSCALL1(exit, retval, int);
SYSCALL0(fork, retval);
SYSCALL3(read, retval, int, void *, size_t);
SYSCALL3(write, retval, int, const void *, size_t);
SYSCALL3(open, retval, const char *, int, mode_t);
SYSCALL1(close, retval, int);
SYSCALL3(waitpid, retval, pid_t, int *, int);
SYSCALL2(creat, retval, const char *, mode_t);
SYSCALL2(link, retval, const char *, const char *);
SYSCALL1(unlink, retval, const char *);
SYSCALL3(execve, retval, const char *, const char **, const char **);
SYSCALL1(chdir, retval, const char *);
SYSCALL1(time, retval, time_t *);
SYSCALL3(mknod, retval, const char *, mode_t, dev_t);
SYSCALL2(chmod, retval, const char *, mode_t);
SYSCALL3(lchown, retval, const char *, uid_t, gid_t);
// unused (break)
SYSCALL2(oldstat, retval, const char *, struct old_stat *);
SYSCALL3(lseek, retval, int, off_t, int);
SYSCALL0(getpid, retval);
SYSCALL5(mount, retval, const char *, const char *, const char *, unsigned int, const void *);
SYSCALL1(umount, retval, const char *);
SYSCALL1(setuid, retval, uid_t);
SYSCALL0(getuid, retval);
SYSCALL1(stime, retval, time_t *);
// unused (ptrace)
SYSCALL1(alarm, retval, int);
SYSCALL2(oldfstat, retval, int, struct old_stat *);
SYSCALL0(pause, retval);
SYSCALL2(utime, retval, const char *, const struct utimbuf *);
// unused (stty)
// unused (gtty)
SYSCALL2(access, retval, const char *, int);
// nice
SYSCALL1(ftime, retval, struct timeb *);
SYSCALL0(sync, retval);
SYSCALL2(kill, retval, int, int);
SYSCALL2(rename, retval, const char *, const char *);
SYSCALL2(mkdir, retval, const char *, mode_t);
SYSCALL1(rmdir, retval, const char *);
SYSCALL1(dup,retval, unsigned int);
SYSCALL1(pipe, retval, int *);
SYSCALL1(times, retval, struct tms *);
// unused (prof)
SYSCALL1(brk, retval, unsigned int);
SYSCALL1(setgid, retval, gid_t);
SYSCALL0(getgid, retval);
SYSCALL2(signal, retval, int, __sighandler_t);
SYSCALL0(geteuid, retval);
SYSCALL0(getegid, retval);
// acct
SYSCALL2(umount2, retval, const char *, int);
// unused (lock)
SYSCALL3(ioctl, retval, unsigned int, int, unsigned int);
SYSCALL3(fcntl, retval, int, int, unsigned int);
// unused (mpx)
SYSCALL2(setpgid, retval, pid_t, pid_t);
// unused (ulimit)
SYSCALL1(olduname, retval, struct oldold_utsname *);
SYSCALL1(umask, retval, mode_t);
SYSCALL1(chroot, retval, const char *);
SYSCALL2(ustat, retval, dev_t, struct ustat *);
SYSCALL2(dup2, retval, unsigned int, unsigned int);
SYSCALL0(getppid, retval);
SYSCALL0(getpgrp, retval);
SYSCALL0(setsid, retval);
SYSCALL3(sigaction, retval, int, const struct sigaction *, struct sigaction *);
SYSCALL0(sgetmask, retval);
SYSCALL1(ssetmask, retval, unsigned int);
SYSCALL2(setreuid, retval, uid_t, uid_t);
SYSCALL2(setregid, retval, gid_t, gid_t);
SYSCALL1(sigsuspend, retval, const sigset_t *);
SYSCALL1(sigpending, retval, sigset_t *);
SYSCALL2(sethostname, retval, const char *, size_t);
SYSCALL2(setrlimit, retval, int, const struct rlimit *);
SYSCALL2(getrlimit, retval, int, struct rlimit *);
SYSCALL2(getrusage, retval, int, struct rusage *);
SYSCALL2(gettimeofday, retval, struct timeval *, struct timezone *);
SYSCALL2(settimeofday, retval, const struct timeval *, const struct timezone *);
SYSCALL2(getgroups, retval, int, gid_t *);
SYSCALL2(setgroups, retval, size_t, const gid_t *);
SYSCALL1(oldselect, retval, int *);
SYSCALL2(symlink, retval, const char *, const char *);
SYSCALL2(oldlstat, retval, const char *, struct old_stat *);
SYSCALL3(readlink, retval, const char *, char *, size_t);
// uselib
// swapon
SYSCALL3(reboot, retval, int, int, int);
// old_readdir
SYSCALL1(old_mmap, retval, struct mmap *);
SYSCALL2(munmap, retval, void *, size_t);
SYSCALL2(truncate, retval, const char *, off_t);
SYSCALL2(ftruncate, retval, int, off_t);
SYSCALL2(fchmod, retval, int, mode_t);
SYSCALL3(fchown, retval, int, uid_t, gid_t);
// getpriority
// setpriority
SYSCALL2(statfs, retval, const char *, struct statfs *);
SYSCALL2(fstatfs, retval, int, struct statfs *);
SYSCALL3(ioperm, retval, unsigned int, unsigned int, int);
SYSCALL2(socketcall, retval, int, unsigned int *);
// syslog
SYSCALL3(setitimer, retval, int, const struct itimerval *, struct itimerval *);
SYSCALL2(getitimer, retval, int, struct itimerval *);
SYSCALL2(newstat, retval, const char *, struct stat *);
SYSCALL2(newlstat, retval, const char *, struct stat *);
SYSCALL2(newfstat, retval, int, struct stat *);
SYSCALL1(uname, retval, struct old_utsname *);
SYSCALL1(iopl, retval, int);
// vhangup
// unused (idle)
// vm86old
SYSCALL4(wait4, retval, pid_t, int *, int, struct rusage *);
// swapoff
SYSCALL1(sysinfo, retval, struct sysinfo *);
SYSCALL2(ipc, retval, unsigned int, struct sysvipc_args *);
SYSCALL1(fsync, retval, int);
SYSCALL1(sigreturn, retval, int);
// clone
SYSCALL2(setdomainname, retval, const char *, size_t);
SYSCALL1(newuname, retval, struct utsname *);
// modify_ldt
// adjtimex
SYSCALL3(mprotect, retval, void *, size_t, int);
SYSCALL3(sigprocmask, retval, int, const sigset_t *, sigset_t *);
// create_module
// init_module
// delete_module
// get_kernel_syms
// quotactl
SYSCALL1(getpgid, retval, pid_t);
SYSCALL1(fchdir, retval, int);
// bdflush
// sysfs
SYSCALL1(personality, retval, int);
// afs
// setfsuid
// setfsgid
SYSCALL5(llseek, retval, int, off_t, off_t, __loff_t *, unsigned int);
SYSCALL3(getdents, retval, unsigned int, struct dirent *, unsigned int);
SYSCALL5(select, retval, int, fd_set *, fd_set *, fd_set *, struct timeval *);
SYSCALL2(flock, retval, int, int);
SYSCALL3(readv, retval, int, const struct iovec *, int);
SYSCALL3(writev, retval, int, const struct iovec *, int);
SYSCALL1(getsid, retval, pid_t);
SYSCALL1(fdatasync, retval, int);
// sysctl
// mlock
// munlock
// mlockall
// munlockall
//
// ...
SYSCALL2(nanosleep, retval, const struct timespec *, struct timespec *);
//
// ...
SYSCALL3(chown, retval, const char *, uid_t, gid_t);
SYSCALL2(getcwd, retval, char *, size_t);
//
// ...
SYSCALL0(vfork, retval);
//
SYSCALL6(mmap2, retval, unsigned int, unsigned int, unsigned int, unsigned int, int, unsigned int);
SYSCALL3(truncate64, retval, const char *, off_t, off_t);
SYSCALL3(ftruncate64, retval, unsigned int, off_t, off_t);
SYSCALL2(stat64, retval, const char *, struct stat64 *);
SYSCALL2(lstat64, retval, const char *, struct stat64 *);
SYSCALL2(fstat64, retval, unsigned int, struct stat64 *);
//
// ...
SYSCALL3(chown32, retval, const char *, unsigned int, unsigned int);
//
#ifdef __LARGE64_FILES
SYSCALL3(getdents64, retval, unsigned int, struct dirent64 *, unsigned int);
#endif /* __LARGE64_FILES */
SYSCALL3(fcntl64, retval, unsigned int, int, unsigned int);
//
SYSCALL2(utimes, retval, const char *, const struct timeval *);


void _exit(int status)
{
	__sys_exit(status);
	for(;;);
}

int fork(void)
{
	return __sys_fork();
}

int read(int fd, void *buf, size_t count)
{
	return __sys_read(fd, buf, count);
}

int write(int fd, const void *buf, size_t count)
{
	return __sys_write(fd, buf, count);
}

int __open(const char *pathname, int flags, mode_t mode)
{
	return __sys_open(pathname, flags, mode);
}

int close(int fd)
{
	return __sys_close(fd);
}

int waitpid(pid_t pid, int *status, int options)
{
	return __sys_waitpid(pid, status, options);
}

/*
int creat(const char *pathname, mode_t mode)
{
	return __sys_creat(pathname, mode);
}
*/

int link(const char *oldpath, const char *newpath)
{
	return __sys_link(oldpath, newpath);
}

int unlink(const char *pathname)
{
	return __sys_unlink(pathname);
}

int _execve(const char *name, const char **argv, const char **envp)
{
	return __sys_execve(name, argv, envp);
}

int chdir(const char *path)
{
	return __sys_chdir(path);
}

int mknod(const char *pathname, mode_t mode, dev_t dev)
{
	return __sys_mknod(pathname, mode, dev);
}

int chmod(const char *path, mode_t mode)
{
	return __sys_chmod(path, mode);
}

int lchown(const char *path, uid_t owner, gid_t group)
{
	return __sys_lchown(path, owner, group);
}

int old_stat(const char *path, struct old_stat *buf)
{
	return __sys_oldstat(path, buf);
}

int lseek(int fd, off_t offset, int whence)
{
	return __sys_lseek(fd, offset, whence);
}

int getpid(void)
{
	return __sys_getpid();
}

int mount(const char *source, const char *target, const char *fstype, unsigned int flags, const void *data)
{
	return __sys_mount(source, target, fstype, flags, data);
}

int umount(const char *target)
{
	return __sys_umount(target);
}

int setuid(uid_t uid)
{
	return __sys_setuid(uid);
}

uid_t getuid(void)
{
	return __sys_getuid();
}

int stime(time_t *t)
{
	return __sys_stime(t);
}

int alarm(unsigned int seconds)
{
	return __sys_alarm(seconds);
}

int old_fstat(int fd, struct old_stat *buf)
{
	return __sys_oldfstat(fd, buf);
}

int pause(void)
{
	return __sys_pause();
}

int utime(const char *filename, const struct utimbuf *times)
{
	return __sys_utime(filename, times);
}

int access(const char *pathname, int mode)
{
	return __sys_access(pathname, mode);
}

int ftime(struct timeb *tp)
{
	return __sys_ftime(tp);
}

void sync(void)
{
	return (void)__sys_sync();
}

int kill(int pid, int signal)
{
	return __sys_kill(pid, signal);
}

int __rename(const char *old, const char *new)
{
	return __sys_rename(old, new);
}

int mkdir(const char *pathname, mode_t mode)
{
	return __sys_mkdir(pathname, mode);
}

int rmdir(const char *pathname)
{
	return __sys_rmdir(pathname);
}

int dup(unsigned int oldfd)
{
	return __sys_dup(oldfd);
}

int pipe(int *pipefd)
{
	return __sys_pipe(pipefd);
}

clock_t times(struct tms *buf)
{
	return __sys_times(buf);
}

int __brk(void *addr)
{
	return __sys_brk((unsigned int)addr);
}

int setgid(gid_t gid)
{
	return __sys_setgid(gid);
}

gid_t getgid(void)
{
	return __sys_getgid();
}

__sighandler_t signal(int signum, __sighandler_t sighandler)
{
	return (__sighandler_t)__sys_signal(signum, sighandler);
}

uid_t geteuid(void)
{
	return __sys_geteuid();
}

gid_t getegid(void)
{
	return __sys_getegid();
}

int umount2(const char *target, int flags)
{
	return __sys_umount2(target, flags);
}

int ioctl(unsigned int fd, int cmd, unsigned int arg)
{
	return __sys_ioctl(fd, cmd, arg);
}

int __fcntl(int fd, int cmd, unsigned int arg)
{
	return __sys_fcntl(fd, cmd, arg);
}

int setpgid(pid_t pid, pid_t pgid)
{
	return __sys_setpgid(pid, pgid);
}

int oldold_uname(struct oldold_utsname *buf)
{
	return __sys_olduname(buf);
}

mode_t umask(mode_t mask)
{
	return __sys_umask(mask);
}

int chroot(const char *path)
{
	return __sys_chroot(path);
}

int ustat(dev_t dev, struct ustat *ubuf)
{
	return __sys_ustat(dev, ubuf);
}

int dup2(unsigned int oldfd, unsigned int newfd)
{
	return __sys_dup2(oldfd, newfd);
}

int getppid(void)
{
	return __sys_getppid();
}

int getpgrp(void)
{
	return __sys_getpgrp();
}

pid_t setsid(void)
{
	return __sys_setsid();
}

int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
	return __sys_sigaction(signum, act, oldact);
}

int sgetmask(void)
{
	return __sys_sgetmask();
}

int ssetmask(unsigned int newmask)
{
	return __sys_ssetmask(newmask);
}

int setreuid(uid_t ruid, uid_t euid)
{
	return __sys_setreuid(ruid, euid);
}

int setregid(gid_t rgid, gid_t egid)
{
	return __sys_setregid(rgid, egid);
}

int sigsuspend(const sigset_t *mask)
{
	return __sys_sigsuspend(mask);
}

int sigpending(sigset_t *set)
{
	return __sys_sigpending(set);
}

int sethostname(const char *name, size_t len)
{
	return __sys_sethostname(name, len);
}

int setrlimit(int resource, const struct rlimit *rlim)
{
	return __sys_setrlimit(resource, rlim);
}

int getrlimit(int resource, struct rlimit *rlim)
{
	return __sys_getrlimit(resource, rlim);
}

int getrusage(int who, struct rusage *usage)
{
	return __sys_getrusage(who, usage);
}

int gettimeofday(struct timeval *tv, void *tz)
{
	return __sys_gettimeofday(tv, (struct timezone *)tz);
}

int settimeofday(const struct timeval *tv, const struct timezone *tz)
{
	return __sys_settimeofday(tv, tz);
}

int getgroups(int size, gid_t *list)
{
	return __sys_getgroups(size, list);
}

int setgroups(int size, const gid_t *list)
{
	return __sys_setgroups(size, list);
}

int old_select(int *params)
{
	return __sys_oldselect(params);
}

int symlink(const char *oldpath, const char *newpath)
{
	return __sys_symlink(oldpath, newpath);
}

int old_lstat(const char *path, struct old_stat *buf)
{
	return __sys_oldlstat(path, buf);
}

ssize_t readlink(const char *path, char *buf, size_t bufsiz)
{
	return __sys_readlink(path, buf, bufsiz);
}

int reboot(int magic1, int magic2, int cmd)
{
	return __sys_reboot(magic1, magic2, cmd);
}

int old_mmap(struct mmap *mmap)
{
	return __sys_old_mmap(mmap);
}

int munmap(void *addr, size_t length)
{
	return __sys_munmap(addr, length);
}

int truncate(const char *path, off_t length)
{
	return __sys_truncate(path, length);
}

int ftruncate(int fd, off_t length)
{
	return __sys_ftruncate(fd, length);
}

int fchmod(int fd, mode_t mode)
{
	return __sys_fchmod(fd, mode);
}

int fchown(int fd, uid_t owner, gid_t group)
{
	return __sys_fchown(fd, owner, group);
}

int statfs(const char *path, struct statfs *buf)
{
	return __sys_statfs(path, buf);
}

int fstatfs(int fd, struct statfs *buf)
{
	return __sys_fstatfs(fd, buf);
}

int ioperm(unsigned int from, unsigned int num, int turn_on)
{
	return __sys_ioperm(from, num, turn_on);
}

int socketcall(int call, unsigned int *args)
{
	return __sys_socketcall(call, args);
}

int socket(int domain, int type, int protocol)
{
	unsigned int args[3];

	args[0] = domain;
	args[1] = type;
	args[2] = protocol;

	return socketcall(SYS_SOCKET, &args[0]);
}

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
{
	unsigned int args[3];

	args[0] = sockfd;
	args[1] = (unsigned int)addr;
	args[2] = addrlen;

	return socketcall(SYS_BIND, &args[0]);
}

int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
{
	unsigned int args[3];

	args[0] = sockfd;
	args[1] = (unsigned int)addr;
	args[2] = addrlen;

	return socketcall(SYS_CONNECT, &args[0]);
}

int listen(int sockfd, int backlog)
{
	unsigned int args[2];

	args[0] = sockfd;
	args[1] = backlog;

	return socketcall(SYS_LISTEN, &args[0]);
}

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
{
	unsigned int args[3];

	args[0] = sockfd;
	args[1] = (unsigned int)addr;
	args[2] = (unsigned int)addrlen;

	return socketcall(SYS_ACCEPT, &args[0]);
}

int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
{
	unsigned int args[3];

	args[0] = sockfd;
	args[1] = (unsigned int)addr;
	args[2] = (unsigned int)addrlen;

	return socketcall(SYS_GETSOCKNAME, &args[0]);
}

int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
{
	unsigned int args[3];

	args[0] = sockfd;
	args[1] = (unsigned int)addr;
	args[2] = (unsigned int)addrlen;

	return socketcall(SYS_GETPEERNAME, &args[0]);
}

int socketpair(int domain, int type, int protocol, int sv[2])
{
	unsigned int args[4];

	args[0] = domain;
	args[1] = type;
	args[2] = protocol;
	args[3] = (unsigned int)&sv[0];

	return socketcall(SYS_SOCKETPAIR, &args[0]);
}

ssize_t send(int sockfd, const void *buf, size_t len, int flags)
{
	unsigned int args[4];

	args[0] = sockfd;
	args[1] = (unsigned int)buf;
	args[2] = len;
	args[3] = flags;

	return socketcall(SYS_SEND, &args[0]);
}

ssize_t recv(int sockfd, void *buf, size_t len, int flags)
{
	unsigned int args[4];

	args[0] = sockfd;
	args[1] = (unsigned int)buf;
	args[2] = len;
	args[3] = flags;

	return socketcall(SYS_RECV, &args[0]);
}

ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen)
{
	unsigned int args[6];

	args[0] = sockfd;
	args[1] = (unsigned int)buf;
	args[2] = len;
	args[3] = flags;
	args[4] = (unsigned int)dest_addr;
	args[5] = addrlen;

	return socketcall(SYS_SENDTO, &args[0]);
}

ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen)
{
	unsigned int args[6];

	args[0] = sockfd;
	args[1] = (unsigned int)buf;
	args[2] = len;
	args[3] = flags;
	args[4] = (unsigned int)src_addr;
	args[5] = (unsigned int)addrlen;

	return socketcall(SYS_RECVFROM, &args[0]);
}

int shutdown(int sockfd, int how)
{
	unsigned int args[2];

	args[0] = sockfd;
	args[1] = how;

	return socketcall(SYS_SHUTDOWN, &args[0]);
}

int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)
{
	unsigned int args[5];

	args[0] = sockfd;
	args[1] = level;
	args[2] = optname;
	args[3] = (unsigned int)optval;
	args[4] = optlen;

	return socketcall(SYS_SETSOCKOPT, &args[0]);
}

int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen)
{
	unsigned int args[5];

	args[0] = sockfd;
	args[1] = level;
	args[2] = optname;
	args[3] = (unsigned int)optval;
	args[4] = (unsigned int)optlen;

	return socketcall(SYS_GETSOCKOPT, &args[0]);
}

int setitimer(int which, const struct itimerval *new_value, struct itimerval *old_value)
{
	return __sys_setitimer(which, new_value, old_value);
}

int getitimer(int which, struct itimerval *curr_value)
{
	return __sys_getitimer(which, curr_value);
}

int stat(const char *path, struct stat *buf)
{
	return __sys_newstat(path, buf);
}

int lstat(const char *path, struct stat *st)
{
	return __sys_newlstat(path, st);
}

int fstat(int fd, struct stat *st)
{
	return __sys_newfstat(fd, st);
}

int old_uname(struct old_utsname *buf)
{
	return __sys_uname(buf);
}

int iopl(int level)
{
	return __sys_iopl(level);
}

int wait4(pid_t pid, int *status, int options, struct rusage *rusage)
{
	return __sys_wait4(pid, status, options, rusage);
}

int sysinfo(struct sysinfo *info)
{
	return __sys_sysinfo(info);
}

int ipc(unsigned int call, struct sysvipc_args *args)
{
	return __sys_ipc(call, args);
}

int fsync(int fd)
{
	return __sys_fsync(fd);
}

int sigreturn(int unused)
{
	return __sys_sigreturn(unused);
}

int setdomainname(const char *name, size_t len)
{
	return __sys_setdomainname(name, len);
}

int uname(struct utsname *buf)
{
	return __sys_newuname(buf);
}

int mprotect(void *addr, size_t len, int prot)
{
	return __sys_mprotect(addr, len, prot);
}

int sigprocmask(int how, const sigset_t *set, sigset_t *oldset)
{
	return __sys_sigprocmask(how, set, oldset);
}

int getpgid(pid_t pid)
{
	return __sys_getpgid(pid);
}

int fchdir(int fd)
{
	return __sys_fchdir(fd);
}

int personality(int persona)
{
	return __sys_personality(persona);
}

int llseek(int fd, off_t offset_high, off_t offset_low, __loff_t *result, unsigned int whence)
{
	return __sys_llseek(fd, offset_high, offset_low, result, whence);
}

int getdents(unsigned int fd, struct dirent *dirp, unsigned int count)
{
	return __sys_getdents(fd, dirp, count);
}

int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout)
{
	return __sys_select(nfds, readfds, writefds, exceptfds, timeout);
}

int flock(int fd, int operation)
{
	return __sys_flock(fd, operation);
}

ssize_t readv(int fd, const struct iovec *iov, int iovcnt)
{
	return __sys_readv(fd, iov, iovcnt);
}

ssize_t writev(int fd, const struct iovec *iov, int iovcnt)
{
	return __sys_writev(fd, iov, iovcnt);
}

int getsid(pid_t pid)
{
	return __sys_getsid(pid);
}

int fdatasync(int fd)
{
	return __sys_fdatasync(fd);
}

int nanosleep(const struct timespec *req, struct timespec *rem)
{
	return __sys_nanosleep(req, rem);
}

int chown(const char *path, uid_t owner, gid_t group)
{
	/* return __sys_chown(path, owner, group); */

	int __err;

	/*
	 * In Fiwix 1.5.0, the old sys_chown (#16) was renamed to
	 * sys_lchown, and the new sys_chown was moved to #182, breaking
	 * binary compatibility with Linux 2.0.
	 *
	 * The following keeps compatibility with Linux 2.0.
	 */
	__err = __sys_chown(path, owner, group);
	if(__err < 0 && errno == ENOSYS) {
		__err = __sys_lchown(path, owner, group);
	}

	return __err;
}

int vfork(void)
{
	return __sys_fork();
}

void *mmap2(void *addr, size_t len, int prot, int flags, int fd, off_t offset)
{
	return (void *)__sys_mmap2((unsigned int)addr, len, prot, flags, fd, offset);
}

int truncate64(const char *path, __loff_t length)
{
	unsigned int low, high;

	low = length & 0xFFFFFFFF;
	high = length >> 32;
	return __sys_truncate64(path, low, high);
}

int ftruncate64(unsigned int fd, __loff_t length)
{
	unsigned int low, high;

	low = length & 0xFFFFFFFF;
	high = length >> 32;
	return __sys_ftruncate64(fd, low, high);
}

int stat64(const char *path, struct stat64 *buf)
{
	return __sys_stat64(path, buf);
}

int lstat64(const char *path, struct stat64 *buf)
{
	return __sys_lstat64(path, buf);
}

int fstat64(unsigned int fd, struct stat64 *buf)
{
	return __sys_fstat64(fd, buf);
}

int chown32(const char *path, unsigned int owner, unsigned int group)
{
	return __sys_chown32(path, owner, group);
}

#ifdef __LARGE64_FILES
ssize_t getdents64(unsigned int fd, struct dirent64 *dirp, unsigned int count)
{
	return __sys_getdents64(fd, dirp, count);
}
#endif /* __LARGE64_FILES */

int fcntl64(unsigned int fd, int cmd, unsigned int arg)
{
	return __sys_fcntl64(fd, cmd, arg);
}

int utimes(const char *filename, const struct timeval times[2])
{
	return __sys_utimes(filename, times);
}
