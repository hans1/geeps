#!/bin/sh
#Disable extraneous and interfering dependency.
echo "install esscom_hw /bin/true" > /etc/modprobe.d/modem_pctel.conf

mknod /dev/ttyS_PCTEL0 c 62 64
