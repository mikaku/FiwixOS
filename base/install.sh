#!/bin/sh
#
# FiwixOS _VERSION_ installation script.
# Copyright 2018-2023, Jordi Sanfeliu. All rights reserved.
# Distributed under the terms of the Fiwix License.
#

OSVERSION="_VERSION_"

KVERSION=$(uname -r)
MAXROOTSIZE=4097
MINPARTSIZE=750
umask 0022

RED="echo -en \\033[1;31m"
GREEN="echo -en \\033[1;32m"
YELLOW="echo -en \\033[1;33m"
CYAN="echo -en \\033[1;36m"
BLUE="echo -en \\033[1;34m"
BGBLUE="echo -en \\033[1;44m"
DEFAULT="echo -en \\033[m"	# \\033[0;39m
REVERSE="echo -en \\033[7m"
BRIGHT="echo -en \\033[1;39m"

DIALOG="dialog --ascii-lines --no-collapse"
HEADER="FiwixOS $OSVERSION Installation"
LINES=24
CONSOLE="/dev/tty12"
keymap=
BOOTDEV=$(df / | grep dev | awk '{print $1}')
HDLIST=$(grep " hd.$" /proc/partitions | awk '{print $4}')
HDNUM=$(echo $HDLIST | wc -w)

# number of partitions and their sizes (in MiB)
nparts=2
bootsize=8
rootsize=max
homesize=0


scroll() {
	local l
	for l in $(seq 1 1 $LINES) ; do
		echo
	done
}

press_enter() {
	local in
	$REVERSE "Press <ENTER> to $1"
	read in
	$DEFAULT
}

cleanup() {
	cd /
	umount /mnt/cdrom 2>/dev/null
	umount /mnt/ram 2>/dev/null
	umount /mnt/disk 2>/dev/null
}

abort() {
	$DEFAULT
	echo
	echo "Installation aborted."
	cleanup
	exit 1
}

system() {
	# setsid sh -c 'exec command <> /dev/tty2 >&0 2>&1'

	local result
	$@ <> $CONSOLE >&0 2>&1
	result=$?
	return $result
}

get_disksize() {
	local disk=$1
	local hd=$(echo $disk | sed 's#/dev/##')
	local kb=$(grep "$hd$" /proc/partitions | awk '{print $3}')
	local size=$(($kb / 1024))
	echo $size
}

get_partsize() {
	local part=$1
	local kb=$(grep "$part$" /proc/partitions | awk '{print $3}')
	local size=$(($kb / 1024))
	echo $size
}

welcome() {
	echo "				  W E L C O M E"
	echo
	echo "			to the installation of FiwixOS $OSVERSION"
	echo "			    for the i386 architecture"
	echo
	echo "		    Copyright (c) 2018-2023 by Jordi Sanfeliu"
	echo "			      <jordi@fibranet.cat>"
	echo
	echo
	echo "				  kernel v$KVERSION"
	echo
	echo
	echo
	echo
	echo
	echo
	echo
	press_enter "continue"
}

info1() {
	local text="
FiwixOS is a Fiwix distribution, an operating system made from
a software collection  that is based upon the Fiwix kernel. It
basically comprises the Fiwix kernel, GNU tools, libraries and
additional software.

Fiwix is an operating system kernel, written by Jordi Sanfeliu
from scratch, based on the UNIX architecture and fully focused
on being POSIX compatible. It is designed and developed mainly
as a hobby OS but also for educational purposes.

It runs on most 32-bit  ISA PCs in existence.  This means that
it should  run even on an old 80386 with 2MiB of RAM. Although
the minimum memory recommended is 128MiB.

"
	$DIALOG --backtitle "$HEADER" --title "" --msgbox "$text" 0 0
}

info2() {
	local text="
Please keep in mind  that this  kernel is not yet  suited  for
production  use and  may  well  have serious  bugs  and broken
features, which have not yet been identified or resolved.


                 *****************************
                 *** USE AT YOUR OWN RISK! ***
                 *****************************

"
	$DIALOG --backtitle "$HEADER" --title "[ WARNING ]" --msgbox "$text" 0 0
}

info3() {
	local text="
The installation  program  will  start  shortly.  You  will be
prompted for the information needed to install FiwixOS in your
hard disk drive. Default values are provided where useful.

You can interrupt the  installation  procedure at  any time by
pressing  <CTRL-C>,  then  type  'install.sh'  and  start  the
installation again.

Please be  patient and  read the  instructions  on  the screen
carefully.

Thanks.

"
	$DIALOG --backtitle "$HEADER" --title "" --msgbox "$text" 0 0
}

error() {
	echo
	echo
	echo "An error occurred during the installation."
	echo "Switch to /dev/tty12 to get more information."
	echo
	press_enter "exit"
	return 1
}

check_disk_drive() {
	if [ -z "$HDLIST" ] ; then
		local text="
Sorry,  no hard disk drives have been detected in your system.

Please, make sure you have an IDE/ATA compatible hard disk and
restart the installation procedure.

Thanks.

"
		$DIALOG --backtitle "$HEADER" --title "[ ERROR ]" --infobox "$text" 0 0
		press_enter "exit"
		exit 1
	fi
}

# RAMdisk is used to store temporary files in /tmp
setup_ramdisk() {
	system "$SOURCE/sbin/mke2fs -q -r 0 -m 0 -b 1024 /dev/ram0" || error || exit 1
	mount -t ext2 /dev/ram0 /mnt/ram || error || exit 1
	mkdir -p /mnt/ram/tmp
}

load_keymap() {
	case $1 in
		1) keymap=cf.bmap ;;
		2) keymap=dk.bmap ;;
		3) keymap=nl.bmap ;;
		4) keymap=fi.bmap ;;
		5) keymap=fr.bmap ;;
		6) keymap=de.bmap ;;
		7) keymap=gr.bmap ;;
		8) keymap=hu.bmap ;;
		9) keymap=it.bmap ;;
		10) keymap=no.bmap ;;
		11) keymap=pl.bmap ;;
		12) keymap=pt.bmap ;;
		13) keymap=es.bmap ;;
		14) keymap=uk.bmap ;;
		15) keymap=us.bmap ;;
		*) return 1 ;;
	esac

	loadkmap </etc/i18n/$keymap
	return 0
}

keyboard_selection() {
	local text="
Please specify the keyboard layout from the list below."
	local kbd
	local result

	kbd=$($DIALOG --output-fd 1 --backtitle "$HEADER" --title "[ KEYBOARD SELECTION ]" --no-tags --menu "$text" 0 40 10 \
		1 "Canadian-French" \
		2 "Danish" \
		3 "Dutch" \
		4 "Finish" \
		5 "French" \
		6 "German" \
		7 "Greece" \
		8 "Hungarian" \
		9 "Italian" \
		10 "Norwegian" \
		11 "Polish" \
		12 "Portuguese" \
		13 "Spanish-Catalan" \
		14 "UK-English" \
		15 "US-English")

	result=$?
	case $result in
		0) : ;;
		*) abort ;;
	esac
	load_keymap $kbd
	pass=2
}

target_media_selection() {
	local menulist=
	local result
	local text="
You need to specify in which hard disk you want to
install FiwixOS $OSVERSION. A minimal of  ${MINPARTSIZE}MiB of
capacity is required if you plan to install a full
system.

The following is the  list of all hard disk drives
detected in your system:
"
	for disk in $HDLIST ; do
		local size=$(get_disksize "/dev/$disk")
		size="(${size}MiB)"
		menulist="$menulist /dev/$disk $size"
	done

	TARGET=$($DIALOG --output-fd 1 --backtitle "$HEADER" --title "[ TARGET MEDIA SELECTION ]" --menu "$text" 0 0 1 $menulist)

	result=$?
	case $result in
		0) : ;;
		1) pass=$(expr $pass - 1) ; return $pass ;;
	esac

	disksize=$(get_disksize $TARGET)
	pass=3
}

installation_type_selection() {
	local text
	local result
	local finished=0

	while [ $finished = 0 ] ; do
		text="
Please specify the type of installation.
"
		if [ "$instype" = 3 ] ; then
			instype=2
		else
			instype=
		fi

		if [ -z "$instype" ] ; then
			instype=$($DIALOG --output-fd 1 --backtitle "$HEADER" --title "[ INSTALLATION TYPE SELECTION ]" --no-tags --menu "$text" 0 0 1 \
				1 "Use the entire disk for FiwixOS" \
				2 "Select an specific partition" \
				3 "Run 'fdisk' to edit the partition table manually")

			result=$?
			case $result in
				0) : ;;
				1) pass=$(expr $pass - 1) ; return $pass ;;
			esac
		fi

		targetpart=
		menulist=

		if [ "$instype" = 1 ] ; then
			finished=1
		fi

		if [ "$instype" = 2 ] ; then
			text="
Specify the partition inside $TARGET
where you want to install FiwixOS $OSVERSION.

Make sure you select a partition with enough capacity.
(${MINPARTSIZE}MiB minimum for a full system)
"
			for part in 1 2 3 4 ; do
				local t=$(echo ${TARGET} | sed 's/^\/dev\///')
				local p="${t}${part}"
				local r=$(grep ${p} /proc/partitions | awk '{print $3}')
				if ! [ -z "$r" ] ; then
					local size=$(get_partsize $p)
					size="(${size}MiB)"
					menulist="$menulist /dev/${p} $size"
				fi
			done

			if [ -z "$menulist" ] ; then
				text="
There are no partition defined in $TARGET
"
				$DIALOG --backtitle "$HEADER" --title "" --msgbox "$text" 0 0
				finished=0
				continue
			else

				targetpart=$($DIALOG --output-fd 1 --backtitle "$HEADER" --title "[ TARGET MEDIA SELECTION ]" --menu "$text" 0 0 2 $menulist)
				result=$?
				case $result in
					0) finished=1 ;;
					1) finished=0
				   	continue ;;
				esac
			fi
			separateboot=1	# selecting a partition implies not to separate /boot
		fi

		if [ "$instype" = 3 ] ; then
			$BRIGHT ; $DEFAULT
			clear
			fdisk -l $TARGET
			fdisk $TARGET
			$BRIGHT ; $BGBLUE
		fi
	done

	pass=4
}

boot_configuration() {
	local text
	local result
	local finished=0

	while [ $finished = 0 ] ; do
		if [ "$instype" = 1 ] ; then
			text="
Do you want to put /boot on a separated partition?

"
			$DIALOG --backtitle "$HEADER" --title "[ INSTALLATION TYPE SELECTION ]" --extra-button --extra-label Cancel --yesno "$text" 0 0

			result=$?
			case $result in
				0 | 1) separateboot=$result ;;
				3) pass=$(expr $pass - 1) ; return $pass ;;
			esac
		fi
		if [ "$instype" = 1 ] || [ "$instype" = 2 ] ; then
			text="
Do you want to install the GRUB boot loader when finished?

"
			$DIALOG --backtitle "$HEADER" --title "[ INSTALLATION TYPE SELECTION ]" --extra-button --extra-label Cancel --yesno "$text" 0 0

			result=$?
			case $result in
				0 | 1) installgrub=$result
				       finished=1 ;;
				3) pass=$(expr $pass - 1) ; return $pass ;;
			esac
		fi
	done

	pass=5
}

select_packages() {
	local text="
Please specify the software selection from the list below.
"
	local result

	software=$($DIALOG --output-fd 1 --backtitle "$HEADER" --title "[ SOFTWARE SELECTION ]" --no-tags --menu "$text" 0 45 3 \
		full "Full install (all packages)" \
		min  "Minimal install (basic functionality)")

	result=$?
	case $result in
		0) : ;;
		1) pass=$(expr $pass - 1) ; return $pass ;;
	esac
	pass=6
}

last_warning() {
	local wish
	local result
	local targettext

	if [ "$instype" = 1 ] ; then
		targettext="hard disk"
		targetdev=$TARGET
	fi
	if [ "$instype" = 2 ] ; then
		targettext="partition"
		targetdev=$targetpart
		nump=$(echo $targetpart | sed 's#^'${TARGET}'##')
	fi

	local text="
If you continue all files currently on the $targettext
'$targetdev' will be erased!

Do you really want to continue ('yes' or 'no')?
"

	while : ; do
		wish=$($DIALOG --output-fd 1 --backtitle "$HEADER" --title "[ LAST WARNING ]" --inputbox "$text" 0 0)
		result=$?
		case $result in
			0) : ;;
			1) pass=$(expr $pass - 1) ; return $pass ;;
		esac

		case $wish in
			yes) pass=999 ; break ;;
			no) pass=$(expr $pass - 1) ; break ;;
		esac
	done

	if [ "$instype" = 1 ] ; then
		disksize=$(($disksize - ($bootsize + 1)))
		if [ "$disksize" -gt $MAXROOTSIZE ] ; then
			nparts=3
			rootsize=$MAXROOTSIZE
			homesize=max
		fi
	fi
}


show_progress() {
	$DIALOG --backtitle "$HEADER" --title "[ CONFIGURING $TARGET ]" --infobox "$progress" 12 50
}

initializing_disk_partition_table() {
	if [ "$instype" = 2 ] ; then
		return
	fi

	progress="Initializing disk partition table\n" ; show_progress

	system "dd if=/dev/zero of=$TARGET bs=1c count=512" || error || exit 1
	echo w | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
}

create_boot_partition() {
	if [ "$separateboot" = 1 ] ; then
		return
	fi
	if [ "$instype" = 2 ] ; then
		return
	fi

	progress=$(echo "${progress}Creating partition $nump for /boot\n") ; show_progress

	(echo n ; echo p ; echo $nump ; echo 1 ; echo +${bootsize}M ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
	nump=$(expr $nump + 1)
}

create_root_partition() {
	if [ "$instype" = 2 ] ; then
		return
	fi

	progress=$(echo "${progress}Creating partition $nump for /\n") ; show_progress

	if [ "$rootsize" = "max" ] ; then
		(echo n ; echo p ; echo $nump ; echo ; echo ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
	else
		(echo n ; echo p ; echo $nump ; echo ; echo +${rootsize}M ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
	fi

	if [ "$nparts" -le 2 ] ; then
		nump=1
	fi
}

create_home_partition() {
	if [ "$instype" = 2 ] ; then
		return
	fi

	if [ "$nparts" -gt 2 ] ; then
		nump=$(expr $nump + 1)
		progress=$(echo "${progress}Creating partition $nump for /home\n") ; show_progress

		if [ "$homesize" = "max" ] ; then
			(echo n ; echo p ; echo $nump ; echo ; echo ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
		else
			(echo n ; echo p ; echo $nump ; echo ; echo +${homesize}M ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
		fi
	fi
}

make_boot_fs() {
	if [ "$separateboot" = 1 ] ; then
		return
	fi
	if [ "$instype" = 2 ] ; then
		return
	fi

	nump=1
	progress=$(echo "${progress}Making /boot filesystem\n") ; show_progress

	(echo t ; echo $nump ; echo 83 ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
	system "$SOURCE/sbin/mke2fs -q -r 0 -b 1024 ${TARGET}${nump}" || error || exit 1
	nump=$(expr $nump + 1)
}

make_root_fs() {
	progress=$(echo "${progress}Making / filesystem\n") ; show_progress

	# count how many partitions there are
	local count=0
	for part in 1 2 3 4 ; do
		local t=$(echo ${TARGET} | sed 's/^\/dev\///')
		local p="${t}${part}"
		local r=$(grep ${p} /proc/partitions | awk '{print $3}')
		if ! [ -z "$r" ] ; then
			count=$(expr $count + 1)
		fi
	done

	if [ "$count" = 1 ] ; then
		(echo t ; echo 83 ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
	else
		(echo t ; echo $nump ; echo 83 ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
	fi
	system "$SOURCE/sbin/mke2fs -q -r 0 -b 1024 ${TARGET}${nump}" || error || exit 1
}

make_home_fs() {
	if [ "$nparts" -gt 2 ] ; then
		progress=$(echo "${progress}Making /home filesystem\n") ; show_progress

		nump=$(expr $nump + 1)
		(echo t ; echo $nump ; echo 83 ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
		system "$SOURCE/sbin/mke2fs -q -r 0 -b 1024 ${TARGET}${nump}" || error || exit 1
		nump=$(expr $nump - 1)
	fi
}

activate_boot() {
	if [ "$installgrub" = 1 ] ; then
		return
	fi

	progress=$(echo "${progress}Activating boot partition\n") ; show_progress

	(echo a ; echo 1 ; echo w) | /busybox fdisk $TARGET >$CONSOLE 2>$CONSOLE || error || exit 1
}

show_target_layout() {
	local text="
The following is the current partition layout in $TARGET:"

	fdisk -l $TARGET | $DIALOG --backtitle "$HEADER" --title "[ DEVICE LAYOUT ]" --programbox "$text" 18 77
}

start_copy() {
	local text="
All software packages in CD-ROM are going to be transferred on to your hard disk."

	$DIALOG --backtitle "$HEADER" --title "[ SOFTWARE INSTALLATION ]" --msgbox "$text" 0 0
}

mount_root_fs() {
	progress="Preparing root filesystem\n" ; show_progress

	system "mount -t ext2 ${TARGET}${nump} /mnt/disk" || error || exit 1
	cd /mnt/disk
}

create_devices() {
	progress=$(echo "${progress}Creating devices\n") ; show_progress

	system "mkdir dev" || error || exit 1
	makedev mem c 1 1 640 mem
	makedev kmem c 1 2 640 kmem
	makedev null c 1 3 666 root
	makedev port c 1 4 640 kmem
	makedev zero c 1 5 666 root
	makedev full c 1 7 666 root
	makedev random c 1 8 644 root
	makedev urandom c 1 9 644 root
	makedev ram0 b 1 0 660 disk
	ln -s /dev/ram0 dev/ram
	makedev ram1 b 1 1 660 disk
	makedev ram2 b 1 2 660 disk
	makedev ram3 b 1 3 660 disk
	makedev ram4 b 1 4 660 disk
	makedev ram5 b 1 5 660 disk
	makedev ram6 b 1 6 660 disk
	makedev ram7 b 1 7 660 disk
	makedev ram8 b 1 8 660 disk
	makedev ram9 b 1 9 660 disk

	makedev fd0 b 2 0 660 floppy
	makedev fd0h360 b 2 4 660 floppy
	makedev fd0h1200 b 2 8 660 floppy
	makedev fd0h720 b 2 12 660 floppy
	makedev fd0h1440 b 2 16 660 floppy
	makedev fd1 b 2 1 660 floppy
	makedev fd1h360 b 2 5 660 floppy
	makedev fd1h1200 b 2 9 660 floppy
	makedev fd1h720 b 2 13 660 floppy
	makedev fd1h1440 b 2 17 660 floppy

	makedev hda b 3 0 660 disk
	makedev hda1 b 3 1 660 disk
	makedev hda2 b 3 2 660 disk
	makedev hda3 b 3 3 660 disk
	makedev hda4 b 3 4 660 disk
	makedev hdb b 3 64 660 disk
	makedev hdb1 b 3 65 660 disk
	makedev hdb2 b 3 66 660 disk
	makedev hdb3 b 3 67 660 disk
	makedev hdb4 b 3 68 660 disk
	makedev hdc b 22 0 660 disk
	makedev hdc1 b 22 1 660 disk
	makedev hdc2 b 22 2 660 disk
	makedev hdc3 b 22 3 660 disk
	makedev hdc4 b 22 4 660 disk
	makedev hdd b 22 64 660 disk
	makedev hdd1 b 22 65 660 disk
	makedev hdd2 b 22 66 660 disk
	makedev hdd3 b 22 67 660 disk
	makedev hdd4 b 22 68 660 disk

	makedev console c 5 1 600 root
	makedev tty c 5 0 666 root
	makedev tty0 c 4 0 660 root
	makedev tty1 c 4 1 660 root
	makedev tty2 c 4 2 660 root
	makedev tty3 c 4 3 660 root
	makedev tty4 c 4 4 660 root
	makedev tty5 c 4 5 660 root
	makedev tty6 c 4 6 660 root
	makedev tty7 c 4 7 660 root
	makedev tty8 c 4 8 660 root
	makedev tty9 c 4 9 660 root
	makedev tty10 c 4 10 660 root
	makedev tty11 c 4 11 660 root
	makedev tty12 c 4 12 660 root
	makedev ttyS0 c 4 64 660 root
	makedev ttyS1 c 4 65 660 root
	makedev ttyS2 c 4 66 660 root
	makedev ttyS3 c 4 67 660 root

	makedev lp0 c 6 0 660 lp

	ln -s /proc/self/fd dev/fd
	ln -s /proc/self/fd/0 dev/stdin
	ln -s /proc/self/fd/1 dev/stdout
	ln -s /proc/self/fd/2 dev/stderr

	makedev fb0 c 29 0 660 root
	ln -s /dev/fb0 dev/fb

	mkfifo dev/fifo
	chmod 666 dev/fifo
}

create_system_dirs() {
	progress=$(echo "${progress}Creating system directories\n") ; show_progress

	mkdir boot
	mkdir home
	mkdir mnt
	mkdir mnt/cdrom
	mkdir mnt/disk
	mkdir mnt/floppy
	mkdir proc
	mkdir root
	mkdir tmp
	mkdir -p usr/sbin
	ln -s usr/bin bin
	ln -s usr/sbin sbin
	mkdir -p usr/lib
	ln -s usr/lib lib
	mkdir -p var/log
	mkdir -p var/run
	mkdir -p var/spool
	chmod 1777 tmp

	touch var/log/wtmp
	touch var/log/btmp
}

makedev() {
	system "mknod /mnt/disk/dev/$1 $2 $3 $4" || error || exit 1
	chmod $5 /mnt/disk/dev/$1 || error || exit 1
	chgrp $6 /mnt/disk/dev/$1 || error || exit 1
}

install_package_manager() {
	progress=$(echo "${progress}Installing package manager\n") ; show_progress

	system "opkg install -V0 -o . --force-overwrite ${SOURCE}/install/pkgs/bin/opkg_0.6.2_i386.ipk" || error || exit 1
}

install_system_software() {
	progress=$(echo "${progress}Installing system software\n") ; show_progress

	local softlist=
	local text="
Please wait while the software is installed, this may take a few minutes.
"

	if [ "$software" = "min" ] ; then
		softlist=$(ls ${SOURCE}/install/base/* 2>/dev/null \
			${SOURCE}/install/pkgs/bin/bash_* \
			${SOURCE}/install/pkgs/bin/bc_* \
			${SOURCE}/install/pkgs/bin/busybox_* \
			${SOURCE}/install/pkgs/bin/bzip2_* \
			${SOURCE}/install/pkgs/bin/chkconfig_* \
			${SOURCE}/install/pkgs/bin/coreutils_* \
			${SOURCE}/install/pkgs/bin/dialog_* \
			${SOURCE}/install/pkgs/bin/e2fsprogs_* \
			${SOURCE}/install/pkgs/bin/file_* \
			${SOURCE}/install/pkgs/bin/findutils_* \
			${SOURCE}/install/pkgs/bin/gawk_* \
			${SOURCE}/install/pkgs/bin/grep_* \
			${SOURCE}/install/pkgs/bin/grub_* \
			${SOURCE}/install/pkgs/bin/gzip_* \
			${SOURCE}/install/pkgs/bin/less_* \
			${SOURCE}/install/pkgs/bin/mandoc_* \
			${SOURCE}/install/pkgs/bin/mingetty_* \
			${SOURCE}/install/pkgs/bin/nano_* \
			${SOURCE}/install/pkgs/bin/ncurses_* \
			${SOURCE}/install/pkgs/bin/pciutils_* \
			${SOURCE}/install/pkgs/bin/perl_* \
			${SOURCE}/install/pkgs/bin/procps_* \
			${SOURCE}/install/pkgs/bin/sed_* \
			${SOURCE}/install/pkgs/bin/sysvinit_* \
			${SOURCE}/install/pkgs/bin/tar_* \
			${SOURCE}/install/pkgs/bin/termcap_* \
			${SOURCE}/install/pkgs/bin/util-linux-ng_* \
			${SOURCE}/install/pkgs/bin/vim_*)
	else
		# we need to keep the alphabetic order (base, bin, extras)
		softlist=$(ls ${SOURCE}/install/base/* ; \
			ls ${SOURCE}/install/pkgs/bin/* ; \
			ls ${SOURCE}/install/extras/* 2>/dev/null)
	fi

	for file in $softlist ; do

		# skip some packages
		case $file in
			*busybox*) continue ;;
			*kernel_${KVERSION}*) continue ;;
			*opkg_0.6.2*) continue ;;
		esac

		# skip kernel headers in minimal installations
		if [ "$software" = "min" ] ; then
			case $file in
				*kernel-headers_${KVERSION}*) continue ;;
			esac
		fi

		# check if it's a 'tar.bz2' or 'ipk'
		unset tar ipk
		tar=$(echo $file | sed 's/\.tar\.bz2$//')
		if [ "$tar" = "$file" ] ; then
			unset tar
			ipk=$(echo $file | sed 's/\(_i386\|_noarch\)\.ipk$//')
			if [ "$ipk" = "$file" ] ; then
				unset ipk
				echo "ERROR: unrecognized file '$file'."
			fi
		fi

		# is a tar.bz2
		if [ -n "$tar" ] ; then
			base=$(basename $file)
			base=$(echo $base | sed 's/\.tar\.bz2$//')
			echo "$base"
			system "tar jxf $file" || error || exit 1
		fi

		# is an ipk
		if [ -n "$ipk" ] ; then
			base=$(basename $file)
			base=$(echo $base | sed 's/\(_i386\|_noarch\)\.ipk$//')
			echo "$base"
			system "opkg install -V0 -o . --force-overwrite $file" || error || exit 1
		fi
	done | $DIALOG --backtitle "$HEADER" --title "[ INSTALLING SYSTEM SOFTWARE ]" --progressbox "$text" 19 50


	text="
Syncing disk buffers ...

"
	$DIALOG --backtitle "$HEADER" --title "[ INSTALLING SYSTEM SOFTWARE ]" --infobox "$text" 0 0
	sync
}

configure_system_files() {
	progress=$(echo "${progress}Configuring system files\n") ; show_progress

	local nump

	# make sure symlink sh points to bash
	ln -sf bash usr/bin/sh

	usr/bin/chown -R root:root etc usr 2>/dev/null
	cp ${SOURCE}/install/README root
	chmod 700 root

	cat <<EOF >root/.bash_profile
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ] ; then
	. ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:/usr/local/bin:/root/bin

export PATH

EOF

	cat <<EOF >root/.bashrc
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

EOF

	nump=1
	if [ "$separateboot" = 0 ] ; then
		cat <<EOF >etc/fstab
${TARGET}${nump}	/boot	ext2	ro,defaults	0 0
EOF
		nump=$(expr $nump + 1)
	fi


	cat <<EOF >>etc/fstab
${TARGET}${nump}	/	ext2	defaults	1 1
EOF
	nump=$(expr $nump + 1)

	if [ "$nparts" -gt 2 ] ; then
		cat <<EOF >>etc/fstab
${TARGET}${nump}	/home	ext2	rw,defaults	0 0
EOF
	fi

	cat <<EOF >>etc/fstab
none		/proc	proc	defaults,noauto	0 0
EOF

	cat <<EOF >>etc/motd

Welcome to FiwixOS $OSVERSION for the i386 architecture.

    - Read the /root/README file to know about all the packages installed.
    - Refer to the Installation CD-ROM for the source code and the license of
      every single package installed in this system.

EOF

	cat <<EOF >>etc/os-release
NAME="FiwixOS"
VERSION="$OSVERSION"
ID=fiwixos
VERSION_ID=$OSVERSION
PRETTY_NAME="FiwixOS $OSVERSION"
HOME_URL="https://fiwix.org/"

EOF

	cp /busybox usr/sbin
	ln -s /usr/sbin/busybox usr/sbin/loadkmap
	ln -s /usr/sbin/busybox usr/bin/mount
	ln -s /usr/sbin/busybox usr/bin/umount
	ln -s /usr/sbin/busybox usr/bin/adduser
	ln -s /usr/sbin/busybox usr/bin/deluser
	ln -s /usr/sbin/busybox usr/bin/addgroup
	ln -s /usr/sbin/busybox usr/bin/delgroup
	ln -s /usr/sbin/busybox usr/bin/passwd

	cat <<EOF >>etc/default/keyboard
KEYMAP="$keymap"
EOF

	sed -i 's/VERSION/'$OSVERSION'/' etc/issue etc/rc.d/rc.sysinit

	if [ "$software" != "min" ] ; then
		# activate system daemons
		/mnt/disk/usr/bin/chroot /mnt/disk sbin/chkconfig --add atd
		/mnt/disk/usr/bin/chroot /mnt/disk sbin/chkconfig --add crond
	fi
	sync
}

build_manpages_db() {
	progress=$(echo "${progress}Building manpages database\n") ; show_progress

	/mnt/disk/usr/bin/chroot /mnt/disk sbin/mandocdb
	sync
}

set_root_password() {
	progress=$(echo "${progress}Setting 'root' password\n") ; show_progress

	local text="
You need to set a password for 'root', the system administrative account.
Note that you will not be able to see the password as you type it.

"
	cd /

	$DIALOG --backtitle "$HEADER" --title "[ SETTING ROOT PASSWORD ]" --infobox "$text" 8 65
	/mnt/disk/usr/bin/chroot /mnt/disk passwd root
	sync
}

no_install_grub() {
	local text
	local targetdev
	local pathtokernel

	if [ "$instype" = 1 ] ; then
		targetdev=${TARGET}2
	fi
	if [ "$instype" = 2 ] ; then
		targetdev=$targetpart
		nump=$(echo $targetpart | sed 's#^'${TARGET}'##')
		nump=$(expr $nump - 1)
	fi

	if [ "$separateboot" = 1 ] ; then
		$pathtokernel="/boot"
	fi

	text="
Since you decided not to install GRUB, the following is the
excerpt that you'll need in order to configure your GRUB manually:

title FiwixOS $OSVERSION (standard VGA)
	root (hd0,${nump})
	kernel ${pathtokernel}/fiwix ro root=$targetdev
"
	$DIALOG --backtitle "$HEADER" --title "[ IMPORTANT NOTICE ]" --msgbox "$text" 0 0
}

install_grub() {
	progress=$(echo "${progress}Installing GRUB\n") ; show_progress

	local bootpath
	local targetdev
	local pathtokernel

	if [ "$installgrub" = 1 ] ; then
		no_install_grub
		return
	fi

	if [ "$separateboot" = 0 ] ; then
		targetdev=${TARGET}2
		mount -t ext2 ${TARGET}1 /mnt/boot || error || exit 1
		bootpath=/mnt
		pathtokernel=
	else
		targetdev=${TARGET}1
		bootpath=/mnt/disk
		pathtokernel="/boot"
	fi
	if [ "$instype" = 1 ] ; then
		nump=0
	fi
	if [ "$instype" = 2 ] ; then
		nump=$(echo $targetpart | sed 's#^'${TARGET}'##')
		nump=$(expr $nump - 1)
		targetdev=${targetpart}
	fi
	mkdir -p ${bootpath}/boot/grub

	cat <<EOF >${bootpath}/boot/grub/device.map
# this device map was generated during the FiwixOS installation
(hd0)     /dev/hda
EOF

	cat <<EOF >${bootpath}/boot/grub/menu.lst
# menu.lst generated during the FiwixOS installation
#
# FiwixOS
# Copyright (C) 2018-2023 Jordi Sanfeliu <jordi@fibranet.cat>
#
# GRUB configuration file
#
default 0
timeout 5
title FiwixOS $OSVERSION (standard VGA)
	root (hd0,${nump})
	kernel ${pathtokernel}/fiwix ro root=${targetdev}
title FiwixOS $OSVERSION (VESA FB 1024x768 32bpp)
	root (hd0,${nump})
	kernel ${pathtokernel}/fiwix ro root=${targetdev}
	vbematch 1024 768 32
title FiwixOS $OSVERSION (VESA FB 1024x768 24bpp)
	root (hd0,${nump})
	kernel ${pathtokernel}/fiwix ro root=${targetdev}
	vbematch 1024 768 24
title FiwixOS $OSVERSION (VESA FB 800x600 32bpp)
	root (hd0,${nump})
	kernel ${pathtokernel}/fiwix ro root=${targetdev}
	vbematch 800 600 32
title FiwixOS $OSVERSION (VESA FB 800x600 24bpp)
	root (hd0,${nump})
	kernel ${pathtokernel}/fiwix ro root=${targetdev}
	vbematch 800 600 24
EOF

	ln -s menu.lst ${bootpath}/boot/grub/grub.conf

	sync ; sync
	grub-install --root-directory=${bootpath} $TARGET || error || exit 1

	# cleaning up
	rm -f ${bootpath}/boot/grub/default
	rm -f /usr/lib 2>/dev/null
	rm -f /usr/sbin/grub* 2>/dev/null
	umount /mnt/boot  2>/dev/null
}

install_kernel() {
	progress=$(echo "${progress}Installing Fiwix kernel\n") ; show_progress

	if [ "$separateboot" = 0 ] ; then
		mount -t ext2 ${TARGET}1 /mnt/disk/boot || error || exit 1
	fi

	system "opkg install -V0 -o /mnt/disk --force-overwrite ${SOURCE}/install/base/kernel_${KVERSION}_i386.ipk" || error || exit 1
	umount /mnt/disk/boot  2>/dev/null

	if ! grep -q "/dev/root / iso9660" /etc/mtab ; then
		umount /mnt/cdrom
	fi
	rm -rf /mnt/disk/tmp/*
	umount /mnt/disk || error || exit 1
	umount /mnt/ram || error || exit 1
	sync ; sync
}

completed() {
	local text="
The installation of FiwixOS $OSVERSION is complete.

When you press ENTER, the system will be shut down and restarted.

*** MAKE SURE THE BOOT DRIVES (CD-ROM AND/OR DISKETTE) ARE EMPTY ***

"
	$DIALOG --backtitle "$HEADER" --title "[ INSTALLATION TERMINATED ]" --msgbox "$text" 0 0
}


# Main
# -----------------------------------------------------------------------------

trap cleanup EXIT
trap abort SIGINT SIGTERM

TARGET=
disksize=
instype=
targetpart=
separateboot=	# 0 = yes, 1 = no
installgrub=
SOURCE=
nump=
progress=
pass=1
software=

$BRIGHT ; $BGBLUE
scroll ; welcome
info1
info2
info3
check_disk_drive
setup_ramdisk

while : ; do
	case $pass in
		0) press_enter "exit" ;;
		1) keyboard_selection ;;
		2) target_media_selection ;;
		3) installation_type_selection ;;
		4) boot_configuration ;;
		5) select_packages ;;
		6) last_warning ;;
		*) break ;;
	esac
done

if [ "$instype" = 1 ] ; then
	nump=1
fi

initializing_disk_partition_table
create_boot_partition
create_root_partition
create_home_partition
make_boot_fs
make_root_fs
make_home_fs
activate_boot
show_target_layout ; start_copy
mount_root_fs
create_devices
create_system_dirs
install_package_manager
install_system_software
configure_system_files
build_manpages_db
set_root_password
install_grub
install_kernel

completed

trap - EXIT SIGINT SIGTERM
reboot
