#!/bin/bash

echo "#################################"
echo "  Running config_server.sh"
echo "#################################"
sudo su


# stop auto upgrades
sudo systemctl stop apt-daily.service
sudo systemctl stop apt-daily.timer
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer

#Replace existing network interfaces file
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# get DHCP working correctly
echo "retry 1;" >> /etc/dhcp/dhclient.conf
echo "timeout 1800;" >> /etc/dhcp/dhclient.conf

useradd cumulus -m -s /bin/bash
echo "cumulus:CumulusLinux!" | chpasswd
sed "s/PasswordAuthentication no/PasswordAuthentication yes/" -i /etc/ssh/sshd_config

## Convenience code. This is normally done in ZTP.
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
mkdir /home/cumulus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus
chown -R cumulus:cumulus /home/cumulus
chmod 600 /home/cumulus/.ssh/*
chmod 700 /home/cumulus/.ssh

export DEBIAN_FRONTEND=noninteractive

# Other stuff
ping 8.8.8.8 -c2
if [ "$?" == "0" ]; then
  apt-get update -qy
  apt-get install lldpd ntp ntpdate -qy
  echo "configure lldp portidsubtype ifname" > /etc/lldpd.d/port_info.conf 
fi

cat << EOT > /etc/ntp.conf
# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help

driftfile /var/lib/ntp/ntp.drift

statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

server 192.168.0.254 iburst

# By default, exchange time with everybody, but don't allow configuration.
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery

# Local users may interrogate the ntp server more closely.
restrict 127.0.0.1
restrict ::1

# Specify interfaces, don't listen on switch ports
interface listen eth0
EOT

sudo systemctl enable ntp.service
sudo systemctl start ntp.service

## NetQ agent
echo " ### Install NetQ Agent ###"
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA88BBC95
cat << EOF > /etc/apt/sources.list.d/netq.list
deb [arch=amd64] https://apps3.cumulusnetworks.com/repos/deb xenial netq-1.3
EOF
cat << EOF > /etc/lldpd.d/port_info.conf
configure lldp portidsubtype ifname
EOF
apt update
apt-get install -y cumulus-netq lldpd
netq config add server 192.168.0.254
netq config add experimental
netq config restart agent


echo "#################################"
echo "   Finished"
echo "#################################"
