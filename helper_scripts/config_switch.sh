#!/bin/bash

echo "#################################"
echo "  Running Extra_Switch_Config.sh"
echo "#################################"
sudo su

## DHCP
echo " ### Make DHCP behave better ###"
echo "retry 1;" >> /etc/dhcp/dhclient.conf
echo "timeout 1800;" >> /etc/dhcp/dhclient.conf

## Networking
echo " ### Baseline Interface file ###"
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto vagrant
iface vagrant inet dhcp

auto eth0
iface eth0 inet dhcp

EOT

## Convenience code. This is normally done in ZTP.
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
mkdir /home/cumulus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus
chown -R cumulus:cumulus /home/cumulus
chmod 600 /home/cumulus/.ssh/*
chmod 700 /home/cumulus/.ssh

## NetQ agent
echo " ### Install NetQ Agent ###"
cat << EOF > /etc/apt/sources.list.d/netq.list
deb https://apps3.cumulusnetworks.com/repos/deb CumulusLinux-3 netq-1.3
EOF
apt update
apt-get install -y cumulus-netq
netq config add server 192.168.0.254
netq config add experimental
netq config restart agent

echo "#################################"
echo "   Finished"
echo "#################################"
