/*
 * fiwix/usershell.c
 *
 * Copyright 2020, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <stdio.h>
#include <paths.h>

static const char _defshells[] = "/bin/sh\n/bin/csh\n";
static FILE *_f;

void setusershell(void)
{
	if(!_f) {
		_f = fopen(_PATH_SHELLS, "r");
	}
	if(!_f) {
		_f = fmemopen((void *)_defshells, strlen(_defshells), "r");
	}
}

char *getusershell(void)
{
	static char line[1024];
	int len;

	if(!_f) {
		setusershell();
	}

	if(!(fgets(line, 1024, _f))) {
		return NULL;
	}

	len = strlen(line);
	if(line[len - 1] == '\n') {
		line[len - 1] = '\0';
	}
	return line;
}

void endusershell(void)
{
	if(_f) {
		fclose(_f);
	}
	_f = NULL;
}
