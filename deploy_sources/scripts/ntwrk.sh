#!/bin/bash
#
# Guest VM network helper.
#
# Testing connectivity.
# ( where $IFACE your uplink ):
# $ iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
# $ echo 1 > /proc/sys/net/ipv4/ip_forward
#

#
# TODO: avoid using hardcoded IPs
#

#
# using IPv4 Bogon TEST-NET-2 ( check: Makefile )
#
IFNM=$(ip -c=never -o link show | grep -oP '(?<=^2:\s)\w+')
ip a add 198.51.100.2/24 dev "$IFNM"
ip link set dev "$IFNM" up
ip route add default via 198.51.100.1
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Remove the script itself
#rm "$0"
