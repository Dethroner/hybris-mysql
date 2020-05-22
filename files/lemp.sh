#!/bin/bash
##################################################
# Install LEMP + PhpMyAdmin                      #
# Author by Dethroner, 2020                      #
##################################################

##################################################
### Vars
VERP=5.0.2			# Version phpmyadmin
FQDN=test.lan 
BD="https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb"
DBROOTPASS=P@ssw0rd
DBNAME=hybrisDB
DBUSER=adb
DBPASS=123

##################################################
### mkdirs
mkdir -p /var/www

##################################################
### PreInstall
debconf-set-selections <<< "postfix postfix/mailname string $FQDN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt install --assume-yes postfix
apt update && apt upgrade -y
apt install -y wget unzip curl gnupg2 ca-certificates lsb-release

##################################################
### Download
cd /tmp
wget $BD

##################################################
### Install package
apt install -y build-essential binutils unzip zip \
			   libpcre3 libpcre3-dev libssl-dev zlib1g-dev libpcrecpp0v5 \
			   php7.3 php7.3-common php7.3-fpm php7.3-mysql php7.3-cgi php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline php7.3-mbstring php7.3-gd php7.3-imap php7.3-curl php7.3-zip php7.3-xml php7.3-bz2 php7.3-intl php7.3-gmp\
			   php-imagick php-phpseclib php-php-gettext php-gettext

##################################################
### Install NGINX
echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" \
	| tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
apt update && apt install -y nginx
systemctl daemon-reload
systemctl enable nginx
systemctl start nginx

##################################################
### Install MySQL
DEBIAN_FRONTEND=noninteractive apt install -y ./mysql-apt-config*.deb
apt update
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $DBROOTPASS"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $DBROOTPASS"
debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Strong Passwoord Encryption (RECOMMENDED)"
DEBIAN_FRONTEND=noninteractive apt -y install mysql-server
echo "bind-address    = 0.0.0.0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
service mysqld start
service mysqld status

##################################################
### Install phpmyadmin
cd /tmp
wget https://files.phpmyadmin.net/phpMyAdmin/$VERP/phpMyAdmin-$VERP-all-languages.zip
unzip phpMyAdmin-$VERP-all-languages.zip
mv phpMyAdmin-$VERP-all-languages /var/www/phpmyadmin
chown -R www-data:www-data /var/www/phpmyadmin
rm -r /var/www/phpmyadmin/setup
cp -a /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php
sed -i "18s/= '';/= '12345678900987654321123456789009';/" /var/www/phpmyadmin/config.inc.php # random number of 32 bits
mysql -uroot -p$DBROOTPASS -e "CREATE DATABASE phpmyadmin DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -uroot -p$DBROOTPASS phpmyadmin < /var/www/phpmyadmin/sql/create_tables.sql

##################################################
### Info about php
cat <<EOF | tee /var/www/index.php
<?php
echo '
<div class="center">
 <table>
  <td width="934px" hieght="73px" bgcolor="#99F">
   <a href="http://10.50.10.100/phpmyadmin">
    <h1 style="font-family: sans-serif; color: #222; line-height: 64px";>Go to phpMyAdmin Version 5.0.2
    <img src="phpmyadmin/themes/original/img/logo_right.png" height="64px"></h1>
   </a>
  </td>
 </table>
</div>
';
phpinfo();
?>
EOF

##################################################
#### Include nginx snippets
sed -i "2s/nginx/www-data/" /etc/nginx/nginx.conf
cp /vagrant/files/conf/default.conf /etc/nginx/conf.d/
service nginx reload

##################################################
### Tuning MySQL
#### Create DBUSER
mysql -uroot -p$DBROOTPASS -e "CREATE USER '$DBUSER'@'%' IDENTIFIED BY '$DBPASS'"
#### Allow password's access
mysql -uroot -p$DBROOTPASS -e "ALTER USER '$DBUSER'@'%' IDENTIFIED WITH mysql_native_password BY '$DBPASS';"
mysql -uroot -p$DBROOTPASS -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DBROOTPASS';"
#### Create DBNAME & select privilege for DBUSER
mysql -uroot -p$DBROOTPASS -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_bin"
mysql -uroot -p$DBROOTPASS -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'%' WITH GRANT OPTION"
mysql -uroot -p$DBROOTPASS -e "FLUSH PRIVILEGES"
mysql -uroot -p$DBROOTPASS -e 'SHOW DATABASES;'
