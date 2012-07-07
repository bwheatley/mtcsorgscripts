#!/bin/bash
cd

#
# Fix Locales
#

echo "en_US.UTF-8 UTF-8" > /var/lib/locales/supported.d/local
dpkg-reconfigure locales

#
# Update Aptitude
#

aptitude update && apt-get -y upgrade

# Install cUrl and DNS Utilities....
# because I like to dig from my servers
#

aptitude -y install curl dnsutils

#
# Add multiverse to sources.list
#

cat <<EOF >> /etc/apt/sources.list

deb http://us.archive.ubuntu.com/ubuntu/ karmic multiverse
deb http://us.archive.ubuntu.com/ubuntu/ karmic-updates multiverse
deb http://security.ubuntu.com/ubuntu karmic-security multiverse

EOF

#
# Update Sources
#
apt-get update

#
# Install Sun-Java
#
aptitude -y install sun-java6-jre
aptitude -y install sun-java6-jdk
aptitude -y install sun-java6-bin
aptitude -y install sun-java6-source
aptitude -y install sun-java6-plugin
aptitude -y install sun-java6-javadb
aptitude -y install openjdk-6-jre
aptitude -y install ia32-sun-java6-bin

#
# Update Alternatives to use ia32-sun-java6-bin
#

update-java-alternatives -s ia32-java-6-sun

#
# Set JAVA_HOME in /etc/profile
#
cat <<EOF >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/ia32-java-6-sun/
export PATH=$PATH:$JAVA_HOME/bin

EOF

#
# Run commands for current session
#
export JAVA_HOME=/usr/lib/jvm/ia32-java-6-sun/
export PATH=$PATH:$JAVA_HOME/bin