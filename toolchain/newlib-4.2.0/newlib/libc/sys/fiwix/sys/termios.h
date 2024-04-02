#ifndef _SYS_TERMIOS_H
#define _SYS_TERMIOS_H

#include <sys/types.h>
#include <machine/termbits.h>
#include <machine/termios.h>

#define NCCS 19

/* Terminal control structure.  */
struct termios {
	tcflag_t c_iflag;	/* Input mode flags */
	tcflag_t c_oflag;	/* Output mode flags */
	tcflag_t c_cflag;	/* Control mode flags */
	tcflag_t c_lflag;	/* Local mode flags */
	cc_t c_line;		/* Line discipline */
	cc_t c_cc[NCCS];	/* Control characters */
};

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

#endif /* _SYS_TERMIOS_H */
