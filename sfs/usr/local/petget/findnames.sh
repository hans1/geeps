#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/pkg_chooser.sh
#  ENTRY1 is a string, to search for a package.
#101129 checkboxes for show EXE DEV DOC NLS. fixed some search bugs.
#110223 run message as separate process.
#110530 ignore packages with different kernel version number, format -k2.6.32.28- in pkg name (also filterpkgs.sh)...
#120203 BK: internationalized.
#120323 replace 'xmessage' with 'pupmessage'.
#120410 Mavrothal: fix "getext" typo.

export TEXTDOMAIN=petget___findnames.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS #has PKGS_SPECS_TABLE.
. /root/.packages/DISTRO_PET_REPOS #has PET_REPOS, PACKAGELISTS_PET_ORDER

entryPATTERN='^'"`echo -n "$ENTRY1" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g' -e 's%\\*%.*%g'`"

CURRENTREPO="`cat /tmp/petget_filterversion`" #search here first.
REPOLIST="${CURRENTREPO} `cat /tmp/petget_active_repo_list | grep -v "$CURRENTREPO" | tr '\n' ' '`"

FNDIT=no
for ONEREPO in $REPOLIST
do
 FNDENTRIES="`cat /root/.packages/Packages-${ONEREPO} | grep -i "$entryPATTERN"`"
 if [ "$FNDENTRIES" != "" ];then
  FIRSTCHAR="`echo "$FNDENTRIES" | cut -c 1 | tr '\n' ' ' | sed -e 's% %%g'`"
  #write these just in case needed...
  ALPHAPRE="`cat /tmp/petget_pkg_first_char`"
  #if [ "$ALPHAPRE" != "ALL" ];then
  # echo "$FIRSTCHAR" > /tmp/petget_pkg_first_char
  #fi
  #echo "ALL" > /tmp/petget_filtercategory
  echo "$ONEREPO" > /tmp/petget_filterversion #ex: slackware-12.2-official
  #this is read when update TREE1 in pkg_chooser.sh...
  echo "$FNDENTRIES" | cut -f 1,10 -d '|' > /tmp/filterpkgs.results
  FNDIT=yes
  break
 fi
done

#110530 ignore packages with different kernel version number, format -k2.6.32.28- in pkg name...
if [ "$FNDIT" = "yes" ];then
 GOODKERNPTN="`uname -r | sed -e 's%\.%\\\.%g' -e 's%^%\\\-k%' -e 's%$%$%'`" #ex: \-k2.6.32$
 BADKERNPTNS="`grep -o '\-k2\.6\.[^-|a-zA-Z]*' /tmp/filterpkgs.results | cut -f 1 -d '|' | grep -v "$GOODKERNPTN" | sed -e 's%$%-%' -e 's%\.%\\\.%g' -e 's%\-%\\\-%g'`" #ex: \-k2\.6\.32\.28\-
 if [ "$BADKERNPTNS" ];then
  echo "$BADKERNPTNS" >> /tmp/petget_badkernptns
  grep -v -f /tmp/petget_badkernptns /tmp/filterpkgs.results > /tmp/filterpkgs.resultsxxx
  mv -f /tmp/filterpkgs.resultsxxx /tmp/filterpkgs.results
 fi
fi

if [ "$FNDIT" = "no" ];then
 pupmessage -bg red -center -title "$(gettext 'PPM find')" "$(gettext 'Sorry, no matching package name')" & #110223 run as separate process.
else
 #101129 postprocess, show EXE, DEV, DOC, NLS...
 DEF_CHK_EXE='true'
 DEF_CHK_DEV='false'
 DEF_CHK_DOC='false'
 DEF_CHK_NLS='false'
 [ -e /var/local/petget/postfilter_EXE ] && DEF_CHK_EXE="`cat /var/local/petget/postfilter_EXE`"
 [ -e /var/local/petget/postfilter_DEV ] && DEF_CHK_DEV="`cat /var/local/petget/postfilter_DEV`"
 [ -e /var/local/petget/postfilter_DOC ] && DEF_CHK_DOC="`cat /var/local/petget/postfilter_DOC`"
 [ -e /var/local/petget/postfilter_NLS ] && DEF_CHK_NLS="`cat /var/local/petget/postfilter_NLS`"
 cp -f /tmp/filterpkgs.results /tmp/filterpkgs.results.post
 [ "$DEF_CHK_EXE" = "false" ] && sed -i -e '/_EXE/d' /tmp/filterpkgs.results.post
 [ "$DEF_CHK_DEV" = "false" ] && sed -i -e '/_DEV/d' /tmp/filterpkgs.results.post
 [ "$DEF_CHK_DOC" = "false" ] && sed -i -e '/_DOC/d' /tmp/filterpkgs.results.post
 [ "$DEF_CHK_NLS" = "false" ] && sed -i -e '/_NLS/d' /tmp/filterpkgs.results.post
 #...main gui will read /tmp/filterpkgs.results.post
fi

