#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (see /usr/share/doc/legal).
#called from /usr/local/petget/installpreview.sh or check_deps.sh
#/tmp/petget_pkg_name_aliases_patterns is written by pkg_chooser.sh.
#passed param is a list of dependencies (DB_dependencies field of the pkg database).
#results format, see comment end of this script.
#100126 handle PKG_NAME_IGNORE variable from file PKGS_MANAGEMENT.
#100711 fix handling of PKG_NAME_ALIASES variable (defined in PKGS_MANAGEMENT file).
#110706 finding missing dependencies fix (running mageia 1).
#110722 versioning info added to dependencies.
#110822 versioning operators can be chained, ex: +linux_kernel&ge2.6.32&lt2.6.33

DB_dependencies="$1" #in standard format of the package database, field 9.

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS #has PKGS_SPECS_TABLE
. /root/.packages/PKGS_MANAGEMENT #has DISTRO_PPM_DEVX_EXCEPTIONS, PKG_ALIASES_INSTALLED

#110722 versioning info added to dependencies...
#the dependencies field can now have &ge, &gt, &eq, &le, &lt
#ex1: |+ncurses,+readline&ge2.3.5,+glibc|
#chained operators allowed: ex2: |+ncurses,+readline&ge2.3.5&&lt2.3.6,+glibc|
#if you want a package to be kernel version sensitive:
#ex3: |+ncurses,+readline+glibc,+linux_kernel&ge2.6.39|

xDB_dependencies="`echo -n "$DB_dependencies" | tr ',' '\n' | cut -f 1 -d '&' | tr '\n' ','`" #110722 chop off any versioning info.

#make pkg deps into patterns... 110722 change DB_dependencies to xDB_dependencies...
PKGDEPS_PATTERNS="`echo -n "$xDB_dependencies" | tr ',' '\n' | grep '^+' | sed -e 's%^+%%' -e 's%^%|%' -e 's%$%|%'`"
echo "$PKGDEPS_PATTERNS" > /tmp/petget_pkg_deps_patterns #ex line, mageia: |libdbus-glib-1_2|

#110722 same as above, but with versioning info...
PKGDEPS_PATTERNS_WITHVER="`echo -n "$DB_dependencies" | tr ',' '\n' | grep '^+' | sed -e 's%^+%%' -e 's%^%|%' -e 's%$%|%' -e 's%&%|%g'`"
echo "$PKGDEPS_PATTERNS_WITHVER" > /tmp/petget_pkg_deps_patterns_with_versioning #ex line, mageia: |libdbus-glib-1_2|ge2.3.6|

#110706 mageia, a dep "libdbus-glib-1_2" must be located in variable PKG_ALIASES_INSTALLED (in file PKGS_MANAGEMENT)...
#/tmp/petget_pkg_name_aliases_patterns[_raw] created in check_deps.sh
for ONEALIAS in `cat /tmp/petget_pkg_name_aliases_patterns_raw | tr '\n' ' ' | tr ',' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 FNDDEPSPTNS="`grep "$ONEALIAS" /tmp/petget_pkg_deps_patterns`"
 if [ "$FNDDEPSPTNS" != "" ];then
  echo "$FNDDEPSPTNS" >> /tmp/petget_pkg_name_aliases_patterns
 fi
done

#need patterns of all installed pkgs...
#100711 /tmp/petget_installed_patterns_system is created in pkg_chooser.sh.
cp -f /tmp/petget_installed_patterns_system /tmp/petget_installed_patterns_all
INSTALLED_PATTERNS_USER="`cat /root/.packages/user-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
echo "$INSTALLED_PATTERNS_USER" >> /tmp/petget_installed_patterns_all

#add these alias names to the installed patterns...
#ALIASES_PATTERNS="`echo -n "$PKG_ALIASES_INSTALLED" | tr -s ' ' | sed -e 's%^ %%' -e 's% $%%' | tr ' ' '\n' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
#echo "$ALIASES_PATTERNS" >> /tmp/petget_installed_patterns_all
#packages may have different names, add them to installed list...
INSTALLEDALIASES="`grep --file=/tmp/petget_installed_patterns_all /tmp/petget_pkg_name_aliases_patterns | tr ',' '\n'`"
[ "$INSTALLEDALIASES" ] && echo "$INSTALLEDALIASES" >> /tmp/petget_installed_patterns_all

#110706 mageia, a dep "libdbus-glib-1_2" must be located in variable PKG_ALIASES_INSTALLED (in file PKGS_MANAGEMENT)...
#/tmp/petget_pkg_name_aliases_patterns[_raw] created in check_deps.sh, pkg_chooser.sh
for ONEALIAS in `cat /tmp/petget_pkg_name_aliases_patterns_raw | tr '\n' ' ' | tr ',' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 FNDPTN="`grep "$ONEALIAS" /tmp/petget_installed_patterns_all`"
 if [ "$FNDPTN" ];then
  FNDDEPPTN="`grep "$ONEALIAS" /tmp/petget_pkg_deps_patterns`"
  [ "$FNDDEPPTN" ] && echo "$FNDDEPPTN" >> /tmp/petget_installed_patterns_all
 fi
done

#100126 some names to ignore, as most likely already installed...
#/tmp/petget_pkg_name_ignore_patterns is created in pkg_choose.sh
cat /tmp/petget_pkg_name_ignore_patterns >> /tmp/petget_installed_patterns_all

#clean it up...
grep -v '^$' /tmp/petget_installed_patterns_all > /tmp/petget_installed_patterns_all-tmp
mv -f /tmp/petget_installed_patterns_all-tmp /tmp/petget_installed_patterns_all

#remove installed pkgs from the list of dependencies...
MISSINGDEPS_PATTERNS="`grep --file=/tmp/petget_installed_patterns_all -v /tmp/petget_pkg_deps_patterns | grep -v '^$'`"
echo "$MISSINGDEPS_PATTERNS" > /tmp/petget_missingpkgs_patterns #can be read by dependencies.sh, find_deps.sh.

#notes on results:
#/tmp/petget_missingpkgs_patterns has a list of missing dependencies, format ex:
#  |kdebase|
#  |kdelibs|
#  |mesa-lib|
#  |qt|
#/tmp/petget_installed_patterns_all (read in dependencies.sh) has a list of already installed
#  packages, both builtin and user-installed. One on each line, exs:
#  |915resolution|
#  |a52dec|
#  |absvolume_puppy|
#  |alsa\-lib|
#  |cyrus\-sasl|
#  ...notice the '-' are backslashed.

#110722
MISSINGDEPS_PATTERNS_WITHVER="`grep --file=/tmp/petget_missingpkgs_patterns /tmp/petget_pkg_deps_patterns_with_versioning | grep -v '^$'`"
echo "$MISSINGDEPS_PATTERNS_WITHVER" > /tmp/petget_missingpkgs_patterns_with_versioning #can be read by dependencies.sh, find_deps.sh.
#...ex each line: |kdebase|ge2.3.6|
# ex with chained operators: |kdebase|ge2.3.6|lt2.4.5|
#note, dependencies.sh currently not using this file.

###END###
