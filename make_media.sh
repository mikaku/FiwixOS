#!/bin/sh
#
# this script creates the FiwixOS media files.
#

SOURCE_FLOPPY=fiwix-floppy-base.img.gz
SOURCE_FLOPPY_INITRD=initrd-base.img.gz
FLOPPY_IMAGE=FiwixOS-$1-i386.img
FLOPPY_INITRD_IMAGE=FiwixOS-$1-initrd-i386.img
ISO_IMAGE=FiwixOS-$1-i386.iso

create_ipk() {
	dir=$1
	prg=$2
	ver=$3
	arch=$4
	deps="$5"
	desc="$6"

	if [ ! -f ${dir}/${prg}-${ver}.tar.bz2 ] ; then
		echo "file ${dir}/${prg}-${ver}.tar.bz2 does not exist."
		return
	fi

	pushd /tmp
		rm -f data.tar.gz
		bzip2 -dc ${dir}/${prg}-${ver}.tar.bz2 > data.tar || exit 1
		gzip -9 data.tar
		cat > control <<EOF
Package: $prg
Version: $ver
Architecture: $arch
Maintainer: jordi@fibranet.cat
Description: $desc
Depends: $deps

EOF
		mkdir -p $prg
		mv data.tar.gz $prg
		tar zcf ${prg}/control.tar.gz control
		echo 2.0 > ${prg}/debian-binary
		tar -C $prg -zcf ${dir}/${prg}_${ver}_${arch}.ipk .
		rm -rf $prg control
	popd
	rm -f ${dir}/${prg}-${ver}.tar.bz2
}

create_directories() {
	media=$1

	mkdir -p /tmp/$media/proc
	mkdir -p /tmp/$media/etc
	mkdir -p /tmp/$media/mnt/boot
	mkdir -p /tmp/$media/mnt/disk
	mkdir -p /tmp/$media/mnt/floppy
	mkdir -p /tmp/$media/mnt/cdrom
	mkdir -p /tmp/$media/mnt/ram
	mkdir -p /tmp/$media/sbin
	mkdir -p /tmp/$media/dev

	mkdir -p /tmp/$media/root ; chmod 700 /tmp/$media/root
	mkdir -p /tmp/$media/bin
	mkdir -p /tmp/$media/sbin
	mkdir -p /tmp/$media/usr/bin
	mkdir -p /tmp/$media/usr/sbin

	ln -s /mnt/disk/var /tmp/$media/var
}

makedev() {
	media=$1 ; shift
	mknod /tmp/$media/dev/$1 $2 $3 $4
	chmod 666 /tmp/$media/dev/$1
}

create_devices() {
	media=$1

	echo "creating memory devices ..."
	makedev $media mem c 1 1
	makedev $media kmem c 1 2
	makedev $media null c 1 3
	makedev $media port c 1 4
	makedev $media zero c 1 5
	makedev $media full c 1 7
	makedev $media random c 1 8
	makedev $media urandom c 1 9
	makedev $media ram0 b 1 0
	ln -s ram0 /tmp/$media/dev/ram
	makedev $media ram1 b 1 1
	makedev $media ram2 b 1 2
	makedev $media ram3 b 1 3
	makedev $media ram4 b 1 4
	makedev $media ram5 b 1 5
	makedev $media ram6 b 1 6
	makedev $media ram7 b 1 7
	makedev $media ram8 b 1 8
	makedev $media ram9 b 1 9

	echo "creating floppy devices ..."
	makedev $media fd0 b 2 0
	makedev $media fd0h360 b 2 4
	makedev $media fd0h1200 b 2 8
	makedev $media fd0h720 b 2 12
	makedev $media fd0h1440 b 2 16
	makedev $media fd1 b 2 1
	makedev $media fd1h360 b 2 5
	makedev $media fd1h1200 b 2 9
	makedev $media fd1h720 b 2 13
	makedev $media fd1h1440 b 2 17

	echo "creating hard disk devices ..."
	makedev $media hda b 3 0
	makedev $media hda1 b 3 1
	makedev $media hda2 b 3 2
	makedev $media hda3 b 3 3
	makedev $media hda4 b 3 4
	makedev $media hdb b 3 64
	makedev $media hdb1 b 3 65
	makedev $media hdb2 b 3 66
	makedev $media hdb3 b 3 67
	makedev $media hdb4 b 3 68
	makedev $media hdc b 22 0
	makedev $media hdc1 b 22 1
	makedev $media hdc2 b 22 2
	makedev $media hdc3 b 22 3
	makedev $media hdc4 b 22 4
	makedev $media hdd b 22 64
	makedev $media hdd1 b 22 65
	makedev $media hdd2 b 22 66
	makedev $media hdd3 b 22 67
	makedev $media hdd4 b 22 68

	echo "creating tty devices ..."
	makedev $media console c 5 1
	makedev $media tty c 5 0
	makedev $media tty0 c 4 0
	makedev $media tty1 c 4 1
	makedev $media tty2 c 4 2
	makedev $media tty3 c 4 3
	makedev $media tty4 c 4 4
	makedev $media tty5 c 4 5
	makedev $media tty6 c 4 6
	makedev $media tty7 c 4 7
	makedev $media tty8 c 4 8
	makedev $media tty9 c 4 9
	makedev $media tty10 c 4 10
	makedev $media tty11 c 4 11
	makedev $media tty12 c 4 12
	makedev $media ttyS0 c 4 64
	makedev $media ttyS1 c 4 65
	makedev $media ttyS2 c 4 66
	makedev $media ttyS3 c 4 67

	makedev $media lp0 c 6 0

	makedev $media psaux c 10 1
	ln -s /dev/psaux /tmp/$media/dev/mouse

	ln -s /proc/self/fd /tmp/$media/dev/fd
	ln -s /proc/self/fd/0 /tmp/$media/dev/stdin
	ln -s /proc/self/fd/1 /tmp/$media/dev/stdout
	ln -s /proc/self/fd/2 /tmp/$media/dev/stderr

	sync
}

do_install_busybox() {
	media=$1 ; shift
	dir=$1 ; shift

	while $(test -n "$1") ; do
		ln -s /busybox /tmp/$media/$dir/$1
		shift
	done
}

install_busybox() {
	media=$1

	if [ "$media" = "iso" ] ; then
		echo "installing Busybox ..."
		do_install_busybox $media bin  addgroup adduser ash cat chgrp \
		chmod chown cp cpio date dd delgroup deluser df dmesg dumpkmap \
		echo egrep false fgrep grep gunzip gzip hostname kill ln login \
		ls mkdir mknod more mount mv pidof ps pwd rm rmdir  sh \
		sleep stty sync tar touch true umount uname vi watch zcat

		do_install_busybox $media sbin  fdisk fsck.minix getty halt \
		init loadkmap mkfs.minix poweroff reboot syslogd

		do_install_busybox $media usr/bin  [ awk basename bunzip2 \
		bzcat cal chvt clear cmp crontab cut dc deallocvt dirname \
		dos2unix du env expr find fold free head hexdump hostid id \
		killall last length loadfont logger md5sum mesg mkfifo od \
		openvt passwd printf readlink realpath renice reset seq \
		sha1sum sort strings tail tee test time top tr tty uniq \
		unix2dos unzip uptime uudecode uuencode vlock wc which who \
		whoami xargs yes

		do_install_busybox $media usr/sbin chroot crond

		# extract a file from a tarfile inside a tar and removing the 'dirname' part
		gzip -dc ${BASE_DIR}/builds/busybox_1.01_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/bin\///" -zxf - ./bin/busybox
		#tar --transform "s/^.\/bin\///" -jxf ${BASE_DIR}/builds/busybox-1.01.tar.bz2 ./bin/busybox
		mv busybox /tmp/$media/busybox
	else
		echo "installing a reduced-size of Busybox ..."
		do_install_busybox $media bin  ash cat chmod chown cp date dd \
		df echo grep gunzip gzip kill ln ls mkdir mknod mount mv ps \
		pwd rm rmdir  sh sleep sync tar touch umount uname zcat

		do_install_busybox $media sbin  fdisk init loadkmap reboot

		do_install_busybox $media usr/bin  [ awk basename cmp dirname \
		du env expr mkfifo passwd seq sort test uniq

		do_install_busybox $media usr/sbin chroot

		# extract a file from a tarfile inside a tar and removing the 'dirname' part
		gzip -dc ${BASE_DIR}/builds/busybox-mini_1.01_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/bin\///" -zxf - ./bin/busybox
		#tar --transform "s/^.\/bin\///" -jxf ${BASE_DIR}/builds/busybox-mini-1.01.tar.bz2 ./bin/busybox
		mv busybox /tmp/$media/busybox
	fi
}

setup_grub_floppy() {
	echo "configuring GRUB ..."
	mkdir -p /tmp/floppy/boot/grub
	cat > /tmp/floppy/boot/grub/menu.lst <<EOF
# FiwixOS
# Copyright (C) 2018-2024, Jordi Sanfeliu.
#
# GRUB configuration file.
#
default 0
timeout 5
title FiwixOS $OSVERSION (standard VGA)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/fd0
title FiwixOS $OSVERSION (VESA FB 1024x768 32bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/fd0
	vbematch 1024 768 32
title FiwixOS $OSVERSION (VESA FB 1024x768 24bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/fd0
	vbematch 1024 768 24
title FiwixOS $OSVERSION (VESA FB 800x600 32bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/fd0
	vbematch 800 600 32
title FiwixOS $OSVERSION (VESA FB 800x600 24bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/fd0
	vbematch 800 600 24
EOF

	ln -s menu.lst /tmp/floppy/boot/grub/grub.conf
}

setup_grub_initrd_floppy() {
	echo "configuring GRUB ..."
	mkdir -p /tmp/floppy/boot/grub
	cat > /tmp/floppy/boot/grub/menu.lst <<EOF
# FiwixOS
# Copyright (C) 2018-2024, Jordi Sanfeliu.
#
# GRUB configuration file.
#
default 0
timeout 5
title FiwixOS $OSVERSION (standard VGA)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/ram0 ramdisksize=1024 initrd=/boot/initrd.img
	module /boot/initrd.img
title FiwixOS $OSVERSION (VESA FB 1024x768 32bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/ram0 ramdisksize=1024 initrd=/boot/initrd.img
	module /boot/initrd.img
	vbematch 1024 768 32
title FiwixOS $OSVERSION (VESA FB 1024x768 24bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/ram0 ramdisksize=1024 initrd=/boot/initrd.img
	module /boot/initrd.img
	vbematch 1024 768 24
title FiwixOS $OSVERSION (VESA FB 800x600 32bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/ram0 ramdisksize=1024 initrd=/boot/initrd.img
	module /boot/initrd.img
	vbematch 800 600 32
title FiwixOS $OSVERSION (VESA FB 800x600 24bpp)
	root (fd0)
	kernel /boot/fiwix ro root=/dev/ram0 ramdisksize=1024 initrd=/boot/initrd.img
	module /boot/initrd.img
	vbematch 800 600 24
EOF

	ln -s menu.lst /tmp/floppy/boot/grub/grub.conf
}

setup_grub_iso() {
	echo "configuring GRUB ..."
	mkdir -p /tmp/iso/boot/grub
	cat > /tmp/iso/boot/grub/menu.lst <<EOF
# FiwixOS
# Copyright (C) 2018-2024, Jordi Sanfeliu.
#
# GRUB configuration file.
#
default 0
timeout 5
title FiwixOS $OSVERSION (standard VGA)
	kernel /boot/fiwix ro root=/dev/hdc rootfstype=iso9660 ramdisksize=4096
title FiwixOS $OSVERSION (VESA FB 1024x768 32bpp)
	kernel /boot/fiwix ro root=/dev/hdc rootfstype=iso9660 ramdisksize=4096
	vbematch 1024 768 32
title FiwixOS $OSVERSION (VESA FB 1024x768 24bpp)
	kernel /boot/fiwix ro root=/dev/hdc rootfstype=iso9660 ramdisksize=4096
	vbematch 1024 768 24
title FiwixOS $OSVERSION (VESA FB 800x600 32bpp)
	kernel /boot/fiwix ro root=/dev/hdc rootfstype=iso9660 ramdisksize=4096
	vbematch 800 600 32
title FiwixOS $OSVERSION (VESA FB 800x600 24bpp)
	kernel /boot/fiwix ro root=/dev/hdc rootfstype=iso9660 ramdisksize=4096
	vbematch 800 600 24
EOF

	ln -s menu.lst /tmp/iso/boot/grub/grub.conf

	mkdir -p /tmp/iso/install/grub
	gzip -dc ${BASE_DIR}/builds/grub_0.97_i386.ipk | tar -xOf - ./data.tar.gz | tar -C /tmp/iso/install/grub -zxf - ./usr/lib/grub/ ./usr/sbin/
	#tar -C /tmp/iso/install/grub -jxf ${BASE_DIR}/builds/grub-0.97.tar.bz2 ./usr/lib/grub/ ./usr/sbin/
	ln -s usr/sbin /tmp/iso/install/grub/sbin
}

copy_etc() {
	media=$1

	echo "configure /etc directory ..."
	tar -C /tmp/$media -jxf etc.tar.bz2
	sed -i 's/_VERSION_/'$OSVERSION'/' /tmp/$media/etc/issue /tmp/$media/etc/rc.d/rcS

	if [ "$media" = "floppy" ] ; then
		sed -i '1 i\/dev/fd0	/	ext2	defaults	0 0' /tmp/$media/etc/fstab
	fi
	if [ "$media" = "iso" ] ; then
		sed -i '1 i\/dev/hdc	/	iso9660	defaults	0 0' /tmp/$media/etc/fstab
	fi
}

kernel_packages() {
	pushd $KERNEL_DIR
		# kernel source code
		make clean >/dev/null
		mkdir -p /tmp/iso/install/fiwix
		tar -jcf /tmp/iso/install/fiwix/fiwix-${KERNEL_VERSION}.tar.bz2 --exclude=.git --exclude=.gitignore --exclude=todo * --transform "s/^/fiwix-$KERNEL_VERSION\//"
	popd

	# headers
	tar -C $KERNEL_DIR --transform "s/^/.\/usr\//" -jcf /tmp/iso/install/base/kernel-headers-${KERNEL_VERSION}.tar.bz2 include
	create_ipk /tmp/iso/install/base/ \
		   kernel-headers \
		   ${KERNEL_VERSION} \
		   noarch \
		   "" \
		   "Header files for the Fiwix kernel for use by Newlib C"

	# kernel
	mkdir /tmp/boot || exit 1
	cp fiwix /tmp/boot/fiwix-${KERNEL_VERSION}
	gzip -dc System.map.gz > /tmp/boot/System.map-${KERNEL_VERSION}
	pushd /tmp/boot
		ln -s System.map-${KERNEL_VERSION} System.map
		ln -s fiwix-${KERNEL_VERSION} fiwix
	popd
	tar -C /tmp/ -jcf /tmp/iso/install/base/kernel-${KERNEL_VERSION}.tar.bz2 ./boot
	rm -rf /tmp/boot
	create_ipk /tmp/iso/install/base/ \
		   kernel \
		   ${KERNEL_VERSION} \
		   i386 \
		   "" \
		   "The Fiwix kernel"
}

make_media_setup() {
	echo "Building the media-setup image"
	echo "-----------------------------------------------------------------------"
	rm -f FiwixOS-${OSVERSION}-*

	tar --transform "s/^./FiwixOS/" --exclude=iso --exclude=.git -jcf FiwixOS-${OSVERSION}-Media-Setup.tar.bz2 .
}

make_floppy() {
	echo "Building the floppy image"
	echo "-----------------------------------------------------------------------"
	rm -rf /tmp/floppy
	mkdir -p /tmp/floppy
	gzip -dc $SOURCE_FLOPPY > $FLOPPY_IMAGE
	mount -o loop -t ext2 $FLOPPY_IMAGE /tmp/floppy

	rm -f /tmp/floppy/boot/grub/fat_stage1_5
	rm -f /tmp/floppy/boot/grub/ffs_stage1_5
	rm -f /tmp/floppy/boot/grub/iso9660_stage1_5
	rm -f /tmp/floppy/boot/grub/jfs_stage1_5
	rm -f /tmp/floppy/boot/grub/minix_stage1_5
	rm -f /tmp/floppy/boot/grub/reiserfs_stage1_5
	rm -f /tmp/floppy/boot/grub/ufs2_stage1_5
	rm -f /tmp/floppy/boot/grub/vstafs_stage1_5
	rm -f /tmp/floppy/boot/grub/xfs_stage1_5

	create_directories floppy
	create_devices floppy
	install_busybox floppy
	copy_etc floppy
	setup_grub_floppy

	cat > /tmp/floppy/etc/motd <<EOF
This is a very reduced operating system just to test the Fiwix kernel.
You cannot install FiwixOS $OSVERSION from here, use the CD-ROM instead.

EOF

	cp -p fiwix /tmp/floppy/boot
	cp -p System.map.gz /tmp/floppy/boot
	umount /tmp/floppy
	fsck.ext2 -fy $FLOPPY_IMAGE
	rm -rf /tmp/floppy
}

make_floppy_initrd() {
	echo "Building the floppy initrd image"
	echo "-----------------------------------------------------------------------"
	rm -rf /tmp/floppy
	mkdir -p /tmp/floppy

	echo "extract floppy filesystem ..."
	mount -o loop,ro -t ext2 $FLOPPY_IMAGE /tmp/floppy
	tar -C /tmp/floppy -jcf initrd.tar.bz2 ./bin ./busybox ./dev ./etc ./mnt ./proc ./root ./sbin ./usr
	umount /tmp/floppy

	echo "create the initrd filesystem ..."
	gzip -dc $SOURCE_FLOPPY_INITRD > initrd.img
	mount -o loop -t ext2 initrd.img /tmp/floppy
	tar -C /tmp/floppy -jxf initrd.tar.bz2
	umount /tmp/floppy
	fsck.ext2 -fy initrd.img

	gzip -dc $SOURCE_FLOPPY > $FLOPPY_INITRD_IMAGE
	mount -o loop -t ext2 $FLOPPY_INITRD_IMAGE /tmp/floppy

	rm -f /tmp/floppy/boot/grub/fat_stage1_5
	rm -f /tmp/floppy/boot/grub/ffs_stage1_5
	rm -f /tmp/floppy/boot/grub/iso9660_stage1_5
	rm -f /tmp/floppy/boot/grub/jfs_stage1_5
	rm -f /tmp/floppy/boot/grub/minix_stage1_5
	rm -f /tmp/floppy/boot/grub/reiserfs_stage1_5
	rm -f /tmp/floppy/boot/grub/ufs2_stage1_5
	rm -f /tmp/floppy/boot/grub/vstafs_stage1_5
	rm -f /tmp/floppy/boot/grub/xfs_stage1_5

	setup_grub_initrd_floppy

	mv initrd.img /tmp/floppy/boot
	cp -p fiwix /tmp/floppy/boot
	umount /tmp/floppy
	fsck.ext2 -fy $FLOPPY_INITRD_IMAGE
	rm -f initrd.tar.bz2
	rm -rf /tmp/floppy
}

make_iso() {
	echo "Building the ISO image"
	echo "-----------------------------------------------------------------------"
	rm -rf /tmp/iso
	mkdir -p /tmp/iso

	create_directories iso
	create_devices iso
	install_busybox iso
	copy_etc iso
	setup_grub_iso

	cat > /tmp/iso/etc/motd <<EOF
At any time, type 'install.sh' and press ENTER to proceed to install this
operating system.

EOF

	cp -p install.sh /tmp/iso/sbin
	chmod +x /tmp/iso/sbin/install.sh
	sed -i 's/_VERSION_/'$OSVERSION'/' /tmp/$media/sbin/install.sh

	# extract some necessary programs for the installation

	gzip -dc ${BASE_DIR}/builds/sed_4.9_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/usr\/bin\///" -zxf - ./usr/bin/sed
#	tar --transform "s/^.\/usr\/bin\///" -jxf ${BASE_DIR}/builds/sed-4.4.tar.bz2 ./usr/bin/sed
	mv sed /tmp/iso/usr/bin

	gzip -dc ${BASE_DIR}/builds/dialog_1.3-20250817_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/usr\/bin\///" -zxf - ./usr/bin/dialog
#	tar --transform "s/^.\/usr\/bin\///" -jxf ${BASE_DIR}/builds/dialog-1.3-20240619.tar.bz2 ./usr/bin/dialog
	mv dialog /tmp/iso/usr/bin

	gzip -dc ${BASE_DIR}/builds/ncurses_5.9_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/usr\/share\/tabset\///" -zxf - ./usr/share/tabset/vt100
#	tar --transform "s/^.\/usr\/share\/tabset\///" -jxf ${BASE_DIR}/builds/ncurses-5.9.tar.bz2 ./usr/share/tabset/vt100
	mkdir -p /tmp/iso/usr/share/tabset
	mv vt100 /tmp/iso/usr/share/tabset
	gzip -dc ${BASE_DIR}/builds/ncurses_5.9_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/usr\/share\/terminfo\/l\///" -zxf - ./usr/share/terminfo/l/linux
#	tar --transform "s/^.\/usr\/share\/terminfo\/l\///" -jxf ${BASE_DIR}/builds/ncurses-5.9.tar.bz2 ./usr/share/terminfo/l/linux
	mkdir -p /tmp/iso/usr/share/terminfo/l
	mv linux /tmp/iso/usr/share/terminfo/l

	gzip -dc ${BASE_DIR}/builds/e2fsprogs_1.40.11_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/usr\/sbin\///" -zxf - ./usr/sbin/mke2fs ./usr/sbin/e2fsck ./usr/sbin/debugfs ./usr/sbin/tune2fs
#	tar --transform "s/^.\/usr\/sbin\///" -jxf ${BASE_DIR}/builds/e2fsprogs-1.40.11.tar.bz2 ./usr/sbin/mke2fs ./usr/sbin/e2fsck ./usr/sbin/debugfs ./usr/sbin/tune2fs
	mv mke2fs e2fsck debugfs tune2fs /tmp/iso/sbin
	ln -s /sbin/e2fsck /tmp/iso/sbin/fsck.ext2

	gzip -dc ${BASE_DIR}/builds/opkg_0.6.2_i386.ipk | tar -xOf - ./data.tar.gz | tar --transform "s/^.\/usr\/bin\///" -zxf - ./usr/bin/opkg
	mv opkg /tmp/iso/usr/bin
	mkdir -p /tmp/iso/etc/opkg
	cat > /tmp/iso/etc/opkg/opkg.conf <<EOF
dest root /
dest ram /tmp
arch i386 1
arch noarch 1
EOF

	ln -s /mnt/ram/tmp /tmp/iso/tmp

	# copy all packages
	mkdir -p /tmp/iso/install/pkgs/bin/
	cp -pr ${BASE_DIR}/builds/*.ipk /tmp/iso/install/pkgs/bin/
	mkdir -p /tmp/iso/install/pkgs/src/
	cp -pr ${BASE_DIR}/makeall.sh /tmp/iso/install/pkgs/src/
	cp -pr ${BASE_DIR}/src/* /tmp/iso/install/pkgs/src/
	mkdir -p /tmp/iso/install/pkgs/buildlogs/
	cp -pr ${BASE_DIR}/logs/* /tmp/iso/install/pkgs/buildlogs/
	# copy whole iso tree
	cp -pr iso/* /tmp/iso/
	chown -R root:root /tmp/iso

	echo "creating some ipk packages ..."
	mkdir -p /tmp/iso/install/base
	cp -p basesystem.tar.bz2 /tmp/iso/install/base
	mv /tmp/iso/install/base/basesystem.tar.bz2 /tmp/iso/install/base/basesystem-${OSVERSION}.tar.bz2
	create_ipk /tmp/iso/install/base/ \
		   basesystem \
		   ${OSVERSION} \
		   noarch \
		   "" \
		   "The skeleton package which defines basic FiwixOS directories and tools"

	create_ipk /tmp/iso/install/extras/ \
		   doom1_shareware \
		   1.9 \
		   noarch \
		   "lxdoom" \
		   "The shareware .WAD file for DOOM 1"

	create_ipk /tmp/iso/install/extras/ \
		   doom2_shareware \
		   1.9 \
		   noarch \
		   "lxdoom" \
		   "The shareware .WAD file for DOOM 2"

	create_ipk /tmp/iso/install/extras/ \
		   urw_base35 \
		   20151005 \
		   noarch \
		   "" \
		   "Core Font Set containing 35 freely distributable fonts from (URW)++"

	mv /tmp/iso/README /tmp/iso/install
	mv /tmp/iso/LICENSE /tmp/iso/install
	sed -i 's/_VERSION_/'$OSVERSION'/' /tmp/iso/install/README /tmp/iso/install/LICENSE

	kernel_packages

	ln -sf /install/grub/sbin/grub /tmp/iso/usr/sbin/grub
	ln -sf /install/grub/sbin/grub-install /tmp/iso/usr/sbin/grub-install
	ln -sf /install/grub/sbin/grub-md5-crypt /tmp/iso/usr/sbin/grub-md5-crypt
	ln -sf /install/grub/sbin/grub-set-default /tmp/iso/usr/sbin/grub-set-default
	ln -sf /install/grub/usr/lib /tmp/iso/usr/lib
	cp -p /tmp/iso/install/grub/usr/lib/grub/i386-pc/stage2_eltorito .
	genisoimage -quiet -R \
		-V "FiwixOS ${OSVERSION} Installation CD" \
		-b boot/grub/stage2_eltorito \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		-input-charset iso8859-1 \
		-o ${ISO_IMAGE} \
		-graft-points \
		boot/grub/stage2_eltorito=stage2_eltorito \
		boot/fiwix=fiwix \
		boot/System.map.gz=System.map.gz \
		/tmp/iso

	rm -rf /tmp/iso
	rm -f stage2_eltorito
}


# Main
# ----------------------------------------------------------------------------

if [ $# != 2 ] ; then
	echo "$0 <os_version> <kernel_dir>"
	exit 1
fi

BASE_DIR=`pwd`
OSVERSION=$1
KERNEL_DIR=$2
KERNEL_VERSION=$(grep UTS_RELEASE ${KERNEL_DIR}/include/fiwix/system.h | awk '{print $3}' | sed 's/"//g')

cd base || exit 1

# some checks
[ ! -d "$BASE_DIR/builds" ] && echo "ERROR: directory '$BASE_DIR/builds' does not exist." && exit 1
[ ! -d "$BASE_DIR/src" ] && echo "ERROR: directory '$BASE_DIR/src' does not exist." && exit 1
[ ! -d "$BASE_DIR/logs" ] && echo "ERROR: directory '$BASE_DIR/logs' does not exist." && exit 1
[ ! -d "$KERNEL_DIR" ] && echo "ERROR: directory '$KERNEL_DIR' does not exist." && exit 1
[ -z "$KERNEL_VERSION" ] && echo "ERROR: kernel version is '$KERNEL_VERSION'." && exit 1
[ -f ${SOURCE_FLOPPY} ] || echo "ERROR: '${SOURCE_FLOPPY}' does not exist." || exit 1

make_media_setup

set -e

# save the compiled kernel
cp ${KERNEL_DIR}/fiwix .
cp ${KERNEL_DIR}/System.map.gz .

make_floppy && echo "done"
echo
make_floppy_initrd && echo "done"
echo
make_iso && echo "done"

rm -f fiwix System.map.gz
sync ; sync

