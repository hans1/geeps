#!/bin/bash
#welcome1stboot.sh, 01micko for slacko #110923
#set -x
#110925 just run once
export TEXTDOMAIN=welcome1stboot.sh
export OUTPUT_CHARSET=UTF-8
VERSION=0.01
# check connection
#shinobar
LANG=C route | grep -q 'default[ ].*[ ]0\.0\.0\.0[ ]' && \
grep -wq nameserver /etc/resolv.conf && \
#ping -c1 google.com &>/dev/null && CONNECTED="yes" || CONNECTED=
ping -c1 sourceforge.net &>/dev/null && CONNECTED="yes" || CONNECTED=
#LANG=en_US #test
# messages
#[ -f /tmp/firstsplashisdone ] && exit
#echo ok > /tmp/firstsplashisdone

#test screensize and set which gui shows
SCRNSIZE="`xwininfo -root|grep -iE "height"|cut -d ':' -f2`"
if [ "$SCRNSIZE" -le "600" ];then #kicks in at 800x600resolution, eee-701 is 800x480
   BACFLAG=NO
  else BACFLAG=YES
fi
echo $BACFLAG
#MAINMSG="Please answer some questions about your locale, keyboard and timezone by clicking the large Locale button or skip to avoid. You can set your locale later."

if [[ "$CONNECTED" = "yes" ]];then
MAINMSG=$(gettext "Congratulations, you are already connected to the Internet.")
 #echo "connected" > /tmp/firstruncon
 else
 #MAINMSG="${MAINMSG} After this, connect to the Internet"
 if [ "$BACFLAG" = "NO" ];then MAINMSG=$(gettext "You do not have an internet connection")
    MSG2=$(gettext "Click the button to open the internet connection wizard")
	SMALLSCREEN="<hbox>
   <text justify=\"3\"><label>$MSG2</label></text>
   <button>
      <input file>/usr/local/lib/X11/pixmaps/connect48.png</input>
      <width>30</width>
      <action>exit:conn</action>
    </button> 
   </hbox>"
  else
  welcome1stboot && exit #bacon version
 fi
fi
WELCOME=$(gettext "Welcome!")
FIRST=$(gettext "This is the first time you are running Puppy!")
MSG2=$(gettext "You can set up your pup using the \"setup\" icon on the desktop")
MSG3=$(gettext "You can get more information by clicking the \"help\" icon")
export FIRSTBOOT="<window title=\"$WELCOME\">
 <vbox>
  <hbox homogeneous=\"true\">
   <pixmap>
    <width>80</width>
     <input file>/usr/share/doc/puppylogo96.png</input>
   </pixmap> 
  </hbox>
  <hbox homogeneous=\"true\">
   <text wrap=\"false\" use-markup=\"true\"><label>\"<big><big>$WELCOME</big></big>\"</label></text>
  </hbox>
  <hbox homogeneous=\"true\"> 
   <text wrap=\"false\" use-markup=\"true\"><label>\"<big>$FIRST</big>\"</label></text>
  </hbox>
  
  <hseparator></hseparator>
  
  <hbox homogeneous=\"true\">
   <text><label>$MAINMSG</label></text>
  </hbox>
  
  <hseparator></hseparator>
  
  <vbox homogeneous=\"true\"> 
  $SMALLSCREEN
  <hbox>
   <text justify=\"3\"><label>$MSG2</label></text>
   <pixmap>
    <width>30</width>
     <input file>/usr/local/lib/X11/pixmaps/configuration48.png</input>
   </pixmap>
   </hbox>
   <hbox>
   <text justify=\"3\"><label>$MSG3</label></text>
   <pixmap>
    <width>30</width>
     <input file>/usr/local/lib/X11/pixmaps/help48.png</input>
   </pixmap>
  </hbox>
  </vbox>
  <hseparator></hseparator>
  
  <hbox homogeneous=\"true\">
   <button ok>
   </button>
  </hbox>
 </vbox>
</window>"
I=$IFS; IFS="" 
 for STATEMENTS in  $(gtkdialog4 -p FIRSTBOOT -c); do 
	eval $STATEMENTS
 done
 IFS=$I
case $EXIT in
conn) connectwizard ;;
*) exit ;;
esac
 
exit
#end
  