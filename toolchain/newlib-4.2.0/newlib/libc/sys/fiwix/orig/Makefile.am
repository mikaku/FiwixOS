AUTOMAKE_OPTIONS = cygnus
INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)
AM_CCASFLAGS = $(INCLUDES)
 
noinst_LIBRARIES = lib.a
 
#
# Every time you add a new object in this list, you must run 'autoconf' in
# the parent directory (newlib/libc/sys/), and then 'autoreconf' in this
# directory.
#
extra_objs =    syscalls.o \
		wrappers.o \
		system.o \
		cfspeed.o \
		termios.o \
		utmp.o \
		grp.o \
		usershell.o \
		mntent.o \
		realpath.o \
		sigwait.o \
		ftok.o \
		clock_functions.o \
		ipc.o

lib_a_SOURCES =
lib_a_LIBADD = $(extra_objs)
EXTRA_lib_a_SOURCES = syscalls.c crt0.c	# add more source files here if you split up
lib_a_DEPENDENCIES = $(extra_objs)	# syscalls.c into multiple files
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)
 
all: crt0.o
 
ACLOCAL_AMFLAGS = -I ../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host
