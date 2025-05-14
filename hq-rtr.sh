#!/bin/bash

# Installing packages
apt-get install -y chrony nginx

# Chrony
systemctl enable --now chronyd 

cat <<EOF >> /etc/chrony.conf
allow 192.168.100.0/29
allow 192.168.200.0/29
allow 172.16.4.0/28
allow 192.168.3.0/29
local stratum 5
EOF

systemctl restart chronyd

# DNAT

iptables -t nat -A PREROUTING -p tcp --dport 2024 -j DNAT --to-destination 192.168.100.2:2024
sudo iptables -A FORWARD -p tcp -d 192.168.100.2 --dport 2024 -j ACCEPT

# Nginx

cat <<EOF> /etc/nginx/sites-available/proxy.conf
server {
    listen 80;
    server_name moodle.au-team.irpo;

    location / {
        proxy_pass http://192.168.100.2:80;
    }
}
server {
    listen 80;
    server_name wiki.au-team.irpo;

    location / {
        proxy_pass http://192.168.2.10:8080;
    }
}
EOF
nginx -t
systemctl restart nginx
