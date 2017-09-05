#!/bin/sh

set -e
set -x

#
# Configure PHP
#

sudo apt-get install -y php-fpm php-opcache php-gd php-mysql php-soap php-xml php-zip;
sudo sed -i "s/user = www-data/user = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
sudo sed -i "s/group = www-data/group = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
sudo su - -c "echo 'php_admin_value[max_execution_time]=240' >> /etc/php/7.0/fpm/pool.d/www.conf"
sudo su - -c "echo 'php_admin_value[max_input_vars]=1500' >> /etc/php/7.0/fpm/pool.d/www.conf"
sudo service php7.0-fpm restart

# @todo: en TCP?
# @todo: configure php parameters (errors, xdebug, etc.)

#
# Configure web server
#

sudo apt-get install -y apache2
sudo a2enmod alias headers proxy_fcgi ssl status
sudo a2dissite 000-default
sudo mv /tmp/apache2-typo3-site.conf /etc/apache2/sites-available/typo3.conf
sudo a2ensite typo3
sudo service apache2 restart

#
# Configure database server
#

sudo apt-get install -y mariadb-server
sudo mysql -e "CREATE DATABASE typo3;"
sudo mysql -e "CREATE USER typo3@localhost identified by 'typo3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON typo3.* TO typo3"

#
# Configure TYPO3
#

mkdir -p ${HOME}/dists/
tar -zxf /tmp/typo3_src-8.7.4.tar.gz -C ${HOME}/dists/
rm /tmp/typo3_src-8.7.4.tar.gz

mkdir -p ${HOME}/site/
cd ${HOME}/site
ln -s ../dists/typo3_src-8.7.4 typo3_src
ln -s typo3_src/typo3 .
ln -s typo3_src/index.php .
touch FIRST_INSTALL

#$GLOBALS[TYPO3_CONF_VARS][SYS][systemLocale] is not set. This is fine as long as no UTF-8 file system is used.
#@todo: permissions sur les fichiers
#@todo: debug configuration presets

sudo apt-get install -y graphicsmagick
# @todo: image configuration presets

#@todo: create some content and configure site template

#@todo: TYPO3 application context

#
# Helpers
#

echo "<?php phpinfo() ?>" > ${HOME}/site/info.php
