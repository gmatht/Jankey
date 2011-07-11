#!/bin/bash
# Installs keytest 

if [ "$USER" != root ]
then
	echo Need to be root to install, but USER="$USER" 
	exit 1
fi

mkdir out
chgrp keytest out
chmod g+rw keytest out

mkdir /var/cache/keytest
if [ -z "$SUDO_USER" ]
then
	echo we would like to chmod /var/cache/keytest to be the SUDO_USER, but we do not seem to have been run from sudo
else
	chown $SUDO_USER /var/cache/keytest
	chown $SUDO_USER out
fi

KT=`dirname "$0"`
# I haven't tested whether this will work on an RPM based distro. Easy to fix though.
apt-get install xclip xvkbd wmctrl xvfb libqt4-dbg icewm || #svn pylint
	yum install xclip xvkbd wmctrl xvfb libqt4-dbg icewm
adduser keytest < /dev/null
adduser keytest2 < /dev/null
addgroup keytest2 keytest
addgroup $SUDO_USER keytest
addgroup $SUDO_USER keytest2

if ! grep keytest /etc/sudoers
then
	echo allowing admin users to switch to keytest user
	echo '%adm ALL =(keytest,keytest2) NOPASSWD: ALL' >> /etc/sudoers
fi
# cat /mnt/jaunty/etc/cups/printers.conf |grep -o '[^ ]*>$' |grep -v '^<'| sed 's/>$//'

#we should really handle each printer seperately, but this will work if they are similar 
if grep AllowUser /etc/cups/printers.conf
then
	echo printer: using whitelisting, nothings needs be done.
	exit
fi
	
if grep -v "^DenyUser keytest$" /etc/cups/printers.conf | grep DenyUser /etc/cups/printers.conf
then
	echo There are already denied users. We do not support this yet, exiting
	exit
fi

#(cd /etc/cups/ppd/ && ls *.ppd) | sed s/.ppd$// | while read L
cat /etc/cups/printers.conf |grep -o '[^ ]*>$' |grep -v '^<'| sed 's/>$//' | while read L
do
	echo $L
	echo lpadmin -p $L -u deny:keytest,keytest2
	lpadmin -p $L -u deny:keytest,keytest2
done




# change this to true to install this as a service
if false
then
	#Warning, this code has not been tested	
	cp $KT/S99keytest /etc/init.d/keytest # This may not work on redhat
	chown root /etc/init.d/keytest 
	chmod 755 /etc/init.d/keytest
	for RC in 2 3 4 5 
	do
		rm /etc/rc$RC.d/S99keytest
		ln -s /etc/init.d/keytest /etc/rc$RC.d/S99keytest
	done
	mkdir -p /etc/keytest
	(cd $KT; pwd) > /etc/keytest/dir
fi 

# Is noatime enabled by default now?
if false # ! mount | egrep ' / .*(rel|no)atime'
then
	echo -----------------------------------------
 	echo - WARNING!!!!
	echo - It appears that relatime is not enabled on your root partition
	echo - This means that every time you access a file, metadata will be updated
	echo - Keytest reads a *lot* of files
	echo - Unless you enable relatime or noatime, running keytest will
	echo -   * Greatly slow down your forground tasks.
	echo -   * Increase the wear and tear on your harddisk
	echo -----------------------------------------
fi
