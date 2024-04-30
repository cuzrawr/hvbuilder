#!/bin/sh

# Default PATH differs between shells, and is not automatically exported
# by klibc dash. Make it consistent.
export PATH=/sbin:/usr/sbin:/bin:/usr/bin

[ -d /dev ] || mkdir -m 0755 /dev
[ -d /root ] || mkdir -m 0700 /root
[ -d /sys ] || mkdir /sys
[ -d /proc ] || mkdir /proc
[ -d /tmp ] || mkdir /tmp
#test
[ -d /run ] ||mkdir /run
mkdir -p /var/lock
mount -t sysfs -o nodev,noexec,nosuid sysfs /sys
mount -t proc -o nodev,noexec,nosuid proc /proc

# Note that this only becomes /dev on the real filesystem if udev's scripts
# are used; which they will be, but it's worth pointing out
mount -t devtmpfs -o nosuid,mode=0755 udev /dev

# Prepare the /dev directory
[ ! -h /dev/fd ] && ln -s /proc/self/fd /dev/fd
[ ! -h /dev/stdin ] && ln -s /proc/self/fd/0 /dev/stdin
[ ! -h /dev/stdout ] && ln -s /proc/self/fd/1 /dev/stdout
[ ! -h /dev/stderr ] && ln -s /proc/self/fd/2 /dev/stderr

mkdir /dev/pts
mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true

# Export the dpkg architecture
export DPKG_ARCH=
#. /conf/arch.conf
export DPKG_ARCH=amd64


# Set modprobe env
export MODPROBE_OPTIONS="-qb"

# Export relevant variables
export ROOT=
export ROOTDELAY=
export ROOTFLAGS=
export ROOTFSTYPE=
export IP=
export DEVICE=
export BOOT=
export BOOTIF=
export UBIMTD=
export break=
export init=/sbin/init
export readonly=y
export rootmnt=/mnt/newroot
export debug=
export panic=
export blacklist=
export resume=
export resume_offset=
export noresume=
export drop_caps=
export fastboot=n
export forcefsck=n
export fsckfix=

# mkdir -p /mnt/ro_system
# mkdir -p /mnt/rw_system
# mount -t erofs -o ro /dev/vda /mnt/ro_system
# mkdir /mnt/overlay
# mkdir /mnt/overlay/upper
# mkdir /mnt/overlay/work
# mkdir -p /mnt/workdir
# mount -t tmpfs none /mnt/rw_system

# mount -t overlay overlay -o lowerdir=/mnt/ro_system,upperdir=/mnt/rw_system,workdir=/mnt/workdir /mnt/overlay
# ls /mnt/overlay/

mkdir /mnt

mount -t tmpfs inittemp /mnt

mkdir /mnt/lower
mkdir /mnt/rw
mount -t tmpfs root-rw /mnt/rw
mkdir /mnt/rw/upper
mkdir /mnt/rw/work
mkdir /mnt/newroot
mount  -t erofs -o ro /dev/vda /mnt/lower
mount  -t overlay -o lowerdir=/mnt/lower,upperdir=/mnt/rw/upper,workdir=/mnt/rw/work overlayfs-root /mnt/newroot



for x in $(cat /proc/cmdline); do
    case $x in
    init=*)
        init=${x#init=}
        ;;
    root=*)
        ROOT=${x#root=}
        if [ -z "${BOOT}" ] && [ "$ROOT" = "/dev/nfs" ]; then
            BOOT=nfs
        fi
        ;;
    rootflags=*)
        ROOTFLAGS="-o ${x#rootflags=}"
        ;;
    rootfstype=*)
        ROOTFSTYPE="${x#rootfstype=}"
        ;;
    rootdelay=*)
        ROOTDELAY="${x#rootdelay=}"
        case ${ROOTDELAY} in
        *[![:digit:].]*)
            ROOTDELAY=
            ;;
        esac
        ;;
    nfsroot=*)
        # shellcheck disable=SC2034
        NFSROOT="${x#nfsroot=}"
        ;;
    initramfs.runsize=*)
        RUNSIZE="${x#initramfs.runsize=}"
        ;;
    ip=*)
        IP="${x#ip=}"
        ;;
    boot=*)
        BOOT=${x#boot=}
        ;;
    ubi.mtd=*)
        UBIMTD=${x#ubi.mtd=}
        ;;
    resume=*)
        RESUME="${x#resume=}"
        ;;
    resume_offset=*)
        resume_offset="${x#resume_offset=}"
        ;;
    noresume)
        noresume=y
        ;;
    drop_capabilities=*)
        drop_caps="-d ${x#drop_capabilities=}"
        ;;
    panic=*)
        panic="${x#panic=}"
        ;;
    ro)
        readonly=y
        ;;
    rw)
        readonly=n
        ;;
    debug)
        debug=y
        quiet=n
        if [ -n "${netconsole}" ]; then
            log_output=/dev/kmsg
        else
            log_output=/run/initramfs/initramfs.debug
        fi
        set -x
        ;;
    debug=*)
        debug=y
        quiet=n
        set -x
        ;;
    break=*)
        break=${x#break=}
        ;;
    break)
        break=premount
        ;;
    blacklist=*)
        blacklist=${x#blacklist=}
        ;;
    netconsole=*)
        netconsole=${x#netconsole=}
        [ "$debug" = "y" ] && log_output=/dev/kmsg
        ;;
    BOOTIF=*)
        BOOTIF=${x#BOOTIF=}
        ;;
    fastboot|fsck.mode=skip)
        fastboot=y
        ;;
    forcefsck|fsck.mode=force)
        forcefsck=y
        ;;
    fsckfix|fsck.repair=yes)
        fsckfix=y
        ;;
    fsck.repair=no)
        fsckfix=n
        ;;
    esac
done



mount -t tmpfs -o "nodev,noexec,nosuid,size=10%,mode=0755" tmpfs /run


# Move /run to the root
mount -n -o move /run ${rootmnt}/run


# don't leak too much of env - some init(8) don't clear it
# (keep init, rootmnt, drop_caps)
unset debug
unset MODPROBE_OPTIONS
unset DPKG_ARCH
unset ROOTFLAGS
unset ROOTFSTYPE
unset ROOTDELAY
unset ROOT
unset IP
unset BOOT
unset BOOTIF
unset DEVICE
unset UBIMTD
unset blacklist
unset break
unset noresume
unset panic
unset quiet
unset readonly
unset resume
unset resume_offset
unset noresume
unset fastboot
unset forcefsck
unset fsckfix
unset starttime

mount -n -o move /sys ${rootmnt}/sys
mount -n -o move /proc ${rootmnt}/proc
mount -n -o move /dev ${rootmnt}/dev

# debug
#/bin/sh

echo "AAAAAAAAAAAAAAAAA GAY OS BOOTING NICCCEEEE"

exec run-init ${drop_caps} "${rootmnt}" "${init}" "$@" <"${rootmnt}/dev/console" >"${rootmnt}/dev/console" 2>&1
echo "Something went badly wrong in the initramfs."
panic "Please file a bug on initramfs-tools."
