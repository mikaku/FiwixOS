/* libc/sys/linux/sys/utmp.h - utmp structure */

/* Written 2000 by Werner Almesberger */


/* Some things copied from glibc's /usr/include/bits/utmp.h */


#ifndef _SYS_UTMP_H
#define _SYS_UTMP_H


#include <paths.h>
#include <sys/types.h>
#include <sys/time.h>


/* compatibility names for the strings of the canonical file names */
#define UTMP_FILE	_PATH_UTMP
#define WTMP_FILE	_PATH_WTMP

#define UT_LINESIZE	32
#define UT_NAMESIZE	32
#define UT_HOSTSIZE	256

/*
 * The structure describing the status of a terminated process.
 * This type is used in `struct utmp' below.
 */
struct exit_status {
	short int e_termination;	/* Process termination status.  */
	short int e_exit;		/* Process exit status.  */
};

struct utmp {
    short int ut_type;
    pid_t ut_pid;
    char ut_line[UT_LINESIZE];
    char ut_id[4];
    char ut_user[UT_NAMESIZE];
    char ut_host[UT_HOSTSIZE];
    struct exit_status ut_exit;	/* Exit status of a process marked
    				   as DEAD_PROCESS.  */
    struct timeval ut_tv;		/* Time entry was made.  */
    char __filler[44];
};

/* Backwards compatibility hacks.  */
#define ut_name		ut_user
#define ut_time		ut_tv.tv_sec


#define RUN_LVL		1
#define BOOT_TIME	2
#define NEW_TIME	3
#define OLD_TIME	4

#define INIT_PROCESS	5
#define LOGIN_PROCESS	6
#define USER_PROCESS	7
#define DEAD_PROCESS	8


/* --- redundant, from sys/cygwin/sys/utmp.h --- */

struct utmp *_getutline (struct utmp *);
struct utmp *getutent (void);
struct utmp *getutid (struct utmp *);
struct utmp *getutline (struct utmp *);
void endutent (void);
void pututline (struct utmp *);
void setutent (void);
void utmpname (const char *);
int updwtmp(char *, struct utmp *);

#endif /* _SYS_UTMP_H */
