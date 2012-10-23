#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (see /usr/share/doc/legal).
#called from /usr/local/petget/installpreview.sh
#The database entries for the packages to be installed are in /tmp/petget_missing_dbentries-*
#ex: /tmp/petget_missing_dbentries-Packages-slackware-12.2-official
#v424 fix msg, x does not need restart to update menu.
#100117 fix for downloading pets from quirky repo.
#100903 fix if subdirectory field 7 in pkg db entry is empty.
#100921 bypass if file list empty.
#100926 fix hack, one puppy repo does not have "puppylinux" in url.
#101013 improvement suggested by L18L, list current locales in 'trim the fat'.
#101014 another hack, wary5 pets are now in the ibiblio quirky site.
#101016 do not offer to trim-the-fat if install pet pkg(s).
#101116 call download_file to download pkg, instead of direct run of wget.
#101118 improve test fail and exit number.
#110812 hack for pets that are in quirky site at ibiblio.
#120203 BK: internationalized.
#120313 'noarch' repo is on quirky ibiblio site.

export TEXTDOMAIN=petget___downloadpkgs.sh
export OUTPUT_CHARSET=UTF-8

#export LANG=C
PASSEDPARAM=""
[ $1 ] && PASSEDPARAM="$1" #DOWNLOADONLY
FLAGPET="" #101016

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS #
. /root/.packages/DISTRO_PET_REPOS #has PET_REPOS, PACKAGELISTS_PET_ORDER
. /root/.packages/DISTRO_COMPAT_REPOS #v431 has REPOS_DISTRO_COMPAT

echo -n "" > /tmp/petget-installed-pkgs-log

PKGCNT=0 ; FAILCNT=0 ; EXITVAL=0 #101118
for ONELIST in `ls -1 /tmp/petget_missing_dbentries-Packages-*` #ex: petget_missing_dbentries-Packages-puppy-quirky-official
do
 #ex of entry in file $ONELIST: rox-menu-0.5.0|rox-menu|0.5.0||Desktop|128K|pet_packages-quirky|rox-menu-0.5.0.pet|+rox-clib,+rox_filer|menu for a rox panel|t2|8.0rc|official|
 echo -n "" > /tmp/petget_repos
 LISTNAME="`echo -n "$ONELIST" | grep -o 'Packages.*'`" #ex: Packages-puppy-quirky-official
 #note: puppy4, had 4xx, which should resolve to 4 i think...
 REPO_DEFAULT_SUBSUBDIR="`echo -n "$LISTNAME" | cut -f 3 -d '-' | sed -e 's%xx$%%'`" #100903 ex: quirky
 
 #have the compat-distro repo urls in /root/.packages/DISTRO_PKGS_SPECS,
 #variable REPOS_DISTRO_COMPAT ...
 #REPOS_DISTRO_COMPAT has the associated Packages-* local database file...
 for ONEURLENTRY in $REPOS_DISTRO_COMPAT
 do
  PARTPKGDB="`echo -n "$ONEURLENTRY" | cut -f 3 -d '|'`"
  #PARTPKGDB may have a glob * wildcard, convert to reg.expr., also backslash '-'...
  PARTPKGDB="`echo -n "$PARTPKGDB" | sed -e 's%\\-%\\\\-%g' -e 's%\\*%.*%g'`"
  ONEURLENTRY_1_2="`echo -n "$ONEURLENTRY" | cut -f 1,2 -d '|'`"
  [ "`echo "$LISTNAME" | grep "$PARTPKGDB"`" != "" ] && echo "${ONEURLENTRY_1_2}|${LISTNAME}" >> /tmp/petget_repos
 done
 
 #or it may be one of the official puppy repos...
 if [ "`echo "$ONELIST" | grep 'Packages\\-puppy' | grep '\\-official'`" != "" ];then
  for ONEPETREPO in $PET_REPOS #ex: ibiblio.org|http://distro.ibiblio.org/pub/linux/distributions/quirky|Packages-puppy-quirky-official
  do
   ONEPETREPO_3_PATTERN="`echo -n "$ONEPETREPO" | cut -f 3 -d '|' | sed -e 's%\\-%\\\\-%g' -e 's%\\*%.*%g'`"
   ONEPETREPO_1_2="`echo -n "$ONEPETREPO" | cut -f 1,2 -d '|'`"
   [ "`echo -n "$LISTNAME" | grep "$ONEPETREPO_3_PATTERN"`" != "" ] && echo "${ONEPETREPO_1_2}|${LISTNAME}" >> /tmp/petget_repos
   #...ex: ibiblio.org|http://distro.ibiblio.org/pub/linux/distributions/puppylinux|Packages-puppy-4-official
  done
 fi
 
 sort --key=1 --field-separator="|" --unique /tmp/petget_repos > /tmp/petget_repos-tmp
 mv -f /tmp/petget_repos-tmp /tmp/petget_repos
 
 #100117 need a little hack for quirky... not the best, really should be a generic fix...
 #if [ "`echo -n "$ONELIST" | grep 'quirky'`" != "" ];then
 #if [ "$REPO_DEFAULT_SUBSUBDIR" == "quirky" ];then #100903
 
 #110812 hack for pets that are in quirky site at ibiblio...
 OFFICIAL_REPO='puppylinux'
 [ "$REPO_DEFAULT_SUBSUBDIR" == "quirky" ] && OFFICIAL_REPO='quirky' #100903
 [ "$REPO_DEFAULT_SUBSUBDIR" == "wary5" ] && OFFICIAL_REPO='quirky' #101014 wary5 pets also in quirky repo.
 [ "$REPO_DEFAULT_SUBSUBDIR" == "common" ] && OFFICIAL_REPO='quirky' #110812
 [ "$REPO_DEFAULT_SUBSUBDIR" == "drake" ] && OFFICIAL_REPO='quirky' #110812
 [ "$REPO_DEFAULT_SUBSUBDIR" == "noarch" ] && OFFICIAL_REPO='quirky' #120313
 
 #if [ "$REPO_DEFAULT_SUBSUBDIR" == "quirky" -o "$REPO_DEFAULT_SUBSUBDIR" == "wary5" ];then #100903 101014 wary5 pets also in quirky repo.
 if [ "$OFFICIAL_REPO" = "quirky" ];then #110812
  #TMPPETGETREPOS="`grep -v '/puppylinux' /tmp/petget_repos`"
  TMPPETGETREPOS="`grep '/quirky' /tmp/petget_repos`" #100926 fix hack, one puppy repo does not have "puppylinux" in url.
  echo "$TMPPETGETREPOS" > /tmp/petget_repos
 else #100903
  TMPPETGETREPOS="`grep -v '/quirky' /tmp/petget_repos`"
  echo "$TMPPETGETREPOS" > /tmp/petget_repos
 fi
 
 #/tmp/petget_repos has a list of repos for downloading these packages.
 #now put up a window, request which url to use...
 
 LISTNAMECUT="`echo -n "$LISTNAME" | cut -f 2-9 -d '-'`" #take Packages- off.
 
 REPOBUTTONS=""
 for ONEREPOSPEC in `cat /tmp/petget_repos`
 do
  URL_TEST="`echo -n "$ONEREPOSPEC" | cut -f 1 -d '|'`"
  URL_FULL="`echo -n "$ONEREPOSPEC" | cut -f 2 -d '|'`"
  REPOBUTTONS="${REPOBUTTONS}<radiobutton><label>${URL_TEST}</label><variable>RADIO_URL_${URL_TEST}</variable></radiobutton>"
 done
 
 PKGNAMES="`cat $ONELIST | cut -f 1 -d '|' | tr '\n' ' '`"

 [ "$PKGNAMES" = "" -o "$PKGNAMES" = " " ] && continue #100921
  
 export DEPS_DIALOG="<window title=\"$(gettext 'Puppy Package Manager: download')\" icon-name=\"gtk-about\">
<vbox>
 <text><label>$(gettext 'You have chosen to download these packages:')</label></text>
 <text use-markup=\"true\"><label>\"<b>${PKGNAMES}</b>\"</label></text>
 <text><label>$(gettext "Please choose which URL you would like to download them from. Choose 'LOCAL FOLDER' if you have already have them on this computer (on hard drive, USB drive or CD):")</label></text>

 <frame ${LISTNAMECUT}>
  ${REPOBUTTONS}
  <radiobutton><label>$(gettext 'LOCAL FOLDER')</label><variable>RADIO_URL_LOCAL</variable></radiobutton>
 </frame>
 
 <hbox>
  <button>
   <label>$(gettext 'Test URLs')</label>
   <action>/usr/local/petget/testurls.sh</action>
  </button>
  <button>
   <label>$(gettext 'Download packages')</label>
   <action type=\"exit\">BUTTON_PKGS_DOWNLOAD</action>
  </button>
  <button cancel></button>
 </hbox>
</vbox>
</window>
" 

 RETPARAMS="`gtkdialog3 --program=DEPS_DIALOG`"
 #RETPARAMS ex:
 #RADIO_URL_LOCAL="false"
 #RADIO_URL_repository.slacky.eu="true"
 #EXIT="BUTTON_PKGS_DOWNLOAD"
 
 #eval "$RETPARAMS"

 #[ "$EXIT" != "BUTTON_PKGS_DOWNLOAD" ] && exit 1
 [ "`echo "$RETPARAMS" | grep 'BUTTON_PKGS_DOWNLOAD'`" = "" ] && exit 1

 #determine the url to download from....
 #if [ "$RADIO_URL_LOCAL" = "true" ];then
 if [ "`echo "$RETPARAMS" | grep 'RADIO_URL_LOCAL' | grep 'true'`" != "" ];then
  #put up a dlg box asking for folder with pkgs...
  LOCALDIR="/root"
  if [ -s /var/log/petlocaldir ];then
   OLDLOCALDIR="`cat /var/log/petlocaldir`"
   [ -d $OLDLOCALDIR ] && LOCALDIR="$OLDLOCALDIR"
  fi
  LOCALDIR="`Xdialog --backtitle "Note: Files not displayed, only directories" --title "Choose local directory" --stdout --no-buttons --dselect "$LOCALDIR" 0 0`"
  [ $? -ne 0 ] && exit 1
  [ "$LOCALDIR" != "" ] && echo "$LOCALDIR" > /var/log/petlocaldir
  DOWNLOADFROM="file://${LOCALDIR}"
 else
  URL_BASIC="`echo "$RETPARAMS" | grep 'RADIO_URL_' | grep '"true"' | cut -f 1 -d '=' | cut -f 3 -d '_'`"
  DOWNLOADFROM="`cat /tmp/petget_repos | grep "$URL_BASIC" | head -n 1 | cut -f 2 -d '|'`"
 fi
 
 #now download and install them...
 cd /root
 for ONEFILE in `cat $ONELIST | cut -f 7,8,13 -d '|'` #100527 path|fullfilename|repo-id
 do
  PKGCNT=`expr $PKGCNT + 1` #101118
  #100903 reorder...
  ONEREPOID="`echo -n "$ONEFILE" | cut -f 3 -d '|'`" #100527 ex: official (...|puppy|wary5|official|)
  ONEPATH="`echo -n "$ONEFILE" | cut -f 1 -d '|'`" #100527
  ONEFILE="`echo -n "$ONEFILE" | cut -f 1,2 -d '|' | tr '|' '/'`" #100527 path/fullfilename
  [ "`echo -n "$ONEFILE" | rev | cut -c 1-3 | rev`" = "pet" ] && FLAGPET='yes' #101016
  #if [ "$RADIO_URL_LOCAL" = "true" ];then
  if [ "`echo "$RETPARAMS" | grep 'RADIO_URL_LOCAL' | grep 'true'`" != "" ];then
   [ ! -f ${LOCALDIR}/${ONEFILE} ] && ONEFILE="`basename $ONEFILE`"
   cp -f ${LOCALDIR}/${ONEFILE} ./
  else
   #100527 need fix if |path| field of pkg database was empty... 100903 improve...
   #[ "$ONEPATH" == "" ] && ONEFILE="pet_packages-${ONEREPOID}${ONEFILE}"
   [ "$ONEPATH" == "" ] && ONEFILE="pet_packages-${REPO_DEFAULT_SUBSUBDIR}${ONEFILE}"
   #101116 now have a download utility...
   #rxvt -title "Puppy Package Manager: download" -bg orange -fg black -geometry 80x10 -e wget ${DOWNLOADFROM}/${ONEFILE}
   download_file ${DOWNLOADFROM}/${ONEFILE}
   if [ $? -ne 0 ];then #101116
    DLPKG="`basename $ONEFILE`"
    [ -f $DLPKG ] && rm -f $DLPKG
   fi
  fi
  sync
  DLPKG="`basename $ONEFILE`"
  if [ -f $DLPKG -a "$DLPKG" != "" ];then
   if [ "$PASSEDPARAM" = "DOWNLOADONLY" ];then
    /usr/local/petget/verifypkg.sh /root/$DLPKG
   else
    /usr/local/petget/installpkg.sh /root/$DLPKG
    #...appends pkgname and category to /tmp/petget-installed-pkgs-log if successful.
   fi
   if [ $? -ne 0 ];then
    #xmessage -bg red -title "Puppy Package Manager" "ERROR: faulty download of $DLPKG"
    export FAIL_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
  <pixmap><input file>/usr/local/lib/X11/pixmaps/error.xpm</input></pixmap>
   <text use-markup=\"true\"><label>\"<b>$(gettext 'Error, faulty download of') ${DLPKG}</b>\"</label></text>
   <hbox>
    <button ok></button>
   </hbox>
  </vbox>
 </window>" 
    gtkdialog3 --program=FAIL_DIALOG
    FAILCNT=`expr $FAILCNT + 1` #101118
   fi
   #already removed, but take precautions...
   [ "$PASSEDPARAM" != "DOWNLOADONLY" ] && rm -f /root/$DLPKG 2>/dev/null
   #DLPKG_NAME="`basename $DLPKG .pet`" 2>/dev/null
   #DLPKG_NAME="`basename $DLPKG .deb`" 2>/dev/null
   #DLPKG_NAME="`basename $DLPKG .tgz`" 2>/dev/null
   #DLPKG_NAME="`basename $DLPKG .tar.gz`" 2>/dev/null
   #rm -rf /root/$DLPKG_NAME
  else
   #xmessage -bg red -title "Puppy Package Manager" "ERROR: Failed to download ${DLPKG}"
   export FAIL_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
  <pixmap><input file>/usr/local/lib/X11/pixmaps/error.xpm</input></pixmap>
   <text use-markup=\"true\"><label>\"<b>$(gettext 'Error, failed to download') ${DLPKG}</b>\"</label></text>
   <hbox>
    <button ok></button>
   </hbox>
  </vbox>
 </window>
" 
   gtkdialog3 --program=FAIL_DIALOG
   FAILCNT=`expr $FAILCNT + 1` #101118
  fi
 done

done

#101118 exit 1 if all pkgs failed to download...
[ $FAILCNT -ne 0 ] && [ $FAILCNT -eq $PKGCNT ] && EXITVAL=1

if [ "$PASSEDPARAM" = "DOWNLOADONLY" ];then
 export DL_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
  <pixmap><input file>/usr/local/lib/X11/pixmaps/ok.xpm</input></pixmap>
   <text><label>$(gettext 'Finished. The packages have been downloaded to') /root $(gettext 'directory.')</label></text>
   <hbox>
    <button ok></button>
   </hbox>
  </vbox>
 </window>
" 
 gtkdialog3 --program=DL_DIALOG
 exit $EXITVAL
fi

#announce summary of successfully installed pkgs...
#installpkg.sh will have logged to /tmp/petget-installed-pkgs-log
if [ -s /tmp/petget-installed-pkgs-log ];then
 if [ "$FLAGPET" != "yes" ];then #101016 do not offer to trim-the-fat if pet pkg(s)
  BUTTONS9="<text><label>$(gettext "NOTE: If you are concerned about the large size of the installed packages, Puppy has some clever code to delete files that are not likely to be needed for the application to actually run. If you would like to try this, click 'Trim the fat' button (otherwise just click 'OK'):")</label></text>
   <hbox>
    <button><label>$(gettext 'Trim the fat')</label><action type=\"exit\">BUTTON_TRIM_FAT</action></button>
    <button ok></button>
   </hbox>"
 else
  BUTTONS9="<hbox>
    <button ok></button>
   </hbox>"
 fi
 INSTALLEDMSG="`cat /tmp/petget-installed-pkgs-log`"
 CAT_MSG="$(gettext 'Note: the package(s) do not have a menu entry.')"
 [ "`echo "$INSTALLEDMSG" | grep -o 'CATEGORY.*' | grep -v 'none'`" != "" ] && CAT_MSG="$(gettext '...look in the appropriate category in the menu (bottom-left of screen) to run the application. Note, some packages do not have a menu entry.')" #424 fix. 101016 fix.
 export INSTALL_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
   <pixmap><input file>/usr/local/lib/X11/pixmaps/ok.xpm</input></pixmap>
   <text><label>$(gettext 'The following packages have been successfully installed:')</label></text>
   <text wrap=\"false\" use-markup=\"true\"><label>\"<b>${INSTALLEDMSG}</b>\"</label></text>
   <text><label>${CAT_MSG}</label></text>
   ${BUTTONS9}
  </vbox>
 </window>
" 
 RETPARAMS="`gtkdialog3 --program=INSTALL_DIALOG`"
 eval "$RETPARAMS"
 
 #trim the fat...
 if [ "$EXIT" = "BUTTON_TRIM_FAT" ];then
  INSTALLEDPKGNAMES="`echo "$INSTALLEDMSG" | cut -f 2 -d ' ' | tr '\n' ' '`"
  #101013 improvement suggested by L18L...
  CURRLOCALES="`locale -a | grep _ | cut -d '_' -f 1`"
  LISTLOCALES="`echo -e -n "en\n${CURRLOCALES}" | sort -u | tr -s '\n' | tr '\n' ',' | sed -e 's%,$%%'`"
  export TRIM_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
   <pixmap><input file>/usr/local/lib/X11/pixmaps/question.xpm</input></pixmap>
   <text><label>$(gettext "You have chosen to 'trim the fat' of these installed packages:")</label></text>
   <text use-markup=\"true\"><label>\"<b>${INSTALLEDPKGNAMES}</b>\"</label></text>
   <frame Locale>
   <text><label>$(gettext 'Type the 2-letter country designations for the locales that you want to retain, separated by commas. Leave blank to retain all locale files (see /usr/share/locale for examples):')</label></text>
   <entry><default>${LISTLOCALES}</default><variable>ENTRY_LOCALE</variable></entry>
   </frame>
   <frame $(gettext 'Documentation')>
   <checkbox><default>true</default><label>$(gettext 'Tick this to delete documentation files')</label><variable>CHECK_DOCDEL</variable></checkbox>
   </frame>
   <frame $(gettext 'Development')>
   <checkbox><default>true</default><label>$(gettext 'Tick this to delete development files')</label><variable>CHECK_DEVDEL</variable></checkbox>
   <text><label>$(gettext '(only needed if these packages are required as dependencies when compiling another package from source code)')</label></text>
   </frame>
   <text><label>$(gettext "Click 'OK', or if you decide to chicken-out click 'Cancel':")</label></text>
   <hbox>
    <button ok></button>
    <button cancel></button>
   </hbox>
  </vbox>
  </window>"
  RETPARAMS="`gtkdialog3 --program=TRIM_DIALOG`"
  eval "$RETPARAMS"
  [ "$EXIT" != "OK" ] && exit $EXITVAL
#  /usr/X11R7/bin/yaf-splash -font "8x16" -outline 0 -margin 4 -bg orange -text "Please wait, trimming fat from packages..." &
  yaf-splash -bg orange -text "$(gettext 'Please wait, trimming fat from packages...')" &
  X4PID=$!
  elPATTERN="`echo -n "$ENTRY_LOCALE" | tr ',' '\n' | sed -e 's%^%/%' -e 's%$%/%' | tr '\n' '|'`"
  for PKGNAME in $INSTALLEDPKGNAMES
  do
   cat /root/.packages/${PKGNAME}.files |
   while read ONEFILE
   do
    [ ! -f "$ONEFILE" ] && continue
    [ -h "$ONEFILE" ] && continue
    #find out if this is an international language file...
    if [ "$ENTRY_LOCALE" != "" ];then
     if [ "`echo -n "$ONEFILE" | grep --extended-regexp '/locale/|/nls/|/i18n/' | grep -v -E "$elPATTERN"`" != "" ];then
      rm -f "$ONEFILE"
      grep -v "$ONEFILE" /root/.packages/${PKGNAME}.files > /tmp/petget_pkgfiles_temp
      mv -f /tmp/petget_pkgfiles_temp /root/.packages/${PKGNAME}.files
      continue
     fi
    fi
    #find out if this is a documentation file...
    if [ "$CHECK_DOCDEL" = "true" ];then
     if [ "`echo -n "$ONEFILE" | grep --extended-regexp '/man/|/doc/|/doc-base/|/docs/|/info/|/gtk-doc/|/faq/|/manual/|/examples/|/help/|/htdocs/'`" != "" ];then
      rm -f "$ONEFILE" 2>/dev/null
      grep -v "$ONEFILE" /root/.packages/${PKGNAME}.files > /tmp/petget_pkgfiles_temp
      mv -f /tmp/petget_pkgfiles_temp /root/.packages/${PKGNAME}.files
      continue
     fi
    fi
    #find out if this is development file...
    if [ "$CHECK_DEVDEL" = "true" ];then
     if [ "`echo -n "$ONEFILE" | grep --extended-regexp '/include/|/pkgconfig/|/aclocal|/cvs/|/svn/'`" != "" ];then
      rm -f "$ONEFILE" 2>/dev/null
      grep -v "$ONEFILE" /root/.packages/${PKGNAME}.files > /tmp/petget_pkgfiles_temp
      mv -f /tmp/petget_pkgfiles_temp /root/.packages/${PKGNAME}.files
      continue
     fi
     #all .a and .la files... and any stray .m4 files...
     if [ "`echo -n "$ONEBASE" | grep --extended-regexp '\.a$|\.la$|\.m4$'`" != "" ];then
      rm -f "$ONEFILE"
      grep -v "$ONEFILE" /root/.packages/${PKGNAME}.files > /tmp/petget_pkgfiles_temp
      mv -f /tmp/petget_pkgfiles_temp /root/.packages/${PKGNAME}.files
     fi
    fi
   done
  done
  kill $X4PID
 fi

fi

exit $EXITVAL #101118
###END###
