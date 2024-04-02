#ifndef	_ERR_H
#define	_ERR_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern char *__progname;

void __generic_err(const char *format, va_list args)
{
	fprintf(stderr, "%s: ", __progname);
	if(format) {
		vfprintf(stderr, format, args);
	}
	perror(" ");
	fprintf(stderr, "\n");
}

void __generic_errx(const char *format, va_list args)
{
	fprintf(stderr, "%s: ", __progname);
	if(format) {
		vfprintf(stderr, format, args);
	}
	fprintf(stderr, "\n");
}


/* print "program: ", *format, ": ", and the errno string */
void err(int eval, const char *format, ...)
{
	va_list args;

	va_start(args, format);
	__generic_err(format, args);
	va_end(args);
	exit(eval);	/* do not return */
}

void warn(const char *format, ...)
{
	va_list args;

	va_start(args, format);
	__generic_err(format, args);
	va_end(args);
}

void verr(int eval, const char *format, va_list args)
{
	__generic_err(format, args);
	exit(eval);	/* do not return */
}

void vwarn(const char *format, va_list args)
{
	__generic_err(format, args);
}


/* likewise, but without ": " and without the errno string */
void errx(int eval, const char *format, ...)
{
	va_list args;

	va_start(args, format);
	__generic_errx(format, args);
	va_end(args);
	exit(eval);	/* do not return */
}

void warnx(const char *format, ...)
{
	va_list args;

	va_start(args, format);
	__generic_errx(format, args);
	va_end(args);
}

void verrx(int eval, const char *format, va_list args)
{
	__generic_errx(format, args);
	exit(eval);	/* do not return */
}

void vwarnx(const char *format, va_list args)
{
	__generic_errx(format, args);
}

#endif /* _ERR_H */
