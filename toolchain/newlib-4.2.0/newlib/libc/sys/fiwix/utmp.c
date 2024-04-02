/*
 * fiwix/utmp.c
 *
 * Copyright 2018-2020, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/utmp.h>
#include <sys/unistd.h>

void pututline(struct utmp *ut)
{
	FILE *f;
	struct utmp curr_ut;
	char *flags;
	int n;

	if(!access(UTMP_FILE, F_OK)) {
		flags = "r+";
		if(!(f = fopen(UTMP_FILE, flags))) {
			return;
		}

		while((n = fread(&curr_ut, sizeof(struct utmp), 1, f)) == 1) {
			if(
			  (RUN_LVL <= curr_ut.ut_type && curr_ut.ut_type <= OLD_TIME && ut->ut_type == curr_ut.ut_type)
			  ||
			  (INIT_PROCESS <= curr_ut.ut_type && curr_ut.ut_type <= DEAD_PROCESS && !strncmp(ut->ut_id, curr_ut.ut_id, sizeof(curr_ut.ut_id)))
			) {
				if((n = ftell(f)) < 0) {
					fclose(f);
					return;
				}
				if(fseek(f, n - sizeof(struct utmp), SEEK_SET) < 0) {
					fclose(f);
					return;
				}
				fwrite(ut, sizeof(struct utmp), 1, f);
				fclose(f);
				return;
			}
		}
		fclose(f);
		flags = "a";
	} else {
		flags = "w+";
	}

	if(!(f = fopen(UTMP_FILE, flags))) {
		return;
	}
	fwrite(ut, sizeof(struct utmp), 1, f);
	fclose(f);
	return;
}

int updwtmp(char *file, struct utmp *ut)
{
	int fd, errno;
	unsigned int offset;

	errno = 0;
	if((fd = open(file, O_WRONLY)) < 0) {
		perror("fopen");
		return -1;
	}
	offset = lseek(fd, 0, SEEK_END);
	if(offset % sizeof(struct utmp) != 0) {
		offset -= offset % sizeof(struct utmp);
		ftruncate(fd, offset);

		if(lseek(fd, 0, SEEK_END) < 0) {
			close(fd);
			return -1;
		}
	}
	if(write(fd, ut, sizeof(struct utmp)) != sizeof(struct utmp)) {
		ftruncate(fd, offset);
		errno = -1;
	}

	close(fd);
	return errno;
}
