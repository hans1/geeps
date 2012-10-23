#!/bin/sh
# GUI for setup keyboard, timezone and locale
# based on firstsetup but not check extra sfs
# 2aug10 by shinobar <shibno@pos.to>
# 8aug10 v0.2: do not reboot PC but X on locale changed, support Xvesa, support WenQuanYi as a CJK font
# 11aug10 v0.3: '.UTF-8' instead of '.utf8' if rc.country allows
# 12aug10 v0.4: fixd azerty(fr), show version
# 13aug10 v0.5: load console font, OUTPUT_CHARSET for gettext
# 15aug10 : do not loadfont because something seems corrupt, bugfix was fail non-utf8 to utf8
# 17aug10 v0.6: do not write /etc/fontmap
# 29aug10 v0.7: bugfix was UTF8 not choosable if lang choice is one country
# 13oct10 v0.8d4: include changing screen resolusion
# 18oct10 v0.9d: xorgwizard button, sandbox for new keyboard layout, utf8 required other than ISO-8859-1/2
# 22oct10 v0.9d1: numlockx, exit 0 when closed the main dialog, suppress shortcut-keys on the keyboard sandbox
# 29oct10 v1.0: ensure taking the lowest frequency for the refresh rate of the screen, Xvesa support
# 31oct10 v1.1: again the lowest frequency for the refresh rate for .xinitrc
# 7nov10 v1.2: refresh rate near 60Hz, nvidia, clone of xrandrshell, support locale with '@', hostname
# 20nov10 v1.3: Support Xvesa
# 1dec10 v1.4: Puppy 4.2x backward compatibility, Xvasa support, depth
# 4dec10 v1.4: Xvesa link precaution for xorgwizard (thanks to sc0ttman )
# 24dec10 v1.5: avoid @euro.UTF-8, same languege at the top of the list
# 29dec10 v1.6: detection of xvesa resolution
# 31dec10 : Do not translate tooltip-text "Choose main language"
# 4jan11 v1.7: read Xorg driver name from xorg.conf or from /var/log/Xorg.0.log
#            : fix change_xrandr, CLOCKFLICKER, 'us' keymap near the top
# 12jan11 v1.8: no sandbox for Xvesa, Switching Xvesa to Xorg
# 21jan11 v1.8.1: leave 'changed' at status, extralang, fix was lang_check failed to change from pt_BR
# 30jan11 v1.8.2: avoid black screen at changing timezone, lang_chek for Puppy-4.2 and older 
#  3feb11 v1.8.2: full list locale regardless fonts
# 10feb11 v1.8.3: fixed was always list all
#  1apr11 v1.8.4: /etc/hosts (thanks to micko)
# 17oct11 v1.9: /root/Startup/firstrun (was 'fullstart')
#   : removed but optional numlockx binary because of the potential incompatibility (thanks to barry)
#   : removed but optional extralang which is experimental
#   : keep languege list to speed up at repeated run 
# 25nov11 v1.9.5: fixed mainlangs list to speed up, refresh drive icons
#  1jan11 v1.9.6: UTF-8 on main dialog(tnx to zigbert)
#120219 01micko: detecting X driver
# 10mar12 v1.9.9: fix non-utf8 charsets other than ISO-8859-1/2
# v1.9.9: chooselocale, timezone-set, commandline interface, making localedef, mousecheck
# v1.9.9: call extralang only if the locale is changed
# 16mar12: v2.0: video_driver(Barry and shinobar), fix @euro, fix was failed to detect INSTALLED (extralang), fix script name typo quickcountry(thanks to prmasu)
# 29mar12: v2.0.9: fix was cli missing some locales, console font, language deatail dialog(thanks to gcmartin), etc_profile_at_shutdown, DISTRO_XORG_AUTO, splash
# 14apr12: v2.1: Need not restart X for time zone changed, fix video driver detection(jemimah), splash only for firstrun

MYBASE=$(basename $0)
VERSION="2.1"
LIST_ALL="y"   # "" or "y"
CONSOLE_FONT_SUPPORT="y"
XRANDR="y"
MOMENT=2	#v1.9.5: minimum second to show splash #v2.1: no splash if 0

DEBUGFLAG=""
[ "$(echo $VERSION| tr -d '0-9.')" != "" ] && DEBUGFLAG="yes"
echo $MYBASE| grep -q 'debug' && DEBUGFLAG="yes"

# how i called?
#v.1.9.7
# woof calls 'countrywizard composeonly' but need not
# rc.country calls 'chooselocale cli quiet'
# rc.country calls 'timezone-set cli'
#v2.1: splash only for firstrun (MOMENT=0 for countrywizard and etc.)
#  also skip splash with '-s' option 
FULLFEATURE=""; COUNTRYSET=""; RESOCHANGER=""; CLI="";  HELPFLAG=""
case "$1" in
*debug)	DEBUGFLAG="yes"; shift;;
*help) HELPFLAG="yes"; CLI="yes"; shift;;
-s|--skip*splash) MOMENT=0; shift;;
esac 
PARAM1=$1	# PARAM2=$2
[ "$PARAM1" = 'cli' ] && CLI="yes" && shift
[ "$DISPLAY" ] || CLI="yes"
PARAM2=$1
case "$MYBASE" in
*country*) COUNTRYSET="yes"; MOMENT=0;;
chooselocale*)
  [ "$PARAM1" = 'composeonly' ] && exit
  COUNTRYSET="yes"; MOMENT=0
  ;;
timezone-set*) COUNTRYSET="yes"; MOMENT=0;;
xrandr*) RESOCHANGER="yes"; MOMENT=0;;
*) FULLFEATURE="yes"; COUNTRYSET="yes"; RESOCHANGER="yes";;
esac

# avoid multiple run
PS=$(ps)
N=$(echo "$PS"| grep -w "$0"| grep -w 'sh'| wc -l)
if [ $N -gt 1 ] ; then
  echo "$0 seems already running."
  exit
fi

# NLS
export TEXTDOMAIN=countrywizard	#$(basename $0)
export OUTPUT_CHARSET=UTF-8
TITLE="$(gettext 'Country Settings')"
[ "$RESOCHANGER" != "" ] && TITLE=$(gettext 'Resolution Changer')
[ "$FULLFEATURE" != "" ] && TITLE=$(gettext 'Personalize Settings')
[ "$DEBUGFLAG" ] && TITLE="$TITLE - v.$VERSION"

debug() {
	[ "$DEBUGFLAG" = "" ] && return
	echo "$@" >&2
}
debug "$MYBASE-$VERSION"

# lookup puppy status
DISTRO_NAME=""
DISTRO_VERSION=""
[ -f /etc/rc.d/PUPSTATE ] && DISTRO_NAME="Puppy"
[ -f /etc/puppyversion ] && DISTRO_NAME="Puppy" && DISTRO_VERSION="$(cat $TOPDIR/etc/puppyversion)" #old pre-w464 install.
[ -f /etc/DISTRO_SPECS ] && source /etc/DISTRO_SPECS
[ "$DISTRO_VERSION" != "" ] && DISTRO_NAME="$DISTRO_NAME $DISTRO_VERSION"
if [ "$DISTRO_MINOR_VERSION" ]; then
  [  "$DISTRO_MINOR_VERSION" -gt 0 ] && DISTRO_NAME="$DISTRO_NAME-$DISTRO_MINOR_VERSION"
fi
for F in PUPSTATE BOOTCONFIG pupsave.conf; do
  [ -f /etc/rc.d/$F ] && source /etc/rc.d/$F
done
SFSFILE=$(echo $PUPSFS|cut -d',' -f3) #;SFSFILE="/pup-431ml.sfs"	#debug
SFSBASE=$(basename "$SFSFILE")
SUFFIX=$(basename $SFSBASE .sfs|sed -e 's/^.*[0-9]*//')
DISTRO_NAME="$DISTRO_NAME$SUFFIX"
echo $SUFFIX|grep -qi 'ml' && MLPUPPY="true" || MLPUPPY=""
echo $SUFFIX|grep -q 'JP' && JPPUPPY="true" || JPPUPPY=""

# icons and logo
ICONS="/usr/local/lib/X11/mini-icons"
LARGELOGO="/usr/share/doc/puppylogo96.png"
TITLEICON="icon-name=\"gtk-preferences\""
# fonts
UNIFONT="unifont"
JPFONT="M+1P+IPAG"
ZHFONT="WenQuanYi"
FCLIST=$(fc-list)
HAS_ZHFONT=""
HAS_JPFONT=""
HAS_UNIFONT=""
echo "$FCLIST" | grep -qw "$ZHFONT" && HAS_ZHFONT="yes"
echo "$FCLIST" | grep -qw "$JPFONT" && HAS_JPFONT="yes"
echo "$FCLIST" | grep -qw "$UNIFONT" && HAS_UNIFONT="yes"
# global variables
export DIALOG=""
export XPID=""
export MNTPNT=""
export SRCDIR=""
export UTF8=""

# welcome splash
#v2.1: no splash if MOMENT=0
START=0
MOMENT=$(echo $MOMENT| tr -dc '0-9-')
[ "$MOMENT" ] || MOMENT=0
if [ -z "$CLI" -a $MOMENT -gt 0 ]; then
 WELCOME=""
 [ "$HAS_ZHFONT" ] && WELCOME="ようこそ 환영 欢迎 歡迎"
 [ "$HAS_UNIFONT" ] && WELCOME="Bienvenue! Willkommen!\nようこそ 환영 欢迎 歡迎\nДобро пожаловать!"
 #WELCOMEMSG="ようこそ！\nWelcome to Multilingual Puppy!"
 WELCOMEMSG=$(printf "$(gettext 'Welcome to %s!')" "$DISTRO_NAME")
 #[ "$WELCOME" ] && WELCOMEMSG="$WELCOME\n$WELCOMEMSG"
 # welcome splash
 export DIALOG="<window title=\"$TITLE\" $TITLEICON><hbox>
<pixmap><input file>$LARGELOGO</input></pixmap>
<text><input>echo -en \"$WELCOME\n$WELCOMEMSG\"</input></text>
</hbox></window>"
 gtkdialog3 -p DIALOG -c >/dev/null &
 XPID=$!
 START=$(date +%s)
fi

# messages
COUNTRYM=$(gettext 'Country Settings')
COUNTRYMSG=$(gettext 'Setup your language, timezone, and keyboard layout.')
FULLMSG=$(gettext 'The graphical desktop has been configured automatically. Just change the ones you want and click OK.')
OKMSG=$(gettext 'Confirm the settings and click 'OK'.')
RESOM=$(gettext 'Screen resolution')
RESOMSG=$(gettext 'You can change the screen resolution from the menu.')
CCEMSG=$(gettext "If your desired resolution is not shown on the list, you have a chance with running the 'XorgWizard', and may need to choose the video driver.")
NVIDIAMSG=$(gettext "The X-server is now using 'nvidia' driver. You can change the settings with running 'NVIDIA X Serever Settings'. Or you can choose another drivers with running the 'XorgWizard'.")
TOPMSG=""
OKTEXT=""
[ "$COUNTRYSET" != "" ] && TOPMSG=$COUNTRYMSG
if [ "$FULLFEATURE" != "" ] ; then
   TOPMSG=$FULLMSG
   OKTEXT="<text><label>$OKMSG</label></text>"
fi
# another icons
NVIDIAICON=""
for F in /usr/share/pixmaps/nvidia24.png /root/.quickpet/icons/nvidia.png /usr/share/pixmaps/nvidia-settings.png ; do
  [ -s "$F" ] && NVIDIAICON="$F" && break
done
# temporary file
MYTMPDIR="/tmp/countrywizard.qs"
mkdir -p "$MYTMPDIR"
TMPFILE="${MYTMPDIR}/${MYBASE}.tmp"
# external programs and dirs
PREFIX=$(dirname $(dirname $0))
MYDATADIR="$PREFIX/share/i18n"
for P in $PREFIX /usr /usr/local; do
  [ -d "$P/share/i18n" ] && MYDATADIR="$P/share/i18n" && break
done
[ "$FULLFEATURE" != "" ] && CONFIGFILE=/tmp/firstrun || CONFIGFILE=""
#[ "$CONFIGFILE" != "" ] && KEEPCONFIG=/etc/firstrun || KEEPCONFIG="" # handle in /root/Startup/fullstart and /usr/bin/firstrun.sh
#which keymap-set &>/dev/null && KEYMAPSET="yes" || KEYMAPSET=""
KEYMAPSET=""
TIMEZONESET=""	#$(which timezone-set)
#grep -q '^[[:blank:]]*ZONERETVAL=.*\$1' "$TIMEZONESET" || TIMEZONESET=""
EXTRALANG=$(which extralang)
LOAD_CONSOLEFONT=""	#$(which load_consolefont) #use internal
DOTUTF8=".UTF-8"
grep -q '^[[:blank:]]*CLANG=' /etc/rc.d/rc.country || DOTUTF8=".utf8"
#debug "DOTUTF8=$DOTUTF8"
#CHOOSELOCALE=$(which chooselocale)
#grep -q '^[[:blank:]]*ZLANGCHOICE=.*\$1' "$CHOOSELOCALE" || CHOOSELOCALE=""
CHOOSELOCALE=""	# use internal chooselocale
MOUSECHECK=$(which mousecheck)	# v1.9.9
for KEYMAPSDIR in /lib/keymaps /usr/share/kbd/keymaps/i386;do
  [ -d $KEYMAPSDIR ] && break
done
for CONSOLEFONTSDIR in /lib/consolefonts /usr/share/kbd/consolefonts; do
  [ -f $CONSOLEFONTSDIR/lat1-12.psfu* ] && break
done
XWIN=$(which xwin)
#XFULLRESTART=""
#[ $(grep 'export LANG=.NEWLANG' /usr/bin/xwin | wc -l) -lt 2 ] && XFULLRESTART="yes" || XFULLRESTART=""
XPATH=$(which X)
XSERVER=$(readlink "$XPATH")
XVERSION=`Xorg -version 2>&1 | grep '^X Window System Version' | rev | cut -f 1 -d ' ' | rev | cut -c 3` #ex: 3 (as in 1.3.0)
[ ! $XVERSION ] && XVERSION=`Xorg -version 2>&1 | grep '^X.Org X Server' | rev | cut -f 1 -d ' ' | rev | cut -c 3`
[ ! $XVERSION ] && XVERSION=0  # precaution
which Xvesa &>/dev/null && HAS_XVESA="yes" || HAS_XVESA=""
NUMLOCKX=$(which numlockx)
P=/root/Startup/numlockx
[ -s $P -a ! -L $P ] && NUMLOCKX=$P

make_combo() {
  # v1.9.5: always allow dup to speed up
  NODUP=""
  [ "$1" = '-' ] && NODUP="yes" && shift
  echo "$@"| sed -e 's!\([^ ][^ ]*\)!<item>\1</item>!g' |tr '%' ' ' 
#  LIST="$@"
#  [ "$ADDNULL" = "" ] || echo "$@" | grep -q "$NULL" || LIST="$@ $NULL"
# CHOICE=""
# for ONEITEM in $LIST;do
#  [ "$NODUP" = "yes" ] &&  echo "$CHOICE" | grep -q ">$(keyword $ONEITEM)[ ]" && continue
#  CHOICE="$CHOICE
#<item>$(echo $ONEITEM|tr '%' ' ')</item>"
# done
# echo "$CHOICE"
}
keyword() {
  echo "$1"| head -n 1| tr '%' ' '| cut -d' ' -f1
}
swapsign() {
	echo $1|sed -e 's,^GMT-,GMTx,' -e 's,^GMT+,GMT-,' -e 's,^GMTx,GMT+,'
}
tzone_check() {
 T=$(keyword "$1")
 [ "$T" ] || T="UTC"
 case $T in
  JST) T="Asia/Tokyo" ;;
  */*) :;;
  *) T=Etc/$(swapsign "$T") ;;
 esac
 [ -f "/usr/share/zoneinfo/$T" ] && echo -n $T
}
make_tzone_list() {
    [ "$TIMEZONESET" != "" ] && TZONES=$(timezone-set --list| sed -e 's/ .$//'| tr ' ' '%') && return
    TZONES="$(find /usr/share/zoneinfo -type f | grep -v '\.tab$' | sed -e 's%/usr/share/zoneinfo/%%' | sed -e 's%Etc/%%' | grep -v '^GMT' | sort )"
    TZONES="$TZONES
GMT-12%Eniwetok
GMT-11%Samoa
GMT-10%Alaska,Hawaii
GMT-9%Alaska
GMT-8%Los_Angeles
GMT-7%Alberta,Montana,Arizona
GMT-6%Mexico_City,Saskatchewan
GMT-5%Bogota,Lima,New_York
GMT-4%Caracas,La_Paz,Canada
GMT-3%Brasilia,Buenos_Aires,Georgetown
GMT-2%mid-Atlantic
GMT-1%Azores,CapeVerdes
GMT+0%London,Dublin,Edinburgh,Lisbon,Reykjavik,Casablanca
GMT+1%Paris,Berlin,Amsterdam,Brussels,Madrid,Stockholm,Oslo
GMT+2%Athens,Helsinki,Istanbul,Jerusalem,Harare
GMT+3%Kuwait,Nairobi,Riyadh,Moscow
GMT+4%Abu_Dhabi,Muscat,Tblisi,Volgograd,Kabul
GMT+5%Islamabad,Karachi
GMT+6%Almaty,Dhaka
GMT+7%Bangkok,Jakarta
GMT+8%Perth,Singapore,Hongkong
GMT+9%Tokyo
GMT+10%Guam
GMT+11%Magadan,Soloman_Is.
GMT+12%Wellington,Fiji,Marshall_Islands
GMT+13%Rawaki_Islands
GMT+14%Line_Islands
"
}
kmap_check() {
  K1=$(keyword "$1")
  [ "$K1" != "" ] || return
  K1=$(basename $K1 .map)
  if ! echo "$KMAPS_LF" | grep -q "^$K1"; then
    K1=$(echo $K1|cut -b 1-2)
    echo "$KMAPS_LF" | grep -q "^$K1" || return
  fi
  echo $K1
  return
}

xmap() {
  M=$1
  case "$M" in
    az*) M="fr";;	#azerty
    cf*) M="ca";;	#canadian french
    cr*) M="hr";;	#croat
    dv*) M="us";;	#dvorak
    mk*) M="mkd";;	#macedonia
    sl*) M="si";;	#slovene
    sv) M="se";;	#sweden
    uk) M="gb";;	#united kingdom
    wa*) M="be";;	#wangbe
    *)  M=$(echo $M|cut -b 1-2)
        echo "$SYMBOLS" | grep -q "$M" || M="us"
      ;;
  esac
  echo $M
}
makekmaplist() {
    #DEFMAP="us"
    if [ "$KEYMAPSDIR" = "/usr/share/kbd/keymaps/i386" ];then
      MAPS=$(find  /usr/share/kbd/keymaps/i386/[^i]* -name '*.map' -not -name 'defkeymap*' -printf '%f\n'  2>/dev/null)
      MAPS=$(echo "$MAPS"| sed -e 's,^.*/,,' -e 's/\.map//'|sort)
    else
      MAPS=$(ls -1 /lib/keymaps| sed -e 's,.gz,,')
    fi
    #SYMBOLS=$(ls -1 /etc/X11/xkb/symbols/pc)
    LAYOUTS=""
    for D in "$FIRSTSETUP_DATADIR" "/usr/share/i18n"; do
      [ -s "$D/layouts" ] && LAYOUTS="$D/layouts" && break
    done
    if [ "$LAYOUTS" != "" ]; then
      for MP in $MAPS; do
        M=$(echo $MP| tr '1' '-'| cut -d'-' -f1)
        M=$(xmap $M)
        M=$(grep "^[[:blank:]]*$M " "$LAYOUTS"| sed -e 's/^[[:blank:]]*[a-z-]*[ ]*//')
        echo -n "$MP"
        [ "$M" != "" ] && echo " ($M)" || echo " ."
      done
    else
      for MP in $MAPS; do
        echo "$MP -"
      done
    fi
}

locale_name() {
	#LANGDATA="$MYDATADIR/languagelist.data"
	#LANGLIST="$MYDATADIR/languagelist"
	COUNTRYLIST="$MYDATADIR/countrycodes.txt"
	LANGBASE=$(keyword "$1"|cut -d'.' -f1)
	L=$(echo $LANGBASE| cut -d'_' -f1)
	C=$(echo $LANGBASE|cut -d'_' -f2 -s)
	[ "$L" != "" ] || return
	if [ -s "$LANGDATA" ]; then
	  LNAME=$(grep "^.:$LANGBASE:" "$LANGDATA"|cut -d':' -f4)
	  [ "$LNAME" != "" ] && echo -n $LNAME && return
	  LNAME=$(grep "^.:$L:" "$LANGDATA"|cut -d':' -f4)
	  echo -n $LNAME
	fi
	[ "$C" = "" ] && return
	[ -s "$COUNTRYLIST" ] || return
	CNAME=$(grep ";$C" "$COUNTRYLIST"|cut -d';' -f1|tr ' ' '%')
	[ "$CNAME" != "" ] && echo -n ",$CNAME"
}
make_language_list() {
  MAINLANGS_LF="en%English"
  if [ -s "$TRANSLIT" ]; then
   if [ -s "$LANGDATA" ]; then
    ALLLANGS=$(cat "$LANGDATA" | cut -d':' -f2,4 | tr ': ' '%%')
    ADDLANGS=$(grep '^[012]' "$LANGDATA"|cut -d':' -f2,4|tr ': ' '%%')
    if [ -s "$LANGS0" ]; then
     MAINLANGS_LF=""
     LANGS=$(grep -v '^[[:blank:]]*#'  $LANGS0|cut -d'#' -f1|tr -d ' ')
     for L in $LANGS;do
      ALINE=$(echo "$ALLLANGS"|grep -w "^$L")
      [ "$ALINE" != "" ] || ALINE=$L
      MAINLANGS_LF="$MAINLANGS_LF
$ALINE"
     done
    fi
   fi
  else
   # Puppy 4.1x and older
   MAINLANGS_LF="en_US%englist,UNITED%STATES"
   ADDLANGS=""
   for L in $(locale -a); do
      ADDLANGS="$ADDLANGS
$L%$(locale_name $L|tr ' ' '%')"
   done
  fi
  #LANGFILES=$(find "$FIRSTSETUP_DATADIR" -type f -name 'languages*' -not -name 'languages0')
  #ADDLANGS=$(cat $LANGFILES| grep -v '^[[:blank:]]*#'|cut -d'#' -f1|tr ' ' '%')
  CJKLANGS=""
  [ "$HAS_JPFONT" ] && CJKLANGS="ja%日本語"
  if [ "$HAS_ZHFONT" != "" -o "$HAS_UNIFONT" != "" ]; then
	CJKLANGS="ja%日本語
ko%한굴
zh_CN%簡体中文
zh_TW%繁體中文"
  fi
  [ "$HAS_UNIFONT" -o "$LIST_ALL" != "" ] && ADDLANGS="$ALLLANGS"
  ADDLANGS=$(echo "$ADDLANGS"| sort|uniq)
  MAINLANGS_LF="$MAINLANGS_LF
$CJKLANGS
$ADDLANGS"
  # remove unavailable locales
  if [ "$CJKLANGS" != "" ] && [ -z "$LIST_ALL" ]; then
   if ! locale -a | grep 'ko_KR' && [ ! -s "$TRANSLIT_ko" ]; then
      MAINLANGS_LF=$(echo "$MAINLANGS_LF" | grep -vw '^ko')
   fi
   if ! locale -a | grep 'zh_CN' && [ ! -s "$TRANSLIT_zh_CN" ]; then
      MAINLANGS_LF=$(echo "$MAINLANGS_LF" | grep -vw '^zh_CN')
   fi
  fi
  
  if [ "$CHOOSELOCALE" ] && [ -z "$LIST_ALL" ]; then
   MAINLANGS_LF="$MAINLANGS_LF
more..."
  fi
}
lang_check() {
  NEWLANG=""
  PENDING=""
  LANGBASE=$(keyword "$MAINLANG"|cut -d'.' -f1) # ex. 'ja_JP'
  L=$(echo $LANGBASE| cut -d'_' -f1)            # ex. 'ja'
  C=$(echo $LANGBASE|cut -d'_' -f2 -s)          # ex. 'JP'
  debug "LANGBASE=$LANGBASE"
  utf8required $LANGBASE && U="yes" || U=""
  debug "ISOMAP=$ISOMAP"
  [ "$U" != "" ] && UTF="true"
  # translations
  LANGNOW=$LANG
  LANG=$(locale -a 2>/dev/null| grep "^$LANGBASE" | head -n -1)
  _Main_language=$(gettext "Main language")
  _ChooseMain=$(gettext "Choose main language")
  _ChooseDetail=$(gettext 'Choose the language detail.')
  _MarkHere=$(gettext 'Mark here on to support unicode encoding.')
  _Recomended=$(gettext 'Recommended')
  _UTF_8_encoding=$(gettext 'UTF-8 encoding')
  _APPLYING=$(gettext "Applying changes.")
  LANG=$LANGNOW
  if [ "$C"  ]; then
    BASES=$LANGBASE
  else
   if [ -s "$SUPPORTED" ];then
    BASES=$(grep "^${L}_" "$SUPPORTED"|cut -d' ' -f1|cut -d'.' -f1| uniq)
   else
     BASES=$(locale -a | grep "^${L}_") || BASES="en_US"  # 30jan11
   fi
  fi
  # count choices
  N=0
  [ "$BASES" != "" ] && N=$(echo "$BASES"| wc -l)
  #if [ $N -eq 0 ]; then
    #   errmsg "$(gettext 'Languege not supported'): $MAINLANG"
    #   return 1
  #fi
  if [ $N -eq 1 ]; then
      LANGBASE=$BASES
      LANGCHOICE="<text><label>$LANGBASE $(locale_name $LANGBASE| tr '%' ' ')</label></text>"
      LANGNAME=$LANGBASE
  else
	  echo "$BASES"|grep -q "^$LANGBASE[. ]" || LANGBASE=$(echo "$BASES"|grep -m1 "_$REGION")	# v2.0
      [ "$LANGBASE" = "" -a -s "$LANGLIST" ] && LANGBASE=$(grep "^$L;" "$LANGLIST"|head -n 1|cut -d';' -f5|cut -d'.' -f1)
        BASE_NAMES=""
        [ "$LANGBASE" != "" ] && BASE_NAMES="$LANGBASE%$(locale_name $LANGBASE|tr ' ' '%')"
        for B in $BASES;do
			C=$(echo $B|cut -d'_' -f2 -s)
			BASE_NAMES="$BASE_NAMES
$B%$(grep ";$C" "$COUNTRYLIST"|cut -d';' -f1|tr ' ' '%')"
        done
        LANGCHOICE="<combobox tooltip-text=\"$_ChooseMain\"><variable>LANGNAME</variable>
$(make_combo - $BASE_NAMES)
</combobox>"
 	    #SETLANG=$(locale -a|grep "^${L}_"| tail -n 1)
 	    #LANGORG=$LANG
 	    #[ "$SETLANG" != "" ] && LANG=$SETLANG
  fi
  CHECKUTF8=""
  if [ "$U" = "" ]; then
          if [ "$L" = "en" ]; then
            RECOMMEND=""
          else
            #UTF="true"
            RECOMMEND="<text><label>($_Recomended)</label></text>"
          fi
          CHECKUTF8="<hbox><checkbox tooltip-text=\"$_MarkHere\"><label>$_UTF_8_encoding</label>
<variable>UTF</variable><default>$UTF</default></checkbox>$RECOMMEND</hbox>"
  fi
  #if [ "$CHECKUTF8" != "" -o $N -gt 1 ]; then
  if [ $N -gt 1 ]; then	# v2.0.9
        DIALOG="<window title=\"$TITLE\" $TITLEICON><vbox>
        <text><label>$_ChooseDetail</label></text>
<hbox>
<pixmap tooltip-text=\"$_Main_language\" icon_size=\"2\" ><input file stock=\"gtk-italic\"></input></pixmap>
$LANGCHOICE
</hbox>
$CHECKUTF8
 <hbox><button ok></button></hbox>
</vbox></window>"
        waitsplash stop
        eval $(gtkdialog3 -p DIALOG -c || echo "$DIALOG">&2)
        waitsplash start $_APPLYING
        #echo "$EXIT">&2
        #LANG=$LANGORG
        [ "$EXIT" = "OK" ] || return 1
        LANGBASE=$(keyword $LANGNAME|cut -d'.' -f1)
        #echo "$LANGBASE">&2
        [ "$LANGBASE" != "" ] || return 1
        #waitsplash start $_APPLYING
  fi
  #LL=$(echo "$MAINLANGS_LF"| grep -w "$LANGBASE")
  LL=$(echo "$ALLLANGS"|grep -w "^$LANGBASE")
  [ "$LL" != "" ] || LL=$(echo "$ALLLANGS"|grep -w "^$L")
  [ "$LL" != "" ] || LL=$LANGBASE
  # needs to use unicode?
  [ "$U" != "" ] && UTF="true"
  [ "$UTF" = "true" ] && UTF8="$DOTUTF8" || UTF8=""
  [ "$UTF8" != "" ] && LANGBASE=$(echo $LANGBASE| cut -d'@' -f1) # remove @euro, etc.
  PENDING=""
  if [ "$UTF8" != "" -a ! -d /usr/lib/locale/$LANGBASE.utf8 ]; then
    case "$LANGBASE" in
      ja_JP) PENDING="$TRANSLIT_ja";;
      ko_KR) PENDING="$TRANSLIT_ko";;
      zh_CN) PENDING="$TRANSLIT_zh_CN";;
    esac
    [ "PENDING" != "" ] && [ -f "$PENDING" ] && PENDING=""
    if [ "$PENDING" != "" ]; then
      MSG=$(printf "$(gettext  "'%s' is not supported.")" "$LANGBASE" )
      MSG2=$(printf "$(gettext "'%s' is missing.")" "$PENDING")
      MSG="$MSG($MSG2)"
      errmsg "$MSG"
      return 1
    fi
  fi
  NEWLANG="$LANGBASE$UTF8"
  return 0
}
which_isomap() {
  [ "$1" ] && L=$(echo $1| cut -d'.' -f1)
  #MYDATADIR=/usr/share/i18n
  #SUPPORTED=/usr/share/i18n/SUPPORTED
  ISOMAP=""
  [ -s "$SUPPORTED" ] && ISOMAP=$(grep "^$L[A-Z_]* [ ]*ISO-8859-" $SUPPORTED| head -n1| tr -s ' '| cut -s -f2 -d' ')
  debug "ISOMAP=$ISOMAP"
  [ "$ISOMAP" ] || return
  if [ "$ISOMAP" != "ISO-8859-1" ]; then	# ISO-8859-1 maybe builtin the kernel
    [ -s "$MYDATADIR/charmaps/$ISOMAP" ] || [ -s "$MYDATADIR/charmaps/$ISOMAP.gz" ] ||return
    modprobe -l nls_iso$(echo $ISOMAP| cut -s -f2- -d'-') >/dev/null || return
  fi
  echo $ISOMAP
}
utf8required() {
  # needs to use unicode?
  if [ -s "$SUPPORTED" ];then
    ISOMAP=$(which_isomap $1)
    [ -z "$ISOMAP" ]
    return
  else
    locale -a | grep -qx "^$1[^.]*" || return
    locale -a | grep -qi "^$1.*utf"
    return
  fi
}
make_localedef() {	# v1.9.9
  [ "$1" ] && NEWLANG=$1
  L=$(echo "$NEWLANG"| cut -d'.' -f1)
  U=$(echo "$NEWLANG"| cut -s -d'.' -f2)
  [ "$U" ] && U=$DOTUTF8
  ISOMAP=$(which_isomap $L)	#v2.0.9
  if [ -z "$U" ] ; then
    CHARMAP=$ISOMAP	#v2.0.9
    debug "CHARMAP=$CHARMAP"
    [ -z "$CHARMAP" ] && U=$DOTUTF8 && debug "Forced UTF-8 encoding."
  fi
  NEWLANG=$L$U
  [ -z "$CHARMAP" ]  && CHARMAP="UTF-8"
  [ -f /usr/share/i18n/locales/$L ] || return
  if [ "$U" != "" ]; then
    modprobe nls_utf8 || return
  else
	# ISO-8859-1 maybe builtin the kernel
    modprobe nls_iso$(echo $CHARMAP| cut -f2- -d'-') || [ "$CHARMAP" = "ISO-8859-1" ] || return
  fi
  locale -a 2>/dev/null | grep -qx $(echo $L$U|sed -e 's/UTF-8/utf8/') && return 
   [ "$CLI" ] && echo -n "Building localedef..." >&2 #|| waitsplash start
   if [ "$U" != "" ]; then
     localedef -f UTF-8 -i $L --no-archive $L.utf8 > /dev/null || return
   else
     localedef -f $CHARMAP -i $L --no-archive $L > /dev/null || return
   fi
   [ "$CLI" ] && echo "Done." >&2
   true
}
set_locale() {	# v1.9.9
 [ "$1" ] && NEWLANG=$1
 #NEWLANG=$(keyword $NEWLANG)
 NOWLANG=$LANG; [ "$LC_ALL" ] && NOWLANG=$LC_ALL
 echo "'$NOWLANG' --> '$NEWLANG'" >&2
 [ "$NEWLANG" = "$NOWLANG" ] && locale -a | grep -qx $(echo $NEWLANG|sed -e 's/UTF-8/utf8/') && return
 [ "$PENDING" = "" ] || return
 if [ "$CHOOSELOCALE" != "" ]; then
   #waitsplash stop
   chooselocale "$NEWLANG"
   LANG="$NEWLANG" 
   [ "$LC_ALL" ] && LC_ALL="$NEWLANG" || true
   return
 fi
 CHARMAP=""	# set by make_localedef
 ISOMAP=""	#v2.0.9
 make_localedef || return

 # codepage
 CODEPAGE=""
 ISONUM=""
 [ -s "$SUPPORTED" ] && ISONUM=$(grep "^$L[A-Z_]* [ ]*ISO-8859-" $SUPPORTED| head -n1| tr -s ' '| cut -s -f2 -d' '| cut -s -f3 -d'-')
 case "$ISONUM" in
 1) [ "${NEWLANG:0:2}" = "en" ] && CODEPAGE="437" || CODEPAGE="850"
 ;;
 2) CODEPAGE="852";;
 4) CODEPAGE="775" #Baltic
 ;;
 5) #Cyrillic
	[ "${NEWLANG:0:2}" = "ru" ] && CODEPAGE="866" || CODEPAGE="855"
 ;;
 6) CODEPAGE="720"	#Arabic
 ;;
 7) CODEPAGE="737"	#Greek
 ;;
 8) CODEPAGE="862"	#Hebrew
 ;;
 9) CODEPAGE="857"	#Turkish
 ;;
 15) CODEPAGE="858"	#euro
 ;;
 esac
 [ "$CODEPAGE"  ] && modprobe nls_cp$CODEPAGE || CODEPAGE=""
 [ "$CODEPAGE" = "437" ] && CODEPAGE=""	# cp437 is the default
 echo -n "$CODEPAGE" > /etc/codepage
 # end of codepage setting

 # fontmap
 if [ "$CONSOLE_FONT_SUPPORT" ]; then
   FONTMAP="" #FONTMAP=lat1-12.psfu
   if [ "$ISONUM" ]; then
     case "$ISONUM" in
     1)	FONTMAP="" ;;
     2) FONTMAP="lat2-12.psfu"
           [ -s $CONSOLEFONTSDIR/${FONTMAP}* ] || FONTMAP="LatGrkCyr-8x16.psfu";;
     6|8)	FONTMAP="LatArCyrHeb-16.psfu" ;;
     *) FONTMAP="LatGrkCyr-8x16.psfu" ;;
     esac
   fi
   debug "$CONSOLEFONTSDIR/${FONTMAP}.gz"
   [ "$FONTMAP" ] && [ ! -s "$CONSOLEFONTSDIR/${FONTMAP}.gz" ] && FONTMAP="" 
   OLDFONTMAP=$(cat /etc/fontmap 2>/dev/null)
   if [ "$FONTMAP" != "$OLDFONTMAP" ]; then
     echo -n  "$FONTMAP" > /etc/fontmap
     if [ -z "$DISPLAY" ]; then	# only on console (without X)
      if [ "$LOAD_CONSOLEFONT" ];then
        $LOAD_CONSOLEFONT
      else
       [ "$FONTMAP" ] || FONTMAP="lat1-12.psfu"
       case "$FONTMAP" in
       LatArCyrHeb*) setfont $CONSOLEFONTSDIR/${FONTMAP}.gz -C /dev/tty1 ;;
       *) zcat $CONSOLEFONTSDIR/${FONTMAP}.gz | loadfont;;
       esac
      fi
     fi
   fi
 fi

 # profile
 rm -f /tmp/profile
 sed -e "s/^[[:blank:]]*LANG=.*\$/LANG=$NEWLANG/g" /etc/profile > /tmp/profile
 [ -s /tmp/profile ] && mv -f /tmp/profile /etc/profile
 LANG="$NEWLANG"
 [ "$LC_ALL" ] && LC_ALL="$NEWLANG" || true
}
set_timezone() {	# v1.9.9
  [ "$1" ] && NEWTZONE=$1
  [ "$DISPLAY" ] && which xset &>/dev/null && xset s noblank s noexpose -dpms  # 30jan11: avoid the screen go to blank
  if [ "$TIMEZONESET" != ""  ] ; then
    timezone-set $NEWTZONE
  else
    rm -f /etc/localtime
    ln -s /usr/share/zoneinfo/$NEWTZONE /etc/localtime
    export TZ=$NEWTZONE
	debug "hwclock --hctosys --${HWCLOCKTIME}"
    hwclock --hctosys --${HWCLOCKTIME} 
    # correct time stamp
    touch /etc/rc.d/BOOTCONFIG
  fi
}

waitsplash() {
  [ "$XPID" != "" ] && kill $XPID >/dev/null 2>&1
  XPID=""
  #LANG=$LANGORG	# recover lang environment
  [ "$1" = "start" -o "$1" = "progress" ] || return
  PBAR=""
  if [ "$1" = "progress" ]; then
    PBAR="<progressbar>
      <input>while [ -f $COUNTFILE ]; do tail -n 1 $COUNTFILE; sleep 1; done</input>
     </progressbar>"
  fi
  shift	# remove $1
  S=$(gettext "Wait a moment ...")
  DIALOG="<window title=\"$TITLE\" $TITLEICON><vbox>
  <hbox>
  <pixmap><input file>$ICONS/mini-clock.xpm</input></pixmap>
  <text><input>echo -e -n \"$* $S\"</input></text>
  </hbox>
  $PBAR
  </vbox></window>"
  gtkdialog3 -p DIALOG  -c >/dev/null &
  XPID=$!
  #LANG=C	# to be faster
}

errmsg () {
  #echo $0 $@ >&2
  [ "$XPID" != "" ] && kill $XPID >/dev/null 2>&1
  TIMEOUT=0
  SPLASH=""
  BUTTONS="<hbox><button ok></button></hbox>"
  case "$1" in
   error)  M="error";shift;;
   warning) M="warning";shift;;
   info) M="info"; shift;;
   yesno) M="question"; shift
     BUTTONS="<hbox><button yes></button><button no></button></hbox>"
   ;;
   okcancel) M="question"; shift
     BUTTONS="<hbox><button ok></button><button cancel></button></hbox>"
   ;;
   custom) BUTTONS=""; shift;;
   splash) M="info"; BUTTONS=""; SPLASH="yes"; shift;;
   timeout) M="info";shift
            if echo "$1" | grep -q '^[0-9][0-9]*$'; then
              TIMEOUT=$1; shift
            else
              TIMEOUT=10
            fi
            [ $TIMEOUT -lt 5 ] && BUTTONS=""
            ;;
  esac
  [ "$MARK" != "" ] || MARK=$M
  ERRMSG="$*"
  [ "$ERRMSG" = "" ] && ERRMSG=$(gettext "An error occured")
  DIALOG="<window title=\"$TITLE\" $TITLEICON><vbox>
    <hbox>
    <pixmap  icon_size=\"5\"><input file stock=\"gtk-dialog-$MARK\"></input></pixmap>
    <text><input>echo -e -n \"$ERRMSG\"</input></text>
    </hbox>
    $CUSTOM
	$BUTTONS
	</vbox></window>"
  MARK=""
  CUSTOM=""
  if [ $TIMEOUT -eq 0 -a "$SPLASH" = "" ]; then
   RET=$(gtkdialog3 -p DIALOG -c || echo "$DIALOG" >&2)
   EXIT=abort
   eval "$RET"
   case $EXIT in
   yes|OK) return 0
   esac
   return 1
  elif [ "$SPLASH" != "" ]; then
    rm -f $TMPFILE
    gtkdialog3 -p DIALOG -c >$TMPFILE &
    XPID=$!
  else
   rm -f $TMPFILE
   gtkdialog3 -p DIALOG -c >$TMPFILE &
   XPID=$!
   for I in $(seq 1 $TIMEOUT);do
     # 28feb10 to see exact PID
     ps | grep -qw "^[[:blank:]]*$XPID" || break
     sleep 1
   done
   [ "$XPID" != "" ] && kill $XPID && XPID=""
   RET=$(cat $TMPFILE)
   rm -f $TMPFILE
  fi
}

size_rate() {
  echo -n $1
  N=$(echo $2|tr -dc '0-9.')
  [ "$N" == "" -o "$N" = 0 ] && return
  echo -n " -r $N"
}
video_driver() {
  # Barry and shinobar #v2.1 (jemimah and shinobar)
  VIDEODRIVER=""
  XSERVER=$(readlink "$(which X)")
  [ "$XSERVER" = "Xvesa" ] && VIDEODRIVER="Xvesa" && echo "$VIDEODRIVER" && return
  LOADED="`grep -o 'Loading .*xorg/modules/drivers/.*_drv.so' /var/log/Xorg.0.log | rev | cut -f 1 -d '/' | rev | cut -f 1 -d '_' | sort -u`" #111027 fix multiple hits.
  UNLOADED="`grep 'Unload' /var/log/Xorg.0.log | tr -d '"' | rev | cut -f1 -d' ' | cut -f1 -d'/' | rev | cut -f1 -d'_'| sort -u`"
  # ' fix geany highlight
  if [ "$UNLOADED" ]; then
    # remove unloaded
    # 'for' loop instead of 'grep -f' to be free from the busybox version
    for D in $UNLOADED; do
      LOADED=$(echo "$LOADED" | grep -vw "$D")
    done
  fi
  VIDEODRIVER=$(echo "$LOADED"| tail -n1 )	# precaution
 [ "$VIDEODRIVER" = "" ] && VIDEODRIVER="undetermined" # we tried!
  echo "$VIDEODRIVER"
}
check_newreso() {
	MSG=$(gettext "Press 'OK' if you can read this.")
	STEP=6	# timeout is x10sec
    fontsize="x-large" # small, medium, large, x-large
    DIALOG="<window title=\"$TITLE\" $TITLEICON><vbox>
    <text use-markup=\"true\"><label>\"<span size='${fontsize}'>$MSG</span>\"</label></text>
	<progressbar><input>for i in \$(seq 0 10 100); do echo \$i; sleep $STEP; done;echo 100</input>
	  <label>$(gettext 'Or, it will be canceled in 60 seconds.')</label>
      <action type=\"exit\">TIMEOUT</action></progressbar>
	<hbox><button ok></button> <button cancel></button></hbox>
	</vbox></window>" 
	  eval $(gtkdialog3 -p DIALOG -c || echo "$DIALOG">&2)
	  if [ "$EXIT" = "OK" ]; then
	    echo $NEWINDEX > /etc/xrandrindex
	    return 0
	  fi
	    rm -f /etc/xrandrindex
	    DIMLAST=$(echo $SCREENLAST|cut -d'/' -f1|tr -dc '0-9x')
	    #RATELAST=$(echo $SCREENLAST|cut -d'/' -f2|tr -dc '0-9.')
	    OLDRATE=$RATELAST
	    OLDINDEX=$(size_rate $DIMLAST $OLDRATE)
	   debug "xrandr -s $OLDINDEX"
	    xrandr -s $OLDINDEX #restore to what it was before.
	    return 1
}
change_xrandr() {
	NEWDIM=$(echo $NEWSCREEN|cut -d'/' -f1|tr -dc '0-9x')
	#NEWRATE=$(echo $NEWSCREEN|cut -d'/' -f2|tr -dc '0-9.')
    #XRESOELINES=$(xrandr -q| tr -s ' ' | grep '^ [12689]')
    NEWRATE=60
    NRATE=60
    DRATE=1000
    #debug ":$NEWDIM:"
	for W in $(echo "$XRESOELINES"| grep "^ $NEWDIM"); do
	  #debug $W
	  echo $W| grep -q 'x' && continue	# 5jan11 skip dimentions
	  W=$(echo $W| tr dc '0-9.')
	  N=$(echo $W| cut -d'.' -f1)
	  [ "$N" != "" ] || continue
	  D=$(($N - $NRATE))
	  [ $D -lt 0 ] && D=$((0 - $D))
	  [ $D -lt $DRATE ] && DRATE=$D && NEWRATE=$W
	  #debug "$W, $N, $D, $DRATE, $NEWRATE"
	done
	[ "$NEWRATE" != "" ] || NEWRATE=60  # precaution
	NEWINDEX=$(size_rate $NEWDIM $NEWRATE)
	debug "xrandr -s $NEWINDEX"
	MSG="$(gettext 'About to test new screen resolution'): $NEWDIM @${NEWRATE}Hz\\n$(gettext 'Click 'OK', then the screen will be black out for a while, and comes back with new resolution. If the new resolution does not work, wait 60 seconds or press CTRL-ALT-BACKSPACE.')"
    DIALOG="<window title=\"$TITLE\" $TITLEICON><vbox>
    <hbox>
    <pixmap  icon_size=\"5\"><input file stock=\"gtk-dialog-warning\"></input></pixmap>
    <text><input>echo -e -n \"$MSG\"</input></text>
    </hbox>
	<hbox><button ok></button> <button cancel></button></hbox>
	</vbox></window>"
	eval $(gtkdialog3 -p DIALOG -c || echo "$DIALOG">&2)
	[ "$EXIT" = "OK" ] || return 1
	if xrandr -s $NEWINDEX ; then
	  check_newreso && return 0 || return 1
	else
	  MSG="$(gettext 'Failed to change the resolution or the refresh rate'): $NEWDIM @${NEWRATE}Hz\n$(gettext 'Will you do another try with'): $NEWDIM @60Hz?"
      MARK=error
	  if errmsg okcancel "$MSG"; then
	     NEWRATE=60
	     NEWINDEX=$(size_rate $NEWDIM $NEWRATE)
	debug "xrandr -s $NEWINDEX"
	    if xrandr -s $NEWINDEX ; then
	       check_newreso && return 0 || return 1
	    else
	       MSG="$(gettext 'Failed to change the resolution or the refresh rate'): $NEWDIM @${NEWRATE}Hz."
	       errmsg "$MSG"
	       return 1
	    fi
	  fi
	  return 1
	fi
}

yesno_x() {
 debug "RESTARTX=$RESTARTX"
 ICON=mini-x.xpm
 MSG=$(gettext "The X-server needs to restart to complete changes.")
 if [ "$RESTARTX" = "full" ]; then
   ICON=mini-turn.xpm
   MSG=$(gettext "Your PC needs to restart to complete changes.")
   if [ "$PUPMODE" = "5" ]; then
     MSG="$MSG $(gettext 'And you also need to make 'pupsave' at shutdown.')"
   fi
 fi
 MSG="$MSG $(gettext "Press 'Yes' to restart now, 'No' for not now.")"
 if [ "$RESTARTX" = "xorgwizard" ]; then
   MSG=$(gettext "You need to exit graphic mode and go to text mode to run 'XorgWizard'. Press 'Yes' to exit now, 'No' for not now.")
 fi
 # v1.9.5: drive icons to be refreshed after restart
 case "$RESTARTX" in
  tzone|keyboard|locale) :;;
  *) echo "ICONWIPE" > /tmp/pup_event_icon_change_flag
     mkdir -p /var/local
     cp -f /tmp/pup_event_icon_change_flag /var/local	# v1.9.9: see http://bkhome.org/blog/?viewDetailed=02684
     ;;
 esac
 export DIALOG="<window title=\"$TITLE\" $TITLEICON><vbox>
   <hbox><pixmap><input file>$ICONS/$ICON</input></pixmap>
<   <text><input>echo -en \"$MSG\"</input></text>
   </hbox>
   <hbox>
   <button yes></button>
   <button no></button>
   </hbox>
   </vbox></window>"
   waitsplash stop
   eval $(gtkdialog3 -p DIALOG -c)
   if [ "$EXIT" != "Yes" ] ;then
     if [ "$RESTARTX" = "xorgwizard" ]; then
       MSG=$(gettext "To run 'XorgWizard', Menu > Setup > Xorg Video Wizard.")
       errmsg info "$MSG"
     fi
     return 1
   fi
   [ "$RESTARTX" = "full" ] && exec wmreboot
  NEXTWM="`cat /etc/windowmanager`"
  echo -n "$NEXTWM" > /tmp/wmexitmode.txt
  touch /tmp/pup_event_icon_change_flag
  rm -f /tmp/Xflag #prevent endless restarts. see /usr/bin/xwin.
  rm -rf /tmp/.X0-lock
   if [ "$RESTARTX" = "xorgwizard" ]; then
     #120126 01micko # v2.0.9 shinobar: maybe done in /root/Startup/fisrtrun but precaution
     if [ -s /etc/DISTRO_SPECS ] && grep -q '^[[:space:]]*DISTRO_XORG_AUTO=.*yes' /etc/DISTRO_SPECS; then
       rm -f /tmp/DISTRO_SPECS
       grep -v 'DISTRO_XORG_AUTO=' /etc/DISTRO_SPECS > /tmp/DISTRO_SPECS
       echo "#DISTRO_XORG_AUTO='yes'" >> /tmp/DISTRO_SPECS
       [ -s /tmp/DISTRO_SPECS ]  &&  mv -f /tmp/DISTRO_SPECS /etc/DISTRO_SPECS
     fi
     mv -f /etc/X11/xorg.conf /etc/X11/xorg.conf.prev 2>/dev/null
     [ "$HAS_XVESA" = "yes" ] && ln -sf Xvesa "${XPATH}"
     #NEXTWM="`cat /etc/windowmanager`"
     echo -n "$NEXTWM" > /etc/windowmanager #this makes change permanent.
     #echo -n "$NEXTWM" > /tmp/wmexitmode.txt
     sync
     exec killall X
   fi
  #if [ "$RESTARTX" = "Xorg" ]; then
  #  mv -f /etc/X11/xorg.conf /etc/X11/xorg.conf.prev 2>/dev/null
  #  [ -e /usr/bin/Xvesa ] && ln -sf Xvesa "$XPATH"
  #fi
  # ROX-Filer need to restart
  #for PID in $(pidof ROX-Filer); do
  #  kill $PID
  #done
  sync
  restartwm
  exec killall X
}

if [ "$COUNTRYSET" != "" ]; then
 # supported languages
 MAINLANGS_FILE="$MYDATADIR/mainlangs"	# v1.9.5
 SUPPORTED="/usr/share/i18n/SUPPORTED"
 LANGDATA="$MYDATADIR/languagelist.data"
 LANGLIST="$MYDATADIR/languagelist"
 COUNTRYLIST="$MYDATADIR/countrycodes.txt"
 LANGS0="$MYDATADIR/shortlists"	# top languages
 TRANSLIT="/usr/share/i18n/locales/translit_cjk_compat"
 TRANSIT_ja="/usr/share/i18n/locales/translit_cjk_variants"
 TRANSLIT_ko="/usr/share/i18n/locales/translit_hangul"
 TRANSLIT_zh_CN="/usr/share/i18n/locales/iso14651_t1_pinyin"
 # list of languages
 MAINLANGS_LF=""
 F="$MYTMPDIR/mainlangs"
 if [ -s "$MAINLANGS_FILE" ]; then
   F="$MAINLANGS_FILE"
 else
   FONTSTATUS="$HAS_JPFONT:$HAS_ZHFONT:$HAS_UNIFONT"
   if [ "$FONTSTATUS" != "$(cat "$MYTMPDIR/fontstatus")" ] && [ -z "$LIST_ALL" ]; then
     rm -f "$F" 	# expire old language list
     echo -n "$FONTSTATUS" > "$MYTMPDIR/fontstatus"
   fi
 fi
 if [ -s "$F" ]; then
   MAINLANGS_LF=$(cat "$F")
 else
   make_language_list
   echo "$MAINLANGS_LF" > "$MYTMPDIR/mainlangs"
 fi
 MAINLANGS=$MAINLANGS_LF	# replace linefeed to blank
fi

# v1.9.9: commandline interface
# v2.0.9: fix was missing some locales
if [ "$CLI" ]; then
 case $MYBASE in
  chooselocale*)
   if [ "$HELPFLAG" ]; then
     echo "Usage: $MYBASE [--debug] [cli] [LOCALE|quiet]"
     exit
   fi
   PLANG=$(grep '^[[:space:]]*LANG=' /etc/profile 2>/dev/null| tail -n1| cut -f2 -d'=' | cut -f1 -d'#')
   [ "$PLANG" ] && LANG=$PLANG
   [ -z "$LANG" -o "$LANG" = 'C' ] && LANG="en_US"
   DEF_UTF=$(echo $LANG| cut -s -d'.' -f2)  
   BASELANG=$(echo $LANG| cut -d'.' -f1)      # ex. 'ja_JP'
   if [ "$PARAM2" ];then 
    #LANG already chosen. ex: de_DE (.UTF-8 part is specified by UTF8)
    #rc.country calls 'chooselocale cli quiet'
    [ "$PARAM2" = "quiet" ] && COMBO_LOCALE=${BASELANG} || COMBO_LOCALE=$PARAM2
   else
    DIALOG_TABLE=""
    for F in dialog_table dialog_table_x dialog_table_cli; do
      [ -s "$MYDATADIR/$F" ] && DIALOG_TABLE="$MYDATADIR/$F" && break
    done
    [ -z "$DIALOG_TABLE" ] && echo "Error: dialog_table is missing." && exit 1
    if [ "$(basename "$DIALOG_TABLE")" = "dialog_table_x" ];then
      CHOICES=$(cat "$DIALOG_TABLE"|rev|cut -f2- -d' '|rev| tr '\n' ' ')
    else
      CHOICES=$(cat "$DIALOG_TABLE" | tr '\n' ' ')
    fi
    LOCALEDLG="dialog --aspect 10 --title \"Country setup\" --default-item ${BASELANG} --menu \"The locale setting provides money, date and font localization for your country. The current choice is ${BASELANG}. Make a choice to suit your country...\" 0 0 0 ${CHOICES}"
    eval $LOCALEDLG 2>${MYTMPDIR}/chooselocale-choice
    [ $? -ne 0 ] && exit
    COMBO_LOCALE="`cat ${MYTMPDIR}/chooselocale-choice | head -n 1`"
   fi
   CHECK_UTF8=$DEF_UTF #dialog box does not have a UTF-8 checkbox.
   NEWLANG=$COMBO_LOCALE
   echo $NEWLANG| grep -q '@' && CHECK_UTF8=""
   [ "$CHECK_UTF8" ] && NEWLANG=$COMBO_LOCALE$DOTUTF8	# $COMBO_LOCALE.$CHECK_UTF8
    [ "$LANG" = "$NEWLANG" ] && exit 
   set_locale && ERRFLAG="" || ERRFLAG="yes"
   [ "$ERRFLAG" ] && echo "Failed." >&2 || \
   echo -e "New locale is '$LANG'. You need to type \"\\033[1;31mexit\\033[0;39m\" to apply the change."
   exit
  ;;
  timezone-set*)
   if [ "$HELPFLAG" ]; then
     echo "Usage: $MYBASE [--debug] [cli] [TIMEZONE]"
     echo "NOTE: TIMEZONE may be 'JST', 'Asia/Tokyo', 'Etc/GMT-9', 'GMT+9'.
      Thay are all the same. Remark: 'GMT+9' is equal to 'Etc/GMT-9'."
     exit
   fi
   TZ="`readlink /etc/localtime | sed -e 's%/usr/share/zoneinfo/%%'`"
   if [ "$PARAM2" ]; then
     NEWTZONE=$(tzone_check $PARAM2)
   else
     TZONE=$(echo $TZ | sed -e 's%^Etc/%%')
     TZONE=$(tzone_check $TZONE)
     DEF_TIMEZONE=$(echo $TZONE | sed -e 's%^Etc/%%')
     #debug $DEF_TIMEZONE; exit
     ZONECHOICES_CLI=$(grep -v '%' /usr/share/i18n/timezones| grep -v '^$'| sed -e 's/$/ ./')	# add ' .' at tail for dummy, remove null
     ZONECHOICES_CLI="$ZONECHOICES_CLI
$(grep '%' /usr/share/i18n/timezones| tr '%' ' ')"
     ZONECHOICES_CLI=$(echo $ZONECHOICES_CLI)	#| tr '\n' ' '
     ZONEDLG="dialog --aspect 10 --title \"Puppy timezone selector\" --default-item $DEF_TIMEZONE --menu \"Please choose your timezone. If a city/region/country in your timezone is not listed, choose a GMT<number>\" 0 0 0 ${ZONECHOICES_CLI}"
     #debug "$ZONEDLG"
     eval $ZONEDLG 2>${MYTMPDIR}/zoneretval
     [ $? -ne 0 ] && exit
     TZONE="`cat ${MYTMPDIR}/zoneretval`"
     NEWTZONE=$(tzone_check $TZONE)
   fi
   # hardware clock set to
   HWCLOCKTIME="localtime"
   [ -f /etc/clock ] && grep -q '^[^#]*utc' /etc/clock && HWCLOCKTIME="utc"
   [ "$HWCLOCKTIME" = "utc" ] && UTC="true" || UTC="false"
   CHECK_UTC="$HWCLOCKTIME" #dialog box does not have a UTC checkbox.
   OLDTZ=$TZ
   set_timezone || echo "Failed." >&2
   debug "$OLDTZ --> $TZ"
   [ "$TZ" = "$OLDTZ" ] && exit
   echo -e "New Timezone is '$TZ'. You need to type \"\\033[1;31mexit\\033[0;39m\" to apply the change."
   exit
  ;;
  *) echo "$MYBASE cannot run without X." >&2
   exit
  ;;
 esac
 exit	# precaution
fi

HOSTNAMEORG=""
SCREENORG=""
DEPTHORG=""
RATEORG=""
XVESAORG=""
DEPTHORG=""
LOCALEORG=""
TZONEORG=""
UTCORG=""
KMAPORG=""
[ "$CONFIGFILE" != "" ] && rm -f $CONFIGFILE
RETRY="yes"
while [ "$RETRY" != "" ] ; do  #  long loop
 if [ "$COUNTRYSET" != "" ]; then
  # locale
  PLANG=$(grep '^[[:space:]]*LANG=' /etc/profile 2>/dev/null| tail -n1| cut -f2 -d'=' | cut -f1 -d'#')
  [ "$PLANG" ] && LANG=$PLANG
  [ -z "$LANG" -o "$LANG" = 'C' ] && LANG="en_US"
  #debug $LANG
  echo $LANG| grep -qi '\.utf' && UTF="true" || UTF="false"
  LANGBASE=$(echo $LANG| cut -d'.' -f1)      # ex. 'ja_JP'
  L=$(echo $LANGBASE| cut -d'_' -f1)         # ex. 'ja'
  REGION=$(echo $LANGBASE|cut -d'_' -f2 -s)  # ex. 'JP'
  MAINLANG="$LANGBASE%$(locale_name "$LANGBASE")"
  #[ "$MAINLANG" != "" ] || MAINLANG=$(echo "$ALLLANGS"|grep -w "^$L")
  #[ "$MAINLANG" != "" ] || MAINLANG=$LANG
  SAMELANG=$(echo "$MAINLANGS_LF"| grep "^${LANG:0:2}"| head -n 1)
  MAINLANGCHOICE=$(make_combo - $(echo $MAINLANG|tr ' ' '%') $SAMELANG $MAINLANGS)
  OLDLANGBASE=$LANGBASE
  OLDUTF=$UTF

  # timezone
  JST="JST%Japan"
  [ "$HAS_JPFONT" ]  && JST="JST%日本標準時"
  tzone_check $TZONE >/dev/null || TZONE=""
  #TZONEORG=""
  if [ -L /etc/localtime ]; then
    TZONENOW=$(readlink /etc/localtime|sed -e 's,/usr/share/zoneinfo/,,' -e 's,Etc/,,')
    case "$TZONENOW" in
    UTC) TZONENOW="UTC%Universal%Time" ;;
    Asia/Tokyo) TZONENOW="$JST";;
    GMT*) TZONENOW=$(swapsign $TZONENOW);;
    esac
  fi
  #echo "$TZONENOW" >&2
  [ "$TZONENOW" != "$TZONE" ] && TZONE="$TZONENOW"
  for F in "$MYDATADIR/timezones" "$MYTMPDIR/timezones"; do
  [ -s "$F" ] && TZONES=$(cat "$F") && break
  done
  if [ "$TZONES" = "" ]; then
    make_limezone_list
    echo "$TZONES" > "$MYTMPDIR/timezones"
  fi
  if [ "$HAS_JPFONT" ]; then
    TZONES="$JST
$TZONES"
  fi
  TZONES="UTC%Universal%Time
$TZONES"
  TZONECHOICE=$(make_combo $TZONE $TZONES)
  # hardware clock set to
  HWCLOCKTIME="localtime"
  [ -f /etc/clock ] && grep -q '^[^#]*utc' /etc/clock && HWCLOCKTIME="utc"
  [ "$HWCLOCKTIME" = "utc" ] && UTC="true" || UTC="false"

  # keymaps
  SYMBOLS=$(ls -1 /etc/X11/xkb/symbols/pc)
  for F in "$MYDATADIR/keymaps" "$MYTMPDIR/keymaps"; do
    [ -s "$F" ] && KMAPS_LF=$(cat "$F") && break
  done
  if [ "$KMAPS_LF" = "" ]; then
   if [ "$KEYMAPSET" = "yes" ]; then
    KMAPS_LF=$(keymap-set --list| tr ' ' '%')
   else
    KMAPS_LF="$(makekmaplist|tr ' ' '%')"
   fi
   echo "$KMAPS_LF" >"$MYTMPDIR/keymaps"
  fi
  if [ "$HAS_JPFONT" ] ; then
    #KMAPS_LF=$(echo  "$KMAPS_LF" | sed -e 's/Japan/日本語キーボード/')
    # jp first
    JPKMAP="jp"
    echo  "$KMAPS_LF" | grep -q '^jp106' && JPKMAP="jp106"
    TOPLINE=$(echo  "$KMAPS_LF" | head -n 1)
    KMAPS_LF=$(echo  "$KMAPS_LF" | tail +2)
    KMAPS_LF=$(echo  "$KMAPS_LF" | grep -v '^jp')
    KMAPS_LF="$JPKMAP%(日本語キーボード)
$KMAPS_LF"
    if ! echo $TOPLINE| grep -q '^jp'; then
      KMAPS_LF="$TOPLINE
$KMAPS_LF"
    fi
  fi 

  KMAP=$(cat /etc/keymap 2>/dev/null | cut -b 1-2)
  KMAPLABEL=$(echo "$KMAPS_LF"| grep "^$KMAP")
  [ "$KMAPLABEL" != "" ] && KMAP="$KMAPLABEL"
  kmap_check $KMAP >/dev/null || KMAP=""
  # 9jan11: us' keymap near the top
  USKMAP=$(echo "$KMAPS_LF"| grep '^us%')
  KMAPS=$KMAPS_LF
  #KEYCHOICE=$(make_combo - $KMAP us%USA $KMAPS)
  KEYCHOICE=$(make_combo - $KMAP $USKMAP $KMAPS)

  NUMLOCKBOX=""
  NUMLOCK=false
  if [ "$NUMLOCKX" != "" ]; then
    [ -x /root/Startup/numlockx ] && NUMLOCK=true 
    NUMLOCKBOX="<hbox><checkbox tooltip-text=\"$(gettext 'Mark here on if you like to set NumLock on at the desktop starts up.')\">
  <label>$(gettext 'Num Lock')</label><variable>NUMLOCK</variable><default>$NUMLOCK</default></checkbox></hbox>"
  fi

  CHECKUTF8="<hbox><checkbox tooltip-text=\""$(gettext "Mark here on to support unicode encoding.")"\"><label>"$(gettext 'UTF-8 encoding')"</label>
  <variable>UTF</variable><default>$UTF</default></checkbox></hbox>"
  #CHECKUTF8=""


  #LANG=$LANGORG
  UTCBOX="<hbox>
<checkbox tooltip-text=\""$(gettext "Mark here on only if the hardware time should be interpreted as UTC.")"\">
<label>$(gettext 'Use UTC Hardware Clock')</label><variable>UTC</variable><default>$UTC</default></checkbox>
</hbox>"
  [ -f /etc/clock ] || UTCBOX=""
  TIMEZONEBOX="<hbox>
<pixmap tooltip-text=\""$(gettext "Time zone")"\"><input file>$ICONS/mini-clock.xpm</input></pixmap>
<combobox tooltip-text=\""$(gettext "Choose local time zone")"\"><variable>TZONE</variable>$TZONECHOICE</combobox>
</hbox>
$UTCBOX"
 COUNTRYFRAME="<frame $COUNTRYM>
 <vbox>
 <hbox>
 <pixmap tooltip-text=\"Main language\" icon_size=\"2\" ><input file stock=\"gtk-italic\"></input></pixmap>
 <combobox tooltip-text=\"Choose main language\"><variable>MAINLANG</variable>$MAINLANGCHOICE
 </combobox>
 </hbox>
 $CHECKUTF8
 $TIMEZONEBOX
 <hbox>
 <pixmap tooltip-text=\"$(gettext 'Keyboard')\"><input file>$ICONS/mini-keyboard.xpm</input></pixmap>
 <combobox tooltip-text=\"$(gettext 'Choose your keyboard layout')\"><variable>KMAP</variable>$KEYCHOICE</combobox>
 </hbox>
 $NUMLOCKBOX
 </vbox>
 </frame>"
fi

if [ "$RESOCHANGER" ]; then
  SCREENSEL="enabled"
  XVESASEL="enabled"
  XORGSEL="enabled"
  XSERVER=$(readlink $XPATH)
  [ "$XSERVER" = "Xvesa" ] && XVESA="true" || XVESA="false"
  CURRENTDRIVER=$(video_driver)	# v2.0
  #CURRENTDRIVER=""
  #if [ -s "/etc/X11/xorg.conf" ]; then
  #  CURRENTDRIVER="`grep '#card0driver' /etc/X11/xorg.conf | cut -f 2 -d '"'`" #'geany
  #fi
  #if [ "$CURRENTDRIVER" = "" -a $XVERSION -ge 5 -a -s /var/log/Xorg.0.log ]; then
    #120219 01micko: detecting X driver
  #  CURRENTDRIVER=$(grep -E -i " connected|card detect|primary dev" /var/log/Xorg.0.log|head -n1|cut -d ':' -f1|rev|cut -d ' ' -f1|rev|cut -d '(' -f1|tr '[:upper:]' '[:lower:]') #)#geany
  #  [ "$CURRENTDRIVER" = "" ] && CURRENTDRIVER=$(basename "/$(grep 'drivers/.*_drv.so' /var/log/Xorg.0.log| tail -n1| cut -s -d'/' -f2-)"| cut -d'_' -f1)
  #fi
  if [ "$XVESA" = "true" ]; then
   for F in /etc/videomode /tmp/videomode; do
     [ -s $F ] && DIMXDEPTH=$(cat $F| cut -d' ' -f2)
   done
   DIM=$(echo $DIMXDEPTH|cut -d'x' -f1,2)
   DEPTH=$(echo $DIMXDEPTH|cut -d'x' -f3)
   debug "DEPTH=$DEPTH"
   SS=$(Xvesa -listmodes 2>&1 | cut -d ':' -f2| grep '^[ ]*[168].*x16 '| cut -d' ' -f2|sort -nr|grep 'x'|sed -e 's/x16$//')
   NOWRESO=$DIM
   XRESOES="$SS"
   #SCREENSEL="enabled"
   DXORG="false"
   DXVESA="true"
   which Xorg &>/dev/null || XORGSEL="disabled"
  else
   # X resolution
   #XRESOES=$(xrandr -q| tr -s ' ' | grep '^ [0-9]' | cut -d' ' -f2,3 | tr ' ' '%'| sed -e 's/\.[0-9]*/Hz/')
   XRESOELINES=$(xrandr -q| tr -s ' ' | grep '^ [12689]')
   NOWDIM=$(echo "$XRESOELINES"| grep '\*'| tr -s ' '| cut -d' ' -f2| head -n 1) # 5jan11
   NOWRESO="$NOWDIM*"
   XRESOES=$(echo "$XRESOELINES"| grep -v '\*'| tr -s ' '| cut -d' ' -f2|sort -n|uniq) # 5jan11
   NVIDIABOX=""
   BUTTONMSG=$CCEMSG
   if which nvidia-settings &>/dev/null  && NRATE=$(nvidia-settings -q RefreshRate | grep '[0-9]') ; then
     NVIDIABUTTON="<button tooltip-text=\"$(gettext 'Launch the NVIDIA X Server Settings.')\" icon_size=\"2\" ><input file>$NVIDIAICON</input><label>$(gettext 'NVIDIA')</label><action>EXIT:NVIDIA</action></button>"
     XRESOES=""
     BUTTONMSG=$NVIDIAMSG
   fi
   DXORG="true"
   DXVESA="false"
   which Xvesa &>/dev/null || XVESASEL="disabled"
  fi

   if [ "$XRESOES" ]; then
     RESOSEL="enabled"
     XRESOES=$(echo "$NOWRESO
$XRESOES"| sort -nr)
     RESOTXT="<text><label>$RESOMSG</label></text>"
   else
     RESOSEL="disabled"
     RESOTXT=""
   fi
   SCREEN=$NOWRESO
   SCREENS="$XRESOES"
   RESOSELBOX="$RESOTXT
   <hbox>
  <pixmap tooltip-text=\"$(gettext 'Screen resolution')\" icon_size=\"2\"><input file stock=\"gtk-fullscreen\"></input></pixmap>
  <text><label>$(gettext 'Resolution')</label></text>
  <combobox tooltip-text=\"$(gettext 'Choose screen resolution.')\">
  <variable>SCREEN</variable>
  $(make_combo $NOWRESO $XRESOES)
  <visible>$RESOSEL</visible>
  </combobox></hbox>"
  
  	#NOWRATE=$(xrandr | grep '*'| sed -e 's/\*.*$//' -e 's/^.*[ ]//')
	#which nvidia-settings &>/dev/null && NRATE=$(nvidia-settings -q RefreshRate | grep Hz | tr -dc '0-9.'| sed -e 's/^[0.]*//' -e 's/Hz.*//')
	#[ "$NRATE" != "" ] && NOWRATE=$NRATE
	#[ "$OLDRATE" != "" ] || NOWRATE=60
   #RATE=${NOWRATE}Hz
#   REFRESHBOX="<hbox>
#   <pixmap tooltip-text=\"$(gettext 'Refresh rate')\" icon_size=\"2\"><input file stock=\"gtk-dnd-multiple\"></input></pixmap>
#  <text><label>$(gettext 'Refresh rate')</label></text>
#  <combobox tooltip-text=\"$(gettext 'Choosing 60Hz is safe for most case.')\">
#  <variable>RATE</variable>
#  $(make_combo $RATE 50Hz 55Hz 60Hz 65Hz 70Hz 75Hz)
#  </combobox></hbox>"
#  SCREENCHOICE=$(make_combo $SCREEN $SCREENS)
  case "$DEPTH" in
  16) DEPTH16="true"; DEPTH24="false";;
  24) DEPTH16="false"; DEPTH24="true";;
  *)  DEPTH16="false"; DEPTH24="false";;
  esac

   #DEPTH=""
   DEPTHBOX=""
  if [ "$DEPTH16" = "true" -o "$DEPTH24" = "true" ] ;then
   DEPTHBOX="<hbox>
   <pixmap tooltip-text=\""$(gettext "Color depth")"\" icon_size=\"2\" ><input file stock=\"gtk-select-color\"></input></pixmap>
   <text><label>"$(gettext "Color depth")":</label></text>
   <radiobutton tooltip-text=\""$(gettext "16-bit high color depth")"\" >
   <label>"$(gettext "16bit")"</label><variable>DEPTH16</variable>
   <default>$DEPTH16</default>
   </radiobutton>
   <radiobutton tooltip-text=\""$(gettext "24-bit true color depth")"\">
   <label>"$(gettext "24bit")"</label><variable>DEPTH24</variable>
   <default>$DEPTH24</default>
   </radiobutton>
   </hbox>"
  fi
  XVESA=$DXVESA
  XORGSELBOX=""
  if [ "$HAS_XVESA" != "" ]; then
   [ "$CURRENTDRIVER" != "" ] && DRIVERINFO="($CURRENTDRIVER)" || DRIVERINFO=""
   XORGSELBOX="<hbox>
   <pixmap tooltip-text=\""$(gettext "X-server")"\"><input file>$ICONS/mini-x.xpm</input></pixmap>
   <text><label>"$(gettext "X-server")": </label></text>
   <radiobutton tooltip-text=\""$(gettext "Use Xorg as the X server.")"\" >
   <label>Xorg$DRIVERINFO</label><variable>XORG</variable>
    <visible>$XORGSEL</visible>
	<default>$DXORG</default>
   </radiobutton>
   <radiobutton tooltip-text=\""$(gettext "Use Xvesa as the X server.")"\">
   <label>Xvesa</label><variable>XVESA</variable>
    <visible>$XVESASEL</visible>
	<default>$DXVESA</default>
   </radiobutton>
   </hbox>"
  elif [ "$CURRENTDRIVER" != "" ]; then
    DRIVERINFO="$CURRENTDRIVER"
    XORGSELBOX="<text><label>"$(gettext "X-server")": $DRIVERINFO</label></text>"
  fi
  
  #XINFO=$(LANG=C xdpyinfo)
  #DIMENSION=$(echo "$XINFO"|grep 'dimensions:'|head -n 1| cut -d':' -f2|tr -s ' '| cut -d ' ' -f2 )
  #[ "$DIMENSION" = "" ] && DIMENSION=$(xrandr -q | grep '*' | tr -s ' '| cut -d' ' -f2)
  #DEPTH=$(echo "$XINFO"|grep 'depth of root window:'| head -n 1| cut -d':' -f2|tr -s ' '| cut -d ' ' -f2 )
  #[ "$DIMENSION" != "" ] && [ "$DEPTH" != "" ] && SCREEN="${DIMENSION}x$DEPTH"
  #SS=$(ddcprobe| grep 'x'| cut -d' ' -f2| cut -d'x' -f1,2|grep '^[168]'|sort|uniq)
  #SCREENORG=$SCREEN
  #  CCEBOX="<hbox><text><label>$CCEMSG</label></text>
  #  <button><input file>$ICONS/prompt16.xpm</input>
  #  <label>$(gettext 'CCE')</label><action>EXIT:CCE</action></button></hbox>"
   SCREENFRAME="<frame $RESOM><vbox>
    $XORGSELBOX
   $RESOSELBOX
  $DEPTHBOX
  <text><input>echo -en \"$BUTTONMSG\"</input></text>
  <hbox> $NVIDIABUTTON
  <button tooltip-text=\"$(gettext 'Exit graphic mode and run XorgWizard in text mode.')\">
  <input file>$ICONS/wizard16.xpm</input><label>$(gettext 'XorgWizard')</label><action>EXIT:Xorgwizard</action></button></hbox>
  </vbox></frame>"
  fi

 if [ "$FULLFEATURE" != "" ]; then
   HOSTNAME=$(hostname)
   HOSTBOX="<hbox><text><label>$(gettext 'Hostname'):</label></text>
   <entry tooltip-text=\"$(gettext 'Optionally, type your PC name to identify in the network. Alpha-numeric without spaces.')\">
   <input>echo -n \"$HOSTNAME\"</input><variable>HOSTNAME</variable></entry></hbox>"
   if [ "$MOUSECHECK" ]; then
     M_mouse=$(gettext 'Dead mouse? <b>TAB</b> key to select this button then press <b>ENTER</b> key:')
     MOUSEBOX="<text use-markup=\"true\"><label>\"${M_mouse}\"</label></text>
    <vbox><button><input file>/usr/local/lib/X11/mini-icons/Mouse.xpm</input><action>$MOUSECHECK nowait</action></button></vbox>"
   fi
 fi

 #APPLYBUTTON="<button tooltip-text=\"$(gettext 'Apply changes now.')\">
 #<input file stock=\"gtk-apply\"></input><label>$(gettext 'Apply')</label>
 #<action>Exit:Apply</action></button>"

OKTEXT=""
 LEFTBOX=""
 if [ "$HOSTBOX" != "" -o "$COUNTRYFRAME" != "" ]; then
   LEFTBOX="<vbox>$HOSTBOX
 $COUNTRYFRAME</vbox>"
 fi
 TOPBOX="<text><input>echo -en \"$TOPMSG\"</input></text>"
 [ "$MOUSEBOX" ] && TOPBOX="<hbox>$TOPBOX$MOUSEBOX</hbox>" 
 export DIALOG="<window title=\"$TITLE\" $TITLEICON><vbox>
 $TOPBOX
 <hbox>
 $LEFTBOX
 $SCREENFRAME
 </hbox>
 <hbox><text><label>$OKMSG</label></text>
  <button ok></button></hbox>

 </vbox></window>"

 # wait  splash #v2.1: no splash if MOMENT=0
 if [ "$XPID" != "" ]; then
  END=$(($START + $MOMENT))
  while [ $(date +'%s') -lt $END ];do
   sleep 1
  done
 fi
 #[ "$XPID" != "" ] && kill $XPID
 waitsplash stop

 # save the last
 HOSTNAMELAST=$HOSTNAME
 SCREENLAST=$SCREEN
 DEPTHLAST=$DEPTH
 RATELAST=$RATE
 XVESALAST=$XVESA
 LOCALELAST=$LANG
 TZONELAST=$(keyword $TZONE)
 UTCLAST=$UTC
 KMAPLAST=$(keyword $KMAP)
 NUMLOCKLAST=$NUMLOCK
 [ "$HOSTNAMEORG" = "" ] && HOSTORG="$HOSTNAMELAST"
 [ "$SCREENORG" = "" ] && SCREENORG="$SCREENLAST"
 [ "$DEPTHORG" = "" ] && DEPTHORG="$DEPTHLAST"
 [ "$RATEORG" = "" ] && RATEORG="$RATELAST"
 [ "$XVESAORG" = "" ] && XVESAORG="$XVESALAST"
 [ "$LOCALEORG" = "" ] && LOCALEORG="$LOCALELAST"
 [ "$TZONEORG" = "" ] && TZONEORG="$TZONELAST"
 [ "$UTCORG" = "" ] && UTCORG="$UTCLAST"
 [ "$KMAPORG" = "" ] && KMAPORG="$KMAPLAST"

 CHANGES=""
 RETRY=""
 #RESTARTX=""

 # 12jun10 : hack against gtk bug with EXIT  variable
 # removed cancel button because they does not return EXIT variable with some locale
 #echo "$DIALOG"
 RET=$((gtkdialog3 -p DIALOG -c || echo "$DIALOG">&2)| grep -E '^[A-Z][0-9A-Z]*=')
 #echo "$RET"
 #[ "$RET" ] || exit
 eval "$RET"
 EXITMODE="$EXIT"
 debug "$EXITMODE"
 case "$EXIT" in
  Apply) RETRY="yes";;
  abort) [ "$CONFIGFILE" != "" ] && echo "abort" > $CONFIGFILE
          exit 0 ;;
 esac
 
 APPLYING=$(gettext "Applying changes.")
 waitsplash start $APPLYING
 # firstsetup
 #if ! which firstsetup &>/dev/null; then
 #  F=$HOME/.config/firstsetup/firstsetup.conf
 #  mkdir -p $(dirname $F)
 #  echo "SETUP=done" > $F
 #fi

 # locale
 LOCALECHANGED=""
 LANGCHOICE=$(keyword $MAINLANG)
 if [ "$LANGCHOICE" != "$OLDLANGBASE" -o "$OLDUTF" != "$UTF" ]; then
  if [ "$CHOOSELOCALE" ] && echo $LANGCHOICE| grep -q '\.\.\.'; then
   waitsplash stop
   NOWLANG=$LANG
   chooselocale
   [ "$LANG" != "$NOWLANG" ] && LOCALECHANGED="locale"
  else
   SUCCESS=""
   lang_check && set_locale "$NEWLANG" && LOCALECHANGED="locale" && SUCCESS="yes"
   [ "$SUCCESS" != "" ] || echo "Locale error." >&2
  fi
  if [ "$LOCALECHANGED" != "" ]; then
   export LANG=$NEWLANG
   #[ "$RESTARTX" = "" ] && RESTARTX="locale"
   CHANGES="$CHANGES
 $(gettext 'Main language')"
#else
#  echo "Got some errors!" >&2
  fi
 elif [ "$COUNTRYSET" ]; then
   # ensure current localedef
   L=$LANGCHOICE
   [ "$UTF" = "true" ] && UTF8="$DOTUTF8" || UTF8=""
   [ "$UTF8" != "" ] && L=$(echo $L| cut -d'@' -f1) # remove @euro, etc.
   NEWLANG=$L$UTF8
   make_localedef "$NEWLANG"
 fi

 # hostname
 HOSTNAME=$(keyword $HOSTNAME)
 [ "$HOSTNAME" != "" ] || HOSTNAME=$HOSTNAMELAST
 if [ "$HOSTNAME" != "$HOSTNAMELAST" ]; then
   hostname $HOSTNAME
   echo -n $HOSTNAME > /etc/hostname
   echo "127.0.0.1 localhost $HOSTNAME" > /tmp/hosts
   grep -vw 'localhost'  /etc/hosts >> /tmp/hosts
   [ -s /tmp/hosts ] && mv -f /tmp/hosts /etc/hosts
   CHANGES="$CHANGES
 $(gettext 'Hostname')"
 fi
 # timezone
  if [ "$(keyword $TZONE)$UTC" != "$TZONELAST$UTCLAST" ]; then
  #HWCLOCKTIME="localtime"
  #grep -qw '^[^#]*utc' /etc/clock && HWCLOCKTIME="utc"
  HWCORG="$HWCLOCKTIME"
  [ "$UTC" = "true" ] && HWCLOCKTIME="utc" || HWCLOCKTIME="localtime"
  NEWTZONE=$(tzone_check $TZONE)
  #if [ "$(readlink /etc/localtime)" != "/usr/share/zoneinfo/$NEWTZONE" -o "$HWCLOCKTIME" != "$HWCORG" ];then
  CHANGES="$CHANGES
 $(gettext 'Time zone')"
  if [ "$HWCLOCKTIME" != "$HWCORG" ]; then
    grep -v 'HWCLOCKTIME=' /etc/clock > $TMPFILE
    echo -n "HWCLOCKTIME=$HWCLOCKTIME" >> $TMPFILE
    [ -s "$TMPFILE" ] && mv -f "$TMPFILE" /etc/clock
  fi
  set_timezone
  #RESTARTX="timezone"
 fi

 # keymap
 if [ "$(keyword $KMAP)" != "$KMAPLAST" ]; then
  SKMAP="$KMAP"
  KMAP=$(kmap_check $KMAP) || SKMAP="$KMAP"
  #echo "KMAP=$KMAP" # debug
  #KMAP=""    # debug
  #OLDKMAP=$(basename "$(cat /etc/keymap 2>/dev/null)" .map)
  #if [ "$KMAP" != "" ] && [ "$KMAP" != "$OLDKMAP" ];then
  #[ "$XSERVER" = "Xvesa" ] && [ "$RESTARTX" = "" ] && RESTARTX="keyboard"
  if which keymap-set &>/dev/null; then
   keymap-set $KMAP
  else
    errmsg "The 'keymap-set' not found." 
    exit 1
  fi
  if [ "$XSERVER" = "Xvesa" -o  "$XVESA" = "true" ]; then
    EXIT="OK"  # cannot test on the sandbox
  else 
    MSG="$(gettext 'The keyboard layout is changed to'): $SKMAP\\n\\n$(gettext 'You can type into this box to test your new keyboard layout.')"
   CUSTOM="<entry></entry>
   <hbox><button><input file stock=\"gtk-ok\"></input>
   <label>$(gettext 'OK')</label><action>EXIT:OK</action></button>
   <button><input file stock=\"gtk-cancel\"></input>
   <label>$(gettext 'Cancel')</label><action>EXIT:Cancel></action></button>
   </hbox>"
     MARK=info
     errmsg custom "$MSG"
     eval "$RET"
   fi
   if [ "$EXIT" = "OK" ] ; then
     CHANGES="$CHANGES
 $(gettext 'Keyboard')"
   else
     keymap-set $KMAPLAST
     RETRY="yes"
   fi
 fi

 # numlock
 if [ "$NUMLOCK" != "$NUMLOCKLAST" ]; then
   CHANGES="$CHANGES
 $(gettext 'NumLock')"
   P=/root/Startup/numlockx
   [ -x "$NUMLOCKX" ] || chmod +x "$NUMLOCKX"
   [ "$NUMLOCK" = "true" ] && "$NUMLOCKX" on || "$NUMLOCKX" off
   if [ "$NUMLOCKX" = $P ]; then
     [ "$NUMLOCK" = "true" ] && chmod +x $P || chmod -x $P
   else
     rm -f $P  # precaution
     [ "$NUMLOCK" = "true" ] && ln -sf  "$NUMLOCKX"  $P || rm -f $P
   fi
 fi

 # videomode
    NEWDEPTH=24
   [ "$DEPTH16" = "true" ] && NEWDEPTH=16
   [ "$DEPTH" != "" ] || NEWDEPTH=""
   DEPTH=$NEWDEPTH
   debug "NEWDEPTH=$NEWDEPTH"
 if [ "$SCREEN$RATE$DEPTH$XVESA" != "$SCREENLAST$RATELAST$DEPTHLAST$XVESALAST" ]; then
   NEWSCREEN=$SCREEN
   NEWDIM=$(echo ${NEWSCREEN}|tr '/*' '  '|cut -d' ' -f1)
   NEWRATE=$(echo $RATE|tr -dc '0-9.')
  if [ "$XVESA" != "true" -a "$XVESALAST" != "true" ] ; then
    if [ "$XRANDR" != "" ] ; then
      waitsplash stop
      if change_xrandr ; then
        CHANGES="$CHANGES
 $(gettext 'Screen resolution')"
       #pidof jwm &>/dev/null && RESTARTX="Xorg"
      else
        RETRY="yes"
      fi
    else
      CHANGES="$CHANGES
 $(gettext 'X-server')"
      [ "$XSERVER" = "Xorg" ] || ln -sf Xorg $XPATH
     #RESTARTX="Xorg"
    fi
    rm -f /etc/videomode /tmp/videomode
  fi
  if [ "$XVESA" = "true" -a  "$HAS_XVESA" = "yes"  ]; then
    if [ "$NEWDEPTH" = "" -a  "$XVESALAST" != "true" ]; then
     NEWDEPTH=$(LANG=C xdpyinfo|grep 'depth of root window:'| head -n 1| cut -d':' -f2|tr -s ' '| cut -d ' ' -f2)
    fi
    [ "$NEWDEPTH" != "" ] || NEWDEPTH=16
    VMODE=$(Xvesa -listmodes 2>&1|grep -w "${NEWDIM}x${NEWDEPTH}"| head -n 1|cut -d':' -f1)
    if [ "$VMODE" = "" ]; then
      SS=$(Xvesa -listmodes 2>&1 | cut -d ':' -f2| grep '^[ ]*[168].*x16 '| cut -d' ' -f2|sort -nr|grep 'x'|sed -e 's/x16$//')
      LARGEST=$(echo "$SS" | head -n 1)
      LARGESTX=$(echo $LARGEST| cut -d'x' -f1)
      NEWX=$(echo $NEWDIM| cut -d'x' -f1)
      [ $NEWX -ge $LARGESTX ] && NEWDIM=$LARGEST || NEWDIM=800x600
      VMODE=$(Xvesa -listmodes 2>&1|grep -w "${NEWDIM}x${NEWDEPTH}"| head -n 1| cut -d':' -f1)
    fi
    if [ "$VMODE" != "" ]; then
      if [ "$XVESA" = "$XVESALAST" ]; then
        CHANGES="$CHANGES
 $(gettext 'Screen resolution')"
      else
        CHANGES="$CHANGES
 $(gettext 'X-server')"
      fi
    VMODE="$VMODE ${NEWDIM}x${NEWDEPTH}"
    ln -sf Xvesa $XPATH
    echo -n "$VMODE" > /tmp/videomode
    rm -f /etc/videomode
    #RESTARTX="videomode"
    fi
  fi
  if [ "$XVESA" != "$XVESALAST" -a  "$XVESA" != "true" ]; then
      CHANGES="$CHANGES
 $(gettext 'X-server')"
     ln -sf Xorg $XPATH
     rm -f /etc/videomode /tmp/videomode
     #RESTARTX="Xorg"
  fi
 fi

  #waitsplash stop
  # changed?
  MSG=$(gettext "Nothing is changed.")
  if [ "$CHANGES" != "" ]; then
   CHANGES=$(echo "$CHANGES"|tr ' ' '%')
   CHANGES=$(echo $CHANGES|tr '% ' ' ,')
   MSG=$(gettext 'Changes completed.')
   [ "$RETRY" != "" ] && MSG=$(gettext 'Changed')
   MSG="$MSG: ($CHANGES)"
  fi
  [ "$RETRY" != "" ] && EXITMODE=""
 #echo $MSG>&2
  #v2.1: no splash if MOMENT=0
   if [ $MOMENT -gt 0 ] && [ "$CHANGES" != "" -o "$EXITMODE" = "OK" -o "$EXITMODE" = "Apply" ]; then
     errmsg splash "$MSG"
     START=$(date +%s)
   fi
done	# end of the long loop

if [ "$XPID" != "" ]; then
  END=$(($START + $MOMENT))
  while [ $(date +'%s') -lt $END ];do
    sleep 1
  done
  kill $XPID && XPID=""
fi

 #if [ "$(readlink /etc/localtime)" != "/usr/share/zoneinfo/$NEWTZONE" -o "$HWCLOCKTIME" != "$HWCORG" ];then
 #debug "$(keyword $TZONE)$UTC:$TZONEORG$UTCORG"
 #v2.1: was needed for older versions of lupu, but need not now
 #if [ "$(keyword $TZONE)$UTC" != "$TZONEORG$UTCORG" ]; then
 # RESTARTX="tzone"
 #fi

 if [ "$(keyword $KMAP)"  != "$KMAPORG" ];then
#  CHANGES="$CHANGES
#$(gettext 'Keyboard')"
  [ "$XSERVER" = "Xvesa" ] && [ "$RESTARTX" = "" ] && RESTARTX="keyboard"
 fi

# if [ "$LANG" != "$LOCALEORG" ]; then
#   CHANGES="$CHANGES
#$(gettext 'Main language')"
#   RESTARTX="locale"
# fi

 if [ "$SCREEN$DEPTH$XVESA" != "$SCREENORG$DEPTHORG$XVESAORG" ]; then
#   CHANGES="$CHANGES
#$(gettext 'Screen resolution')"
   #RESTARTX="videomode"
   pidof jwm &>/dev/null && RESTARTX="xrandr"
   if [  "$XVESA" = "true" ]; then
     RESTARTX="xvesa" 
   fi
   if [  "$XVESA" != "$XVESAORG" ] ; then
#    CHANGES="$CHANGES
#$(gettext 'X-server')"
     RESTARTX="xserver" 
     if [ "$XVESA" != "true" ]; then
       RESTARTX="Xorg"
 	   [ "$CURRENTDRIVER" = "" -a $XVERSION -lt 5 ] && RESTARTX="xorgwizard"
     fi
   fi
 fi

# need restart PC?
if [ "$LOCALECHANGED" != "" ]; then
    cp -f /etc/profile /var/local/etc_profile_at_shutdown	#v2.0.9 rc.update reads this
	if [ "$EXTRALANG"  ]; then
	  waitsplash start
	  "$EXTRALANG"	# additional language package
	fi
	RESTARTX="locale"
	#[ "$XFULLRESTART" != "" ] && RESTARTX="full"
fi

[ "$EXITMODE" = "Xorgwizard" ] && RESTARTX="xorgwizard"
if echo $RESTARTX | grep -qi 'Xorg' ; then	#v2.0.9
  [ "$CONFIGFILE" != "" ] && rm -f "$CONFIGFILE"
else
  [ "$CHANGES" != "" ] && STATUS="changed" || STATUS="done"
  [ "$CONFIGFILE" != "" ] && echo "$STATUS" > $CONFIGFILE
fi

# Nvidia settings
if [ "$EXITMODE" = "NVIDIA" ] && which nvidia-settings &>/dev/null ; then
  waitsplash stop
  exec nvidia-settings
fi

# need restart X?
[ "$RESTARTX" != "" ] && yesno_x

exit 0
