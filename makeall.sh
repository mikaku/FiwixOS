#!/bin/bash
#
# FiwixOS 3.3
# Copyright 2018-2024, Jordi Sanfeliu. All rights reserved.
# Distributed under the terms of the Fiwix License.
#
# Package building script

ROOT=$(pwd)
PREFIX="${ROOT}/installation"
BUILDS="${ROOT}/builds"
LOGS="${ROOT}/logs"
SRC="src"
export LDFLAGS="-s"

mkdir -p $BUILDS $LOGS

# 'y' argument (continue after each build)
yes=$1

_unpack() {
	name=$1 ; f=$2
	ext=
	case $f in
		j) ext="tar.bz2" ;;
		J) ext="tar.xz" ;;
		l) ext="tar.lz" ;;
		z) test -f "${SRC}/$name.tar.gz" && ext="tar.gz" || ext="tgz" ;;
	esac
	rm -rf $name
	tar ${f}xf ${SRC}/$name.$ext || exit 1
}

_patch() {
	name=$1
	echo "patching $name"
	patch -p1 < ../${SRC}/$name.patch || exit 1
}

_make() {
	if [ -z "$1" ] ; then
		make DESTDIR=${PREFIX} || exit 1
		make DESTDIR=${PREFIX} install || exit 1
	else
		make DESTDIR=${PREFIX} CPPFLAGS="$1" || exit 1
		make DESTDIR=${PREFIX} CPPFLAGS="$1" install || exit 1
	fi
}

_opkg() {
	prg="$1"
	ver="$2"
	arch="$3"
	deps="$4"
	desc="$5"

	name="$prg-$ver"
	pushd $PREFIX
		if [ -z "$arch" ] ; then
			echo "Unspecified architecture."
			exit 1
		fi
		if [ -z "$desc" ] ; then
			echo "Unspecified description."
			exit 1
		fi
		bzip2 -dc ${BUILDS}/$name.tar.bz2 > data.tar || exit 1
		gzip -9 data.tar
		mkdir $name
#		IFS="-" read -r prg ver <<< "${name}"
		cat > control <<EOF
Package: $prg
Version: $ver
Architecture: $arch
Maintainer: jordi@fibranet.cat
Description: $desc
Depends: $deps

EOF
		mv data.tar.gz ${name}
		tar zcf ${name}/control.tar.gz control
		echo 2.0 > ${name}/debian-binary
		tar -C $name -zcf ${BUILDS}/${prg}_${ver}_$arch.ipk .
	popd
}

_pack() {
	name=$1
	extrargs=$2
	rm -rf $name
	pushd $PREFIX
		# Bash regex to exclude 'e3-x.y.z' package
                if ! [[ "$name" =~ ^e3-.*$ ]] ; then
			echo "stripping debug symbols ..."
			find -type f -executable -exec strip --strip-debug {} \;
		fi
		tar jcvf ${BUILDS}/$name.tar.bz2 $extrargs .
	popd
}

_error() {
	sync ; sync
	echo
	echo " *** An error occurred. Build has been stopped ***"
	exit 1
}

_build() {
	prg=$1
	ver=$2

	echo "building $prg-$ver ..."
	(
	case $prg in
		Python)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				cat > Modules/Setup.local << "EOF"
*static*

readline readline.c -lreadline -ltermcap

array arraymodule.c	# array objects
cmath cmathmodule.c _math.c # -lm # complex math library functions
math mathmodule.c _math.c -lm # math library functions, e.g. sin()
_struct _struct.c	# binary structure packing/unpacking
_weakref _weakref.c	# basic weak reference support
#_testcapi _testcapimodule.c    # Python C API test module
_random _randommodule.c	# Random number generator
_elementtree -I$(srcdir)/Modules/expat -DHAVE_EXPAT_CONFIG_H -DUSE_PYEXPAT_CAPI _elementtree.c	# elementtree accelerator
_pickle _pickle.c	# pickle accelerator
_datetime _datetimemodule.c	# datetime accelerator
_bisect _bisectmodule.c	# Bisection algorithms
_heapq _heapqmodule.c	# Heap queue algorithm
_asyncio _asynciomodule.c  # Fast asyncio Future


# Modules with some UNIX dependencies -- on by default:
# (If you have a really backward UNIX, select and socket may not be
# supported...)

fcntl fcntlmodule.c	# fcntl(2) and ioctl(2)
#spwd spwdmodule.c		# spwd(3)
grp grpmodule.c		# grp(3)
select selectmodule.c	# select(2); not on ancient System V

# Memory-mapped files (also works on Win32).
#mmap mmapmodule.c

# CSV file helper
#_csv _csv.c

_crypt _cryptmodule.c -lcrypt	# crypt(3); needs -lcrypt on some systems


termios termios.c	# Steen Lumholt's termios module
resource resource.c	# Jeremy Hylton's rlimit interface

_posixsubprocess _posixsubprocess.c  # POSIX subprocess module helper

_md5 md5module.c

_sha1 sha1module.c
_sha256 sha256module.c
_sha512 sha512module.c
_sha3 _sha3/sha3module.c

pyexpat expat/xmlparse.c expat/xmlrole.c expat/xmltok.c pyexpat.c -I$(srcdir)/Modules/expat -DHAVE_EXPAT_CONFIG_H -DXML_POOR_ENTROPY -DUSE_PYEXPAT_CAPI

binascii binascii.c

zlib zlibmodule.c -I$(prefix)/include -L$(exec_prefix)/lib -lz
_bz2 _bz2module.c -lbz2

EOF
				./configure --prefix=/usr --without-threads --disable-shared --without-ensurepip  LDFLAGS="-static" CFLAGS="-static -std=gnu99" || exit 1
				sed -i 's|/\* #undef HAVE_CLOCK_GETTIME \*/$|#define HAVE_CLOCK_GETTIME 1|' pyconfig.h
				make DESTDIR=${PREFIX} CPPFLAGS="-DHAVE_CLOCK_GETTIME" LDFLAGS="-static" LINKFORSHARED=" " || exit 1
				make DESTDIR=${PREFIX} CPPFLAGS="-DHAVE_CLOCK_GETTIME" LDFLAGS="-static" LINKFORSHARED=" " install || exit 1
			popd
			pushd $PREFIX
				rm -rf usr/lib/python3.6/test
				ln -s python3.6 usr/bin/python
			popd
			_pack $prg-$ver
			;;

		SDL)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./autogen.sh || exit 1
				./configure --prefix=/usr --disable-threads --enable-video-svga || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		aalib)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		at)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=${PREFIX}/usr --with-jobdir=/var/spool/at --with-atspool=/var/spool/at/spool --with-daemon_username=root --with-daemon_groupname=root || exit 1
				make DESTDIR=${PREFIX} || exit 1
				make install \
					DESTDIR=${PREFIX} \
					DAEMON_USERNAME=`id -nu` \
					DAEMON_GROUPNAME=`id -ng` \
					ATJOB_DIR=${PREFIX}/var/spool/at \
					ATSPOOL_DIR=${PREFIX}/var/spool/at/spool \
					INSTALL_ROOT_USER=`id -nu` \
					INSTALL_ROOT_GROUP=`id -nu` || exit 1
			popd
			pushd $PREFIX
				pushd usr
					mkdir -p share/doc/$prg-$ver
					mv doc/at/* share/doc/$prg-$ver
					rmdir -p doc/at
				popd
				sed -i 's@'$PREFIX'@@' usr/bin/batch
				sed -i 's@'$PREFIX'@@' usr/sbin/atrun

				mkdir -p etc/rc.d/init.d
				cat > etc/rc.d/init.d/atd << "EOF"
#!/bin/bash
#
# atd		Start/Stop the at daemon.
#
# chkconfig:	345 95 5
# description: 	At allows you to specify that a command will be run at \
#		a particular time.
# processname:	atd
# pidfile:	/var/run/atd.pid

# Source function library.
. /etc/init.d/functions
 
# See how we were called.
  
prog="atd"

start() {
	echo -n $"Starting $prog: "	
	if [ -e /var/run/atd.pid ] && [ -e /proc/`cat /var/run/atd.pid` ]; then
		echo -n $"cannot start $prog: $prog is already running.";
		failure $"cannot start $prog: $prog already running.";
		echo
		return 1
	fi
	daemon /usr/sbin/atd
	RETVAL=$?
	echo
	return $RETVAL
}

stop() {
	echo -n $"Stopping $prog: "
	killproc /usr/sbin/atd
	RETVAL=$?
	echo
        [ $RETVAL -eq 0 ] && rm -f /var/run/atd.pid;
	return $RETVAL
}	

rhstatus() {
	status $prog
}	

restart() {
  	stop
	start
}	

case "$1" in
  start)
  	start
	;;
  stop)
  	stop
	;;
  restart)
  	restart
	;;
  status)
  	rhstatus
	;;
  *)
	echo $"Usage: $0 {start|stop|status|restart}"
	exit 1
esac
EOF
				chmod 755 etc/rc.d/init.d/atd
				mkdir -p etc/logrotate.d
				cat > etc/logrotate.d/atd << "EOF"
/var/log/atd {
	postrotate
		/bin/kill -HUP `cat /var/run/atd.pid 2>/dev/null` 2>/dev/null || true
	endscript
}
EOF
				chmod 644 etc/logrotate.d/atd
				echo "" > etc/at.deny
				chmod 600 etc/at.deny
			popd
			_pack $prg-$ver
			;;

		autoconf)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		automake)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		bash)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --without-bash-malloc --enable-job-control --with-curses CPPFLAGS=-D_POSIX_VERSION=1 || exit 1
				make DESTDIR=${PREFIX} "CPPFLAGS=-D_POSIX_VERSION -DHAVE_UNISTD_H -DHAVE_TERMIOS_H" || exit 1
				make DESTDIR=${PREFIX} "CPPFLAGS=-D_POSIX_VERSION -DHAVE_UNISTD_H -DHAVE_TERMIOS_H" install || exit 1
			popd
			pushd $PREFIX
				pushd usr/bin
					ln -s bash sh
					# POSIX requires to provide execable alternatives for regular built-ins
					for ea in alias bg cd command fc fg getopts hash jobs read type ulimit umask unalias wait ; do
						cat > "$ea" <<EOF
#!/bin/sh
builtin $ea "\$@"
EOF
						chmod +x "$ea"
					done
				popd
			popd
			_pack $prg-$ver
			;;

		bc)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				LIBS="-lncurses" ./configure --prefix=/usr --with-readline || exit 1
				_make "-DELIDE_CODE=1"
			popd
			_pack $prg-$ver
			;;

		busybox)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				cp ../${SRC}/$prg-$ver-config .config
				make || exit 1
				make PREFIX=$PREFIX install || exit 1
			popd
			_pack $prg-$ver
			;;

		busybox-mini)
			prg=busybox
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				cp ../${SRC}/$prg-$ver-config.mini .config
				make || exit 1
				make PREFIX=$PREFIX install || exit 1
			popd
			_pack $prg-mini-$ver
			rm -rf $prg-$ver
			;;

		byacc)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			pushd $PREFIX
				pushd usr/bin
					ln -s yacc byacc
				popd
			popd
			_pack $prg-$ver
			;;

		bzip2)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				make || exit 1
				make install PREFIX=${PREFIX}/usr || exit 1
			popd
			pushd $PREFIX
				pushd usr/bin
					# regenerate bad symlinks
					rm -f bzcmp bzegrep bzfgrep bzless
					ln -sf bzdiff bzcmp
					ln -sf bzgrep bzegrep
					ln -sf bzgrep bzfgrep
					ln -sf bzmore bzless
				popd
			popd
			_pack $prg-$ver
			;;

		chkconfig)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				make || exit 1
				make instroot=${PREFIX} install || exit 1
			popd
			_pack $prg-$ver
			;;

		coreutils)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --disable-threads --disable-acl --disable-xattr --without-selinux --enable-install-program=arch,hostname --enable-no-install-program=chcon,runcon,uptime || exit 1
				make DESTDIR=${PREFIX} "CPPFLAGS=-DSTAT_STATFS2_BSIZE" || exit 1
				make DESTDIR=${PREFIX} "CPPFLAGS=-DSTAT_STATFS2_BSIZE" install || exit 1
				# build the su command as it was in coreutils-8.17
				gcc -I. -I./lib -Ilib -Isrc -I./src -g -O2 -MT src/su.o -MD -MP -c -o src/su.o src/su.c
				gcc -g -O2 -Wl,--as-needed -s -o src/su src/su.o src/libver.a lib/libcoreutils.a /usr/lib/libcrypt.a
				cp -p src/su $PREFIX/usr/bin
				cp -p man/su.1 $PREFIX/usr/share/man/man1
			popd
			pushd $PREFIX
				chmod 4755 usr/bin/su
			popd
			_pack $prg-$ver
			;;

		cpio)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		dash)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		ddrescue)
			_unpack $prg-$ver l
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		dialog)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		diffstat)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		diffutils)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		dmidecode)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				_make
			popd
			_pack $prg-$ver
			;;

		dos2unix)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				_make
			popd
			_pack $prg-$ver
			;;

		e2fsprogs-libs)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-htree --disable-nls || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		e2fsprogs)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-htree --disable-nls || exit 1
				_make
			popd
			pushd $PREFIX
				rm -f usr/sbin/fsck
				rm -f usr/sbin/fsck.ext3
				rm -f usr/sbin/mkfs.ext3
				rm -f usr/sbin/filefrag
				rm -f usr/man/man8/fsck.8
				rm -f usr/man/man8/fsck.ext3.8
				rm -f usr/man/man8/mkfs.ext3.8
				rm -f usr/man/man8/filefrag.8
			popd
			_pack $prg-$ver
			;;

		e3)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				export PREFIX ; make || exit 1
				make install || exit 1
			popd
			pushd $PREFIX
				mkdir usr
				mv bin man usr
				pushd usr/bin
					ln -sf e3 e3ws
					ln -sf e3 e3em
					ln -sf e3 e3pi
					ln -sf e3 e3vi
					ln -sf e3 e3ne
				popd
			popd
			_pack $prg-$ver
			;;

		ed)
			_unpack $prg-$ver l
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		enscript)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			pushd $PREFIX
				mv usr/etc .
			popd
			_pack $prg-$ver
			;;

		expat)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		file)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-shared || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		findutils)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-threads || exit 1
				_make "-D_POSIX_ARG_MAX=4096"
			popd
			_pack $prg-$ver
			;;

		flex)
			_unpack $prg-$ver l
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			pushd $PREFIX
				pushd usr/bin
					ln -sf flex flex++
				popd
			popd
			_pack $prg-$ver
			;;

		gawk)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				sed -i 's|^#define HAVE_SOCKETS 1$|/* #undef HAVE_SOCKETS */|' config.h
				_make "-DGETPGRP_VOID=1 -DELIDE_CODE=1"
			popd
			_pack $prg-$ver
			;;

		global)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make "-DELIDE_CODE=1"
			popd
			_pack $prg-$ver
			;;

		gmp)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		gnu-ghostscript)
			# <https://ftp.icm.edu.pl/packages/ghostscript/fonts/>
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				LIBS="-llzma -lz" ./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		gnuit)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			pushd $PREFIX
				rm -f usr/bin/git
			popd
			_pack $prg-$ver
			;;

		gperf)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		grep)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		groff)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --with-urw-fonts-dir=/usr/share/fonts/urw-fonts || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		grub)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-fat --disable-ffs --disable-ufs2 --disable-reiserfs --disable-vstafs --disable-jfs --disable-xfs --disable-gunzip --disable-serial --disable-auto-linux-mem-opt --disable-packet-retransmission --without-curses || exit 1
				_make
			popd
			pushd $PREFIX
				sed -i 's#^prefix=/usr#prefix=/#' usr/sbin/grub-install
				sed -i 's#^exec_prefix=.*#exec_prefix=/usr#' usr/sbin/grub-install
#				sed -i 's#^grub_prefix=/boot/grub#grub_prefix=/grub#' usr/sbin/grub-install
				sed -i 's#linux\*)#linux\* | fiwix\*)#' usr/sbin/grub-install
				sed -i 's#^prefix=/usr#prefix=/#' usr/sbin/grub-md5-crypt
				sed -i 's#^exec_prefix=.*#exec_prefix=/usr#' usr/sbin/grub-md5-crypt
			popd
			_pack $prg-$ver
			;;

		gsl)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		gzip)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		indent)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-threads || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		jpeg)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		lcms2)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		less)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			pushd $PREFIX
				ln -s less usr/bin/more
			popd
			_pack $prg-$ver
			;;

		libarchive)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				LIBS="-liconv -llzma -lz" ./configure --prefix=/usr || exit 1
				sed -i 's|^#define HAVE_PTHREAD_H 1$|/* #undef HAVE_PTHREAD_H */|' config.h
				_make
			popd
			pushd $PREFIX
				# this line appeared in 3.6.2 and prevented a success built of 'opkg'
				sed -i 's/^Requires.private: /#Requires.private: /' usr/lib/pkgconfig/libarchive.pc
			popd
			_pack $prg-$ver
			;;

		libffi)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		libiconv)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		libpng)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --enable-static || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		libtool)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr --enable-static || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		libuuid)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		libxcrypt)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr --disable-werror --disable-shared --disable-libtool-lock || exit 1
				_make "-DENABLE_WEAK_HASHES"
			popd
			_pack $prg-$ver
			;;

		libxslt)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				./autogen.sh --prefix=/usr
				_make
			popd
			_pack $prg-$ver
			;;

		libxml2)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				./autogen.sh --prefix=/usr --with-http=no --with-ftp=no --with-python=no
				_make
			popd
			_pack $prg-$ver
			;;

		logrotate)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				LIBS="-liconv" ./configure --prefix=/usr || exit 1
				_make
				mkdir -p ${PREFIX}/etc/cron.daily
				cp examples/logrotate.cron ${PREFIX}/etc/cron.daily/logrotate
				chmod 755 ${PREFIX}/etc/cron.daily/logrotate
				cp examples/logrotate.conf ${PREFIX}/etc
				cat >> ${PREFIX}/etc/logrotate.conf << "EOF"

# no packages own wtmp -- we'll rotate them here
/var/log/wtmp {
    monthly
    minsize 1M
    create 0664 root utmp
    rotate 1
}

/var/log/btmp {
    missingok
    monthly
    minsize 1M
    create 0600 root utmp
    rotate 1
}

EOF
			popd
			pushd $PREFIX
				mkdir etc/logrotate.d/
			popd
			_pack $prg-$ver
			;;

		lookbusy)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		lrzsz)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=${PREFIX}/usr --disable-pubdir --disable-syslog --disable-nls || exit 1
				_make
			popd
			pushd $PREFIX
				pushd usr/bin
					ln -sf lrb rb
					ln -sf lrx rx
					ln -sf lrz rz
					ln -sf lsb sb
					ln -sf lsx sx
					ln -sf lsz sz
				popd
			popd
			_pack $prg-$ver
			;;

		lua)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				sed -i 's@INSTALL_TOP= /usr/local@INSTALL_TOP = '$PREFIX'/usr@' Makefile || exit 1
				make DESTDIR=${PREFIX} generic || exit 1
				make DESTDIR=${PREFIX} install || exit 1
			popd
			_pack $prg-$ver
			;;

		lxdoom)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-cpu-opt || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		lzip)
			_unpack $prg-$ver l
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		m4)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		make)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		mandoc)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				_make
			popd
			_pack $prg-$ver
			;;

		mingetty)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				_make
			popd
			_pack $prg-$ver
			;;

		mpc)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		mpfr)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-thread-safe || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		nano)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-threads || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		nasm)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		ncompress)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				_make
			popd
			_pack $prg-$ver
			;;

		ncurses)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --with-share=no --with-debug=no || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		ncurses-examples)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				sed -i '/^demo_termcap/d' programs || exit 1
				./configure --prefix=/usr --with-share=no --with-debug=no || exit 1
				_make
			popd
			pushd $PREFIX
				pushd usr/share
					mkdir ncurses-examples
					mv * ncurses-examples
				popd
				pushd usr
					mv bin share/ncurses-examples
				popd
			popd
			_pack $prg-$ver
			;;

		newt)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./autogen.sh #|| exit 1
				LIBS="-liconv" ./configure --prefix=/usr --disable-nls || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		openjpeg)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./bootstrap.sh || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		opkg)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				mkdir conf
				pushd conf
					ln -s /usr/share/libtool/build-aux/config.guess config.guess
					ln -s /usr/share/libtool/build-aux/config.sub config.sub
					ln -s /usr/share/libtool/build-aux/install-sh install-sh
					ln -s /usr/share/libtool/build-aux/depcomp depcomp
					ln -s /usr/share/libtool/build-aux/ltmain.sh ltmain.sh
				popd
				./autogen.sh || exit 1
				./configure --prefix=/usr --disable-curl --disable-gpg --enable-xz --enable-bzip2 --sysconfdir=/etc --localstatedir=/var || exit 1
				_make
			popd
			pushd $PREFIX
				mkdir -p etc/opkg
				cat > etc/opkg/opkg.conf <<EOF
dest root /
dest ram /tmp
arch i386 1
arch noarch 1
EOF
			popd
			_pack $prg-$ver
			;;

		patch)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		pciutils)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				_make
			popd
			_pack $prg-$ver
			;;

		pcre)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		perl)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./Configure -Dprefix=/usr -des || exit 1
				make || exit 1
#				make test || exit 1
				make DESTDIR=${PREFIX} install || exit 1
			popd
			_pack $prg-$ver '--exclude="*\.0"'
			;;

		picocom)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				make || exit 1
				mkdir -p ${PREFIX}/usr/bin/
				cp pcasc pc?m picocom ${PREFIX}/usr/bin
				mkdir -p ${PREFIX}/usr/share/man/man1
				cp picocom.1 ${PREFIX}/usr/share/man/man1
			popd
			_pack $prg-$ver
			;;

		pkg-config)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-threads || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		popt)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		procps)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				make DESTDIR=${PREFIX} SHARED=0 || exit 1
				make DESTDIR=${PREFIX} SHARED=0 install || exit 1
			popd
			pushd $PREFIX
				mv bin/ps usr/bin
				rmdir bin
			popd
			_pack $prg-$ver
			;;

		pwgen)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		readline)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
#				./configure --prefix=/usr --with-curses --disable-shared CPPFLAGS="-D_POSIX_VERSION" || exit 1
				./configure --prefix=/usr --disable-shared CPPFLAGS="-D_POSIX_VERSION" || exit 1
				_make "-D_POSIX_VERSION -DHAVE_TERMIOS_H"
			popd
			_pack $prg-$ver
			;;

		sed)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		sharutils)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-threads --disable-nls || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		slang)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				make DESTDIR=${PREFIX} static || exit 1
				make DESTDIR=${PREFIX} install-static || exit 1
			popd
			pushd $PREFIX
				mv usr/etc .
			popd
			_pack $prg-$ver
			;;

		stress)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		svgalib)
			# WARNING: you need to have installed svgalib-1.4.3
			# before, otherwise utils/ programs won't be built.
			_unpack $prg-$ver z
			mkdir -p ${PREFIX}/usr/include
			mkdir -p ${PREFIX}/usr/bin
			mkdir -p ${PREFIX}/usr/lib
			mkdir -p ${PREFIX}/etc/vga
			mkdir -p ${PREFIX}/usr/share/$prg-$ver/demos
			mkdir -p ${PREFIX}/usr/share/man
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				# this is needed to make lxdoom happy
				sed -i 's/# chipset VGA/chipset VGA/' src/config/libvga.config || exit 1
				make static || exit 1
				make install TOPDIR=${PREFIX} || exit 1
				make demoprogs || exit 1
				find demos -perm 4755 -exec cp {} ${PREFIX}/usr/share/$prg-$ver/demos \;
				find threeDKit -perm 4755 -exec cp {} ${PREFIX}/usr/share/$prg-$ver/demos \;
			popd
			_pack $prg-$ver
			;;

		symlinks)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				sed -i 's@MANDIR  = /usr/man/man8/symlinks.8@MANDIR  = '$PREFIX'/usr/man/man8/symlinks.8@' Makefile || exit 1
				sed -i 's@BINDIR  = /usr/local/bin@BINDIR  = '$PREFIX'/usr/bin@' Makefile || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		sysvinit)
			_unpack $prg-$ver z
			pushd $prg-$ver/src || exit 1
				patch -p2 < ../../${SRC}/$prg-$ver.patch || exit 1
				make ROOT=${PREFIX} || exit 1
				make ROOT=${PREFIX} install || exit 1
			popd
			_pack $prg-$ver
			;;

		tar)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr || exit 1
				_make
			popd
			pushd $PREFIX
				pushd usr/bin
					ln -sf tar gtar
				popd
			popd
			_pack $prg-$ver
			;;

		termcap)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=${PREFIX}/usr --enable-install-termcap --with-termcap=${PREFIX}/etc/termcap || exit 1
				sed -i '/^INSTALL = / s/$/ -D/' Makefile
				_make
			popd
			_pack $prg-$ver
			;;

		texinfo)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		texinfo.old)
			rm -rf texinfo-$ver
			tar zxf ${SRC}/texinfo-$ver.tar.gz || exit 1
			pushd texinfo-$ver || exit 1
				patch -p1 < ../${SRC}/texinfo-$ver.patch || exit 1
				./configure --prefix=/usr || exit 1
				make DESTDIR=${PREFIX} || exit 1
				make DESTDIR=${PREFIX} install || exit 1
			popd
			rm -rf texinfo-$ver
			cd $PREFIX
			tar zcvf ${BUILDS}/texinfo-$ver.tar.gz .
			;;

		tiff)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		time)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		tmpwatch)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		tree)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				sed -i 's@MANDIR=\${PREFIX}@MANDIR=\${DESTDIR}/usr@' Makefile || exit 1
				sed -i 's@\$(DESTDIR)@\$(DESTDIR)/usr/bin@g' Makefile || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		units)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				LIBS="-lncurses" ./configure --prefix=/usr --sharedstatedir=/var/lib || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		unzip)
			_unpack $prg$ver z
			pushd $prg$ver || exit 1
				_patch $prg$ver
				sed -i 's@prefix = /usr/local@prefix = '$PREFIX'/usr@' unix/Makefile || exit 1
				make -f unix/Makefile generic_gcc "LOCAL_UNZIP=-DHAVE_TERMIOS_H -D_POSIX_VERSION" || exit 1
				make -f unix/Makefile install "LOCAL_UNZIP=-DHAVE_TERMIOS_H -D_POSIX_VERSION" || exit 1

			popd
			_pack $prg-$ver
			rm -rf $prg$ver
			;;

		util-linux-ng)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --enable-static --disable-tls --disable-libuuid --disable-uuidd --disable-nls --disable-arch --disable-cramfs --disable-switch_root --disable-pivot_root --disable-unshare --disable-mesg --disable-wall --disable-init --disable-schedutils --disable-fsck --disable-libblkid --enable-login-utils --enable-write || exit 1
				_make "-DHAVE_TERMIOS_H"
			popd
			pushd $PREFIX
				mv bin/login usr/bin/login
				mv sbin/* usr/sbin
				rmdir bin
				rmdir lib
				rmdir sbin
				# remove unused tools
				rm -f usr/bin/logger
				rm -f usr/bin/renice
				rm -f usr/bin/linux* usr/bin/i386
				rm -f usr/sbin/vigr
				rm -f usr/sbin/mkfs
				rm -f usr/sbin/mkfs.bfs
				rm -f usr/share/man/man1/logger.1
				rm -f usr/share/man/man1/renice.1
				rm -f usr/share/man/man1/more.1
				rm -f usr/share/man/man8/linux*.8
				rm -f usr/share/man/man8/i386.8
				rm -f usr/share/man/man8/mkfs.8
				rm -f usr/share/man/man8/mkfs.bfs.8
			popd
			_pack $prg-$ver
			;;

		vim)
			_unpack $prg-$ver j
			ver2=$(echo $ver | sed 's/\.//')
			pushd $prg$ver2 || exit 1
				./configure --prefix=/usr || exit 1
				_make "-DHAVE_SYS_UTSNAME_H"
			popd
			pushd $PREFIX
				pushd usr/bin
					ln -s vim vi
				popd
				cat > usr/share/vim/vim$ver2/vimrc << "EOF"
if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
   set fileencodings=ucs-bom,utf-8,latin1
endif

set nocompatible	" Use Vim defaults (much better!)
set bs=indent,eol,start		" allow backspacing over everything in insert mode
"set ai			" always set autoindenting on
"set backup		" keep a backup file
set viminfo='20,\"50	" read/write a .viminfo file, don't store more
			" than 50 lines of registers
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time

" Only do this part when compiled with support for autocommands
if has("autocmd")
  augroup redhat
  autocmd!
  " In text files, always limit the width of text to 78 characters
  " autocmd BufRead *.txt set tw=78
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal! g'\"" |
  \ endif
  " don't write swapfile on most commonly used directories for NFS mounts or USB sticks
  autocmd BufNewFile,BufReadPre /media/*,/run/media/*,/mnt/* set directory=~/tmp,/var/tmp,/tmp
  " start with spec file template
  autocmd BufNewFile *.spec 0r /usr/share/vim/vimfiles/template.spec
  augroup END
endif

if has("cscope") && filereadable("/usr/bin/cscope")
   set csprg=/usr/bin/cscope
   set csto=0
   set cst
   set nocsverb
   " add any database in current directory
   if filereadable("cscope.out")
      cs add $PWD/cscope.out
   " else add database pointed to by environment
   elseif $CSCOPE_DB != ""
      cs add $CSCOPE_DB
   endif
   set csverb
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

filetype plugin on

if &term=="xterm"
     set t_Co=8
     set t_Sb=[4%dm
     set t_Sf=[3%dm
endif

" Don't wake up system with blinking cursor:
" http://www.linuxpowertop.org/known.php
let &guicursor = &guicursor . ",a:blinkon0"
EOF
				mkdir -p etc/profile.d
				cat > etc/profile.d/vim.sh << "EOF"
VIM=/usr/share/vim/vim74
export VIM
EOF
			popd
			_pack $prg-$ver
			rm -rf $prg$ver2
			;;

		vixie-cron)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				_make
			popd
			pushd $PREFIX
				pushd usr/sbin
					ln -s cron crond
				popd
				mkdir -p var/cron/tabs
				chmod 710 var/cron
				chmod 700 var/cron/tabs
				mkdir -p etc/cron.d
				mkdir -p etc/rc.d/init.d
				cat > etc/rc.d/init.d/crond << "EOF"
#!/bin/bash
#
# crond		Start/Stop the cron clock daemon.
#
# chkconfig:	2345 90 60
# description: 	cron is a standard UNIX program that runs user-specified \
#		programs at periodic scheduled times. vixie cron adds a \
#		number of features to the basic UNIX cron, including better \
#		security and more powerful configuration options.
# processname:	crond
# config:	/etc/crontab
# pidfile:	/var/run/crond.pid

# Source function library.
. /etc/init.d/functions
 
# See how we were called.
  
prog="crond"

start() {
	echo -n $"Starting $prog: "	
	if [ -e /var/run/crond.pid ] && [ -e /proc/`cat /var/run/crond.pid` ]; then
		echo -n $"cannot start $prog: $prog is already running.";
		failure $"cannot start $prog: $prog already running.";
		echo
		return 1
	fi
	daemon /sbin/crond $CRONDARGS
	RETVAL=$?
	echo
	return $RETVAL
}

stop() {
	echo -n $"Stopping $prog: "
	killproc /sbin/crond
	RETVAL=$?
	echo
        [ $RETVAL -eq 0 ] && rm -f /var/run/crond.pid;
	return $RETVAL
}	

rhstatus() {
	status $prog
}	

restart() {
  	stop
	start
}	

reload() {
	echo -n $"Reloading cron daemon configuration: "
	killproc $prog -HUP
	RETVAL=$?
	echo
	return $RETVAL
}	

case "$1" in
  start)
  	start
	;;
  stop)
  	stop
	;;
  restart)
  	restart
	;;
  reload)
  	reload
	;;
  status)
  	rhstatus
	;;
  *)
	echo $"Usage: $0 {start|stop|status|reload|restart}"
	exit 1
esac
EOF
				chmod 755 etc/rc.d/init.d/crond
				mkdir -p etc/logrotate.d
				cat > etc/logrotate.d/cron << "EOF"
/var/cron/log {
	postrotate
		/bin/kill -HUP `cat /var/run/cron.pid 2>/dev/null` 2>/dev/null || true
	endscript
}
EOF
				chmod 644 etc/logrotate.d/cron
			popd
			_pack $prg-$ver
			;;

		vttest)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr --sharedstatedir=/var/lib || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		wdiff)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-threads || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		which)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		xml2)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				LIBS="-liconv -llzma -lz" ./configure --prefix=/usr || exit 1
				_make
			popd
			pushd $PREFIX
				rm -f usr/bin/html2 usr/bin/2html
				ln -s xml2 usr/bin/html2
				ln -s 2xml usr/bin/2html
			popd
			_pack $prg-$ver
			;;

		xmlto)
			_unpack $prg-$ver j
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		xz)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --disable-threads --disable-shared || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		zgv)
			_unpack $prg-$ver z
			pushd $PREFIX
				mkdir -p usr/bin
				mkdir -p usr/share/man/man1
				mkdir -p usr/share/info
			popd
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				sed -i 's@PREFIX=/usr/local@PREFIX='$PREFIX'/usr@' config.mk || exit 1
				sed -i 's@#SHARE_INFIX@SHARE_INFIX@' config.mk || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		zile)
			_unpack $prg-$ver z
			pushd $prg-$ver || exit 1
				_patch $prg-$ver
				./configure --prefix=/usr --with-ncurses || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

		zip)
			_unpack $prg$ver z
			pushd $prg$ver || exit 1
				sed -i 's@prefix = /usr/local@prefix = '$PREFIX'/usr@' unix/Makefile || exit 1
				make -f unix/Makefile generic_gcc "LOCAL_ZIP=-DHAVE_TERMIOS_H -D_POSIX_VERSION" || exit 1
				make -f unix/Makefile install "LOCAL_ZIP=-DHAVE_TERMIOS_H -D_POSIX_VERSION" || exit 1

			popd
			_pack $prg-$ver
			rm -rf $prg$ver
			;;

		zlib)
			_unpack $prg-$ver J
			pushd $prg-$ver || exit 1
				./configure --prefix=/usr || exit 1
				_make
			popd
			_pack $prg-$ver
			;;

	esac
	) 2>&1 | tee -a ${LOGS}/$prg.buildlog

	retval="${PIPESTATUS[0]}" ; [ $retval -gt 0 ] && _error
}

build() {
	local prg=$1
	local ver=$2
	local arch=$3
	local deps="$4"
	local desc="$5"

	if ! [ -f ${BUILDS}/${prg}-${ver}.tar.bz2 ] ; then
		rm -rf $PREFIX
		rm -f ${LOGS}/$prg.buildlog
		mkdir -p $PREFIX
		{ time _build "$@" ; } 2>> ${LOGS}/$prg.buildlog
	else
		echo "File '${BUILDS}/${prg}-${ver}.tar.bz2' already exists."
	fi

	if ! [ -f ${BUILDS}/${prg}_${ver}_${arch}.ipk ] ; then
		_opkg "$@"
	else
		echo "File '${BUILDS}/${prg}_${ver}_${arch}.ipk' already exists."
		return
	fi

	echo
	echo "$prg-$ver completed!"
	echo
	sync ; sync


	if [ -n "$yes" ] ; then
		return
	else
		echo "Press any key to continue."
		read a
	fi
	echo
}

build Python 3.6.15 i386 "" "Python 3.6 interpreter"
build SDL 1.2.15 i386 "" "Cross-platform multimedia library"
build aalib 1.4.0 i386 "" "ASCII art library"
build at 3.1.23 i386 "" "Job spooling tools"
build autoconf 2.69 i386 "" "A GNU tool for automatically configuring source code"
build automake 1.15.1 i386 "" "A GNU tool for automatically creating Makefiles"
build bash 4.4.18 i386 "" "The GNU Bourne Again shell"
build bc 1.07.1 i386 "" "GNU's bc (a numeric processing language) and dc (a calculator)"
build busybox 1.01 i386 "" "Statically linked binary providing simplified versions of system commands"
build busybox-mini 1.01 i386 "" "Statically linked binary providing simplified versions of system commands"
#build byacc 20230521 i386 "" "Berkeley Yacc, a parser generator"
build byacc 20240109 i386 "" "Berkeley Yacc, a parser generator"
build bzip2 1.0.8 i386 "" "File compression utility"
build chkconfig 1.3.30.2 i386 "" "A system tool for maintaining the /etc/rc*.d hierarchy"
build coreutils 9.1 i386 "" "A set of basic GNU tools commonly used in shell scripts"
#build cpio 2.14 i386 "" "A GNU archiving program"
build cpio 2.15 i386 "" "A GNU archiving program"
build dash 0.5.12 i386 "" "Small and fast POSIX-compliant shell"
#build ddrescue 1.25 i386 "" "Data recovery tool trying hard to rescue data in case of read errors"
build ddrescue 1.28 i386 "" "Data recovery tool trying hard to rescue data in case of read errors"
#build dialog 1.3-20230209 i386 "" "A utility for creating TTY dialog boxes"
build dialog 1.3-20240619 i386 "" "A utility for creating TTY dialog boxes"
#build diffstat 1.65 i386 "" "A utility which provides statistics based on the output of diff"
build diffstat 1.66 i386 "" "A utility which provides statistics based on the output of diff"
#build diffutils 3.6 i386 "" "GNU collection of diff utilities"
build diffutils 3.10 i386 "" "GNU collection of diff utilities"
#build dmidecode 2.12 i386 "" "Tool to analyse BIOS DMI data"
build dmidecode 3.6 i386 "" "Tool to analyse BIOS DMI data"
#build dos2unix 7.5.0 i386 "" "Text file format converters"
build dos2unix 7.5.2 i386 "" "Text file format converters"
#build e2fsprogs 1.29 i386 "" "Utilities for managing ext2 and ext3 file systems"
build e2fsprogs-libs 1.37 i386 "" "Ext2/3/4 file system specific libraries"
build e2fsprogs 1.37 i386 "" "Utilities for managing ext2 and ext3 file systems"
build e3 2.7.1 i386 "" "Text editor with key bindings similar to WordStar, Emacs, pico, nedit, or vi"
#build ed 1.19 i386 "" "The GNU line editor"
build ed 1.20.2 i386 "" "The GNU line editor"
build enscript 1.6.6 i386 "" "A plain ASCII to PostScript converter"
build expat 2.5.0 i386 "" "An XML parser library"
#build file 5.41 i386 "" "Utility for determining file types"
build file 5.45 i386 "" "Utility for determining file types"
build findutils 4.4.2 i386 "" "The GNU versions of find utilities (find and xargs)"
build flex 2.6.4 i386 "" "A tool for generating scanners (text pattern recognizers)"
build gawk 3.1.8 i386 "" "The GNU version of the AWK text processing utility"
#build global 6.6.10 i386 "" "Source code tag system"
build global 6.6.13 i386 "" "Source code tag system"
build gmp 6.2.1 i386 "" "GNU arbitrary precision library"
build gnu-ghostscript 9.14.1 i386 "" "Interpreter for PostScript language & PDF"
build gnuit 4.9.5 i386 "" "GNU Interactive Tools"
build gperf 3.1 i386 "" "A perfect hash function generator"
#build grep 3.8 i386 "" "Pattern matching utilities"
build grep 3.11 i386 "" "Pattern matching utilities"
#build groff 1.22.4 i386 "" "A document formatting system"
build groff 1.23.0 i386 "" "A document formatting system"
build grub 0.97 i386 "" "Grand Unified Boot Loader"
#build gsl 2.7.1 i386 "" "The GNU Scientific Library for numerical analysis"
build gsl 2.8 i386 "" "The GNU Scientific Library for numerical analysis"
#build gzip 1.12 i386 "" "GNU data compression program"
build gzip 1.13 i386 "" "GNU data compression program"
build indent 2.2.12 i386 "" "A GNU program for formatting C code"
build jpeg 9e i386 "" "The Independent JPEG Group's JPEG software"
build lcms2 2.15 i386 "" "Color Management System"
build less 633 i386 "" "A text file browser similar to more, but better"
build libarchive 3.6.2 i386 "" "A library for handling streaming archive formats"
build libffi 3.4.4 i386 "" "A portable foreign function interface library"
build libiconv 1.17 i386 "" "A character set conversion library"
build libpng 1.6.37 i386 "" "A library of functions for manipulating PNG image format files"
build libtool 2.4.7 i386 "" "The GNU Portable Library Tool"
build libuuid 1.0.3 i386 "" "Universally unique ID library"
build libxcrypt 4.4.33 i386 "" "Extended crypt library for descrypt, md5crypt, bcrypt, and others"
build libxml2 v2.9.14 i386 "" "Library providing XML and HTML support"
build libxslt v1.1.34 i386 "" "Library providing the Gnome XSLT engine"
build logrotate 3.21.0 i386 "" "Rotates, compresses, removes and mails system log files"
build lookbusy 1.4 i386 "" "A synthetic load generator"
build lrzsz 0.12.14 i386 "" "The lrz and lsz modem communications programs"
build lua 5.4.6 i386 "" "Powerful light-weight programming language"
build lxdoom 1.4.4 i386 "" "A version of Doom for SVGAlib and XFree86"
build lzip 1.23 i386 "" "LZMA compressor with integrity checking"
build m4 1.4.18 i386 "" "GNU macro processor"
build make 4.2.1 i386 "" "A GNU tool which simplifies the build process for users"
build mandoc 1.14.6 i386 "" "A suite of tools for compiling mdoc and man"
build mingetty 1.08 i386 "" "A compact getty program for virtual consoles only"
build mpc 1.1.0 i386 "" "GNU MPC is a complex floating-point library with exact rounding"
build mpfr 3.1.6 i386 "" "C library for multiple-precision floating-point computations"
build nano 4.9.3 i386 "" "A small text editor"
build nasm 2.16.01 i386 "" "A portable x86 assembler which uses Intel-like syntax"
build ncompress 4.2.4.6 i386 "" "Fast compression and decompression utilities"
build ncurses 5.9 i386 "" "Ncurses support utilities"
build ncurses-examples 20180127 i386 "" "A set of examples using ncurses"
build newt r0-52-23 i386 "" "A library for text mode user interfaces"
build openjpeg 1.5.2 i386 "" "JPEG 2000 command line tools"
build opkg 0.6.2 i386 "" "A lightweight package management system based upon ipkg"
build patch 2.7.6 i386 "" "Utility for modifying/upgrading files"
build pciutils 3.8.0 i386 "" "PCI bus related utilities"
build pcre 8.45 i386 "" "Perl-compatible regular expression library"
build perl 5.20.3 i386 "" "Practical Extraction and Report Language"
build picocom 3.1 i386 "" "Minimal serial communications program"
build pkg-config 0.25 i386 "" "A tool for determining compilation options"
build popt 1.19 i386 "" "C library for parsing command line parameters"
build procps 3.2.8 i386 "" "System and process monitoring utilities"
build pwgen 2.08 i386 "" "Automatic password generation"
build readline 7.0 i386 "" "A library for editing typed command lines"
build sed 4.4 i386 "" "A GNU stream text editor"
build sharutils 4.15.2 i386 "" "The GNU shar utilities for packaging and unpackaging shell archives"
build slang 2.3.3 i386 "" "Shared library for the S-Lang extension language"
build stress 1.0.4 i386 "" "A tool to put given subsystems under a specified load"
build svgalib 1.4.3 i386 "" "Low-level fullscreen SVGA graphics library"
build symlinks 1.4.3 i386 "" "A utility which maintains a system's symbolic links"
#build sysvinit 2.84 i386 "" "Programs which control basic system processes"
#build sysvinit 2.86 i386 "" "Programs which control basic system processes"
build sysvinit 2.87dsf i386 "" "Programs which control basic system processes"
build tar 1.34 i386 "" "GNU file archiving program"
build termcap 1.3.1 i386 "" "The terminal feature database used by certain applications"
build texinfo 5.2 i386 "" "Tools needed to create Texinfo format documentation files"
build tiff 4.4.0 i386 "" "Library of functions for manipulating TIFF format image files"
build time 1.9 i386 "" "A GNU utility for monitoring a program's use of system resources"
build tmpwatch 2.11 i386 "" "A utility for removing files based on when they were last accessed"
build tree 2.1.1 i386 "" "File system tree viewer"
build units 2.22 i386 "" "A utility for converting amounts from one unit to another"
build unzip 60 i386 "" "A utility for unpacking zip files"
build util-linux-ng 2.17 i386 "" "Collection of basic system utilities"
build vim 7.4 i386 "" "The VIM editor"
build vixie-cron 4.1 i386 "" "The Vixie cron daemon for executing specified programs at set times"
build vttest 20230201 i386 "" "Test VT100-type terminal"
build wdiff 1.2.2 i386 "" "Compare files on a word per word basis"
build which 2.21 i386 "" "Displays where a particular program in your path is located"
build xml2 0.5 i386 "" "XML/Unix Processing Tools"
build xmlto 0.0.28 i386 "" "A tool for converting XML files to various formats"
build xz 5.0.8 i386 "" "LZMA compression utilities"
build zgv 5.9 i386 "" "Picture viewer for SVGAlib"
build zile 2.3.24 i386 "" "Zile Is Lossy Emacs"
build zip 30 i386 "" "A file compression and packaging utility compatible with PKZIP"
build zlib 1.2.13 i386 "" "Compression and decompression library"
echo
echo "DONE."
exit
