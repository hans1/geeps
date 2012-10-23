#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/pkg_chooser.sh
#find all pkgs that have been user-installed, format for display.


#/root/.packages/usr-installed-packages has the list of installed pkgs...
touch /root/.packages/user-installed-packages
cut -f 1,10 -d '|' /root/.packages/user-installed-packages > /tmp/installedpkgs.results


###END###
