/*
 * fiwix/termios.c
 *
 * Copyright 2018-2020, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/termios.h>
#include <sys/ioctl.h>
#include <paths.h>

static char __ctty[] = _PATH_TTY;

#ifdef __cplusplus
extern "C" {
#endif

/*
int tcgetattr(int, struct termios *);
int tcsetattr(int, int, const struct termios *);
pid_t tcgetpgrp(int);
int tcsetpgrp(int, pid_t);
int tcflow(int, int);
int tcflush(int, int);
void cfmakeraw(struct termios *);
int tcdrain(int);
char *ctermid(char *);
int tcsendbreak(int, int);
*/


int tcgetattr(int fd, struct termios *termios)
{
	return ioctl(fd, TCGETS, termios);
}

int tcsetattr(int fd, int optional_actions, const struct termios *termios)
{
	int cmd;

	switch(optional_actions) {
		case TCSANOW:
			cmd = TCSETS;
			break;
		case TCSADRAIN:
			cmd = TCSETSW;
			break;
		case TCSAFLUSH:
			cmd = TCSETSF;
			break;
		default:
			errno = EINVAL;
			return -1;
	}
	return ioctl(fd, cmd, termios);
}

pid_t tcgetpgrp(int fd)
{
	int p;
    
	if(ioctl(fd, TIOCGPGRP, &p) < 0) {
		return (pid_t)-1;
	}
	return (pid_t)p;
}


int tcsetpgrp(int fd, pid_t pid)
{
	int p;
	
	p = (int)pid;
	return ioctl(fd, TIOCSPGRP, &p);
}

int tcflow(int fd, int action)
{
	return ioctl(fd, TCXONC, action);
}

int tcflush(int fd, int queue_selector)
{
	return ioctl(fd, TCFLSH, queue_selector);
}

/* this function is part of the GNU C Library */
void cfmakeraw(struct termios *t)
{
	t->c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL|IXON);
	t->c_oflag &= ~OPOST;
	t->c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
	t->c_cflag &= ~(CSIZE|PARENB);
	t->c_cflag |= CS8;
	t->c_cc[VMIN] = 1;		/* read returns when one char is available */
	t->c_cc[VTIME] = 0;
}

int tcdrain(int fd)
{
	return ioctl(fd, TCSBRK, 1);
}

char *ctermid(char *s)
{
	if(!s) {
		return __ctty;
	}

	return strcpy(s, _PATH_TTY);
}

int tcsendbreak(int fd, int duration)
{
	if(duration <=0) {
		return ioctl(fd, TCSBRK, 0);
	}

	errno = (EINVAL);
	return -1;
}

#ifdef __cplusplus
}
#endif
