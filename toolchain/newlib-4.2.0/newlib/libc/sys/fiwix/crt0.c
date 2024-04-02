/*
 * fiwix/crt0.c
 *
 * Copyright 2018-2020, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <fcntl.h>
 
extern char **environ;
extern char **__argv;
extern char *__progname;

extern void exit(int);
extern int main(int argc, char *argv[], char *envp[]);
 
void _start(int esp)
{
	int *p;
	int argc;
	char **argv;
	int retval;

	p = &esp;
	argc = *(--p);
	argv = (char **)(++p);

	/* helpers for getprogname() */
	__argv = argv;
	__progname = argv[0];

	p += argc;
	environ = (char **)(++p);

	/* run the global constructors */
	_init();

	retval = main(argc, argv, environ);
	exit(retval);
}
