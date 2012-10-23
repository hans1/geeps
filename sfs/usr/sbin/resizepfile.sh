#!/bin/sh
#2007 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)
#make the pup_save.2fs file bigger.

# 3-5-2011 re write to gtk2 Xdialog it was in xmessage before by Joe Arose

#variables created at bootup by /initrd/usr/sbin/init...
. /etc/rc.d/PUPSTATE #v2.02
#PUPMODE=current operating configuration,
#PDEV1=the partition have booted off, DEV1FS=f.s. of PDEV1,
#PUPSFS=pup_201.sfs versioned name, stored on PDEV1, PUPSAVE=vfat,sda1,/pup_save.2fs

#find out what modes use a pup_save.2fs file...
CANDOIT="no"
case $PUPMODE in
 "12") #pup_save.3fs (pup_rw), nothing on pup_ro1, pup_xxx.sfs (pup_ro2).
  PERSISTMNTPT="/initrd/pup_rw"
  CANDOIT="yes"
  ;;
 "13") #tmpfs (pup_rw), pup_save.3fs (pup_ro1), pup_xxx.sfs (pup_ro2).
  PERSISTMNTPT="/initrd/pup_ro1"
  CANDOIT="yes"
  ;;
esac

 if [ "$CANDOIT" != "yes" ];then
  Xdialog --title "Resize personal storage file" \
          --infobox "Sorry, you are not currently using a personal persistent
storage file. If this is the first time that you booted
, say from a live-CD, you are currently running
totally in RAM and you will be asked to create a personal
storage file when you end the session (shutdown the PC or
reboot). Note, the file will be named pup_save.2fs and
will be created in a place that you nominate.
If you have installed  to hard drive, or installed
such that personal storage is an entire partition, then
you will not have a pup_save.2fs file either.
Press OK to exit..." 0 0 60000
  
 
  exit
 fi

[ ! "$PUPSAVE" ] && exit #precaution
[ ! "$PUP_HOME" ] && exit #precaution.



SAVEFS="`echo -n "$PUPSAVE" | cut -f 2 -d ','`"
SAVEPART="`echo -n "$PUPSAVE" | cut -f 1 -d ','`"
SAVEFILE="`echo -n "$PUPSAVE" | cut -f 3 -d ','`"
NAMEPFILE="`basename $SAVEFILE`"

HOMELOCATION="/initrd${PUP_HOME}${SAVEFILE}"
SIZEFREE=`df -m | grep "$PERSISTMNTPT" | tr -s " " | cut -f 4 -d " "` #free space in pup_save.3fs
ACTUALSIZK=`ls -sk $HOMELOCATION | tr -s " " | cut -f 1 -d " "` #total size of pup_save.3fs
if [ ! $ACTUALSIZK ];then
 ACTUALSIZK=`ls -sk $HOMELOCATION | tr -s " " | cut -f 2 -d " "`
fi
ACTUALSIZE=`expr $ACTUALSIZK \/ 1024`
APATTERN="/dev/${SAVEPART} "
PARTFREE=`df -m | grep "$APATTERN" | tr -s " " | cut -f 4 -d " "`



Xdialog --title "Resize personal storage file utility " \
        --menu "
Your personal file is $NAMEPFILE, and this contains all 
of your data,configuration files,history files, 
installed packages and so on. 

You have $SIZEFREE Mbytes free space left in $NAMEPFILE,
out of a total size of $ACTUALSIZE Mbytes.

File $NAMEPFILE is actually stored on partition $SAVEPART.
You have $PARTFREE Mbytes space left in $SAVEPART.

So, you need to make a decision. If you see that you are running
low on space in $NAMEPFILE, you can make it bigger, but of
course there must be enough space in $SAVEPART.

PLEASE NOTE THAT AFTER YOU HAVE SELECTED AN OPTION BELOW,
NOTHING WILL HAPPEN. THE RESIZING WILL HAPPEN AT REBOOT.

Select an option to make $NAMEPFILE bigger by that amount...
(note, this is one-way, you cannot make it smaller)" 0 0 9 \
        "64" "MB larger" \
        "128" "MB larger" \
        "256" "MB larger" \
        "512" "MB larger " \
        "1024" "MB larger  1GB" \
        "2048" "MB larger  2GB" \
        "4096" "MB larger  4GB"  \
        "8192" "MB larger  8GB"  2> /tmp/reply2

REPLYX=$?

#for debugging 

REPLY2=`cat /tmp/reply2`
# echo $REPLY2

#zero the value
KILOBIG=

case $REPLYX in
  0)
    echo "'$choice' chosen."
	;;
  1)
    echo "Cancel pressed."
	exit
	;;
  255)
    echo "Box closed."
	exit 
	;;
esac


#--------------------------------------------
#        ##   Select increase in MB       ##
#--------------------------------------------
   if [ "$REPLY2" = "64" ]; then
   KILOBIG="65536"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "64M" > /tmp/reply3   
   
   elif  [ "$REPLY2" = "128" ]; then
   KILOBIG="131072"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "128M" > /tmp/reply3 
   
   elif  [ "$REPLY2" = "256" ]; then
   KILOBIG="262144"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "256M" > /tmp/reply3 
    
   
   elif  [ "$REPLY2" = "512" ]; then
   KILOBIG="524288"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "512M" > /tmp/reply3 
   
   elif  [ "$REPLY2" = "1024" ]; then
   KILOBIG="1048576"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "1G" > /tmp/reply3 
   
   elif  [ "$REPLY2" = "2048" ]; then
   KILOBIG="2097152"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "2G" > /tmp/reply3 
   
   elif  [ "$REPLY2" = "4096" ]; then
   KILOBIG="4194304"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "4G" > /tmp/reply3 
   
   
   elif  [ "$REPLY2" = "8192" ]; then
   KILOBIG="8388608"
   echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt
   echo "8G" > /tmp/reply3 
         
   fi

#/initrd/pupsaveresize.txt


Xdialog --title "Resize personal storage file"  \
        --infobox "Okay, you have chosen to increase $NAMEPFILE by $KILOBIG Kbytes,
        however as the file is currently in use, it will happen at reboot.

Technical notes:
The required size increase has been written to file pupsaveresize.txt,
in partition $SAVEPART (currently mounted on /mnt/home).
File pupsaveresize.txt will be read at bootup and the resize performed
then pupsaveresize.txt will be deleted.

WARNING: If you have multiple pup_save files, be sure to select
the same one when you reboot.

The change will only happen at reboot.
Click OK to exit..." 0 0 60000


#notes:
#  dd if=/dev/zero bs=1k count=$KILOBIG | tee -a $HOMELOCATION > /dev/null
