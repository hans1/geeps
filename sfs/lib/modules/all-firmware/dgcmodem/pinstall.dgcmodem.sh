#!/bin/sh
[ "`which pupdial_init_hotpluggable`" != "" ] \
 && rm -f /etc/init.d/Dgcmodem 2>/dev/null
 
#Indicate not configured - script waits for it.
rm -f /etc/dgcmodem/.serial_configured

sleep 0.5

#Edit config script to avoid device instances 1-7, avoid setting /dev/modem link.
if [ -f /usr/sbin/dgcconfig ];then
 if [ "`grep '^#Edited by Puppy Linux' /usr/sbin/dgcconfig`" = "" ];then
  echo "/usr/sbin/dgcconfig found and being modified."
  sed -i -e 's%^#\!/bin/bash$%#\!/bin/bash\n#Edited by Puppy Linux during extraction of firmware for modem initialization.%' \
   -e 's%while \[ $u -lt 8 \]; do%while [ $u -le 0 ]; do%' \
   -e 's%^[\ \	]*echo \"alias /dev/modem%#echo \"alias /dev/modem%' \
   -e 's%-[ef] /etc/modprobe.conf \]%& \&\& false%' \
   -e 's%if \[ -d /etc/udev/rules\.d \]; then%if [ -f /etc/udev/rules.d ]; then%' \
   -e 's%ln -sf /dev/ttyS...0 /dev/modem%/bin/true #&%' \
   -e 's%first=240%first=244%' \
   -e 's%max=249%max=251%' \
   -e 's%\tmajor=\${first}%\t[ "${device}" = "ttySDGC" -o  "${device}" = "cuaDGC" ] \\\n\t\t\&\& echo 0 \\\n\t\t\&\& return 0\n\n&%' \
   -e 's%\tunconfigure_rcscript || exit%#&%' \
   -e 's%\tremove_kernel_modules || exit%#&%' \
   -e 's%rm -f /dev/modem$%/bin/true #&%' \
   -e 's%mv /dev/modem /dev/modem.old$%/bin/true #&%' \
   -e 's%/etc/modprobe.d/dgc%/etc/modprobe.d/modem_dgc%' \
   -e 's%) > \${outmodprobeconf}$%&.conf%' \
   -e 's%update_modprobeconf \${outmodprobeconf}%&.conf%' \
   -e 's%\${outmodprobeconf}.conflicts%&.conf%' \
   /usr/sbin/dgcconfig
  sync
 fi
 
 #Use edited config script to create devices.
 /usr/sbin/dgcconfig --serial
fi
