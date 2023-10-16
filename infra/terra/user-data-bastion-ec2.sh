#!/bin/bash

sudo yum -y update
sudo yum -y install yum-utils

sudo yum -y remove mariadb-libs

sudo yum -y install https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
sudo yum-config-manager --disable mysql80-community
sudo yum-config-manager --enable mysql57-community

sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
sudo yum -y install mysql-community-client
