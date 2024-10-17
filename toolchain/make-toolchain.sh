#!/bin/sh
#
# FiwixOS 3.4
# Copyright 2018-2024, Jordi Sanfeliu. All rights reserved.
# Distributed under the terms of the Fiwix License.
#
# GNU toolchain building script (with newlib) for the i386-pc-fiwix platform.
#

set -e

ROOT=$(pwd)
TARGET="i386-fiwix"
PREFIX="${ROOT}/installation"
LOG=

BINUTILS="binutils-2.25.1"
GCC="gcc-4.7.4"
NEWLIB="newlib-4.2.0"

export TARGET=${TARGET}
export PREFIX=${PREFIX}


error() {
	echo
	echo "An error has occurred. Please check the logfile '$LOG'."
	exit 1
}

_opkg() {
	prg=$1
	ver=$2
	arch=$3
	deps=$4
	desc=$5
	name="$prg-$ver"
	filename="${prg}_${ver}_$arch.ipk"

	if [ -f $filename ] ; then
		echo "File '$filename' already exists."
		return
	fi

	rm -rf $name
	mkdir $name
	pushd $name
		bzip2 -cd ../${name}.tar.bz2 > data.tar
		bzip2 -9 data.tar

		cat > control <<EOF
Package: $prg
Version: $ver
Architecture: $arch
Maintainer: Jordi Sanfeliu <jordi@fibranet.cat>
Description: $desc
Depends: $deps

EOF
		tar zcf control.tar.gz control
		echo 2.0 > debian-binary
		tar zcf ../$filename . || exit 1
	popd
	echo "$filename"
	rm -rf $name
	sync
}

setup_binutils() {
	test -f builds/${BINUTILS}.tar.bz2 && return
	LOG="${BINUTILS}.log"
	rm -f ${LOG}
	rm -rf ${PREFIX}/*
	rm -rf build-${BINUTILS}.final
	mkdir -p builds
	if [ ! -d ${BINUTILS} ] ; then
		echo -n "extracting binutils ... " | tee -a ${LOG}
		tar -jxf ${BINUTILS}.tar.bz2 || exit 1
		echo "done" | tee -a ${LOG}
		echo -n "patching binutils ... " | tee -a ${LOG}
		pushd ${BINUTILS}
			patch -p1 < ../${BINUTILS}.patch || exit 1
#			the following steps are not needed, the patch already covers it
#			cp ../${BINUTILS}.patch+ld-emulparams-elf_i386_fiwix.sh ld/emulparams/elf_i386_fiwix.sh || exit 1
#			pushd ld
#				automake || exit 1
#			popd
		popd
		echo "done" | tee -a ${LOG}
	fi
}

build_binutils() {
	test -f builds/${BINUTILS}.tar.bz2 && return
	mkdir build-${BINUTILS}.final || exit 1
	pushd build-${BINUTILS}.final
		echo "building ${BINUTILS}" | tee -a ../${LOG}
		CFLAGS="-march=i386 -s" CXXFLAGS="-march=i386" ../${BINUTILS}/configure \
			--prefix=/usr \
			--with-arch=i386 \
			-with-build-sysroot=/ \
			--with-sysroot=/ \
			--disable-multilib \
			--disable-nls \
			--disable-werror \
			--disable-shared
		make DESTDIR=${PREFIX} 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} install 2>&1 | tee -a ../${LOG}
	popd

	sync

	# at this point we need to pack binutils
	pushd $PREFIX || error
		tar jcvf ../builds/${BINUTILS}.tar.bz2 . | tee -a ../$LOG
	popd

	# at this point we need to remove the installation directory
	pushd $PREFIX || error
		rm -rf usr
	popd

	sync

	echo "***** ${BINUTILS} COMPLETED! *****" | tee -a ${LOG}
	echo | tee -a ${LOG}
	echo -e '\007'

	# STOP HERE
	# exit 0
}

setup_gcc() {
	test -f builds/${GCC}.tar.bz2 && return
	LOG="${GCC}.log"
	rm -f ${LOG}
	rm -rf build-${GCC}.final
	if [ ! -d ${GCC} ] ; then
		echo -n "extracting gcc ... " | tee -a ${LOG}
		tar -jxf ${GCC}.tar.bz2 || exit 1
		echo "done" | tee -a ${LOG}
		echo -n "patching gcc ... " | tee -a ${LOG}
		pushd ${GCC}
			patch -p1 < ../${GCC}.patch || exit 1
#			the following steps are not needed, the patch already covers it
#			cp ../${GCC}.patch+gcc-config-fiwix.h gcc/config/fiwix.h || exit 1
#			pushd libstdc++-v3
#				autoconf || exit 1
#			popd
		popd
		echo "done" | tee -a ${LOG}
	fi
}

build_gcc() {
	test -f builds/${GCC}.tar.bz2 && return
	mkdir build-${GCC}.final || exit 1
	pushd build-${GCC}.final
		echo "building ${GCC}" | tee -a ../${LOG}
		CFLAGS="-march=i386 -s" CXXFLAGS="-march=i386" ../${GCC}/configure \
			--prefix=/usr \
			--with-arch=i386 \
			--with-gmp=/ \
			--with-mpfr=/ \
			--with-mpc=/ \
			--enable-languages=c,c++ \
			--disable-lto \
			--disable-shared \
			--disable-multilib \
			--with-newlib \
			--disable-nls \
			--disable-bootstrap \
			--disable-libstdcxx-pch \
			--disable-werror
		make DESTDIR=${PREFIX} all-gcc 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} install-gcc 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} all-target-libgcc 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} install-target-libgcc 2>&1 | tee -a ../${LOG}
	popd
	ln -s /usr/bin/gcc ${PREFIX}/usr/bin/cc
	rm -f ${PREFIX}/usr/lib/gcc/i386-pc-fiwix/4.7.4/include-fixed/limits.h

	sync

	# at this point we need to pack gcc
	pushd $PREFIX || error
		rm -f ./usr/bin/i386-pc-fiwix-*
		tar jcvf ../builds/${GCC}.tar.bz2 . | tee -a ../$LOG
	popd

	# now untar binutils and rename all binaries to avoid newlib complaints
	pushd $PREFIX || error
		tar jxf ../builds/${BINUTILS}.tar.bz2
		pushd usr/bin
			for file in * ; do mv $file i386-fiwix-$file ; done
		popd
	popd

	sync

	echo "***** ${GCC} COMPLETED! *****" | tee -a ${LOG}
	echo | tee -a ${LOG}
	echo -e '\007'

	# STOP HERE
	#exit 0
}

setup_newlib() {
	test -f builds/${NEWLIB}.tar.bz2 && return
	LOG="${NEWLIB}.log"
	rm -f ${LOG}
	rm -rf build-${NEWLIB}.final
	if [ ! -d ${NEWLIB} ] ; then
		echo -n "extracting newlib " | tee -a ${LOG}
		tar -zxf ${NEWLIB}.tar.gz || exit 1
		echo "done" | tee -a ${LOG}
		echo -n "patching newlib " | tee -a ${LOG}
		pushd ${NEWLIB}
			patch -p1 < ../${NEWLIB}.getlogin.patch
			patch -p1 < ../${NEWLIB}.patch || exit 1
			tar -C newlib/libc/sys -zxf ../${NEWLIB}.patch+newlib-libc-sys-fiwix.tar.gz || exit 1
			pushd newlib/libc/sys
				autoconf || exit 1
			popd
#			pushd newlib/libc/sys/fiwix
#				autoconf
#			popd
		popd
		echo "done" | tee -a ${LOG}
	fi
}

build_newlib() {
	export PATH=${PREFIX}/usr/bin:${PATH}

	test -f builds/${NEWLIB}.tar.bz2 && return
	mkdir build-${NEWLIB}.final || exit 1
	pushd build-${NEWLIB}.final
		echo "building ${NEWLIB}" | tee -a ../${LOG}
		../${NEWLIB}/configure \
			--target=${TARGET} \
			--host=i386 \
			--prefix=/usr \
			--with-arch=i386 \
			--enable-libstdcxx \
			--enable-newlib-io-c99-formats \
			--enable-newlib-long-time_t
		make DESTDIR=${PREFIX} all 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} install 2>&1 | tee -a ../${LOG}
	popd
	sed -i 's/_Noreturn/__attribute__((__noreturn__))/' ${PREFIX}/usr/i386-fiwix/include/stdlib.h

	# remove spawn.h as its functions are not provided with Newlib and it confuses autotools
	rm -f ${PREFIX}/usr/i386-fiwix/include/spawn.h

	sync

	# at this point we need to pack newlib
	pushd $PREFIX || error
		tar --transform "s/i386-fiwix/i386-pc-fiwix/" -jcvf ../builds/${NEWLIB}.tar.bz2 ./usr/i386-fiwix | tee -a ../$LOG
	popd

	sync

	echo "***** ${NEWLIB} COMPLETED! *****" | tee -a ${LOG}
	echo | tee -a ${LOG}
	echo -e '\007'

	# STOP HERE
	#exit 0
}

build_libstdc() {
	IFS="-" read -r prg ver <<< "${GCC}"
	GCCLIBSTDC="${prg}_libstdc++-$ver"
	test -f builds/${GCCLIBSTDC}.tar.bz2 && return
	LOG="${GCCLIBSTDC}.log"
	rm -f ${LOG}
	pushd build-${GCC}.final
		echo "building ${GCCLIBSTDC}" | tee -a ../${LOG}
		rm -rf i386-pc-fiwix/libquadmath
		rm -rf i386-pc-fiwix/libssp
		rm -rf i386-pc-fiwix/libstdc++-v3
		ln -s ../${NEWLIB}/newlib .
		ln -s ../${NEWLIB}/libgloss .
		make DESTDIR=${PREFIX} all-target-libstdc++-v3 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} all-target-libssp 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} all-target-libquadmath 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} install all-target-libstdc++-v3 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} install all-target-libssp 2>&1 | tee -a ../${LOG}
		make DESTDIR=${PREFIX} install all-target-libquadmath 2>&1 | tee -a ../${LOG}
	popd
	rm -f ${PREFIX}/usr/lib/gcc/i386-pc-fiwix/4.7.4/include-fixed/limits.h
	rm -rf ${PREFIX}/usr/lib/gcc/i386-pc-fiwix/4.7.4/include/ssp/

	sync

	# at this point we need to pack libstdc++
	pushd $PREFIX || error
		tar jcvf ../builds/${GCCLIBSTDC}.tar.bz2 ./usr/include/ ./usr/lib* ./usr/share/ | tee -a ../$LOG
	popd

	sync

	echo "***** ${GCCLIBSTDC} COMPLETED! *****" | tee -a ${LOG}
	echo | tee -a ${LOG}
	echo -e '\007'
}

# Main
# ----------------------------------------------------------------------------

setup_binutils
build_binutils

setup_gcc
build_gcc

setup_newlib
build_newlib

build_libstdc

echo "" | tee -a ${LOG}
echo "Toolchain for ${TARGET} completed." | tee -a ${LOG}
echo "" | tee -a ${LOG}


echo "creating ipk packages ..."
pushd builds
	IFS="-" read -r prg ver <<< "${BINUTILS}"
	_opkg $prg $ver i386 "" "A GNU collection of binary utilities."

	IFS="-" read -r prg ver <<< "${GCC}"
	_opkg $prg $ver i386 "binutils" "The GNU Compiler Collection."

	IFS="-" read -r prg ver <<< "${NEWLIB}"
	_opkg $prg $ver i386 "" "A simple ANSI C library, math library and collection of board support packages."

	IFS="-" read -r prg ver <<< "${GCC}"
	_opkg "${prg}_libstdc++" $ver i386 "gcc" "GNU Standard C++ Library."
popd

