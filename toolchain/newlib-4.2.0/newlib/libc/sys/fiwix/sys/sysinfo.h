#ifndef _SYS_SYSINFO_H
#define _SYS_SYSINFO_H

struct sysinfo {
	int uptime;			/* seconds since boot */
	unsigned int loads[3];		/* load average (1, 5 and 15 minutes) */
	unsigned int totalram;		/* total usable main memory size */
	unsigned int freeram;		/* available memory size */
	unsigned int sharedram;		/* amount of shared memory */
	unsigned int bufferram;		/* amount of memory used by buffers */
	unsigned int totalswap;		/* total swap space size */
	unsigned int freeswap;		/* available swap space */
	unsigned short int procs;	/* number of current processes */
	char _f[22];			/* pads structure to 64 bytes */
};

int	sysinfo(struct sysinfo *info);

#endif /* _SYS_SYSINFO_H */
