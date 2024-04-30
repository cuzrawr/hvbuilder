#!/bin/bash

# required
# curl
# tar
# xz-utils
# erofs tools
# libguestfs-tools
# cloud-hypervisor (specific package may vary)


echo "Building initrd..."

# Download rootfs.tar.xz from Jenkins
/usr/bin/curl -L -C - -f -o rootfs.tar.xz https://jenkins.linuxcontainers.org/job/image-debian/lastStableBuild/architecture=amd64,release=bookworm,variant=cloud/artifact/rootfs.tar.xz

# Extract rootfs
#tar xpvf rootfs.tar.xz --xattrs-include='*.*' --numeric-owner

# decompress
cp rootfs.tar.xz 1.tar.xz
xz -dv 1.tar.xz



################### WARNING ADDING SIZE IS IMPORTAND AND DEPENDS ON WHAT U WANNA DO NEXT
################### IF THER NO ENOUGH SIZE IN output.qcow2 BUILD WILL CRASH


# Create output.qcow2 from raw tar + adding size
virt-make-fs --format=qcow2 --size=+100M 1.tar output.qcow2

# Customize the image
virt-customize -v -x -a "output.qcow2" \
    --root-password password:123 \
    --hostname "hostname" \
    --firstboot-command 'ssh-keygen -A && systemctl restart sshd' \
    --copy-in "busybox-static_1.35.0-4+b3_amd64.deb:/var/cache/apt/" \
    --install "/var/cache/apt/busybox-static_1.35.0-4+b3_amd64.deb"

echo " "
echo "Please wait, this could take a while..."
echo " "

# Extract the modified rootfs and create debian2.erofs
rm -rf rootfs_building
mkdir -p rootfs_building
guestfish --ro --format=qcow2 -m /dev/sda -a output.qcow2 -i copy-out / rootfs_building
mkfs.erofs --all-root -T31536000 debian2.erofs rootfs_building

# Check if debian2.erofs exists
if [ -f "./debian2.erofs" ]; then
    echo "debian2.erofs created successfully."
else
    echo "Error: debian2.erofs was not created. Check the process."
    exit 1
fi

# Check if vmlinux.bin exists for cloud-hypervisor
if [ ! -f "./linux-cloud-hypervisor/arch/x86/boot/compressed/vmlinux.bin" ]; then
    echo "Error: vmlinux.bin does not exist. Build it first or place it in ./linux-cloud-hypervisor/arch/x86/boot/compressed/"
    exit 1
fi

# Run cloud-hypervisor for testing
cloud-hypervisor --kernel ./linux-cloud-hypervisor/arch/x86/boot/compressed/vmlinux.bin \
    --disk path=./debian2.erofs \
    --cmdline "console=hvc0 root=/dev/vda1 rw" \
    --cpus boot=2 \
    --memory size=1024M \
    --net "tap=,mac=,ip=,mask=" \
    --initramfs=./customInitrd/initrd.cpio.gz
