#!/bin/bash

# Bash "strict mode", to help catch problems and bugs in the shell
# script. Every bash script you write should include this. See
# http://redsymbol.net/articles/unofficial-bash-strict-mode/ for
# details.
set -euo pipefail

# Tell apt-get we're never going to be able to give manual
# feedback:
export DEBIAN_FRONTEND=noninteractive

NAGIOS="4.4.6"
PLUGINS="2.3.3"

# Update the package listing, so we know what package exist:
apt-get update

# Install security updates:
apt-get -y upgrade

# Install new packages for nagios install
apt-get install -y autoconf gcc libc6 make wget unzip apache2 apache2-utils php libgd-dev ca-certificates

# Install new packages for plugins install
apt-get install -y libmcrypt-dev bc gawk dc build-essential snmp libnet-snmp-perl gettext

# Delete cached files we don't need anymore:
apt-get clean
rm -rf /var/lib/apt/lists/*


# Download and compile Nagios-core from the official repo.
cd /tmp
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-$NAGIOS.tar.gz
tar -xvf nagios-$NAGIOS.tar.gz
cd ./nagios-$NAGIOS
./configure --with-httpd-conf="/etc/apache2/sites-enabled"
make all

# This creates the nagios user and group. The www-data user is also added to the nagios group.
make install-groups-users
usermod -a -G nagios www-data

# This step installs the binary files, CGIs, and HTML files.
make install

# This installs the service or daemon files and also configures them to start on boot.
make install-init

# This installs and configures the external command file.
make install-commandmode

# This installs the *SAMPLE* configuration files. These are required as Nagios needs some configuration files to allow it to start.
make install-config

# This installs the Apache web server configuration files and configures the Apache settings.
make install-webconf
a2enmod rewrite
a2enmod cgi

# Create nagiosadmin user with default password "nagios".
htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagios

# Install plugins
cd /tmp
wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-$PLUGINS/nagios-plugins-$PLUGINS.tar.gz
tar -xvf nagios-plugins-$PLUGINS.tar.gz
cd ./nagios-plugins-$PLUGINS
./tools/setup
./configure
make
make install
