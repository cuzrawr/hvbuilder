#!/bin/bash

set -Eeuo pipefail

# Function to handle errors globally
error() {
    echo "Error: An error occurred at line $1." >&2
    exit 1
}
trap 'error $LINENO' ERR

# Constants
DOWNLOAD_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
KERNEL_REPO="https://github.com/cloud-hypervisor/linux.git"
KERNEL_BRANCH="ch-6.2"
LINUX_CONFIG_URL="https://raw.githubusercontent.com/cloud-hypervisor/cloud-hypervisor/main/resources/linux-config-x86_64"
VM_NAME="VMNameTest"
KERNEL_OUTPUT="linux-cloud-hypervisor/arch/x86/boot/compressed/vmlinux.bin"

# Function to download files
download_file() {
    local url="$1"
    local output="$2"
    echo "Downloading file from: $url... and saving output as file: $output"
    wget -c "$url" -O "$output"
}

# Function to clone and build Linux kernel
build_kernel() {
    echo "Cloning and building Linux kernel..."
    git clone --depth 1 "$KERNEL_REPO" -b "$KERNEL_BRANCH" linux-cloud-hypervisor
    pushd linux-cloud-hypervisor >/dev/null
    download_file "$LINUX_CONFIG_URL" .config
    # Compile the kernel
    echo "Compiling the kernel..."
    KCFLAGS="-Wa,-mx86-used-note=no" make bzImage -j "$(nproc)"
    make -j "$(nproc)"
    popd >/dev/null
}

# Function to convert QCOW2 to RAW format
convert_disk() {
    echo "Converting QCOW2 to RAW format..."
    qemu-img convert -p -f qcow2 -O raw "debian-12-genericcloud-amd64.qcow2" "debian-12-genericcloud-amd64.raw"
}

# init costum debian with .deb installed
customize_image() {
    echo "Customizing Debian image..."
    virt-customize -v -x -a "debian-12-genericcloud-amd64.raw" \
        --root-password password:123 \
        --append-line "/etc/ssh/sshd_config.d/rootlogin.conf:PermitRootLogin yes" \
        --append-line "/etc/ssh/sshd_config.d/rootlogin.conf:PasswordAuthentication yes" \
        --hostname "$VM_NAME" \
        --firstboot-command 'ssh-keygen -A && systemctl restart sshd' \
        --copy-in "busybox-static_1.35.0-4+b3_amd64.deb:/var/cache/apt/" \
        --install "/var/cache/apt/busybox-static_1.35.0-4+b3_amd64.deb"
}

# Function to boot the customized distribution
boot_vm() {
    echo "Booting the customized distribution via cloud-hypervisor..."
    cloud-hypervisor --kernel "./$KERNEL_OUTPUT" \
        --disk path="./debian-12-genericcloud-amd64.raw" \
        --cmdline "console=hvc0 root=/dev/vda1 initrd=./initrd rw" \
        --cpus boot=4 \
        --memory size=1024M \
        --net "tap=,mac=,ip=,mask="
}

# Main script
main() {


   echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! DEPRECATED DONT USE !!!!!!!!!!!!!!!!!!!!!!!!"
  #  download_file "$DOWNLOAD_URL" "debian-12-genericcloud-amd64.qcow2"
 #   build_kernel
#    convert_disk
 #   customize_image
    #echo "Cloud-hypervisor has started the virtual machine."

   #<<<<<<<<<<<<<<<< to boot vm
   # boot_vm

}

main
