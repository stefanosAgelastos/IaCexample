#!/bin/bash
# install nginx
sudo apt-get update
sudo apt-get -y install nginx
# make sure nginx is started
sudo service nginx start