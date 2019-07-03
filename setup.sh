#!/usr/bin/env bash

sudo yum update -y
sudo yum -y install vim git tree jq

# git clone https://github.com/bloomberg/chef-bcpc.git

# install virtual box dependencies
sudo yum -y install kernel-headers kernel-devel binutils glibc-headers glibc-devel font-forge
sudo yum -y install gcc dkms make qt libgomp patch 

sudo cd /etc/yum.repos.d
sudo wget -P /etc/yum.repos.d http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
sudo yum install -y VirtualBox-5.2
sudo /sbin/rcvboxdrv setup
sudo pip install netaddr

# install vagrant
sudo wget https://releases.hashicorp.com/vagrant/2.2.5/vagrant_2.2.5_x86_64.rpm
sudo yum install -y vagrant_2.2.5_x86_64.rpm
