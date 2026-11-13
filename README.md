This repository contains the source archives and patches required to build the
final set of FiwixOS packages.

I use it to add or update packages for upcoming FiwixOS releases. Put each
upstream archive in the `src/` directory, together with any required patch
files. Then update `makeall.sh` with the package name and version, and specify
how to build it.

To use this repository on your FiwixOS system when porting packages, add it to
a virtual disk. I recommend creating the virtual disk on your host operating
system:

e.g. under Linux:

`$ truncate -s 6G fiwix-builds-6GB.img`

Next, attach the disk image to your QEMU command:

```
$ qemu-system-i386 \
        -drive file=FiwixOS-3.6-i386.raw,format=raw,if=ide,cache=writeback,index=0 \
        -drive file=fiwix-builds-6GB.img,format=raw,if=ide,cache=writeback,index=3 \
        -boot c \
        -m 256 \
        -enable-kvm
```

Boot FiwixOS and login. Run `fdisk` and configure only the first
partition, `/dev/hdd1`. Then format it as EXT2 and you are done.

```
# mkfs.ext2 -r 0 -m 0 /dev/hdd1
# shutdown -h 0
```

You can now mount the virtual disk from your host operating system and clone
this repository onto it.

After cloning the repository, you can add packages or update packages. Then
boot FiwixOS, mount the filesystem, and build the packages by running
`makeall.sh`.


Building the media files
------------------------
- `base/install.sh` is the installation script included on the installation
  CD-ROM. It installs FiwixOS on your computer.

- `make_media.sh` is the script for creating the final FiwixOS media. Run it
   as `root`.

  Example: `./make_media.sh 3.6 /path/to/fiwix/source/code`

