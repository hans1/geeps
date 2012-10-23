#!/bin/sh
# Patriot Jan 2009 for Puppy Linux 4.1.1 GPL
# Revision 0.0.6
# 13sep09 dialogbox by shinobar
# 4nov09 TIMELIMIT 30sec
# 26dec09 wmpoweroff, adjustable less than 10sec.
# dec 2011 added suspend to gtkdialog

TIMELIMIT=30	# sec, no dialog if 0(zero).

_farewell="Power button is pushed, and about to shut down..."
_press_ok="Press 'OK' to shutdown right now,"
_press_suspend="Press 'suspend' to suspend puppy"
_or_cancel="'Cancel' to continue puppy."
#_ten_sec="Shutting down in 10 seconds."
_limit1="Shutting down in"
_limit2="seconds."

#echo $0 > /root/acpi.log
#date >> /root/acpi.log

SOUND="/usr/share/audio/bark.au"
PLAY="aplay"
[ -f "$SOUND" ] && which $(basename $PLAY) >/dev/null && $(basename $PLAY) "$SOUND" 

#echo "DISPLAY=$DISPLAY" >> /root/acpi.log
X_pid=`ps ax | awk '{if (match($5, "X$") || $5 == "X") print $1}'`
if [ "$X_pid" != "" ]; then
#if [ "$DISPLAY" != "" ]; then
 [ -f /etc/rc.d/PUPSTATE ] && source /etc/rc.d/PUPSTATE
 [ -f /etc/rc.d/pupsave.conf ] && source /etc/rc.d/pupsave.conf
 GTKDIALOG=$(which gtkdialog3)
 PUPSAVECONFIG=$(which pupsaveconfig)
 [ "$PUPSAVECONFIG" = "" ] && PUPSAVECONFIG=$(which pupsave)
 [ "$TIMELIMIT" = "" ] && TIMELIMIT=0
 if [ $TIMELIMIT -gt 0 ] && [ "$GTKDIALOG" != "" ] && \
  [ "$PUPMODE" != "5" -o "$PRECHOICE" != "" -o "$PUPSAVECONFIG" = "" ]; then

   mo=acpi.mo
   # set locale
   for lng in C $(echo $LANGUAGE|cut -d':' -f1) $LC_ALL $LANG;do :;done   # ex.    ja_JP.UTF-8
   # search locale file
   lng1=$(echo $lng|cut -d'.' -f1)      # ex.   ja_JP
   lng2=$(echo $lng|cut -d'_' -f1)   # ex.   ja
   LOCALEDIR=/usr/share/locale
   [ "$mo" ] || mo=$(basename $0).mo
   for D in en C $lng2 $lng1 $lng
   do
     F="$LOCALEDIR/$D/LC_MESSAGES/$mo"
     [ -f "$F" ] && . "$F"
   done
   DIV=10
   [ $TIMELIMIT -le 20 ] && DIV=5
   [ $TIMELIMIT -le 10 ] && DIV=$TIMELIMIT
   STEP=$(($TIMELIMIT / $DIV))
   TIMELIMIT=$(($STEP * $DIV))
   PITCH=$((100 / $DIV))
   export DIALOG="<window title=\"acpid\"><vbox>
  <text><label>$_farewell</label></text>
  <text><label>$_press_ok</label></text>
  <text><label>$_press_suspend</label></text>
  <text><label>$_or_cancel</label></text>
  <progressbar><label>$_limit1 $TIMELIMIT $_limit2</label>
      <input>for i in \$(seq 0 $PITCH 100); do echo \$i; sleep $STEP; done</input>
      <action type=\"exit\">OK</action>
  </progressbar>
  <hbox>
   <button cancel></button>
   <button>
    <input file stock=\"gtk-media-pause\"></input>
    <label>Suspend</label>
    <action type=\"exit\">suspend</action>
   </button>
   <button ok></button>
  </hbox>
 </vbox></window>"
 #echo "$DIALOG"
	eval $($GTKDIALOG -p DIALOG -c)
	[ "$EXIT" = "Cancel" ]&& exit
	[ "$EXIT" = "suspend" ]&& touch /tmp/suspend && /etc/acpi/actions/suspend.sh && exit #111205 Rolf(rhadon)
 fi
 wmpoweroff
else
 poweroff
fi
