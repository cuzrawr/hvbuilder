



First of all use make in root directory!!!!!

possible commands:

make fetchbuild  = donwload and build busybox binary with own .config
make test        = run some tests

make             = produce build initrd
make all         = same as previous

make info        = show detailed info about produced initrd


if you want do it by hands instead, there tips:


# BusyBox Setup Guide

This guide outlines the manual process of setting up BusyBox, a software suite that provides several Unix utilities in a single executable file.

## Getting Started

1. **Download BusyBox**: Navigate to [BusyBox Downloads](https://www.busybox.net/downloads/busybox-snapshot.tar.bz2) and download the latest snapshot of BusyBox.

2. **Extract the Archive**: Use the following command to extract the downloaded tarball:
    ```bash
    tar -xvf busybox-*.tar.bz2
    cd busybox-*
    ```

3. **Copy Configuration Files**: Copy the configuration files from the `busybox_build` directory to your current BusyBox directory.

4. **Build BusyBox**: Execute the following command to build BusyBox. The `-j` flag specifies the number of jobs to run simultaneously, which can speed up the build process by utilizing multiple CPU cores.
    ```bash
    make -j
    ```

## Setting Up Scripts

Create symbolic links for all utilities provided by BusyBox:
```bash
cd bin && for t in $(./busybox --list); do ln -s busybox $t; done && cd -
```

## Creating initrd Image

Generate an initrd image using the following commands:
```bash
find initrd/ -print0 | cpio --null --create --verbose --format=newc | gzip --best > ./test-initramfs.cpio.gz
find . | cpio -o -H newc  > ../initrd.new
```

