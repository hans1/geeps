#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from pkg_chooser.sh
#package to be previewed prior to installation is TREE1 -- inherited from parent.
#/tmp/petget_filterversion has the repository that installing from.
#100821 bug in Lucid 5.1, /tmp/pup_event_sizefreem had two identical lines.
#101221 yaf-splash fix.
#120101 01micko: jwm >=547 has -reload, no screen flicker.
#120116 rev. 514 introduced icon rendering method which broke -reload at 547. fixed at rev. 574.
#120203 BK: internationalized.

export TEXTDOMAIN=petget___installpreview.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

#/usr/X11R7/bin/yaf-splash -font "8x16" -outline 0 -margin 4 -bg orange -text "Please wait, processing package database files..." &
yaf-splash -close never -bg orange -text "$(gettext 'Please wait, processing package database files...')" &
X1PID=$!

#ex: TREE1=abiword-1.2.4 (first field in database entry).
DB_FILE=Packages-`cat /tmp/petget_filterversion` #ex: Packages-slackware-12.2-official

rm -f /tmp/petget_missing_dbentries-* 2>/dev/null

tPATTERN='^'"$TREE1"'|'
DB_ENTRY="`grep "$tPATTERN" /root/.packages/$DB_FILE | head -n 1`"
#line format: pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|
#optionally on the end: compileddistro|compiledrelease|repo| (fields 11,12,13)

DB_pkgname="`echo -n "$DB_ENTRY" | cut -f 1 -d '|'`"
DB_nameonly="`echo -n "$DB_ENTRY" | cut -f 2 -d '|'`"
DB_version="`echo -n "$DB_ENTRY" | cut -f 3 -d '|'`"
DB_pkgrelease="`echo -n "$DB_ENTRY" | cut -f 4 -d '|'`"
DB_category="`echo -n "$DB_ENTRY" | cut -f 5 -d '|'`"
DB_size="`echo -n "$DB_ENTRY" | cut -f 6 -d '|'`"
DB_path="`echo -n "$DB_ENTRY" | cut -f 7 -d '|'`"
DB_fullfilename="`echo -n "$DB_ENTRY" | cut -f 8 -d '|'`"
DB_dependencies="`echo -n "$DB_ENTRY" | cut -f 9 -d '|'`"
DB_description="`echo -n "$DB_ENTRY" | cut -f 10 -d '|'`"

[ "$DB_description" = "" ] && DB_description="$(gettext 'no description available')"

SIZEFREEM=`cat /tmp/pup_event_sizefreem | head -n 1` #100821 bug in Lucid 5.1, file had two identical lines.
SIZEFREEK=`expr $SIZEFREEM \* 1024`

if [ $DB_size ];then
 SIZEMK="`echo -n "$DB_size" | rev | cut -c 1`"
 SIZEVAL=`echo -n "$DB_size" | rev | cut -c 2-9 | rev`
 SIZEINFO="<text><label>$(gettext 'After installation, this package will occupy') ${SIZEVAL}${SIZEMK}B. $(gettext 'The amount of free space that you have for installation is') ${SIZEFREEM}MB (${SIZEFREEK}KB).</label></text>"
 SIZEVALz=`expr $SIZEVAL \/ 3`
 SIZEVALz=`expr $SIZEVAL + $SIZEVALz`
 SIZEVALx2=`expr $SIZEVALz + 10000`
 if [ $SIZEVALx2 -ge $SIZEFREEK ];then
  MSGWARN1="${SIZEINFO}<text use-markup=\"true\"><label>\"<b>$(gettext "A general rule-of-thumb is that the free space should be at least the original-package-size plus installed-package-size plus 10MB to allow for sufficient working space during and after installation. It does not look to good, so you had better click the 'Cancel' button")</b> -- $(gettext "note, if you are running Puppy in a mode that has a 'pupsave' file, then the Utility menu has an entry 'Resize personal storage file' that should solve the problem.")\"</label></text>"
 else
  MSGWARN1="${SIZEINFO}<text use-markup=\"true\"><label>\"<b>$(gettext "...free space looks ok, so click 'Install' button:")</b>\"</label></text>"
 fi
else
 MSGWARN1="<text use-markup=\"true\"><label>\"<b>$(gettext 'Unfortunately the provider of the package database has not supplied the size of this package when installed. If you are able to see the size of the compressed package, multiple that by 3 to get the approximate installed size. The free available space, which is') ${SIZEFREEM}MB (${SIZEFREEK}KB), $(gettext 'should be at least 4 times greater.')</b>\"</label></text>"
fi


#find missing dependencies...
if [ "$DB_dependencies" = "" ];then
 #DEPINFO="<text><label>The provider of the package database has not supplied any dependency information for this package. However, after installing it you will have the option to test for any missing shared library files. If uncertain, you might want to look for online documentation for this package that explains any required dependencies.</label></text>"
 DEPINFO="<text><label>$(gettext 'It seems that all dependencies are already installed. Sometimes though, the dependency information in the database is incomplete, however a check for presence of needed shared libraries will be done after installation.')</label></text>"
else

 #find all missing pkgs...
 /usr/local/petget/findmissingpkgs.sh "$DB_dependencies"
 #...returns /tmp/petget_installed_patterns_all, /tmp/petget_pkg_deps_patterns, /tmp/petget_missingpkgs_patterns
 MISSINGDEPS_PATTERNS="`cat /tmp/petget_missingpkgs_patterns`"
 #/tmp/petget_missingpkgs_patterns has a list of missing dependencies, format ex:
 #|kdebase|
 #|kdelibs|
 #|mesa|
 #|qt|

 DEPBUTTON=""
 ONLYMSG=""
 if [ "$MISSINGDEPS_PATTERNS" = "" ];then
  DEPINFO="<text><label>$(gettext 'It seems that all dependencies are already installed. Sometimes though, the dependency information in the database is incomplete, however a check for presence of needed shared libraries will be done after installation.')</label></text>"
 else
  ONLYMSG=" $(gettext 'ONLY')"
  DEPBUTTON="<button>
   <label>$(gettext 'Examine dependencies')</label>
   <action>echo \"${TREE1}\" > /tmp/petget_installpreview_pkgname</action>
   <action type=\"exit\">BUTTON_EXAMINE_DEPS</action>
  </button>"
  xMISSINGDEPS="`echo "$MISSINGDEPS_PATTERNS" | sed -e 's%|%%g' | tr '\n' ' '`"
  DEPINFO="<text><label>$(gettext 'Warning, the following dependent packages are missing:')</label></text>
  <text use-markup=\"true\"><label>\"<b>${xMISSINGDEPS}</b>\"</label></text>
  <text><label>$(gettext "A warning, these dependencies may have other dependencies not necessarily listed here. It is recommended that you click the 'Examine dependencies' button to find all dependencies before installing.")</label></text>
  <text use-markup=\"true\"><label>\"<b>$(gettext "Please click 'Examine dependencies' to install") ${TREE1} $(gettext "as well as its dependencies")</b>\"</label></text>"
  if [ $DB_size ];then
   MSGWARN1="<text><label>$(gettext 'After installation, this package will occupy') ${SIZEVAL}${SIZEMK}B, $(gettext 'however the dependencies will need more space so you really need to find what they will need first.')</label></text>"
  else
   MSGWARN1="<text><label>$(gettext 'Also, the package database provider has not supplied the installed size of this package, so you will have to try and estimate whether you have enough free space for it (and the dependencies)')</label></text>"
  fi
 fi 
fi

kill $X1PID

export PREVIEW_DIALOG="<window title=\"$(gettext 'Puppy Package Manager: preinstall')\" icon-name=\"gtk-about\">
<vbox>
 <text><label>$(gettext 'You have chosen to install package') '${TREE1}'. $(gettext 'A short description of this package is:')</label></text>
 <text use-markup=\"true\"><label>\"<b>${DB_description}</b>\"</label></text>
 ${DEPINFO}
 
 ${MSGWARN1}
 
 <frame>
  <hbox>
   <text><label>$(gettext 'If you would like more information about') '${TREE1}', $(gettext 'such as what it is for and the dependencies, this button will download and display detailed information:')</label></text>
   <button><label>More info</label><action>/usr/local/petget/fetchinfo.sh ${TREE1} & </action></button>
  </hbox>
 </frame>
 
 <hbox>
  ${DEPBUTTON}
  <button>
   <label>Install ${TREE1}${ONLYMSG}</label>
   <action>echo \"${TREE1}\" > /tmp/petget_installpreview_pkgname</action>
   <action type=\"exit\">BUTTON_INSTALL</action>
  </button>
  <button cancel></button>
 </hbox>
</vbox>
</window>
"

RETPARAMS="`gtkdialog3 --center --program=PREVIEW_DIALOG`"

eval "$RETPARAMS"
[ "$EXIT" != "BUTTON_INSTALL" -a "$EXIT" != "BUTTON_EXAMINE_DEPS" ] && exit

#DB_ENTRY has the database entry of the main package that we want to install.
#DB_FILE has the name of the database file that has the main entry, ex: Packages-slackware-12.2-slacky

if [ "$EXIT" = "BUTTON_EXAMINE_DEPS" ];then
 /usr/local/petget/dependencies.sh
 [ $? -ne 0 ] && exec /usr/local/petget/installpreview.sh #reenter.
 #returns with /tmp/petget_missing_dbentries-* has the database entries of missing deps.
 #the '*' on the end is the repo-file name, ex: Packages-slackware-12.2-slacky
 
 #compose pkgs into checkboxes...
 MAIN_REPO="`echo "$DB_FILE" | cut -f 2-9 -d '-'`"
 MAINPKG_NAME="`echo "$DB_ENTRY" | cut -f 1 -d '|'`"
 MAINPKG_SIZE="`echo "$DB_ENTRY" | cut -f 6 -d '|'`"
 MAINPKG_DESCR="`echo "$DB_ENTRY" | cut -f 10 -d '|'`"
 MAIN_CHK="<checkbox><default>true</default><label>${MAINPKG_NAME} SIZE: ${MAINPKG_SIZE}B DESCRIPTION: ${MAINPKG_DESCR}</label><variable>CHECK_PKG_${MAIN_REPO}_${MAINPKG_NAME}</variable></checkbox>"
 INSTALLEDSIZEK=0
 [ "$MAINPKG_SIZE" != "" ] && INSTALLEDSIZEK=`echo "$MAINPKG_SIZE" | rev | cut -c 2-10 | rev`
 
 #making up the dependencies into tabs, need limit of 8 per tab...
 #also limit to 6 tabs (gedit is way beyond this!)...
 echo -n "" > /tmp/petget_moreframes
 echo -n "" > /tmp/petget_tabs
 echo "0" > /tmp/petget_frame_cnt
 DEP_CNT=0
 ONEREPO=""
 for ONEDEPSLIST in `ls -1 /tmp/petget_missing_dbentries-*`
 do
  ONEREPO_PREV="$ONEREPO"
  ONEREPO="`echo "$ONEDEPSLIST" | grep -o 'Packages.*' | sed -e 's%Packages\\-%%'`"
  FRAME_CNT=`cat /tmp/petget_frame_cnt`
  if [ "$ONEREPO_PREV" != "" ];then #next repo, so start a new tab.
   DEP_CNT=0
   FRAME_CNT=`expr $FRAME_CNT + 1`
   echo "$FRAME_CNT" > /tmp/petget_frame_cnt
   #w017 bugfix, prevent double frame closure...
   [ "`cat /tmp/petget_moreframes | tail -n 1 | grep '</frame>$'`" = "" ] && echo "</frame>" >> /tmp/petget_moreframes
  fi
  cat $ONEDEPSLIST |
  while read ONELIST
  do
   DEP_NAME="`echo "$ONELIST" | cut -f 1 -d '|'`"
   DEP_SIZE="`echo "$ONELIST" | cut -f 6 -d '|'`"
   DEP_DESCR="`echo "$ONELIST" | cut -f 10 -d '|'`"
   DEP_CNT=`expr $DEP_CNT + 1`
   case $DEP_CNT in
    1)
     echo -n "<frame REPOSITORY: ${ONEREPO}>" >> /tmp/petget_moreframes
     echo -n "Dependencies|" >> /tmp/petget_tabs
     echo -n "<checkbox><default>true</default><label>${DEP_NAME} SIZE: ${DEP_SIZE}B DESCRIPTION: ${DEP_DESCR}</label><variable>CHECK_PKG_${ONEREPO}_${DEP_NAME}</variable></checkbox>" >> /tmp/petget_moreframes
    ;;
    8)
     FRAME_CNT=`cat /tmp/petget_frame_cnt`
     FRAME_CNT=`expr $FRAME_CNT + 1`
     if [ $FRAME_CNT -gt 5 ];then
      echo -n "<text use-markup=\"true\"><label>\"<b>$(gettext 'SORRY! Too many dependencies, list truncated. Suggest install some deps first.')</b>\"</label></text>" >> /tmp/petget_moreframes
     else
      echo -n "<checkbox><default>true</default><label>${DEP_NAME} SIZE: ${DEP_SIZE}B DESCRIPTION: ${DEP_DESCR}</label><variable>CHECK_PKG_${ONEREPO}_${DEP_NAME}</variable></checkbox>" >> /tmp/petget_moreframes
     fi
     echo "</frame>" >> /tmp/petget_moreframes
     DEP_CNT=0
     echo "$FRAME_CNT" > /tmp/petget_frame_cnt
    ;;
    *)
     echo -n "<checkbox><default>true</default><label>${DEP_NAME} SIZE: ${DEP_SIZE}B DESCRIPTION: ${DEP_DESCR}</label><variable>CHECK_PKG_${ONEREPO}_${DEP_NAME}</variable></checkbox>" >> /tmp/petget_moreframes
    ;;
   esac
   [ $FRAME_CNT -gt 5 ] && break #too wide!
   ADDSIZEK=0
   [ "$DEP_SIZE" != "" ] && ADDSIZEK=`echo "$DEP_SIZE" | rev | cut -c 2-10 | rev`
   INSTALLEDSIZEK=`expr $INSTALLEDSIZEK + $ADDSIZEK`
   echo "$INSTALLEDSIZEK" > /tmp/petget_installedsizek
  done
  INSTALLEDSIZEK=`cat /tmp/petget_installedsizek`
  FRAME_CNT=`cat /tmp/petget_frame_cnt`
  [ $FRAME_CNT -gt 5 ] && break #too wide!
 done
 TABS="`cat /tmp/petget_tabs`"
 MOREFRAMES="`cat /tmp/petget_moreframes`"
 #make sure last frame has closed...
 [ "`echo "$MOREFRAMES" | tail -n 1 | grep '</frame>$'`" = "" ] && MOREFRAMES="${MOREFRAMES}</frame>"
 
 INSTALLEDSIZEM=`expr $INSTALLEDSIZEK \/ 1024`
 MSGWARN2="$(gettext "If that looks like enough free space, go ahead and click the 'Install' button...")"
 testSIZEK=`expr $INSTALLEDSIZEK \/ 3`
 testSIZEK=`expr $INSTALLEDSIZEK + $testSIZEK`
 testSIZEK=`expr $testSIZEK + 8000`
 [ $testSIZEK -gt $SIZEFREEK ] && MSGWARN2="$(gettext "Not too good! recommend that you make more space before installing -- see 'Resize personal storage file' in the 'Utility' menu.")"
 
 export DEPS_DIALOG="<window title=\"$(gettext 'Puppy Package Manager: dependencies')\" icon-name=\"gtk-about\">
<vbox>
 
 <frame REPOSITORY: ${MAIN_REPO}>
  ${MAIN_CHK}
 </frame>

 <notebook labels=\"${TABS}\">
 ${MOREFRAMES}
 </notebook>
 
 <hbox>
 <text><label>$(gettext "Sometimes Puppy's automatic dependency checking comes up with a list that may include packages that don't really need to be installed, or are already installed under a different name. If uncertain, just accept them all, but if you spot one that does not need to be installed, then un-tick it.")</label></text>
 
 <text><label>$(gettext 'Puppy usually avoids listing the same package more than once if it exists in two or more repositories. However, if the same package is listed twice, choose the one that seems to be most appropriate.')</label></text>
 </hbox>
 
 <hbox>
  <vbox>
   <text><label>$(gettext 'Click to see the hierarchy of the dependencies:')</label></text>
   <hbox>
    <button>
     <label>$(gettext 'View hierarchy')</label>
     <action>/usr/local/bin/defaulttextviewer /tmp/petget_deps_visualtreelog & </action>
    </button>
   </hbox>
  </vbox>
  <text><label>\"   \"</label></text>
  <text use-markup=\"true\"><label>\"<b>$(gettext 'If all of the above packages are selected, the total installed size will be') ${INSTALLEDSIZEK}KB (${INSTALLEDSIZEM}MB). $(gettext 'The free space available for installation is') ${SIZEFREEK}KB (${SIZEFREEM}MB). ${MSGWARN2}</b>\"</label></text>
 </hbox>
 
 <hbox>
  <button>
   <label>$(gettext 'Download-only selected packages')</label>
   <action type=\"exit\">BUTTON_PKGS_DOWNLOADONLY</action>
  </button>
  <button>
   <label>$(gettext 'Download-and-install selected packages')</label>
   <action type=\"exit\">BUTTON_PKGS_INSTALL</action>
  </button>
  <button cancel></button>
 </hbox>
</vbox>
</window>
"

 RETPARAMS="`gtkdialog3 --center --program=DEPS_DIALOG`"

 #example if 'Install' button clicked:
 #CHECK_PKG_slackware-12.2-official_libtermcap-1.2.3="true"
 #CHECK_PKG_slackware-12.2-official_pygtk-2.12.1="true"
 #CHECK_PKG_slackware-12.2-slacky_beagle-0.3.9="true"
 #CHECK_PKG_slackware-12.2-slacky_libgdiplus-2.0="true"
 #CHECK_PKG_slackware-12.2-slacky_libgdiplus-2.2="true"
 #CHECK_PKG_slackware-12.2-slacky_mono-2.2="true"
 #CHECK_PKG_slackware-12.2-slacky_monodoc-2.0="true"
 #EXIT="BUTTON_PKGS_INSTALL"

 if [ "`echo "$RETPARAMS" | grep '^EXIT' | grep -E 'BUTTON_PKGS_INSTALL|BUTTON_PKGS_DOWNLOADONLY'`" != "" ];then
  #remove any unticked pkgs from the list...
  for ONECHK in `echo "$RETPARAMS" | grep '^CHECK_PKG_' | grep '"false"' | tr '\n' ' '`
  do
   ONEREPO="`echo -n "$ONECHK" | cut -f 1 -d '=' | cut -f 3 -d '_'`" #ex: slackware-12.2-slacky
   ONEPKG="`echo -n "$ONECHK" | cut -f 1 -d '=' | cut -f 4-9 -d '_'`"  #ex: libtermcap-1.2.3
   opPATTERN='^'"$ONEPKG"'|'
   grep -v "$opPATTERN" /tmp/petget_missing_dbentries-Packages-${ONEREPO} > /tmp/petget_tmp
   mv -f /tmp/petget_tmp /tmp/petget_missing_dbentries-Packages-${ONEREPO}
  done
 else
  exit
 fi
fi

#come here, want to install pkg(s)...

#DB_ENTRY has the database entry of the main package that we want to install.
#DB_FILE has the name of the database file that has the main entry, ex: Packages-slackware-12.2-slacky
#TREE1 is name of main pkg, ex: abiword-1.2.3

#check to see if main pkg entry already in install-lists...
touch /tmp/petget_missing_dbentries-${DB_FILE} #create if doesn't exist.
mPATTERN='^'"$TREE1"'|'
if [ "`grep "$mPATTERN" /tmp/petget_missing_dbentries-${DB_FILE}`" = "" ];then
 echo "$DB_ENTRY" >> /tmp/petget_missing_dbentries-${DB_FILE}
fi

#now do the actual install...
PASSEDPRM=""
[ "`echo "$RETPARAMS" | grep '^EXIT' | grep 'BUTTON_PKGS_DOWNLOADONLY'`" != "" ] && PASSEDPRM="DOWNLOADONLY"
/usr/local/petget/downloadpkgs.sh $PASSEDPRM
[ $? -ne 0 ] && exit 1
[ "$PASSEDPRM" = "DOWNLOADONLY" ] && exit

#w482 adjust msg as appropriate, restart jwm and update menu if required...
INSTALLEDCAT="menu" #any string.
[ "`cat /tmp/petget-installed-pkgs-log | grep -o 'CATEGORY' | grep -v 'none'`" = "" ] && INSTALLEDCAT="none"
RESTARTMSG="$(gettext 'Please wait, updating help page and menu...')"
if [ "`pidof jwm`" != "" ];then #120101
 JWMVER=`jwm -v|head -n1|cut -d ' ' -f2|cut -d - -f2`
 if vercmp $JWMVER lt 574;then #120116 introduced rev 547, but 574 fixes -reload.
  RESTARTMSG="$(gettext 'Please wait, updating help page and menu (the screen will flicker!)...')"
 fi
fi
[ "$INSTALLEDCAT" = "none" ] && RESTARTMSG="$(gettext 'Please wait, updating help page...')"
#/usr/X11R7/bin/yaf-splash -font "8x16" -outline 0 -margin 4 -bg orange -text "${RESTARTMSG}" &
yaf-splash -bg orange -text "${RESTARTMSG}" &
X3PID=$!

#w091019 update image cache...
iUPDATE='no'
for iONE in `cat /tmp/petget_missing_dbentries-* | cut -f 1 -d '|' | tr '\n' ' '`
do
 if [ -f /root/.packages/${iONE}.files ];then
  [ "`grep 'usr/share/icons/hicolor' /root/.packages/${iONE}.files`" != "" ] && iUPDATE='yes'
 fi
done
[ "$iUPDATE" = "yes" ] && gtk-update-icon-cache -f /usr/share/icons/hicolor/

#master help index has to be updated...
##to speed things up, find the help files in the new pkg only...
/usr/sbin/indexgen.sh #${WKGDIR}/${APKGNAME}
#Reconstruct configuration files for JWM, Fvwm95, IceWM...
if [ "$INSTALLEDCAT" != "none" ];then
 /usr/sbin/fixmenus
 if [ "`pidof jwm`" != "" ];then #120101
  if vercmp $JWMVER lt 574;then #120116 547 to 574.
   jwm -restart #w482
  else
   jwm -reload
  fi
 fi
fi
kill $X3PID

#check any missing shared libraries...
PKGS="`cat /tmp/petget_missing_dbentries-* | cut -f 1 -d '|' | tr '\n' '|'`"
/usr/local/petget/check_deps.sh $PKGS

###END###
