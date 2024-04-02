#ifndef _MNTENT_H
#define _MNTENT_H

#include <stdio.h>
#include <paths.h>

#define MNTTAB	_PATH_MNTTAB
#define MOUNTED	_PATH_MOUNTED

/* generic mount options */
#define MNTOPT_RO	"ro"	/* read only */

struct mntent {
	char *mnt_fsname;	/* device name */
	char *mnt_dir;		/* mounting point */
	char *mnt_type;		/* filesystem type */
	char *mnt_opts;		/* comma-separated list of mount options */
	int mnt_freq;		/* dump frequency (in days) */
	int mnt_passno;		/* pass number on parallel fsck */
};

FILE *setmntent(const char *, const char *);
int endmntent(FILE *);
struct mntent *getmntent(FILE *);
char *hasmntopt(const struct mntent *, const char *);

#endif	/* _MNTENT_H */
