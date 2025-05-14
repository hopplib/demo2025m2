#!/bin/bash

# Installing packages
apt-get install -y mdadm chrony nfs-server docker-engine docker-compose

# Chrony
systemctl enable --now chronyd

echo allow 172.16.4.2 iburst >> /etc/chrony.conf

systemctl restart chronyd

# RAID

mdadm --create --verbose /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd

mdadm --detail --scan | tee -a /etc/mdadm/conf

mkfs.ext4 /dev/md0

mkdir -p /raid5/nfs

echo '/dev/md0 /raid5 ext4 defaults,nofail 0 0' | tee -a /etc/fstab

mount -a

echo /raid5/nfs *(rw,sync,no_subtree_check) >> /etc/exports

exportfs -a

systemctl restart nfs-server

systemctl enable --now nfs-server

# Moodle

systemctl enable --now docker
systemctl enable --now docker-compose

cat <<EOF > moodle.yml
Services:
  mariadb:
    image: docker.io/bitnami/mariadb:latest
    environment:
      # ALLOW_EMPTY_PASSWORD is recommended only for development.
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_USER=bn_moodle
      - MARIADB_DATABASE=bitnami_moodle
      - MARIADB_CHARACTER_SET=utf8mb4
      - MARIADB_COLLATE=utf8mb4_unicode_ci
    volumes:
      - 'mariadb_data:/bitnami/mariadb'
  moodle:
    image: docker.io/bitnami/moodle:4.5
    ports:
      - '80:8080'
      - '443:8443'
    environment:
      - MOODLE_DATABASE_HOST=mariadb
      - MOODLE_DATABASE_PORT_NUMBER=3306
      - MOODLE_DATABASE_USER=bn_moodle
      - MOODLE_DATABASE_NAME=bitnami_moodle
      # ALLOW_EMPTY_PASSWORD is recommended only for development.
      - ALLOW_EMPTY_PASSWORD=yes
    volumes:
      - 'moodle_data:/bitnami/moodle'
      - 'moodledata_data:/bitnami/moodledata'
    depends_on:
      - mariadb
volumes:
  mariadb_data:
    driver: local
  moodle_data:
    driver: local
  moodledata_data:
    driver: local
EOF

docker-compose build
docker-compose up -d

