Since Fiwix does not support networking yet, it is not able to download the
upstream tarballs from Internet. This repository includes all the tarballs
(and patches) to create the final FiwixOS packages.

I use this repository to update the packages that will form the next FiwixOS
version, and also to include new ones. Every upstream tarball must go into
the `src/` directory along with its own patch file (if needed). Also, you must
modify the script `makeall.sh` to include the new package name and version,
and also you must specify how it must be build.

In order to use this repository from your FiwixOS system and be able to port
your packages, you need to include this repository into a virtual disk drive.
I recommend you to create a virtual disk drive in your Host Operating System:

e.g. under Linux:

`$ truncate -s 4G fiwix-builds-4GB.img`

Then, the first thing you need to do is format it under FiwixOS. You must
include this disk image into your QEMU command, like this:

```
$ qemu-system-i386 \
        -drive file=FiwixOS-3.3-i386.raw,format=raw,if=ide,cache=writeback,index=0 \
        -drive file=fiwix-builds-4GB.img,format=raw,if=ide,cache=writeback,index=3 \
        -boot c \
        -m 256 \
        -enable-kvm \
        -machine pc \
        -cpu 486 \
        -chardev pty,id=pciserial \
        -device pci-serial,chardev=pciserial \
        -serial pty
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

This repository also includes the GNU Toolchain and the Newlib C library into
the `toolchain/` directory. Use the script `make-toolchain.sh` to build the
whole Toolchain.


Building the media files
------------------------
- `base/install.sh` is the installation script that comes with the Installation
  CD-ROM. This is the script that is used to install FiwixOS in your computer.

- `make_media.sh` is the script intended to be run under `root` to create the
  final FiwixOS media.

  Example: `./make_media.sh 3.3 /path/to/fiwix/source/code`

