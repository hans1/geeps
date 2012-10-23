#!/bin/sh
#101111 This is called by /sbin/pup_event_backend_modprobe script, when mwave.ko is fetched, but before the module is loaded.
#This is part of mwavem-1.0.2 firmware pkg in zdrv.

echo 'alias char-major-10-219 mwave' > /etc/modprobe.d/modem_mwave.conf
