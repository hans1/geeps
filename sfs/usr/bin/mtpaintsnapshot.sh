#!/bin/bash
DIALOG=Xdialog

$DIALOG --title "Screenshot" \
        --radiolist "Choose delay before capture" 0 0 0 \
        "Capture Now" 	 " "	ON \
        "5 Second Delay"    " " off \
        "10 Second Delay" "" off \
        "20 Second Delay"    "" off \
        "30 Second Delay"   "" off \
        "60 Second Delay"	"" off 2>/tmp/checklist.tmp.$$

retval=$?
choice=`cat /tmp/checklist.tmp.$$`
rm -f /tmp/checklist.tmp.$$




case $choice in
  Capture*)
           sleep 0.2
           exec mtpaint -s;;
  5*)
           sleep 5
           exec mtpaint -s;;
  10*)
           sleep 10
           exec mtpaint -s;;
  20*)
           sleep 20
           exec mtpaint -s;;
  30*)
           sleep 30
           exec mtpaint -s;;
  60*)
           sleep 60
           exec mtpaint -s;;
esac

