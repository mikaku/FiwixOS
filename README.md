This repository contains all the tarballs and patches needed to build the final
set of FiwixOS packages.

I use it to add or update packages for the next FiwixOS release. Place each
upstream tarball in the `src/` directory, along with its patch file, if one is
needed. You must also update `makeall.sh` to include the package name and
version and specify how to build it.

To use this repository from your FiwixOS system and port packages, include it
on a virtual disk drive. I recommend creating the virtual disk in your host
operating system:

e.g. under Linux:

`$ truncate -s 6G fiwix-builds-6GB.img`

Then, the first thing you need to do is format it under FiwixOS. You must
include this disk image into your QEMU command, like this:

Then format the virtual disk under FiwixOS. To do that, add the disk image to
your QEMU command as shown below:

```
$ qemu-system-i386 \
        -drive file=FiwixOS-3.6-i386.raw,format=raw,if=ide,cache=writeback,index=0 \
        -drive file=fiwix-builds-6GB.img,format=raw,if=ide,cache=writeback,index=3 \
        -boot c \
        -m 256 \
        -enable-kvm
```

Boot your FiwixOS and login, then execute `fdisk` and configure only the first
partition `/dev/hdd1`. Then format the partition with EXT2 and you are done.

```
# mkfs.ext2 -r 0 -m 0 /dev/hdd1
# shutdown -h 0
```

At this point you can mount this virtual disk from your host Operating System,
and clone this repository into it.

Once you have clone it you can add new packages or update them, then boot
FiwixOS and mount the filesystem to build the packages with the script
`makeall.sh`.


Building the media files
------------------------
- `base/install.sh` is the installation script that comes with the Installation
  CD-ROM. This is the script that is used to install FiwixOS in your computer.

- `make_media.sh` is the script intended to be run under `root` to create the
  final FiwixOS media.

  Example: `./make_media.sh 3.6 /path/to/fiwix/source/code`

