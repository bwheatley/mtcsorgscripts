#!/bin/sh
clear

# Get the domain list and make a menu
echo "+==========================================================================+"
echo "| Welcome to automated PHP as FastCGI script. Please select a domain name: |"
echo "+==========================================================================+"
echo ""
count=0
psapass=`cat /etc/psa/.psa.shadow`
domainlist=`mysql psa -uadmin -p$psapass -N -e "select name from domains"`
for word in $domainlist; do
count=`expr $count + 1`
echo $word >> domainlist.lst
done;
DOMAINS=(`cat domainlist.lst`)
rm -f domainlist.lst
i=0
x=0
while (( $i<$count )); do
x=`expr $i + 1`
echo "$x -  ${DOMAINS[i]}"
let i++
done;

echo ""
echo "Total domains: $count"
echo ""

# Let's make the user input the domain number.
dummy=0
read -p "Please input the number of the domain (EXIT to quit) : " USERSCRIPT

# Check to see if the input is numeric or "EXIT"
testing=`echo "$USERSCRIPT" | egrep "^[0-9]+$"`
if [ "$USERSCRIPT" != "EXIT"  ]; then
if [ ! "$testing" ]; then
echo ""
echo "Invalid input. Please enter either the number of a domain, or "EXIT" to quit. Please run the script again."
echo ""
exit 0;
fi
else
clear
echo  "Thank you for using the automated PHP as FastCGI script. Goodbye.";
echo ""
exit 0;
fi

# Check to see if input is within the domain number array range
ACTUALSCRIPT=`expr $USERSCRIPT - 1`
compare_result=`echo "$ACTUALSCRIPT<$dummy" | bc`
compare_result2=`echo "$USERSCRIPT>$count" | bc`
if [ "$compare_result" == "1" ]; then
echo ""
echo "Invalid domain selection. The number you have entered does not belong to any domain. Please run the script again."
echo ""
exit 0;
fi
if [ "$compare_result2" == "1" ]; then
echo ""
echo "Invalid domain selection. The number you have entered does not belong to any domain. Please run the script again."
echo ""
exit 0;
fi

# Figure out which domain we are talking about here
choice=${DOMAINS[$ACTUALSCRIPT]}
rawlinuxuser=(`mysql psa -uadmin -p$psapass -e "select s.login from sys_users s inner join hosting h on h.sys_user_id = s.id inner join domains d on d.id = h.dom_id where d.name = '$choice'"`)
linuxuser=${rawlinuxuser[1]}

# Display the disclaimer
echo ""
echo "WARNING!"
echo "========"
echo ""
echo "You have chosen to make '$choice' domain on this server run PHP as FastCGI. Please note that this script is not officially endorsed and/or supported by (mt) Media Temple. Therefore, (mt) Media Temple  cannot be held liable for any potential loss of data or property which may occur as a result of using this script. We strongly encourage you to backup your data prior to using this script. Finally, this script will NOT work on (dv) Dedicated-Virtual Servers 3.0 and below."
echo ""
read -p "Do you agree to the above statement, and are sure you wish to proceed? [YES/no] : " USERCONFIRM
if [ "$USERCONFIRM" != "YES" ]; then
clear
echo "Thank you for using the automated PHP as FastCGI script. Goodbye."
echo ""
exit 0;
fi

# Proceed
clear
echo "Commencing with patching '$choice' to run PHP as FastCGI... Domain user is: $linuxuser"
echo ""

# Check whether or not the domain folders actually exist on the server
DIRECTORY=/var/www/vhosts/$choice/conf
echo "Checking whether or not the target domain exists on this server..."
echo ""
if [ ! -d "$DIRECTORY" ]; then
clear
echo "The domain entity for '$choice' exists in Plesk, however, the domain's virtual host directory seems to be missing from the server. The script cannot proceed further."
echo ""
exit 0;
fi

# Check to see if vhost.conf has already been modded
echo "Checking if relevant entries have already been added to vhost.conf..."
vhostfile="/var/www/vhosts/$choice/conf/vhost.conf"

if [ -f $vhostfile ]; then
CHK=`cat /var/www/vhosts/$choice/conf/vhost.conf | grep php-cgi | wc -l`
if [ $CHK != 0 ]; then
echo ""
echo "It seems that vhost.conf has already been modified with relevant entries to run PHP as FastCGI"
read -p "Continue anyway? [YES/no] : " USERSCRIPTF
if [ "$USERSCRIPTF" != "YES" ]; then
clear
echo "Thank you for using the automated PHP as FastCGI script. Goodbye."
echo ""
exit 0;
fi
fi
fi

# Check to see if /bin/ directory exists and make it if it does not.
if [ ! -d "/var/www/vhosts/$choice/bin" ]; then
mkdir /var/www/vhosts/$choice/bin
fi
tehoutfile="/var/www/vhosts/$choice/bin/php_cgi"
outfile2="/var/www/vhosts/$choice/phpconf/php.ini"
if [ -a $tehoutfile ]; then
echo ""
read -p "It seems that php-cgi already exists inside your domain's /bin/ folder. Continue anyway (file will be backed up)? [YES/no] : " PHPEXISTS
if [ "$PHPEXISTS" != "YES" ]; then
clear
echo "Thank you for using the automated PHP as FastCGI script. Goodbye."
echo ""
exit 0;
else
TODAY2=$(date)
bdate1=`echo $TODAY2 | sed 's/ /_/g'`
bdate2=`echo $bdate1 | sed 's/:/./g'`
mv /var/www/vhosts/$choice/bin/php_cgi /var/www/vhosts/$choice/bin/php_cgi.backup.$bdate2
fi
fi

# Continue with changes
echo ""
echo "Proceeding with the changes..."
if [ ! -d "/var/www/vhosts/$choice/phpconf" ]; then
mkdir /var/www/vhosts/$choice/phpconf
fi
if [ -f $outfile2 ]; then
echo ""
read -p "Php.ini file already exists inside your domain's /phpconf/ folder. Backup (otherwise it will be removed)? [YES/no] : " INIEXISTS
if [ "$INIEXISTS" != "YES" ]; then
rm -f /var/www/vhosts/$choice/phpconf/php.ini
else
TODAY=$(date)
t3hestring=`echo $TODAY | sed 's/ /_/g'`
t3hestring2=`echo $t3hestring | sed 's/:/./g'`
mv /var/www/vhosts/$choice/phpconf/php.ini /var/www/vhosts/$choice/phpconf/php.ini.backup.$t3hestring2
fi
fi

cp /etc/php.ini /var/www/vhosts/$choice/phpconf/
chown -R $linuxuser:psacln /var/www/vhosts/$choice/phpconf/
cp /usr/bin/php-cgi /var/www/vhosts/$choice/bin/
chown -R $linuxuser:psacln /var/www/vhosts/$choice/bin/
echo "
AddHandler fcgid-script .php
SuexecUserGroup $linuxuser psacln
<Directory /var/www/vhosts/$choice/httpdocs>
FCGIWrapper '/var/www/vhosts/$choice/bin/php-cgi -c /var/www/vhosts/$choice/phpconf/' .php
Options +ExecCGI +FollowSymLinks
allow from all
</Directory>" >> /var/www/vhosts/$choice/conf/vhost.conf
/usr/local/psa/admin/sbin/httpdmng --reconfigure-all
echo ""
read -p "Domain $choice has successfully been patched to run PHP as FastCGI. Restart Apache web server now? [Y/n] : "  USERSCRIPTZ
echo ""
if [ "$USERSCRIPTZ" != "Y"  ]; then
clear
echo  "Thank you for using the automated PHP as FastCGI script. Please make sure to restart your server for changes to take effect. Also, please make sure to enable CGI and FastCGI support for '$choice' in Plesk."
echo ""
exit 0;
fi
clear
echo "Your Apache web server will now be restarted. Please make sure to enable CGI and FastCGI support for '$choice' within Plesk."
echo ""
sleep 5
/etc/init.d/httpd graceful
exit 0;