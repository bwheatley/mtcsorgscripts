#!/bin/bash

# This script is designed to install a patched version of PHP 5.2.17 on a
# (dv) 4.0, as well as switch specified domain(s) to run this version of PHP.
#
# If PHP 5.2.17 has already been installed, the script will just skip to
# switching the specified domain(s) to use that version.

# check that we are indeed on a Plesk 10.4.4 server
if ! grep -q '^\(11\.0\.9\|10\.4\.4\)$' /usr/local/psa/version
then
	echo "Script only tested with Plesk 10.4.4 and 11.0.9 on (dv) 4.0."
	echo "cat /usr/local/psa/version"
	cat /usr/local/psa/version
	exit 99
fi

if [ "$1" == "--help" ]
then
	echo -e "install_PHP_5.2.17.sh usage:\n"
	echo	"install_PHP_5.2.17.sh (domain1.com) (domain2.com) (...)"
	exit 1
fi

# disclaimer time
echo "
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-===========-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Thank you for running the (dv) 4.0 PHP 5.2.17 installation / activation script.

Please keep in mind that PHP 5.2.17 is outdated and unsupported.  This is the
last version of PHP 5.2 which will ever be released; it was released on
January 6, 2011.  This script will apply two security patches which have been
back-ported to this version of PHP from actually current releases, but there
are otherwise no security fixes for PHP 5.2 any more.  Ultimately, it is
unsafe to remain on PHP 5.2 in the long-term, and a migration strategy to
port incompatible PHP code to current PHP versions is urgently recommended.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-===========-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	***Important Note***

We do not recommend running this script on a live server, as it installs and
potentially upgrades server software, as well as reconfigures Apache and PHP
settings on your domain(s).  This script is best used on a (dv) 4.0 server which
has just had its sites migrated (without DNS being switched yet) from an older
server, with some still requiring PHP 5.2.  This way, you will still have time
to test all of the sites and verify that things are working correctly before
making the switch live for the rest of the internet.

If you do run this script on a server with live sites already, pretty please
with a cherry on top, ensure that you have made current backups of your data.
"
if [ ${#*} -gt 0 ]
	then
		echo "If you press <ENTER>, this script will install PHP 5.2.17"
		echo "if necessary and attempt to activate it on these domains:"
		echo -e "$*\n"
	else
		echo "If you press <ENTER>, this script will just install PHP"
		echo -e "5.2.17, if it is not installed already.\n"
fi

read -p "Press <Ctrl-C> to abort.  Press <ENTER> to acknowledge and proceed."

# establish any functions or variables which are useful\necessary later

# counter for later
unset domains_activated

# make sure we don't inherit old chown recommendations
unset chown_recommendations

# missed domain tracker for later
unset missed_domains

# function to allow us to install whatever the current version is of an RPM
# without pulling all its dependencies, based on current CentOS version
centos_version=$(egrep -o "[[:digit:]]+\.[[:digit:]]+" /etc/issue)
if [ "$centos_version" == "5.8" ]
	then
		repo_base="http://mirror.umd.edu/centos/5.8/os/x86_64/CentOS/"
	else
		repo_base="http://vault.centos.org/$centos_version/os/x86_64/CentOS/"
fi

function nodeps_rpminstall {
	rpm -Uvh --nodeps $repo_base$(curl $repo_base |\
		grep -o "${1%.*}"'-[[:digit:]][^"]*x86_64.rpm' | tail -1)
}

# first, we will check if PHP 5.2.17 has been installed on this server yet

if [ ! -d /usr/local/php-5.2.17 ]
then
# we haven't installed 5.2.17 on this server yet so let's give it a try

	# install dev tools
	yum -y -x '*.i?86' -x 'dogtail*' -x 'apr*' -x 'subversion*'\
		groupinstall 'Development Tools'	|| exit 14

	# get there
	mkdir -p /opt/php-compile	|| exit 10
	cd /opt/php-compile		|| exit 11

	# clear out old sources if present, pull sources, relocate ourselves
	rm -rf ./php-5.2.17
	curl http://museum.php.net/php5/php-5.2.17.tar.bz2 | tar jvxf -
	cd php-5.2.17			|| exit 12
	
	# patch sources against some high profile vulnerabilities
	patch -u -p1 < <(curl http://php52.jpnc.info/phppatch.tar.gz |\
		 tar zxvOf -)		|| exit 13

	# install dependencies for our PHP config options
	nodeps_rpminstall libXpm-devel.x86_64
	nodeps_rpminstall libX11-devel.x86_64
	nodeps_rpminstall xorg-x11-proto-devel.x86_64
	yum -y -x '*.i?86' install\
		libxml2-devel.x86_64\
		bzip2-devel.x86_64\
		curl-devel.x86_64\
		libidn-devel.x86_64\
		libpng-devel.x86_64\
		gmp-devel.x86_64\
		libc-client-devel.x86_64\
		openldap-devel.x86_64\
		libmcrypt-devel.x86_64\
		readline-devel.x86_64\
		libtermcap-devel.x86_64\
		net-snmp-devel.x86_64\
		libxslt-devel.x86_64\
		gdbm-devel.x86_64\
		db4-devel.x86_64\
		libjpeg-devel.x86_64\
		cyrus-sasl-devel.x86_64\
		unixODBC-devel.x86_64\
		aspell-devel.x86_64\
		libtidy-devel.x86_64\
		libtool-ltdl-devel.x86_64\
		freetype-devel.x86_64

	# configure the compilation of PHP with the following options,
	# which include most of the compilation options used in Plesk's PHP build
	./configure\
		'--build=x86_64-redhat-linux-gnu'\
		'--host=x86_64-redhat-linux-gnu'\
		'--target=x86_64-redhat-linux-gnu'\
		'--prefix=/usr/local/php-5.2.17'\
		'--cache-file=../config.cache'\
		'--with-libdir=lib64'\
		'--with-config-file-path=/etc'\
		'--with-config-file-scan-dir=/etc/php.d'\
		'--disable-debug'\
		'--with-pic'\
		'--disable-rpath'\
		'--without-pear'\
		'--with-bz2'\
		'--with-freetype-dir=/usr'\
		'--with-png-dir=/usr'\
		'--enable-gd-native-ttf'\
		'--with-xpm-dir=/usr'\
		'--enable-dba'\
		'--with-gdbm=/usr'\
		'--without-t1lib'\
		'--with-gettext'\
		'--with-gmp'\
		'--with-iconv'\
		'--with-jpeg-dir=/usr'\
		'--with-openssl'\
		'--with-zlib'\
		'--with-layout=GNU'\
		'--enable-exif'\
		'--enable-ftp'\
		'--enable-magic-quotes'\
		'--enable-sockets'\
		'--with-kerberos'\
		'--enable-ucd-snmp-hack'\
		'--enable-shmop'\
		'--enable-calendar'\
		'--with-libxml-dir=/usr'\
		'--enable-xml'\
		'--enable-force-cgi-redirect'\
		'--enable-pcntl'\
		'--with-imap=shared'\
		'--with-imap-ssl'\
		'--enable-mbstring=shared'\
		'--enable-mbregex'\
		'--with-gd=shared'\
		'--enable-bcmath=shared'\
		'--with-db4=/usr'\
		'--with-xmlrpc=shared'\
		'--with-ldap=shared'\
		'--with-ldap-sasl'\
		'--with-mysql=shared,/usr'\
		'--with-mysqli=shared,/usr/lib64/mysql/mysql_config'\
		'--enable-dom=shared'\
		'--enable-wddx=shared'\
		'--with-snmp=shared,/usr'\
		'--enable-soap=shared'\
		'--with-xsl=shared,/usr'\
		'--enable-xmlreader=shared'\
		'--enable-xmlwriter=shared'\
		'--with-curl=shared,/usr'\
		'--enable-fastcgi'\
		'--enable-pdo=shared'\
		'--with-pdo-odbc=shared,unixODBC,/usr'\
		'--with-pdo-mysql=shared,/usr/lib64/mysql/mysql_config'\
		'--without-pdo-sqlite'\
		'--without-sqlite'\
		'--enable-json=shared'\
		'--enable-zip=shared'\
		'--with-readline'\
		'--without-libedit'\
		'--with-pspell=shared'\
		'--with-mcrypt=shared,/usr'\
		'--with-tidy=shared,/usr'\
		'--enable-sysvmsg=shared'\
		'--enable-sysvshm=shared'\
		'--enable-sysvsem=shared'\
		'--enable-posix=shared'\
		'--with-unixODBC=shared,/usr'	|| exit 15
	
	# compile
	make					|| exit 16

	# install
	make install				|| exit 17
	
# if we made it to here, PHP 5.2.17 should be installed in /usr/local/php-5.2.17

else
	echo "PHP 5.2.17 already installed in /usr/local/php-5.2.17"
	echo "If this version is not actually or completely installed there,"
	echo "please either remove that directory or modify this script."
fi

# At this point, we've either just installed 5.2.17, or it already was there
# from another time this script was run.  Now, we'll cycle through each arg
# passed on the command line, which should be a list of the domain names, and
# set each one up to run PHP 5.2.17 via FastCGI

domain_list="$(mysql -uadmin -p$(</etc/psa/.psa.shadow)\
	-Nse 'select name from psa.domains')"

until [ -z $1 ]
do
# test to make sure the domain requested has been added in Plesk
if ! echo "$domain_list" | grep -q "^$1$"
then
	missed_domains="$missed_domains $1"
else
# if it is in the list, we'll proceed to switching it to our 5.2.17
# first, we will set it to run PHP as an Apache module in Plesk
# this will allow our FastCGI configuration later to not conflict with
# Plesk FastCGI configurations
	/usr/local/psa/bin/domain --update "$1" -php_handler_type module

# Set variables so we can control for the possibility that the domain is not
# added under its own subscription
	unset doc_root
	doc_root="$(/usr/local/psa/bin/domain --info $1 |\
		 awk '/--WWW-Root--:/ {print $2}')"
	
	unset subscription_root
	subscription_root="$(echo $doc_root | cut -d/ -f 1-5)"

# Create link to the PHP executable in the domain
	ln -s -v -f /usr/local/php-5.2.17/bin/php-cgi\
		"$subscription_root/bin/php-cgi-5.2.17"	|| exit 18

# Create a PHP FastCGI wrapper script to allow us to use domain level php.ini
	cat > "$subscription_root/bin/phpwrap-5.2.17" <<-EOF
		#!/bin/sh
		export PHPRC="$subscription_root/etc/"
		exec $subscription_root/bin/php-cgi-5.2.17
		EOF
	chmod -v 755 "$subscription_root/bin/phpwrap-5.2.17"

# Apply proper ownership values to the dom/bin directory to allow FastCGI exec
	chown -Rhv $(/usr/local/psa/bin/domain --info "$1" |\
		awk '/FTP Login:/ {print $3}'):psacln "$subscription_root/bin"

# Append to or create vhost.conf and vhost_ssl.conf
	tee -a /var/www/vhosts/$1/conf/vhost{,_ssl}.conf > /dev/null <<EOF
<IfModule mod_fcgid.c>
	<Files ~ (\.php)>
		SetHandler fcgid-script
		FCGIWrapper $subscription_root/bin/phpwrap-5.2.17 .php
		Options +ExecCGI
		allow from all
	</Files>
</IfModule>
EOF

# The domain is now ready to go, we'll run 'web' after cycling through all args

# Update counter for nice output of domains processed
(( domains_activated++ ))

# Update recommended chown commands
chown_recommendations="$(echo "$chown_recommendations"
	echo "  chown -Rv $(/usr/local/psa/bin/domain --info $1 |\
	awk '/FTP Login:/ {print $3}'):psacln $doc_root"
	echo "  chown -v :psaserv $doc_root")"

fi
shift
done

# 'web'
/usr/local/psa/admin/sbin/httpdmng --reconfigure-all

test -x /usr/local/php-5.2.17/bin/php-cgi && {
	echo -e "\n\n"
	echo "PHP 5.2.17 successfully installed and activated"\
		"on $domains_activated domain(s)"
	[ ${#missed_domains} -gt 0 ] && {
	  for dom in $missed_domains
	  do
		echo -e "\n'$dom' does not exist in Plesk."
		echo "Please add '$dom' in Plesk, then run script again."
	  done
	}
}

# If domains have been processed, print out the following
(( domains_activated >= 1 )) && {
echo -e "\n"
echo "We hope this has helped you out.  Since the domain(s) are now running"
echo "PHP as FastCGI processes, your code will run as the FTP user(s) for the"
echo "domains.  We recommend issuing commands like the following to ensure"
echo "the domains' ownership values match the ownership values that their"
echo "PHP scripts will now run with:"
echo "$chown_recommendations"
echo ""
}
