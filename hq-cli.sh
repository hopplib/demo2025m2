#!/bin/bash

# Installing packages
apt-get install -y yandex-browser-stable chrony nfs-server

# Chrony

systemctl enable --now chronyd
echo "server 172.16.4.2 iburst" >> /etc/chrony.conf
systemctl restart chronyd

# Nfs

mkdir -p /mnt/nfs

echo "192.168.100.2:/exported/path mnt/nfs nfs default 0 0" >> /etc/fstab

cat /etc/exports

exposrtfs -v

