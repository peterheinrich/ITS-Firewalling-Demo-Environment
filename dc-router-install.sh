#!/bin/bash

in-target /bin/sh -c -- "apt install -y -q vim mc net-tools tcpdump"
in-target /bin/sh -c -- "apt install -y -q sudo"
in-target /bin/sh -c -- "usermod -a -G sudo sysadmin"
in-target /bin/sh -c -- 'echo XKBMODEL=\"pc105\" > /etc/default/keyboard'
in-target /bin/sh -c -- 'echo XKBLAYOUT=\"de\" >> /etc/default/keyboard'
in-target /bin/sh -c -- 'echo XKBVARIANT=\"de_CH\" >> /etc/default/keyboard'
in-target /bin/sh -c -- 'echo XKBOPTIONS=\"\" >> /etc/default/keyboard'
in-target /bin/sh -c -- 'echo BACKSPACE=\"guess\" >> /etc/default/keyboard'

in-target /bin/sh -c -- 'echo "source /etc/network/interfaces.d/*" > /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "auto lo" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "iface lo inet loopback" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "auto enp0s3" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "iface enp0s3 inet static" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    address 172.16.0.1" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    network 172.16.0.0" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    netmask 255.255.0.0" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    broadcast 172.16.255.255" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "auto enp0s8" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "iface enp0s8 inet static" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    address 192.168.110.2" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    network 192.168.110.0" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    netmask 255.255.255.0" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    broadcast 192.168.110.255" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    gateway 192.168.110.1" >> /etc/network/interfaces'

in-target /bin/sh -c -- 'echo "supersede domain-name-servers 8.8.8.8" >> /etc/dhcp/dhclient.conf'

in-target /bin/sh -c -- 'sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf'

poweroff