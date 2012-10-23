#!/bin/sh
# suspend.sh 28sep09 by shinobar

# do not suspend at shutdown proccess
#111129 added suspend to acpi_poweroff.sh
if [ ! -f /tmp/suspend ];then
  for P in acpi_poweroff.sh
  do
    ps ax | grep -v 'grep' | grep -q "sh[ ].*$P" && exit
  done
fi
rm -f /tmp/suspend
for P in wmpoweroff poweroff
do
  pidof "$P" >/dev/null && exit
done

# do not suspend if usb media mounted
USBS=$(probedisk2|grep '|usb' | cut -d'|' -f1 )
for USB in $USBS
do
	mount | grep -q "^$USB" && exit
done

# process before suspend
# sync for non-usb drives
sync
rmmod ehci_hcd

#suspend
echo -n mem > /sys/power/state

# process at recovery from suspend
modprobe ehci_hcd