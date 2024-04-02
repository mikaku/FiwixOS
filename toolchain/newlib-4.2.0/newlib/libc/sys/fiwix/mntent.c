/*
 * fiwix/mntent.c
 *
 * Copyright 2020, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <mntent.h>
#include <string.h>

static int split_strtok(char *buf, char *args_space, char *args[])
{
	char *token, *copy;
	char *delimiters;
	int offset, max_tokens;
	int n;

	if(!buf) {
		return 0;
	}

	max_tokens = 6;
	offset = n = 0;
	delimiters = " \t";
	copy = strdup(buf);

	token = strtok(copy, delimiters);

	if(token) {
		do {
			if(args_space) {
				strcpy(args_space + offset, token);
				args[n] = args_space + offset;
				offset += strlen(token) + 1;
			}
			n++;
		} while((token = strtok(NULL, delimiters)) && n < max_tokens);
	}

	free(copy);
	return n;
}

FILE *setmntent(const char *filename, const char *type)
{
	return fopen(filename, type);
}

int endmntent(FILE *stream)
{
	fclose(stream);
	return 1;
}

struct mntent *getmntent_r(FILE *stream, struct mntent *mntbuf, char *buf, int buflen)
{
	char *args[6];

	while(fgets(buf, buflen, stream)) {
		if(buf[0] == '#') {
			continue;
		}
		if(split_strtok(buf, buf, args) == 6) {
			mntbuf->mnt_fsname = args[0];
			mntbuf->mnt_dir = args[1];
			mntbuf->mnt_type = args[2];
			mntbuf->mnt_opts = args[3];
			mntbuf->mnt_freq = atoi(args[4]);
			mntbuf->mnt_passno = atoi(args[5]);
			return mntbuf;
		}
	}

	return NULL;
}

struct mntent *getmntent(FILE *stream)
{
	static struct mntent mntbuf;
	static char buffer[4096];

	memset(&mntbuf, 0, sizeof(struct mntent));
	memset(buffer, 0, sizeof(buffer));

	return getmntent_r(stream, &mntbuf, buffer, sizeof(buffer));
}


/* Copyright (C) 1995-2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

/* Search MNT->mnt_opts for an option matching OPT.
   Returns the address of the substring, or null if none found.  */
char *hasmntopt(const struct mntent *mnt, const char *opt)
{
  const size_t optlen = strlen (opt);
  char *rest = mnt->mnt_opts, *p;

  while ((p = strstr (rest, opt)) != NULL)
    {
      if (p == rest
	  || (p[-1] == ','
	      && (p[optlen] == '\0' ||
		  p[optlen] == '='  ||
		  p[optlen] == ',')))
	return p;

      rest = strchr (rest, ',');
      if (rest == NULL)
	break;
      ++rest;
    }

  return NULL;
}
