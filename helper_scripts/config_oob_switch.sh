#! /bin/bash

MAXIF=$(ls -d /sys/class/net/swp* | sed "s/^.*swp//" | sort -g | tail -n 1)

net add vlan 1
net add interface swp1-${MAXIF} bridge access 1
net add vlan 1 ip address 192.168.0.1/24
net commit

