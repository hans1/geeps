#!/bin/sh
#(c) Copyright Barry Kauler Dec. 2010. License GPL v3 /usr/share/doc/legal.
#This script is executed from /sbin/pup_event_backend_modprobe.
#It executes if a module to be loaded by modprobe has an associated firmware package.
#Thus, this script will execute while Puppy is running, immediately
#after all the firmware files are copied from the firmware tarball in /lib.../all-firmware.
KERNVER="`uname -r`"
rm -f /etc/modprobe.d/modem_slmodem.conf

#101229 Create modprobe.d file.
[ -f /lib/modules/$KERNVER/slmodem/slamr.ko ] \
 && echo 'alias char-major-242 slamr
install slamr modprobe --ignore-install ungrab-winmodem ; modprobe --ignore-install slamr' >> /etc/modprobe.d/modem_slmodem.conf

if [ -f /lib/modules/$KERNVER/slmodem/slusb.ko ];then
 echo 'alias char-major-243 slusb' >> /etc/modprobe.d/modem_slmodem.conf
else
 #110123 Remove slusb init script if driver absent (likely in kernels after 2.6.30).
 rm -f /etc/init.d/Slmodemusb 2>/dev/null
fi
