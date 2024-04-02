#ifndef _SYS_TERMIO_H
#define _SYS_TERMIO_H

#include <machine/termbits.h>
#include <machine/termios.h>

#define NCC	8

struct termio {
	unsigned short int c_iflag;	/* input mode flags */
	unsigned short int c_oflag;	/* output mode flags */
	unsigned short int c_cflag;	/* control mode flags */
	unsigned short int c_lflag;	/* local mode flags */
	unsigned char c_line;		/* line discipline */
	unsigned char c_cc[NCC];	/* control characters */
};

#endif /* _SYS_TERMIO_H */
