#!/bin/sh
#copyright 01micko 2011
#GPL3 see /usr/share/doc/legal/
#NO warranty
#110117 0.1 simple prog to arrange desk icons
#110118 0.2 added custom save setting
#110119 0.3 bugfix in custom if changed wallpaper 
#110120 0.4 add lupu/luci specific support, test for rox running, revise drive icon routine, revise close routine, bugfix for /etc/eventmanager
#110511 0.5 add extra 'spup' option
ver="0.5"
#is rox running?
ROXRUNNING=`ps|grep "/usr/local/apps/ROX-Filer/ROX-Filer -p /root/Choices/ROX-Filer/PuppyPin"|grep -v "grep"`
[ "$ROXRUNNING" = "" ]&& gtkdialog-splash  -icon gtk-dialog-error -timeout 5 -deco deskset -fontsize large -bg hotpink -close never -text "ERROR: Rox pinboard is not running. You can't use this application" && exit
#eventmanager has a bug where pristine it has double quotes arround bool statements, after evenmanager is run they disappear
HASQUOTES=`grep '"' /etc/eventmanager`
if [[ "$HASQUOTES" != "" ]];then #110120
 sed -i 's/\"//g' /etc/eventmanager
fi 
. /etc/eventmanager
#get radio defaults for drive icons from /etc/eventmanager
if [[ "$ICONDESK" = "false" && "$ICONPARTITIONS" = "true" ]];then
 RADIO6=true
 RADIO7=false
 RADIO8=false
 RADIO9=false
 elif [[ "$ICONDESK" = "true" && "$ICONPARTITIONS" = "true" ]];then
  RADIO6=false
  RADIO7=true
  RADIO8=false
  RADIO9=false
 elif [[ "$ICONDESK" = "true" && "$ICONPARTITIONS" = "false" ]];then
  RADIO6=false
  RADIO7=false
  RADIO8=true
  RADIO9=false
 elif [[ "$ICONDESK" = "false" && "$ICONPARTITIONS" = "false" ]];then
  RADIO6=false
  RADIO7=false
  RADIO8=false
  RADIO9=true
fi 
#define working directorys
APPDIR="`dirname $0`"
[ "$APPDIR" = "." ] && APPDIR="`pwd`"
export APPDIR="$APPDIR"
#define config dir/file
CONFDIR="$HOME/.desksetup"
CONFFILE="$CONFDIR/desk.conf"
#export $CONFFILE
cp -af $CONFFILE ${CONFFILE}.bak
. $CONFFILE
PIXMAPDIR="/usr/local/lib/X11/mini-icons"
#gui
export deskset="<window title=\"Desktop Setup $ver\"  icon-name=\"gtk-preferences\">
 <vbox>
  <notebook labels=\"Desk Icons|Drive Icons\">
   <vbox>
   <pixmap>
    <input file>$PIXMAPDIR/mini-desktop.xpm</input>
   </pixmap>
   <text use-markup=\"true\"><label>\"<b>Choose a desktop layout</b>\"</label></text>
   <radiobutton tooltip-text=\"This is the standard Puppy desktop that has been a tradition since Barry Kauler started Puppy in 2003, for purists\">
	<label>\"Traditional -full desktop icons\"</label>
	<variable>RADIO1</variable>
	<action>if true sed -i 's/RADIO1=[a-z]*[a-z]/RADIO1=true/' $CONFFILE</action>
	<action>if false sed -i 's/RADIO1=[a-z]*[a-z]/RADIO1=false/' $CONFFILE</action>
	<default>$RADIO1</default>
   </radiobutton>
   <radiobutton tooltip-text=\"This includes just the file, browse, edit, console and play icons, for those who move fast\">
	<label>\"Minimal -essential desktop icons\"</label>
	<variable>RADIO2</variable>
	<action>if true sed -i 's/RADIO2=[a-z]*[a-z]/RADIO2=true/' $CONFFILE</action>
	<action>if false sed -i 's/RADIO2=[a-z]*[a-z]/RADIO2=false/' $CONFFILE</action>
	<default>$RADIO2</default>
   </radiobutton>
   <radiobutton tooltip-text=\"There will be no application icons on the desktop, this is for minimalists\">
	<label>\"Bare -no desktop icons\"</label>
	<variable>RADIO3</variable>
	<action>if true sed -i 's/RADIO3=[a-z]*[a-z]/RADIO3=true/' $CONFFILE</action>
	<action>if false sed -i 's/RADIO3=[a-z]*[a-z]/RADIO3=false/' $CONFFILE</action>
	<default>$RADIO3</default>
   </radiobutton>
   <radiobutton tooltip-text=\"This template is the standard Slacko layout\">
	<label>\"Slacko custom icons\"</label>
	<variable>RADIO4</variable>
	<action>if true sed -i 's/RADIO4=[a-z]*[a-z]/RADIO4=true/' $CONFFILE</action>
	<action>if false sed -i 's/RADIO4=[a-z]*[a-z]/RADIO4=false/' $CONFFILE</action>
	<default>$RADIO4</default>
   </radiobutton>
   <radiobutton tooltip-text=\"This will display your saved custom pinboard\">
	<label>\"Custom -choose your saved profile\"</label>
	<variable>RADIO5</variable>
	<action>if true sed -i 's/RADIO5=[a-z]*[a-z]/RADIO5=true/' $CONFFILE</action>
	<action>if false sed -i 's/RADIO5=[a-z]*[a-z]/RADIO5=false/' $CONFFILE</action>
	<default>$RADIO5</default>
   </radiobutton>
   <hbox>
   <text><label>Click this button to save your custom arrangement</label></text>
   <button tooltip-text=\"Clicking here will save your desktop changes to a customised file. Be aware that this omits drive icons\">
    <input file stock=\"gtk-save\"></input>
    <action>. $APPDIR/func customsave</action>
   </button>
   </hbox>
  </vbox>
  
  <vbox>
   <pixmap>
    <input file>$PIXMAPDIR/mini-diskette.xpm</input>
   </pixmap>
   <text use-markup=\"true\"><label>\"<b>Choose a drive icon layout</b>\"</label></text>
   <radiobutton tooltip-text=\"This is for minimalist bare desktops, there will be no drive icons at all\">
	<label>\"Clean -no drive icons\"</label>
	<variable>RADIO6</variable>
	
	<default>$RADIO6</default>
   </radiobutton>
   <radiobutton tooltip-text=\"This is the default for all puppies, each partition will have it's own icon as will plugged drives\">
	<label>\"Traditional -an icon for each partition\"</label>
	<variable>RADIO7</variable>
	
	<default>$RADIO7</default>
   </radiobutton>
   <radiobutton tooltip-text=\"There will be only the root of the drives on the desktop\">
	<label>\"Lean -only root drive icons\"</label>
	<variable>RADIO8</variable>
	
	<default>$RADIO8</default>
   </radiobutton>
   <radiobutton tooltip-text=\"There will be only 1 drive icon which starts Pmount\">
	<label>\"Minimal -One drive icon\"</label>
	<variable>RADIO9</variable>
	
	<default>$RADIO9</default>
   </radiobutton>
  </vbox>
 </notebook>
  <hbox homogeneous=\"true\">
   <text use-markup=\"true\"><label>\"<i>When <b>Apply</b> is clicked X will restart</i>\"</label></text>
  </hbox>
  <hbox>
   <button tooltip-text=\"Clicking Apply will save your changes and restart the X server. Be sure you have saved all your work\">
    <input file stock=\"gtk-apply\"></input>
    <label>Apply</label>
    <action>. $APPDIR/func apply</action>
    <action>exit:applied</action>
   </button>
   <button>
    <input file stock=\"gtk-quit\"></input>
    <label>Close</label>
    <action>cp -af ${CONFFILE}.bak $CONFFILE </action>
    <action>exit:closed</action>
   </button>
  </hbox>
 </vbox>
</window>
"
gtkdialog3 -p deskset -c
unset deskset
#end