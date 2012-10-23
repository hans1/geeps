#!/bin/sh -a
#sfs_installation.sh
#01micko GPL 18/10/2010

#ok, we need to know what PUPMODE we are in
#if frugal then we grab sfs and download to /initrd/mnt/dev_save (we include usb installs here)
#if live (no save yet) we abort
#if full we expand, make a pet and install 
#if save back to CD we expand and make a pet and install, checking for available RAM first.
#NOTE:this script is only suitable for sfs compatible with your puppy version see TO DO
#TO DO: filter for incompatible sfs
#26/10/2010 #ver 0.1 beta, now fully converting sfs to pet and installing with petget, not dependent on quickpet
#04/11/2010 #ver 0.2 beta shinobar found a bug when loading an sfs previously from partition. Fixed.
#20/11/2010 #ver 0.2.1 beta testing version. Trying with BK's "download_file" frontend for wget
#21/11/2010 #ver 0.3 beta. Fixed syntax bugs for stand-alone application of this script
#22/11/2010 #ver 0.4 beta. Added simple gui for standalone
#23/11/2010 #ver 0.5 beta. Fixed bug if used from quickpet, then stand alone
#07/12/2010 #ver 0.6 Fixing some standalone issues
#13/03/2011 #ver 0.7 if shino's sfs_load is present we use that
#20/03/2011 #ver 0.8 fixed bug if devx was called from quickpet #Jim1911

#get pupmode and other info
. /etc/rc.d/PUPSTATE
. /etc/DISTRO_SPECS
. /etc/rc.d/BOOTCONFIG
#see how many sfs we have loaded and check if we were called from quickpet, we have 5 seconds
QPRUNNING=`ps|grep "quickpack"|grep -v "grep"`
if [ "$QPRUNNING" = "" ];then
 if [[ "$EXTRASFSLIST" != "" ]];then
    rm -f /tmp/currently_loaded_sfs
    for SFSLOADED in $EXTRASFSLIST;do
   echo "$SFSLOADED" >> /tmp/currently_loaded_sfs
   done
 fi
 if [[ $PUPMODE = 2 || $PUPMODE = 3 || $PUPMODE = 77 ]];then SFSLOADEDCOUNT="0"
  else SFSLOADEDCOUNT=`wc -l /tmp/currently_loaded_sfs|cut -f1 -d ' '`
 fi
 if [[ $SFSLOADEDCOUNT -ge 6 ]];then gtkdialog-splash -icon gtk-dialog-warning -timeout 5 -fontsize large -bg orange -close box  -text "You already have the maximum number of sfs files loaded. Exiting so you can unload an sfs from BootManager" &
	exit
 fi
fi

#test for shinobar's sfs_load (load on the fly)
SFSLOAD=`which sfs_load`

case $PUPMODE in

######Puppy must be installed
5) Xdialog -msgbox "You need to install Puppy to use an SFS file" 0 0 0
exit 2
;;

###############"frugal install"(includes usb)
12|13) 
GRABSFS=$1
if [[ -f /tmp/grabthesfs ]];then GRABSFS=`cat /tmp/grabthesfs`
fi
rm -f /tmp/grabthesfs #20101123 Jim1911
REMOTE=`echo $GRABSFS|cut -d ':' -f1`
if [[ "$REMOTE" = "http" || "$REMOTE" = "ftp" ]];then
 THESFS=`basename $GRABSFS`
 [[ -f /initrd${PUP_HOME}/${THESFS} ]]&& killall Xdialog && Xdialog -msgbox "You already have ${THESFS} downloaded. \nLoad it from \"Bootmanager\"" 0 0 0 && exit
 #echo "eval rxvt -bg black -fg white -title "sfs_grab" -e wget -t 0 -c -P /initrd${PUP_HOME} $GRABSFS" > /tmp/sfsinstallget
 #. /tmp/sfsinstallget
 WGET="rxvt -bg black -fg white -title "sfs_grab" -e wget -t0 -c"
 [ -x /usr/sbin/download_file ] && WGET="download_file"
 cd /initrd${PUP_HOME}
 #download_file $GRABSFS
 $WGET $GRABSFS
 cd $HOME
 sync
	else
 THESFS=`basename $GRABSFS`
 . /etc/rc.d/BOOTCONFIG
 SFSEXISTS=`ls /initrd${PUP_HOME}|grep "$THESFS"`
 [[ `echo $LASTUNIONRECORD|grep $THESFS` != "" ]] && gtkdialog-splash -bg red -icon gtk-dialog-warning -timeout 6 -close box -text "$THESFS is already loaded.. exiting" && exit
 if [[ "$SFSEXISTS" = "" ]];then cp -f $GRABSFS /mnt/home/${THESFS}
 fi
 sync
fi

if [[ -f /initrd${PUP_HOME}/${THESFS} ]];then  Xdialog --timeout 3 -msgbox "Installing ${THESFS} " 0 0 0 
	else Xdialog --timeout 3 -msgbox "Failed to download ${THESFS}"  0 0 0 && exit
	exit
fi
if [[ "$SFSLOAD" != "" ]];then #if sfs_load is present then use.
 sfs_load ${THESFS}
 else 
 . /etc/rc.d/BOOTCONFIG
 OLDEXTRASFSLOADED=`echo $LASTUNIONRECORD|cut -d ' ' -f 3,4,5,6,7,8`
 grep -v 'EXTRASFSLIST' /etc/rc.d/BOOTCONFIG > /tmp/BOOTCONFIG
 cat /tmp/BOOTCONFIG > /etc/rc.d/BOOTCONFIG
 if [[ "$EXTRASFSLIST" != "" ]];then echo "EXTRASFSLIST='$EXTRASFSLIST ${THESFS}'" >> /etc/rc.d/BOOTCONFIG
	else
 NEWEXTRASFSLOADED="${OLDEXTRASFSLOADED} ${THESFS}"
 echo "EXTRASFSLIST='$NEWEXTRASFSLOADED'" >> /etc/rc.d/BOOTCONFIG
 fi
 echo "ok, we got the sfs, we triggered the BOOTCONFIG, now we reboot"
 Xdialog --title "Sfs_grab" --clear \
        --yesno "Your ${THESFS} is installed. \nTo activate it you must reboot. You \ncan reboot now or do it later \n \nReboot Now?" 0 0 0
  case $? in 
  0)  echo ${THESFS} >> /etc/sfs_downloaded.qp
  wmreboot;;
  1) exit ;;
  255) exit ;;
  esac
fi
;;

###################"part full install"(save to entire partition, includes usb)
6|7) 
GRABSFS=$1
if [[ -f /tmp/grabthesfs ]];then GRABSFS=`cat /tmp/grabthesfs`
fi
rm -f /tmp/grabthesfs #20101123
REMOTE=`echo $GRABSFS|cut -d ':' -f1`
if [[ "$REMOTE" = "http" || "$REMOTE" = "ftp" ]];then
 THESFS=`basename $GRABSFS`
 [[ -f /${THESFS} ]]&& killall Xdialog &&  Xdialog -msgbox "You already have ${THESFS} downloaded. \nLoad it from \"Bootmanager\"" 0 0 0 && exit 
 cd "/"
 #echo "eval rxvt -bg black -fg white -title "sfs_grab" -e wget -t 0 -c  $GRABSFS" > /tmp/sfsinstallget
 #. /tmp/sfsinstallget
 WGET="rxvt -bg black -fg white -title "sfs_grab" -e wget -t0 -c"
 [ -x /usr/sbin/download_file ] && WGET="download_file"
 #download_file $GRABSFS
 $WGET $GRABSFS
 sync
 if [[ -f /${THESFS} ]];then  Xdialog --timeout 3 -msgbox "Installing ${THESFS} " 0 0 0 
  else Xdialog --timeout 3 -msgbox "Failed to download ${THESFS}"  0 0 0 && exit
 fi
  else
  THESFS=`basename $GRABSFS`
 . /etc/rc.d/BOOTCONFIG
 SFSEXISTS=`ls /|grep "$THESFS"`
 [[ `echo $LASTUNIONRECORD|grep $THESFS` != "" ]] && gtkdialog-splash -bg red -icon gtk-dialog-warning -timeout 6 -close box -text "$THESFS is already loaded.. exiting" && exit
 if [[ "$SFSEXISTS" = "" ]];then cp -f $GRABSFS /${THESFS}
 fi
 sync
fi
cd "$HOME"
if [[ "$SFSLOAD" != "" ]];then #if sfs_load is present then use.
 sfs_load ${THESFS}
 else
 . /etc/rc.d/BOOTCONFIG
 OLDEXTRASFSLOADED=`echo $LASTUNIONRECORD|cut -d ' ' -f 3,4,5,6,7,8`
 grep -v 'EXTRASFSLIST' /etc/rc.d/BOOTCONFIG > /tmp/BOOTCONFIG
 cat /tmp/BOOTCONFIG > /etc/rc.d/BOOTCONFIG
 if [[ "$EXTRASFSLIST" != "" ]];then echo "EXTRASFSLIST='$EXTRASFSLIST ${THESFS}'" >> /etc/rc.d/BOOTCONFIG
  else
 NEWEXTRASFSLOADED="${OLDEXTRASFSLOADED} ${THESFS}"
 echo "EXTRASFSLIST='$NEWEXTRASFSLOADED'" >> /etc/rc.d/BOOTCONFIG
 fi
 echo "ok, we got the sfs, we triggered the BOOTCONFIG, now we reboot"
 Xdialog --title "Sfs_grab" --clear \
        --yesno "Your ${THESFS} is installed. \nTo activate it you must reboot. You \ncan reboot now or do it later \n \nReboot Now?" 0 0 0
  case $? in 
  0)  echo ${THESFS} >> /etc/sfs_downloaded.qp
  wmreboot;;
  1) exit ;;
  255) exit ;;
  esac
fi
;;

#############"full install or live save to cd\dvd"
77|2|3) 
#Xdialog -msgbox "Full installs or live save to cd/dvd are unsupported at the moment" 0 0 0
#exit
#set -x
GRABSFS=$1
THISFS=`basename $1`
if [[ -f /tmp/grabthesfs ]];then GRABSFS=`cat /tmp/grabthesfs`
	rm -f /tmp/grabthesfs #20101123
 else Xdialog --title "Install Space" --clear \
	--yesno "Please ensure you have enough disk space to install $THISFS, \nyou need approxianately 4 times the size of the sfs \nContinue?" 0 0 0
			case $? in 
			0) echo "ok" & ;;
			1) exit ;;
			255) exit ;;
			esac
fi
echo $GRABSFS
THESFS=`basename $GRABSFS`
echo $THESFS
THESFSMNT=`basename $THESFS .sfs`
echo $THESFSMNT
SFSALREADYINSTALLED=`grep $THESFSMNT $HOME/.packages/user-installed-packages`
if [[ "$SFSALREADYINSTALLED" != "" ]];then killall Xdialog && Xdialog --timeout 5 -msgbox "You already have $THESFSMNT installed" 0 0 0 &
 exit
fi
REMOTE=`echo $GRABSFS|cut -d ':' -f1`
if [[ "$REMOTE" = "http" || "$REMOTE" = "ftp" ]];then
 cd "/tmp"
 #echo "eval rxvt -bg black -fg white -title "sfs_grab" -e wget -t 0 -c -P /tmp $GRABSFS" > /tmp/sfsinstallget
 #. /tmp/sfsinstallget
 WGET="rxvt -bg black -fg white -title "sfs_grab" -e wget -t0 -c"
 [ -x /usr/sbin/download_file ] && WGET="download_file"
 #download_file $GRABSFS
 $WGET $GRABSFS
  else
  cp -f $GRABSFS /tmp/${THESFS}
fi 
cd $HOME
sync
gtkdialog-splash -icon gtk-dialog-info -bg thistle -text "Please wait while ${THESFSMNT} is processed..." &
CHECKSFS=`echo $THESFS | sed 's/^.*\.//'`
if [[ "$CHECKSFS" != "sfs" ]]; then
	xmessage -center -bg orange "Not a valid SFS, please choose SFS file"
	exit
fi
   cd "/tmp"
   unsquashfs  -d $THESFSMNT $THESFS
   sleep 1
   if [ $? = 0 ];then rm -f $THESFS
    else
    killall yaf-splash && gtkdialog-splash -bg yellow -icon gtk-dialog-error -timeout 3 -text "failed to extract $THESFS, please download again"
    rm -f $THESFS
    exit
   fi
   sync
   INSTSIZE=`du -sk $THESFSMNT|awk '{print $1}'`
   INSTSIZEK=${INSTSIZE}K
  	####TO DO... add a check for installed duplicate dependencies to facilitate clean uninstallation, general puppy bug really for full installs
  	
  	#SFSSTRING=`grep -w ${THESFSMNT} $HOME/.quickpet/Sfs-puppy-lucid-official`
  	SFSSTRING=`grep -w ${THESFSMNT} /etc/quickpet/Sfs-puppy-spup-official`
	if [[ "$SFSSTRING" != "" ]];then  #added for QP install of sfs
	 SFSPRINT=`echo $SFSSTRING|sed 's/sfs$/pet/g'`
	 SFSSIZE=`echo $SFSSTRING|cut -d '|' -f6`
	 NEWSFSPRINT=`echo "$SFSPRINT"|sed "s/$SFSSIZE/$INSTSIZEK/"`
	 [[ -f $THESFSMNT/pet.specs ]]&& rm -f $THESFSMNT/pet.specs
	 touch $THESFSMNT/pet.specs
	 echo "$NEWSFSPRINT" >> $THESFSMNT/pet.specs
	 tar -czf ${THESFSMNT}.tar.gz $THESFSMNT
	 sync
	 tgz2pet ${THESFSMNT}.tar.gz
	 if [ $? != 0 ];then killall yaf-splash && xmessage -center "failed to compress ${THESFSMNT}.. aborting"
      exit 2
      else killall yaf-splash && gtkdialog-splash -bg yellow -icon gtk-dialog-info -timeout 3 -text "${THESFSMNT}.pet was successfully created, now installing"
     fi
     rm -rf ${THESFSMNT}
     sync
     sleep 2
	 cd $HOME
	 petget +/tmp/${THESFSMNT}.pet
	 killall yaf-splash 2>/dev/null
	 sleep 2
	  if [[ -f $HOME/.packages/${THESFSMNT}.files ]];then 
	   gtkdialog-splash -icon gtk-apply -timeout 6 -fontsize large -bg green -close never -text "Successfully installed $THESFS as ${THESFSMNT}.pet."
	   echo ${THESFS} >> /etc/sfs_downloaded.qp
	   . /etc/quickpet/prefs.conf
	    if [ "$CHKBOX" = "false" ];then cp -f /tmp/${THESFSMNT}.pet $HOME/.quickpet/Downloads/${THESFSMNT}.pet
	    fi
	    else gtkdialog-splash -bg red -icon gtk-dialog-error -timeout 4 -text "Failed to install ${THESFSMNT}.pet."
	  fi
	 sync
	 exit
	 else
	 #quickpet_lupu-4beta2|quickpet_lupu|4beta2||Setup|484K||quickpet_lupu-4beta2.pet||Quickpet Install Popular Programs||||
	 #format #packagename-ver1|packagename|ver1|||||packagename-ver1.pet|||||| 
	 THESFSVERSION=`echo $THESFSMNT|cut -d '-' -f2`
	 THESFSNAME=`echo $THESFSMNT | cut -d '-' -f1`
	 if [[ `echo $THESFSMNT | grep "devx"` != "" ]];then
		THESFSNAME=`echo $THESFSMNT | cut -d '_' -f 1,2`
		THESFSVERSION=`echo $THESFSMNT|cut -d '_' -f3`
	 fi
	 SFSASPETNAME=`echo $THESFS | sed 's/sfs$/pet/'`
	 touch $THESFSMNT/pet.specs
	 echo -e "${THESFSMNT}|${THESFSNAME}|$THESFSVERSION|||$INSTSIZEK||${SFSASPETNAME}||||||" > $THESFSMNT/pet.specs
	 tar -czf ${THESFSMNT}.tar.gz $THESFSMNT
	 sync
	 tgz2pet ${THESFSMNT}.tar.gz
	  if [ $? != 0 ];then xmessage -center "failed to compress ${THESFSMNT}.. aborting"
       exit 2
        else killall yaf-splash && gtkdialog-splash -bg yellow -icon gtk-dialog-info -timeout 3 -text "${THESFSMNT}.pet was successfully created, now installing" &
      fi
     rm -rf ${THESFSMNT}
	 sync
	 sleep 2
	 cd $HOME
	 petget +/tmp/${THESFSMNT}.pet
	 killall yaf-splash 2>/dev/null
	 sleep 2
	  if [[ -f $HOME/.packages/${THESFSMNT}.files ]];then 
	  xmessage -center -bg green "Successfully installed ${THESFSMNT}.pet. If you want 
	  to save the ${THESFSMNT}.pet it is in /tmp"
	   else xmessage -center -bg red "Failed to install ${THESFSMNT}.pet."
	  fi
	 sync
	 exit 0
	fi
;;

##Of course must be puppy!
*) echo 'um, are you running a Puppy?!'
exit
;;
esac


##END