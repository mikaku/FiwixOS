/*
 * fiwix/grp.c
 *
 * Copyright 2018-2020, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <grp.h>
#include <errno.h>
#include <sys/syslimits.h>

static FILE *f;
static char *mem[NGROUPS_MAX];
static struct group g;
static char line[1024];


/* rewind next getgrent back to start of database */
void setgrent()
{
	if(f) {
		fclose(f);
	}
	f = fopen(_PATH_GROUP, "r");
}

/* release group database resources */
void endgrent()
{
	if(f) {
		fclose(f);
	}
	f = 0;
}

/* fetch next group */
struct group *getgrent()
{
	char *l, *p;
	int n;

	memset(line, 0, sizeof(line));
	if(!(l = fgets(line, sizeof(line) - 1, f))) {
		return NULL;
	}

	/* get name */
	g.gr_name = l;
	if(!(l = strchr(l, ':'))) {
		return NULL;
	}
	*l++ = '\0';

	/* get password */
	g.gr_passwd = l;
	if(!(l = strchr(l, ':'))) {
		return NULL;
	}
	*l++ = '\0';

	/* get group id */
	p = l;
	if(!(l = strchr(l, ':'))) {
		return NULL;
	}
	*l++ = '\0';
	g.gr_gid = atoi(p);

	/* get members */
	memset(mem, 0, sizeof(mem));
	g.gr_mem = mem;
	for(n = 0; *l != '\n' && *l != '\0' && n < NGROUPS_MAX; n++) {
		mem[n] = l;
		if((p = strchr(l, ','))) {
			l = p;
			*l++ = '\0';
			continue;
		}
		if((l = strchr(l, '\n')) || (l = strchr(l, '\r'))) {
			*l = '\0';
			break;
		}
	}
	return(&g);
}

/* fetch group with given group id */
struct group *getgrgid(gid_t gid)
{
	struct group *g;

	setgrent();
	while((g = getgrent())) {
		if(g->gr_gid == gid) {
			break;
		}
	}
	endgrent();
	return(g);
}

/* fetch named group */
struct group *getgrnam(const char *name)
{
	struct group *g;

	setgrent();
	while((g = getgrent())) {
		if(!strcmp(g->gr_name, name)) {
			break;
		}
	}
	endgrent();
	return(g);
}
