#!/bin/bash

read -p "Ip of HQ_SRV: " HQ_SRV

# Installing

apt-get install task-samba-dc chrony docker-engine docker-compose ansible

# Chrony

systemctl enable --now chronyd

echo "allow 172.16.4.2 iburst" >> /etc/chrony.conf

systemctl restart chronyd

# Samba and kerberos set up
systemctl disable --now krb5kdc nmb smb slapd

echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
systemctl restart systemd-resolved

samba-tool domain provision --realm=domain.alt --domain domain --adminpass='Pa$$word' --dns-backend=SAMBA_INTERNAL --option="dns forwarder=$HQ_SRV" --server-role=dc

systemctl enable --now samba

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Adding group

samba-tool group add HQ

# Creating users and adding to group

samba-tool user create user#1.hq
samba-tool user create user#2.hq
samba-tool user create user#3.hq
samba-tool user create user#4.hq
samba-tool user create user#5.hq

samba-tool group addmembers "HQ" user#1.hq,user#2.hq,user#2.hq,user#4.hq,user#5.hq

# Mediawiki

cat <<EOF > ./wiki.yml
services:
  mediawiki:
    image: mediawiki:latest
    container_name: wiki
    ports:
     - 8080:80
    links:
     - datebase
    volumes:
     - images:/var/www/html/images
     # - ./LocalSettings.php:/var/www/html/LocalSettings.php

  database:
    image: mariadb
    container_name: mariadb
    environment:
	MYSQL_ROOT_PASSWORD: 1234
	MYSQL_DATABASE: mediawiki
	MYSQL_USER: wiki
	MYSQL_PASSWORD: WikiP@ssw0rd
    volumes:
         - db:/var/lib/mysql
volumes:
  images:
  db:
EOF

docker compose up -d

# Ansible

ssh-keygen -t ed25519 -N ""
ssh-copy-id root@192.168.3.1
ssh-copy-id root@192.168.100.1
ssh-copy-id root@192.168.100.2
ssh-copy-id root@192.168.200.3


mkdir -p /etc/ansible
cat <<EOF>> /etc/ansible/inventory.ini
[group]
hq-srv ansible_host=192.168.100.2 
hq-cli ansible_host=192.168.200.3
hq-rtr ansible_host=192.168.100.1
br-rtr ansible_host=192.168.3.1
EOF
ansible all -i /etc/ansible/inventory.ini -m ping
