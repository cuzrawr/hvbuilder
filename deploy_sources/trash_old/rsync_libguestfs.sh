#!/bin/bash -

set -x

# The target directory.
mkdir -p /tmp/backup

# Create the daemon.
rm -f /tmp/rsyncd.pid

cat <<EOF > /tmp/rsyncd.conf
port = 2999
pid file = /tmp/rsyncd.pid

[backup]
  path = /home/host/TestAndDevel/clouddebian/root_debootstrap
  use chroot = false
  read only = false
EOF

rsync --daemon --config=/tmp/rsyncd.conf

# Run guestfish and attach to the guest.
guestfish --ro --network --format=qcow2 -a debian-vm.qcow2 -i <<EOF
trace on
rsync-out /etc rsync://rjones@192.168.122.1:2999/backup archive:true
EOF

# Kill the rsync daemon.
kill `cat /tmp/rsyncd.pid`
