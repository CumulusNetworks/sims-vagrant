#! /bin/bash

net add vlan 1
net add interface swp1-48 bridge access 1
net add vlan 1 ip address 192.168.0.1/24
net commit

