#!/bin/sh
#Barry Kauler, Feb. 2012. GPL3 (/usr/share/doc/legal)
#this is the post-install script for a langpack PET created by /usr/sbin/momanager.
#MoManager will replace the strings TARGETLANG and POSTINSTALLMSG.
#120315 maybe have hunspell dictionaries in langpack.

echo "Post install script for TARGETLANG language pack"

#if [ "$LANG" = "C" ];then #in case caller script did this.
 LANG="`grep '^LANG=' /etc/profile | cut -f 2 -d '=' | cut -f 1 -d ' '`"
 export LANG
#fi
LANG1="`echo -n $LANG | cut -f 1 -d '_'`"  #ex: de

if [ -d usr/share/applications.in ];then
 for ADESKTOPFILE in `find usr/share/applications.in -mindepth 1 -maxdepth 1 -type f -name '*.desktop' | tr '\n' ' '`
 do
  ABASEDESKTOP="`basename $ADESKTOPFILE`"
  if [ -f usr/share/applications/${ABASEDESKTOP} ];then
   if [ "`grep '^Name\[TARGETLANG\]' usr/share/applications/${ABASEDESKTOP}`" = "" ];then
    if [ "`grep '^Name\[TARGETLANG\]' usr/share/applications.in/${ABASEDESKTOP}`" != "" ];then
     #aaargh, these accursed back-slashes! ....
     INSERTALINE="`grep '^Name\[TARGETLANG\]' usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
     sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" usr/share/applications/${ABASEDESKTOP}
    fi
   fi
  fi
 done
 #rm -r -f usr/share/applications.in
 #...don't remove it. might be useful for ppm when install future packages.
fi

if [ -d usr/share/desktop-directories.in ];then
 for ADESKTOPFILE in `find usr/share/desktop-directories.in -mindepth 1 -maxdepth 1 -type f -name '*.directory' | tr '\n' ' '`
 do
  ABASEDESKTOP="`basename $ADESKTOPFILE`"
  if [ -f usr/share/desktop-directories/${ABASEDESKTOP} ];then
   if [ "`grep '^Name\[TARGETLANG\]' usr/share/desktop-directories/${ABASEDESKTOP}`" = "" ];then
    if [ "`grep '^Name\[TARGETLANG\]' usr/share/desktop-directories.in/${ABASEDESKTOP}`" != "" ];then
     #aaargh, these accursed back-slashes! ....
     INSERTALINE="`grep '^Name\[TARGETLANG\]' usr/share/desktop-directories.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
     sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" usr/share/desktop-directories/${ABASEDESKTOP}
    fi
   fi
  fi
 done
 rm -r -f usr/share/desktop-directories.in
fi

#120315 maybe have hunspell dictionaries in langpack (see also momanager)...
for ONEHUN in `find ./usr/share/hunspell -mindepth 1 -maxdepth 1 -type f -name '*.dic' -o -name '*.aff' | tr '\n' ' '`
do
 HUNBASE="`basename $ONEHUN`"
 [ -e ./usr/lib/seamonkey ] && ln -snf ../../../share/hunspell/${HUNBASE} ./usr/lib/seamonkey/dictionaries/${HUNBASE}
 [ -e ./usr/lib/firefox ] && ln -snf ../../../share/hunspell/${HUNBASE} ./usr/lib/firefox/dictionaries/${HUNBASE}
done


if [ "`pwd`" = "/" ];then #installing PET in a running puppy.
 if [ "$LANG1" != "en" ];then
  #need to update SSS translations...
  fixscripts
  fixdesk
  fixmenus
  pupdialog --background green --backtitle "Language Pack" --msgbox "POSTINSTALLMSG" 0 0 &
 fi
fi
