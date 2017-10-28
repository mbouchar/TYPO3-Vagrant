#!/bin/sh

set -e
set -x

if [ "${TYPO3_VERSION}" == "" ]; then
    echo "You must specify the TYPO3 version to use as the TYPO3_VERSION environment variable to the script"
    exit 1
fi

if [ "${PHP_VERSION}" == "" ]; then
    echo "You must specify the PHP version to use as the PHP_VERSION environment variable to the script"
    exit 1
fi

#
# Configure PHP
#

sudo apt-get install -y php-fpm php-opcache php-gd php-mysql php-soap php-xml php-zip php-xdebug;
sudo sed -i "s/user = www-data/user = vagrant/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sudo sed -i "s/group = www-data/group = vagrant/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sudo su - -c "echo 'php_admin_value[max_execution_time]=240' >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
sudo su - -c "echo 'php_admin_value[max_input_vars]=1500' >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
sudo su - -c "echo 'php_admin_value[xdebug.max_nesting_level]=400' >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
sudo service php${PHP_VERSION}-fpm restart

# @todo: en TCP?
# @todo: configure php parameters (errors, xdebug, etc.)

#
# Configure web server
#

sudo apt-get install -y apache2
sudo a2enmod alias headers proxy_fcgi rewrite ssl status
sudo a2dissite 000-default
sudo mv /tmp/apache2-typo3-site.conf /etc/apache2/sites-available/typo3.conf
sudo sed -i "s/proxy:unix:\/var\/run\/php\/php-fpm.sock/proxy:unix:\/var\/run\/php\/php${PHP_VERSION}-fpm.sock/" /etc/apache2/sites-available/typo3.conf
sudo a2ensite typo3
sudo service apache2 restart

#
# Configure database server
#

sudo apt-get install -y mariadb-server
sudo mysql -e "CREATE DATABASE typo3;"
sudo mysql -e "CREATE USER typo3@localhost identified by 'typo3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON typo3.* TO typo3@localhost"

#
# Configure TYPO3
#

mkdir -p ${HOME}/dists/
tar -zxf /tmp/typo3_src-${TYPO3_VERSION}.tar.gz -C ${HOME}/dists/
rm /tmp/typo3_src-${TYPO3_VERSION}.tar.gz

cd ${HOME}/dists/typo3_src-${TYPO3_VERSION}
patch -p1 -i /tmp/TYPO3-8-lts-add-install-commands.patch
rm /tmp/TYPO3-8-lts-add-install-commands.patch

mkdir -p ${HOME}/site/
cd ${HOME}/site
ln -s ../dists/typo3_src-${TYPO3_VERSION} typo3_src
ln -s typo3_src/typo3 .
ln -s typo3_src/index.php .
touch FIRST_INSTALL

cd ${HOME}/site/
/usr/bin/env php typo3/sysext/core/bin/typo3 install:environmentandfolders
# @todo: default values for host and port
/usr/bin/env php typo3/sysext/core/bin/typo3 install:databaseconnect:mysql --user=typo3 --password=typo3 --database=typo3 --host=localhost --port=3306
/usr/bin/env php typo3/sysext/core/bin/typo3 install:databasedata --username=admin --password=password
/usr/bin/env php typo3/sysext/core/bin/typo3 install:setconfig --path=SYS/UTF8filesystem --value=true --type=bool
/usr/bin/env php typo3/sysext/core/bin/typo3 install:setconfig --path=SYS/systemLocale --value='en_US.UTF-8'
/usr/bin/env php typo3/sysext/core/bin/typo3 install:defaultconfiguration

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
