#!/bin/bash
#screeny : takes screen shots of fullscreen and windows
#DEPENDS : +xwd
# (c) Mick Amadio, 01micko@gmail.com LGPL (see /usr/share/doc/legal)
v=0.2
#set work dir
APPDIR=$(pwd)
export APPDIR

[ ! $(which xwd) ] && \
	echo "error: install xwd package for your distro" && exit 1
[ ! -f $HOME/.screenyrc ] && echo 'CB=true' > $HOME/.screenyrc && \
echo 'SEC=1' >> $HOME/.screenyrc
. $HOME/.screenyrc

#gui
export SCREENY='<window title="Screeny '$v'" resizable="false" icon-name="gtk-page-setup">
 <vbox>
  <text use-markup="true">
   <label>"<span color='"'blue'"'><big><b>Capture Screen Shot</b></big></span>"</label>
  </text>
  <text><label>Choose window or fullscreen</label></text>
  <frame>
   <button>
    <input file stock="gtk-find"></input>
    <label>window</label>
    <action type="exit">window</action>
   </button>
  </frame>
  <frame>
   <button>
    <input file stock="gtk-fullscreen"></input>
    <label>fullscreen</label>
    <action type="exit">full</action>
   </button>
   <hbox> 
    <text><label>Set Delay</label></text>
    <entry width-request="40" tooltip-text="useful only for full shots">
     <variable>SEC</variable>
     <default>'$SEC'</default>
    </entry>
   </hbox>
  </frame>
  <text><label>Name your output file (optional)</label></text>
  <entry tooltip-text="choose a name if desired, else your shot will be capturexxx.png">
   <variable>NAME</variable>
   <default>capture$$</default>
  </entry> 
  <checkbox tooltip-text="Uncheck this to avoid the splash messages (faster)">
   <label>Uncheck to turn off messages</label>
   <variable>CB</variable>
   <default>'$CB'</default>
  </checkbox> 
  <hbox><button cancel></button></hbox>
 </vbox>
</window>'
eval $(gtkdialog -p SCREENY -c)
export CAPTURE="$HOME/${NAME}.png"
. $APPDIR/screenfunc
case $EXIT in
window)[ "$CB" = "true" ] && \
yaf-splash -bg yellow -close never -timeout 3 -text \
"Hover mouse over desired window and click"
echo "CB=$CB" > $HOME/.screenyrc
echo "SEC=$SEC" >> $HOME/.screenyrc 
. $APPDIR/screenfunc snap_func1
;;
full)
[ "$SEC" -gt "3" ] && \
WAIT=$((${SEC}-2))
[ "$SEC" -gt "3" ] && \
yaf-splash -bg yellow -close never -timeout $WAIT -text \
"Waiting ..." &
sleep $SEC
echo "CB=$CB" > $HOME/.screenyrc
echo "SEC=$SEC" >> $HOME/.screenyrc 
. $APPDIR/screenfunc snap_func2
;;
*)exit ;;
esac
[ "$CB" = "true" ] && \
yaf-splash -bg green -close never -timeout 4 -text \
"Your $EXIT screen shot is saved as $CAPTURE" 
exit
