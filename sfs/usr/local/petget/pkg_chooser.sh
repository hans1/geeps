#!/bin/bash
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (/usr/share/doc/legal/lgpl-2.1.txt).
#The Puppy Package Manager main GUI window.
#v424 reintroduce the 'ALL' category, for ppup build only.
#v425 enable ENTER key for find box.
#100116 add quirky repo at ibiblio. 100126: bugfixes.
#100513 reintroduce the 'ALL' category for quirky (t2).
#100903 handle puppy-wary5 repo.
#100911 handle puppy-lucid repo.
#101126 prevent 'puppy-quirky' radiobutton first for quirky 1.4 (based on wary5 pkgs).
#101129 checkboxes for show EXE DEV DOC NLS.
#101205 bugfix for: make sure first radiobutton matches list of pkgs.
#110118 alternate User Interfaces. see also configure.sh.
#110505 support sudo for non-root user.
#110706 fix for deps checking.
#120203 BK: internationalized.
#120327 sometimes the selected repo radiobutton did not match listed packages at startup.

export TEXTDOMAIN=petget___pkg_chooser.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

#export LANG=C

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS
. /root/.packages/PKGS_MANAGEMENT #has PKG_REPOS_ENABLED, PKG_NAME_ALIASES

#101129 choose to display EXE, DEV, DOC, NLS pkgs...
mkdir -p /var/local/petget
DEF_CHK_EXE='true'
DEF_CHK_DEV='false'
DEF_CHK_DOC='false'
DEF_CHK_NLS='false'
[ -e /var/local/petget/postfilter_EXE ] && DEF_CHK_EXE="`cat /var/local/petget/postfilter_EXE`"
[ -e /var/local/petget/postfilter_DEV ] && DEF_CHK_DEV="`cat /var/local/petget/postfilter_DEV`"
[ -e /var/local/petget/postfilter_DOC ] && DEF_CHK_DOC="`cat /var/local/petget/postfilter_DOC`"
[ -e /var/local/petget/postfilter_NLS ] && DEF_CHK_NLS="`cat /var/local/petget/postfilter_NLS`"
#pass in variable and state... ex: EXE false (see also filterpkgs.sh)
#this script handles checkbox actions...
echo "#!/bin/ash
echo -n \"\$2\" > /var/local/petget/postfilter_\${1}
cp -f /tmp/filterpkgs.results /tmp/filterpkgs.results.post
DEF_CHK_EXE='true'
DEF_CHK_DEV='false'
DEF_CHK_DOC='false'
DEF_CHK_NLS='false'
[ -e /var/local/petget/postfilter_EXE ] && DEF_CHK_EXE=\"\`cat /var/local/petget/postfilter_EXE\`\"
[ -e /var/local/petget/postfilter_DEV ] && DEF_CHK_DEV=\"\`cat /var/local/petget/postfilter_DEV\`\"
[ -e /var/local/petget/postfilter_DOC ] && DEF_CHK_DOC=\"\`cat /var/local/petget/postfilter_DOC\`\"
[ -e /var/local/petget/postfilter_NLS ] && DEF_CHK_NLS=\"\`cat /var/local/petget/postfilter_NLS\`\"
[ \"\$DEF_CHK_EXE\" = \"false\" ] && sed -i -e '/_EXE/d' /tmp/filterpkgs.results.post
[ \"\$DEF_CHK_DEV\" = \"false\" ] && sed -i -e '/_DEV/d' /tmp/filterpkgs.results.post
[ \"\$DEF_CHK_DOC\" = \"false\" ] && sed -i -e '/_DOC/d' /tmp/filterpkgs.results.post
[ \"\$DEF_CHK_NLS\" = \"false\" ] && sed -i -e '/_NLS/d' /tmp/filterpkgs.results.post
" > /tmp/filterpkgs.results.postfilter.sh
chmod 777 /tmp/filterpkgs.results.postfilter.sh


#finds all user-installed pkgs and formats ready for display...
/usr/local/petget/finduserinstalledpkgs.sh #writes to /tmp/installedpkgs.results

#100711 moved from findmissingpkgs.sh...
if [ ! -f /tmp/petget_installed_patterns_system ];then
 INSTALLED_PATTERNS_SYS="`cat /root/.packages/woof-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_SYS" > /tmp/petget_installed_patterns_system
 #PKGS_SPECS_TABLE also has system-installed names, some of them are generic combinations of pkgs...
 INSTALLED_PATTERNS_GEN="`echo "$PKGS_SPECS_TABLE" | grep '^yes' | cut -f 2 -d '|' |  sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_GEN" >> /tmp/petget_installed_patterns_system
 sort -u /tmp/petget_installed_patterns_system > /tmp/petget_installed_patterns_systemx
 mv -f /tmp/petget_installed_patterns_systemx /tmp/petget_installed_patterns_system
fi
#100711 this code repeated in findmissingpkgs.sh...
cp -f /tmp/petget_installed_patterns_system /tmp/petget_installed_patterns_all
INSTALLED_PATTERNS_USER="`cat /root/.packages/user-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
echo "$INSTALLED_PATTERNS_USER" >> /tmp/petget_installed_patterns_all

#process name aliases into patterns (used in filterpkgs.sh, findmissingpkgs.sh) ... 100126...
xPKG_NAME_ALIASES="`echo "$PKG_NAME_ALIASES" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g'`"
echo "$xPKG_NAME_ALIASES" > /tmp/petget_pkg_name_aliases_patterns_raw #110706
cp -f /tmp/petget_pkg_name_aliases_patterns_raw /tmp/petget_pkg_name_aliases_patterns #110706 _raw see findmissingpkgs.sh.

#100711 above has a problem as it has wildcards. need to expand...
#ex: PKG_NAME_ALIASES has an entry 'cxxlibs,glibc*,libc-*', the above creates '|cxxlibs|,|glibc.*|,|libc\-.*|',
#    after expansion: '|cxxlibs|,|glibc|,|libc-|,|glibc|,|glibc_dev|,|glibc_locales|,|glibc-solibs|,|glibc-zoneinfo|'
echo -n "" > /tmp/petget_pkg_name_aliases_patterns_expanded
for ONEALIASLINE in `cat /tmp/petget_pkg_name_aliases_patterns | tr '\n' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 echo -n "" > /tmp/petget_temp1
 for PARTONELINE in `echo -n "$ONEALIASLINE" | tr ',' ' '`
 do
  grep "$PARTONELINE" /tmp/petget_installed_patterns_all >> /tmp/petget_temp1
 done
 ZZZ="`echo "$ONEALIASLINE" | sed -e 's%\.\*%%g' | tr -d '\\'`"
 [ -s /tmp/petget_temp1 ] && ZZZ="${ZZZ},`cat /tmp/petget_temp1 | tr '\n' ',' | tr -s ',' | tr -d '\\'`"
 ZZZ="`echo -n "$ZZZ" | sed -e 's%,$%%'`"
 echo "$ZZZ" >> /tmp/petget_pkg_name_aliases_patterns_expanded
done
cp -f /tmp/petget_pkg_name_aliases_patterns_expanded /tmp/petget_pkg_name_aliases_patterns

#w480 PKG_NAME_IGNORE is definedin PKGS_MANAGEMENT file... 100126...
xPKG_NAME_IGNORE="`echo "$PKG_NAME_IGNORE" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g' -e 's%\-%\\-%g'`"
echo "$xPKG_NAME_IGNORE" > /tmp/petget_pkg_name_ignore_patterns

repocnt=0
COMPAT_REPO=""
COMPAT_DBS=""
echo -n "" > /tmp/petget_active_repo_list

#100116 quirky...
QUIRKY_DB=''
if [ "$DISTRO_COMPAT_VERSION" != "wary5" ];then #101126
 if [ "`echo "$DISTRO_NAME" | grep -i 'quirky'`" != "" ];then
  if [ "`echo -n "$PKG_REPOS_ENABLED" | grep 'puppy\-quirky'`" != "" ];then
   echo 'puppy-quirky-official' >> /tmp/petget_active_repo_list
   QUIRKY_DB='<radiobutton><label>puppy-quirky</label><action>/tmp/filterversion.sh puppy-quirky-official</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>'
   FIRST_DB='puppy-quirky-official'
   repocnt=1
  fi
 fi
fi

if [ "$DISTRO_BINARY_COMPAT" != "puppy" ];then #w477 if compat-distro is puppy, bypass.
 for ONE_DB in `ls -1 /root/.packages/Packages-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}* | tr '\n' ' '`
 do
  BASEREPO="`basename $ONE_DB`"
  bPATTERN=' '"$BASEREPO"' '
  [ "`echo -n "$PKG_REPOS_ENABLED" | grep "$bPATTERN"`" = "" ] && continue
  repocnt=`expr $repocnt + 1`
  COMPAT_REPO="`echo -n "$ONE_DB" | rev | cut -f 1 -d '/' | rev | cut -f 2-4 -d '-'`"
  if [ "$COMPAT_DBS" = "" ];then #101205
   COMPAT_DBS="<radiobutton><label>${COMPAT_REPO}</label><action>/tmp/filterversion.sh ${COMPAT_REPO}</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>"
  else
   COMPAT_DBS="${COMPAT_DBS}
<radiobutton><label>${COMPAT_REPO}</label><action>/tmp/filterversion.sh ${COMPAT_REPO}</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>"
  fi
  echo "${COMPAT_REPO}" >> /tmp/petget_active_repo_list #read in findnames.sh
  [ "$FIRST_DB" = "" ] && [ $repocnt = 1 ] && FIRST_DB="$COMPAT_REPO"
 done
fi

PUPPY_DBS=""

#100903 another hack...
if [ "$DISTRO_COMPAT_VERSION" == "wary5" ];then
 if [ "`echo -n "$PKG_REPOS_ENABLED" | grep 'puppy\-wary5'`" != "" ];then
  echo 'puppy-wary5-official' >> /tmp/petget_active_repo_list
  PUPPY_DBS='<radiobutton><label>puppy-wary5</label><action>/tmp/filterversion.sh puppy-wary5-official</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>'
  FIRST_DB='puppy-wary5-official'
  repocnt=1
 fi
fi

#100911 another hack...
if [ "$DISTRO_COMPAT_VERSION" == "lucid" ];then
 if [ "`echo -n "$PKG_REPOS_ENABLED" | grep 'puppy\-lucid'`" != "" ];then
  echo 'puppy-lucid-official' >> /tmp/petget_active_repo_list
  PUPPY_DBS='<radiobutton><label>puppy-lucid</label><action>/tmp/filterversion.sh puppy-lucid-official</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>'
  FIRST_DB='puppy-lucid-official'
  repocnt=1
 fi
fi

xrepocnt=$repocnt #w476
for ONE_DB in `ls -1 /root/.packages/Packages-puppy* | sort -r | tr '\n' ' '`
do
 BASEREPO="`basename $ONE_DB`"
 #100903 if wary5, want to list quirky repo, as has same code base...
 [ "$BASEREPO" = "Packages-puppy-quirky-official" ] && [ "$DISTRO_COMPAT_VERSION" != "wary5" ] && continue #100126 already handled above. 100903
 [ "$BASEREPO" = "Packages-puppy-wary5-official" ] && continue #100903 already handled above.
 [ "$BASEREPO" = "Packages-puppy-lucid-official" ] && continue #100911 already handled above.
 bPATTERN=' '"$BASEREPO"' '
 [ "`echo -n "$PKG_REPOS_ENABLED" | grep "$bPATTERN"`" = "" ] && continue
 PUPPY_REPO="`echo -n "$ONE_DB" | rev | cut -f 1 -d '/' | rev | cut -f 2-4 -d '-'`"
 #chop size of label down a bit, to fit in 800x600 window...
 PUPPY_REPO_CUT="`echo -n "$ONE_DB" | rev | cut -f 1 -d '/' | rev | cut -f 2,3 -d '-'`"
 PUPPY_REPO_FULL="`echo -n "$ONE_DB" | rev | cut -f 1 -d '/' | rev | cut -f 2-9 -d '-'`"
 if [ "$PUPPY_DBS" = "" ];then #101205
  PUPPY_DBS="<radiobutton><label>${PUPPY_REPO_CUT}</label><action>/tmp/filterversion.sh ${PUPPY_REPO_FULL}</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>"
 else
  PUPPY_DBS="${PUPPY_DBS}
<radiobutton><label>${PUPPY_REPO_CUT}</label><action>/tmp/filterversion.sh ${PUPPY_REPO_FULL}</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>"
 fi
 echo "${PUPPY_REPO}" >> /tmp/petget_active_repo_list #read in findnames.sh
 [ "$FIRST_DB" = "" ] && [ $repocnt = $xrepocnt ] && FIRST_DB="$PUPPY_REPO" #w476
 repocnt=`expr $repocnt + 1`
done

FILTER_CATEG="Desktop"
#note, cannot initialise radio buttons in gtkdialog...
echo "Desktop" > /tmp/petget_filtercategory #must start with Desktop.
echo "$FIRST_DB" > /tmp/petget_filterversion #ex: slackware-12.2-official

#if [ "$DISTRO_BINARY_COMPAT" = "ubuntu" -o "$DISTRO_BINARY_COMPAT" = "debian" ];then
if [ 0 -eq 1 ];then #w020 disable this choice.
 #filter pkgs by first letter, for more speed. must start with ab...
 echo "ab" > /tmp/petget_pkg_first_char
 FIRSTCHARS="
<radiobutton><label>a,b</label><action>echo ab > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>c,d</label><action>echo cd > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>e,f</label><action>echo ef > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>g,h</label><action>echo gh > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>i,j</label><action>echo ij > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>k,l</label><action>echo kl > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>m,n</label><action>echo mn > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>o,p</label><action>echo op > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>q,r</label><action>echo qr > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>s,t</label><action>echo st > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>u,v</label><action>echo uv > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>w,x</label><action>echo wx > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>y,z</label><action>echo yz > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>0-9</label><action>echo 0123456789 > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>ALL</label><action>echo ALL > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
"
 xFIRSTCHARS="<hbox>
${FIRSTCHARS}
</hbox>"
else
 #do not dispay the alphabetic radiobuttons...
 echo "ALL" > /tmp/petget_pkg_first_char
 FIRSTCHARS=""
 xFIRSTCHARS=""
fi

#finds pkgs in repository based on filter category and version and formats ready for display...
/usr/local/petget/filterpkgs.sh $FILTER_CATEG #writes to /tmp/filterpkgs.results

echo '#!/bin/sh
echo $1 > /tmp/petget_filterversion
' > /tmp/filterversion.sh
chmod 777 /tmp/filterversion.sh

#  <text use-markup=\"true\"><label>\"<b>To install or uninstall,</b>\"</label></text>

ALLCATEGORY=''
if [ "$DISTRO_BINARY_COMPAT" = "puppy" ];then #v424 reintroduce the 'ALL' category.
 ALLCATEGORY="<radiobutton><label>$(gettext 'ALL')</label><action>/usr/local/petget/filterpkgs.sh ALL</action><action>refresh:TREE1</action></radiobutton>"
fi
#100513 also for 't2' (quirky) builds...
if [ "$DISTRO_BINARY_COMPAT" = "t2" ];then #reintroduce the 'ALL' category.
 ALLCATEGORY="<radiobutton><label>$(gettext 'ALL')</label><action>/usr/local/petget/filterpkgs.sh ALL</action><action>refresh:TREE1</action></radiobutton>"
fi

#w476 reverse COMPAT_DBS, PUPPY_DBS...
#100412 make sure first radiobutton matches list of pkgs...
#101205 bugfix...
DB_ORDERED="${QUIRKY_DB}
${PUPPY_DBS}
${COMPAT_DBS}"
FIRST_DB_cut="`echo -n "$FIRST_DB" | cut -f 1,2 -d '-' | sed -e 's%\\-%\\\\-%g'`" #ex: puppy-lucid-official cut to puppy\-lucid.
fdPATTERN='>'"$FIRST_DB_cut"'<'
DB_temp0="`echo "$DB_ORDERED" | sed -e 's%^$%%' | grep "$fdPATTERN"`"
if [ ! "$DB_temp0" ];then #120327 above may fail.
 #ex: FIRST_DB=ubuntu-precise-main, DB_ORDERED=puppy-precise\npuppy-noarch\nubuntu-precise-main\nubuntu-precise-multiverse
 FIRST_DB_cut="`echo -n "$FIRST_DB" | cut -f 1,2,3 -d '-' | sed -e 's%\\-%\\\\-%g'`" #ex: ubuntu-precise-main becomes ubuntu\-precise\-main
 fdPATTERN='>'"$FIRST_DB_cut"'<'
 DB_temp0="`echo "$DB_ORDERED" | sed -e 's%^$%%' | grep "$fdPATTERN"`"
fi
DB_temp1="`echo "$DB_ORDERED" | sed -e 's%^$%%' | grep -v "$fdPATTERN"`"
DB_ORDERED="$DB_temp0
$DB_temp1"

#  <text use-markup=\"true\"><label>\"<b>Just click on a package!</b>\"</label></text>
#  <text><label>\" \"</label></text>

#110118 alternate User Interfaces...
touch /var/local/petget/ui_choice
UI="`cat /var/local/petget/ui_choice`"
[ "$UI" = "" ] && UI="Ziggy"
. /usr/local/petget/ui_${UI}


RETPARAMS="`gtkdialog3 --program=MAIN_DIALOG`"

#eval "$RETPARAMS"

###END###
