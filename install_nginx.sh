#!/bin/bash
# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done
# install nginx
sudo apt-get update
sudo apt-get -y install nginx
# make sure nginx is started
sudo service nginx start