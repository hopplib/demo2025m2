#!/bin/bash

# Installing packages

apt-get install -y chrony nginx

# Chrony

systemctl enable chronyd --now

cat <<EOF >> /etc/chrony.conf
allow 192.168.100.0/29
allow 192.168.200.0/29
allow 172.16.4.0/28
allow 192.168.3.0/29
local stratum 5
EOF

systemctl restart chronyd

# DNAT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.3.2:8080
iptables -t nat -A PREROUTING -p tcp --dport 2024 -j DNAT --to-destination 192.168.3.2:2024
iptables -A FORWARD -p tcp -d 192.168.3.2 --dport 8080 -j ACCEPT
iptables -A FORWARD -p tcp -d 192.168.3.2 --dport 2024 -j ACCEPT


