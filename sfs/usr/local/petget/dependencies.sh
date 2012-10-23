#!/bin/sh
#called from /usr/local/petget/installpreview.sh
#/tmp/petget_installpreview_pkgname (writen in installpreview.sh) has name of package being
#  previewed prior to installation. ex: abiword-1.2.3
#/tmp/petget_filterversion has the repository that installing from (written in pkgchooser.sh).
#  ex: slackware-12.2-slacky
#  ...full package database file is /root/.packages/Packages-slackware-12.2-slacky
#/tmp/petget_missingpkgs_patterns (written in findmissingpkgs.sh) has a list of missing dependencies, format ex:
#  |kdebase|
#  |kdelibs|
#  |mesa-lib|
#  |qt|
#  ...that is, pkg name-only with vertical-bars on both ends, one name per line.
#/tmp/petget_installed_patterns_all (writen in findmissingpkgs.sh) has a list of already installed
#  packages, both builtin and user-installed. One on each line, exs:
#  |915resolution|
#  |a52dec|
#  |absvolume_puppy|
#  |alsa\-lib|
#  |cyrus\-sasl|
#  ...notice the '-' are backslashed.
#110722 versioning info added to dependencies.
#110723 remove hardcoded path /root/.packages, so can run script in Woof.
#110822 versioning operators can be chained, ex: +linux_kernel&ge2.6.32&lt2.6.33
#111107 01micko: fix for '||' messing things up.
#120203 BK: internationalized.
#120221 jemimah: grep '[a-zA-Z]' so as to find deps with all capitals (ex: SDL).

export TEXTDOMAIN=petget___dependencies.sh
export OUTPUT_CHARSET=UTF-8

if [ -f ./PKGS_MANAGEMENT ];then #110723
. ./PKGS_MANAGEMENT
. ./DISTRO_PET_REPOS
. ./DISTRO_SPECS
 RUNNINGWOOF='yes'
 PREPATH='./'
else
. /root/.packages/PKGS_MANAGEMENT #has DISTRO_PPM_DEVX_EXCEPTIONS, PKG_ALIASES_INSTALLED
. /root/.packages/DISTRO_PET_REPOS
. /etc/DISTRO_SPECS
 RUNNINGWOOF='no'
 PREPATH='/root/.packages/'
fi

#a problem is that the dependencies may have their own dependencies. Some pkg
#databases have all dependencies up-front, whereas some only list the higher-level
#dependencies and the dependencies of those have to be looked for.

#/usr/X11R7/bin/yaf-splash -font "8x16" -outline 0 -margin 4 -bg orange -text "Please wait, processing package database files..." &
yaf-splash -bg orange -text "$(gettext 'Please wait, processing package database files...')" &
X1PID=$!

ALLINSTALLEDPKGS="`cat /tmp/petget_installed_patterns_all`"
TREE1="`cat /tmp/petget_installpreview_pkgname`"


#this is the db of the main pkg...
DB_MAIN="${PREPATH}Packages-`cat /tmp/petget_filterversion`" #ex: Packages-slackware-12.2-official 110723
if [ "$RUNNINGWOOF" = "no" ];then
 #...should have first preference when looking for dependencies...
 DB_OTHERS="`ls -1 ${PREPATH}Packages-* | grep -v "$DB_MAIN"`"
 #if DB_MAIN is puppy-4, puppy-3 or puppy-2, then only look in those...
 if [ "`echo "$DB_MAIN" | grep '\\-puppy\\-2'`" != "" ];then
  DB_OTHERS="`echo "$DB_OTHERS" | grep '\\-puppy\\-2'`"
 else
  if [ "`echo "$DB_MAIN" | grep '\\-puppy\\-3'`" != "" ];then
   DB_OTHERS="`echo "$DB_OTHERS" | grep '\\-puppy\\-3'`"
  else
   if [ "`echo "$DB_MAIN" | grep '\\-puppy\\-4'`" != "" ];then
    DB_OTHERS="`echo "$DB_OTHERS" | grep '\\-puppy\\-4'`"
   else
    #do not look in puppy-2, puppy-3 or puppy-4...
    DB_OTHERS="`echo "$DB_OTHERS" | grep -v '\\-puppy\\-[234]'`"
   fi
  fi
 fi
else
 #running woof, restrict search for deps to only the one pkg db file.
 DB_OTHERS=""
fi
DB_OTHERS="`echo "$DB_OTHERS" | tr '\n' ' '`"

#the question is, how deep to search for deps? i'll go down 2 levels... make it 3...
cp -f /tmp/petget_missingpkgs_patterns /tmp/petget_missingpkgs_patternsx
echo "$(gettext 'HIERARCHY OF MISSING DEPENDENCIES OF PACKAGE') $TREE1" > /tmp/petget_deps_visualtreelog #w017
echo "$(gettext "Format of each line: 'a-missing-dependent-pkg: missing dependencies of a-missing-dependent-pkg'")" >> /tmp/petget_deps_visualtreelog #w017
for ONELEVEL in 1 2 3
do
 echo "" >> /tmp/petget_deps_visualtreelog #w017
 echo -n "" > /tmp/petget_missingpkgs_patterns2
 for depPATTERN in `cat /tmp/petget_missingpkgs_patternsx`
 do
  ONEDEP="`echo -n "$depPATTERN" | sed -e 's%|%%g'`" #convert to exact name, ex: abiword
  depPATTERN="`echo -n "$depPATTERN" | sed -e 's%\\-%\\\\-%g'`" #backslash '-'
  #find database entry for this package...
  for ONEDB in $DB_MAIN $DB_OTHERS
  do
   DB_dependencies="`cat $ONEDB | cut -f 1,2,9 -d '|' | grep "$depPATTERN" | cut -f 3 -d '|' | head -n 1 | sed -e 's%,$%%'`"
   if [ "$DB_dependencies" != "" ];then
    ALLDEPS_PATTERNS="`echo -n "$DB_dependencies" | tr ',' '\n' | grep '^+' | sed -e 's%^+%%' -e 's%$%|%' -e 's%^%|%'`" #put '|' on each end.
    echo "$ALLDEPS_PATTERNS" > /tmp/petget_subpkg_deps_patterns
    MISSINGDEPS_PATTERNS="`grep --file=/tmp/petget_installed_patterns_all -v /tmp/petget_subpkg_deps_patterns`"
    echo "$MISSINGDEPS_PATTERNS" >> /tmp/petget_missingpkgs_patterns2
    #w017 log a visual tree...
    MISSDEPSLIST="`echo "$MISSINGDEPS_PATTERNS" | sed -e 's%|%%g' | tr '\n' ' '`"
    case $ONELEVEL in
     1)
      echo "$ONEDEP: $MISSDEPSLIST" >> /tmp/petget_deps_visualtreelog
     ;;
     2)
      echo "    $ONEDEP: $MISSDEPSLIST" >> /tmp/petget_deps_visualtreelog
     ;;
     3)
      echo "        $ONEDEP: $MISSDEPSLIST" >> /tmp/petget_deps_visualtreelog
     ;;
    esac
    break
   fi
  done
 done
 sort -u /tmp/petget_missingpkgs_patterns2 > /tmp/petget_missingpkgs_patternsx
 cat /tmp/petget_missingpkgs_patternsx >> /tmp/petget_missingpkgs_patterns #accumulate them.
done
sort -u /tmp/petget_missingpkgs_patterns > /tmp/petget_missingpkgs_patternsx
mv -f /tmp/petget_missingpkgs_patternsx /tmp/petget_missingpkgs_patterns

#now find the entries in the databases...
rm -f /tmp/petget_missing_dbentries* 2>/dev/null
#for depPATTERN in `cat /tmp/petget_missingpkgs_patterns` #ex depPATTERN=|kdelibs| ex2: |kdelibs&gt2.3.6|
#111107 01micko: fix for '||' messing things up...
for depPATTERN in `grep '[a-zA-Z]' /tmp/petget_missingpkgs_patterns` #ex depPATTERN=|kdelibs| ex2: |kdelibs&gt2.3.6|. 120221 jemimah
do

 #110722 separate out any versioning... (see also findmissingpkgs.sh)
 xdepPATTERN="`echo -n "$depPATTERN" | sed -e 's%&.*%|%'`" #ex: changes |kdelibs&gt2.3.6| to |kdelibs|
 depVERSIONING="`echo -n "$depPATTERN" | grep -o '&.*' | tr -d '|'`" #ex: &gt2.3.6
 if [ "$depVERSIONING" ];then
  #VERTEST_OP="`echo -n "$depVERSIONING" | cut -c 2,3`" #ex: gt
  #VERTEST_VAL="`echo -n "$depVERSIONING" | cut -f 2 -d '&' | cut -c 2-99`" #ex: 2.3.6
  #110822 similar code in support/findpkgs in woof...
  DEPCONDS="`echo -n "$depVERSIONING" | cut -f 2-9 -d '&' | tr '&' ' '`" #can have chained operators, ex: ge2.6.32 lt2.6.33
 fi
 
 depPATTERN="`echo -n "$depPATTERN" | sed -e 's%\\-%\\\\-%g'`" #backslash '-'.
 
 for ONEREPODB in $DB_MAIN $DB_OTHERS
 do
  DBFILE="`basename $ONEREPODB`" #ex: Packages-slackware-12.2-official
  #find database entry(s) for this package...
  DB_ENTRY="`cat $ONEREPODB | grep "$depPATTERN"`"
  if [ "$DB_ENTRY" != "" ];then
   DB_version="`echo -n "$DB_ENTRY" | cut -f 3 -d '|'`"
   if [ "$depVERSIONING" ];then #110722
    #110822 support chained operators...
    condFLG='good'
    for ACOND in $DEPCONDS #ex: gt5.6.7 lt6.7.8
    do
     DEPOP="`echo -n "$ACOND" | cut -c 1,2`"
     DEPVER="`echo -n "$ACOND" | cut -c 3-99`"
     if ! vercmp ${DB_version} ${DEPOP} ${DEPVER};then
      condFLG='bad'
     fi
    done
    if [ "$condFLG" = "good" ];then
     echo "$DB_ENTRY" >> /tmp/petget_missing_dbentries-${DBFILE}-2
     break
    fi
    #if vercmp ${DB_version} ${VERTEST_OP} ${VERTEST_VAL};then
    # echo "$DB_ENTRY" >> /tmp/petget_missing_dbentries-${DBFILE}-2
    # break
    #fi
   else
    echo "$DB_ENTRY" >> /tmp/petget_missing_dbentries-${DBFILE}-2
    break
   fi
  fi
 done
done
#clean them up...
for ONEREPODB in $DB_MAIN $DB_OTHERS
do
 DBFILE="`basename $ONEREPODB`" #ex: Packages-slackware-12.2-official
 if [ -f /tmp/petget_missing_dbentries-${DBFILE}-2 ];then
  sort -u /tmp/petget_missing_dbentries-${DBFILE}-2 > /tmp/petget_missing_dbentries-${DBFILE}
  rm -f /tmp/petget_missing_dbentries-${DBFILE}-2
 fi
done

kill $X1PID

###END###

