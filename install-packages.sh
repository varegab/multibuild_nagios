#!/bin/bash

# Bash "strict mode", to help catch problems and bugs in the shell
# script. Every bash script you write should include this. See
# http://redsymbol.net/articles/unofficial-bash-strict-mode/ for
# details.
set -euo pipefail

# Tell apt-get we're never going to be able to give manual
# feedback:
export DEBIAN_FRONTEND=noninteractive

APACHE="2.4.46"
NAGIOS="4.4.6"

# Update the package listing, so we know what package exist:
apt-get update

# Install security updates:
apt-get -y upgrade

# Install a new package, without unnecessary recommended packages:
apt-get -y install --no-install-recommends autoconf gcc make libapr1-dev libaprutil1-dev libpcre3-dev wget unzip php ca-certificates

# Delete cached files we don't need anymore:
apt-get clean
rm -rf /var/lib/apt/lists/*

# Download Apache httpd from the official repo.
cd /tmp
wget https://downloads.apache.org//httpd/httpd-$APACHE.tar.gz
tar -xvf httpd-$APACHE.tar.gz
cd /tmp/httpd-$APACHE
./configure --prefix=/usr/local/apache2
make
make install
mkdir /etc/apache2/sites-enabled

# Download and compile Nagios-core from the official repo.
cd /tmp
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-$NAGIOS.tar.gz
tar -xvf nagios-$NAGIOS.tar.gz
cd /tmp/nagios-$NAGIOS
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all

# This creates the nagios user and group. The www-data user is also added to the nagios group.
make install-groups-users
usermod -a -G nagios www-data

# This step installs the binary files, CGIs, and HTML files.
make install

# This installs the service or daemon files and also configures them to start on boot.
# make install-daemoninit

# This installs and configures the external command file.
make install-commandmode

# This installs the *SAMPLE* configuration files. These are required as Nagios needs some configuration files to allow it to start.
make install-config

# This installs the Apache web server configuration files and configures the Apache settings.
make install-webconf
a2enmod rewrite
a2enmod cgi
