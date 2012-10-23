#!/bin/sh
# Based on instructions at http://www.a110wiki.de/wiki/Modem

KERNVER="`uname -r`"

#110127 If drivers not present, remove init script (to avoid wait timeout if triggered by udev rule) and exit...
[ "`ls -d /lib/modules/$KERNVER/agrmodem/* 2>/dev/null`" = "" ] \
 && rm -f /etc/init.d/agrsm 2>/dev/null | /bin/true \
 && exit

#110509 remove
#sleep 2 #Wait for possible add-in card..

#Select appropriate variant of the agrsm driver...
if [ "`/sbin/lspci -n | grep ' 11c1:048[cf] '`" != "" ];then
 NEWVARIANT="048pci"
elif [ "`/sbin/lspci -n | grep ' 11c1:06[23]0 '`" != "" ];then
 NEWVARIANT="06pci"
else
 NEWVARIANT="11c11040"
fi

#If necessary, change the variant and run depmod...
for ONEDIR in `ls -d /lib/modules/$KERNVER/agrmodem/* 2>/dev/null`;do
 if [ "$ONEDIR" = "/lib/modules/$KERNVER/agrmodem/$NEWVARIANT" ];then
  mv -f $ONEDIR/agrmodem.HIDE $ONEDIR/agrmodem.ko 2>/dev/null
  mv -f $ONEDIR/agrserial.HIDE $ONEDIR/agrserial.ko 2>/dev/null
  #110127 Uninstall init script if driver variant not present...
  [ ! -e $ONEDIR/agrmodem.ko -o ! -e $ONEDIR/agrmodem.ko ] \
   && rm -f /etc/init.d/agrsm 2>/dev/null
 else
  mv -f $ONEDIR/agrmodem.ko $ONEDIR/agrmodem.HIDE 2>/dev/null
  mv -f $ONEDIR/agrserial.ko $ONEDIR/agrserial.HIDE 2>/dev/null
 fi
done

if [ -e /lib/modules/$KERNVER/agrmodem/$NEWVARIANT/agrmodem.ko ] \
  && [ -e /lib/modules/$KERNVER/agrmodem/$NEWVARIANT/agrserial.ko ];then
 if [ "`grep "/agrmodem/$NEWVARIANT/agrmodem.ko:" /lib/modules/$KERNVER/modules.dep`" = "" ];then
  [ -f /lib/modules/$KERNVER/modules.dep.bin ] \
   && /sbin/depmod-FULL \
   || /sbin/depmod
 fi
 #Create modprobe.d conf to install agrmodem before agrserial, blacklist conflicting modules.
 echo -e "install agrmodem /sbin/modprobe --ignore-install agrmodem && /sbin/modprobe --ignore-install agrserial\ninstall agrserial /bin/true\nblacklist snd_via82xx_modem\nblacklist snd_atiixp_modem\nblacklist snd_intel8x0m\nblacklist snd_ali5451" > /etc/modprobe.d/modem_agrsm.conf
fi

###END###
