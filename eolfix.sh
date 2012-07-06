#!/bin/bash
# Created by Jeff Uberstine for (mt) Media Temple
#
while :
do
clear
echo "************************"
echo "* PHP EOL fixes *"
echo "* Created by Jeff Uberstine *"
echo "************************"
echo "* [a] SourceGuard fix *"
echo "* [b] ionCube 5.3 Installer *"
echo "* [c] Zend Guard Loader 5.3 Installer *"
echo "* [d] APC for PHP 5.3 Installer *"
echo "* [e] Wrapper is Disabled error fix *"
echo "* [t] Set PHP time *"
echo "************************"
echo "* Other Tools *"
echo "* [f] CMS version checker *"
echo "* [g] timthumb.php Updater *"
echo "************************"
echo "* [0] Exit/Stop *"
echo "* [911] OMG I broke something.... help *"
echo "************************"
echo -n "Enter your menu choice [a-0]: "
read yourch
case $yourch in
# Source Guardian Fix Start
a) 
ls /usr/lib64 >/dev/null 2>&1 
export ERR=$?
if (( $ERR != 0 ))
then
echo "32-bit install started"
cd ~/data
mkdir ixed
cd ixed
wget http://www.sourceguardian.com/ixeds/ixed4.lin.x86-32.tar.gz >/dev/null 2>&1
tar -zxf ixed4.lin.x86-32.tar.gz
find ~/domains/ -name "ixed" -type d -exec cp ~/data/ixed/ixed.5.3.lin {} \;
clear
echo "32-bit install complete"
else
echo "64-bit install started"
cd ~/data
mkdir ixed
cd ixed
wget http://www.sourceguardian.com/ixeds/ixed4.lin.x86-64.tar.gz >/dev/null 2>&1
tar -zxf ixed4.lin.x86-64.tar.gz
find ~/domains/ -name "ixed" -type d -exec cp ~/data/ixed/ixed.5.3.lin {} \;
clear
echo "64-bit install complete"
fi
echo "Source Guardian fix has been applied for PHP 5.3. Press enter to return to main menu"
read enterKey
;;
# ionCube Install Start
b) 
site=`echo $PWD |awk -F/ '{ print $3 }'`
cat /home/$site/etc/php.ini | grep "ioncube_loader_lin_5.3.so"
export ERR=$?
 if (( $ERR != 0 ))
 then
 ls /usr/lib64 >/dev/null 2>&1
export ERR=$?
if (( $ERR != 0 ))
then
echo "32-bit install started"
echo "Enter Domain name to install ionCube on"
read domain
cd /home/$site/domains/$domain/
wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz >>/dev/null 2>&1
tar zxvf ioncube_loaders_lin_x86.tar.gz >>/dev/null 2>&1
rm -rf ioncube_loaders_lin_x86.tar.gz >>/dev/null 2>&1
echo zend_extension=/home/$site/domains/$domain/ioncube/ioncube_loader_lin_5.3.so >> /home/$site/etc/php.ini
clear
echo "32-bit install complete"
 else
echo "64-bit install started"
echo "Enter Domain name to install ionCube on"
read domain
cd /home/$site/domains/$domain/
wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz >>/dev/null 2>&1
tar zxvf ioncube_loaders_lin_x86-64.tar.gz >>/dev/null 2>&1
rm -rf ioncube_loaders_lin_x86-64.tar.gz >>/dev/null 2>&1
echo zend_extension=/home/$site/domains/$domain/ioncube/ioncube_loader_lin_5.3.so >> /home/$site/etc/php.ini
clear
echo "64-bit install complete"
echo "ionCube Loader has been installed for PHP 5.3. Press enter to return to main menu"
 fi
else
echo "It appears ionCube for PHP 5.3 is already installed. Press enter to return to main menu"
fi
read enterKey
;;

## Zend Install Start
c) 
site=`echo $PWD |awk -F/ '{ print $3 }'`
cat /home/$site/etc/php.ini | grep "5.3.x/ZendGuardLoader.so"
export ERR=$?
 if (( $ERR != 0 ))
 then
 ls /usr/lib64 >/dev/null 2>&1
export ERR=$?
if (( $ERR != 0 ))
then
echo "32-bit install started"
def=`whoami`
cd ~/data
wget http://repo.ruhosting.me/ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz >/dev/null 2>&1
tar -zxvf ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
echo -e "\n" >> /home/$site/etc/php.ini
echo zend_extension=/home/$site/data/ZendGuardLoader-php-5.3-linux-glibc23-i386/php-5.3.x/ZendGuardLoader.so >> /home/$site/etc/php.ini
echo -e "\n; Enables loading encoded scripts. The default value is On" >>  /home/$site/etc/php.ini
rm ~/data/ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
clear
echo "32-bit install complete"
else
echo "64-bit install started"
def=`whoami`
cd ~/data
wget http://repo.ruhosting.me/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz >/dev/null 2>&1
tar -zxvf ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
echo -e "\n" >> /home/$site/etc/php.ini
echo zend_extension=/home/$site/data/ZendGuardLoader-php-5.3-linux-glibc23-x86_64/php-5.3.x/ZendGuardLoader.so >> /home/$site/etc/php.ini
echo -e "\n; Enables loading encoded scripts. The default value is On" >>  /home/$site/etc/php.ini
rm ~/data/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
clear
echo "64-bit install complete"
echo "Zend Guard Loader has been installed for PHP 5.3. Press enter to return to main menu"
 fi
else
echo "It appears Zend Guard Loader for PHP 5.3 is already installed. Press enter to return to main menu"
fi
read enterKey
;;

## APC Install Start
d) 
site=`echo $PWD |awk -F/ '{ print $3 }'`
export PHPPATH=`php-latest -i | grep "Configure Command" | perl -pe "s/.*'.\/configure'\s*?'--prefix\=(.*?)'.*/\1/"`
mkdir /home/$site/data/lib
mkdir /home/$site/data/lib/php/
cd ~/data/
wget wget http://pecl.php.net/get/APC-3.1.9.tgz
tar -zxvf APC-3.1.9.tgz
cd APC-3.1.9
$PHPPATH/bin/phpize
./configure --with-php-config=$PHPPATH/bin/php-config
make && cp modules/*.so /home/$site/data/lib/php
echo extension_dir=/home/$site/data/lib/php/ >> /home/$site/etc/php.ini
echo extension = apc.so >> /home/$site/etc/php.ini
echo "APC has been installed for PHP 5.3. Press enter to return to main menu"
read enterKey
;;
## Fix Wrapper Error Start
e) 
site=`echo $PWD |awk -F/ '{ print $3 }'`
echo allow_url_include = On >> /home/$site/etc/php.ini
echo "Fix has been applied. Press enter to return to main menu"
read enterKey
;;
f) 
## Start CMS check
echo "If script contines without listing version, this means no CMS's of that type were found"
echo "**********************************************************************"
echo "Below are the WordPress versions"
echo "***WordPress 3.0 and higher are fully compatible with PHP 5.3***"
find ~/domains/*/html/ -name 'version.php' | xargs grep "wp_version ="
echo "**********************************************************************"
echo "Below are the Drupal versions"
echo "***Drupal 6.15 and higher are fully compatible with PHP 5.3***"
find ~/domains/*/html/ -name "system.module" -type f -print -exec egrep "'VERSION'" '{}' \;
echo "**********************************************************************"
echo "Below are the Joomla versions"
echo "***Joomla 1.5.15 and higher are fully compatible with PHP 5.3***"
find ~/domains/*/html/ -name 'version.php' | xargs grep "public \$RELEASE"
echo "**********************************************************************"
echo "Below are the Expression Engine versions"
echo "###NOTE: You you will see a version similar to 213, this really means 2.1.3###"
echo "***Information is limited; however it appears Expression Engine 2.4.0 and higher are compabile with PHP 5.3***"
find ~/domains/*/html/ -name 'config.php' | xargs grep "app_version"
echo "**********************************************************************"
echo "Press enter to return to main menu"
read enterKey
;;
# Start TimThumb Updater
g) 
cd ~/data
wget -O timthumb.php http://timthumb.googlecode.com/svn/trunk/timthumb.php
find ~/domains/*/html/ -maxdepth 10 -name "*thumb.php" -exec cp {} {}.bak \; -exec cp timthumb.php {} \; -exec chmod 200 {}.bak \; -exec egrep -H "'VERSION'" {} \;
echo "All timthumb.php files updated. Press enter to return to main menu"
read enterKey
;;
t)
site=`echo $PWD |awk -F/ '{ print $3 }'`
echo "************************"
echo "* Choose Time Zone *"
echo "************************"
echo "* [1] Set PHP time to Pacific *"
echo "* [2] Set PHP time to Mountain *"
echo "* [3] Set PHP time to Eastern *"
echo -n "Enter your menu choice [a-0]: "
read yourch
case $yourch in
1) echo date.timezone = "US/Pacific" >> /home/$site/etc/php.ini 
echo "Time Zone set to Pacific. Press enter to return to main menu"
read enterKey
;;
2) echo date.timezone = "US/Mountain" >> /home/$site/etc/php.ini 
echo "Time Zone set to Mountain. Press enter to return to main menu"
read enterKey
;;
3) echo date.timezone = "US/Eastern" >> /home/$site/etc/php.ini 
echo "Time Zone set to Eastern. Press enter to return to main menu"
read enterKey
;;
0) rm -rf eolfix.sh && exit 0 ;;
esac
;;
911) 
echo "**********************************************************************"
echo "Well you must have broken something!"
echo ":-("
echo "**********************************************************************"
echo "If you are getting a 500 error after installing Zend Guard Loader or ionCube,"
echo "ensure there are not conflicting or duplicate entries."
echo "**********************************************************************"
echo "Press enter to return to main menu"
read enterKey
;;
0) rm -rf eolfix.sh && exit 0;;
*) echo "Oopps!!! Please select choice 1,2,3 or 4";
echo "Press Enter to continue. . ." ; read ;;
esac
done
