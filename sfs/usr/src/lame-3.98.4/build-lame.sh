#!/bin/bash
#Automatically Created by slkbuild 0.6.4
#Packager: George Vlahavas (vlahavas~at~gmail~dot~com)
#url: http://lame.sourceforge.net/

######Begin Redundant Code######################################
check_for_root() {
	if [ "$UID" != "0" ]; then
		echo "You need to be root"
		exit 1
	fi
}

clean_dirs () {
        for COMPLETED in src pkg; do
                if [ -e $COMPLETED ]; then
                        rm -rf $COMPLETED
                fi
        done
}

clean_old_builds () {
	rm -rf $package.{t[xlgb]z,md5}
	clean_dirs
}

set_pre_permissions() {
	cd $startdir/src
	find . -perm 664 -exec chmod 644 {} \;
	find . -perm 600 -exec chmod 644 {} \;
	find . -perm 444 -exec chmod 644 {} \;
	find . -perm 400 -exec chmod 644 {} \;
	find . -perm 440 -exec chmod 644 {} \;
	find . -perm 777 -exec chmod 755 {} \;
	find . -perm 775 -exec chmod 755 {} \;
	find . -perm 511 -exec chmod 755 {} \;
	find . -perm 711 -exec chmod 755 {} \;
	find . -perm 555 -exec chmod 755 {} \;
}


gzip_man_and_info_pages() {
	for DOCS in man info; do
		if [ -d "$startdir/pkg/usr/share/$DOCS" ]; then
			mv $startdir/pkg/usr/share/$DOCS $startdir/pkg/usr/$DOCS
			if [[ ! "$(ls $startdir/pkg/usr/share)" ]]; then
				rm -rf $startdir/pkg/usr/share
			fi
		fi
		if [ -d "$startdir/pkg/usr/$DOCS" ]; then
			# I've never seen symlinks in info pages....
			if [ "$DOCS" == "man" ]; then
				(cd $startdir/pkg/usr/$DOCS
				for manpagedir in $(find . -type d -name "man*" 2> /dev/null) ; do
					( cd $manpagedir
					for eachpage in $( find . -type l -maxdepth 1 2> /dev/null) ; do
						ln -s $( readlink $eachpage ).gz $eachpage.gz
						rm $eachpage
					done )
				done)
			fi
			find $startdir/pkg/usr/$DOCS -type f -exec gzip -9 '{}' \;
		fi
	done
	[ -a $startdir/pkg/usr/info/dir.gz ] && rm -f $startdir/pkg/usr/info/dir.gz
}

set_post_permissions() {
	for DIRS in usr/share/icons usr/doc; do
		if [ -d "$startdir/pkg/$DIRS" ]; then
			if [ "$DIRS" == "usr/doc" ]; then
				find $startdir/pkg/$DIRS -type f -exec chmod 644 {} \;
				find $startdir/pkg/$DIRS -type d -exec chmod 755 {} \;
			fi
		fi
		[ -d $startdir/pkg/$DIRS ] && chown root:root -R $startdir/pkg/$DIRS
	done
	[ -d $startdir/pkg/usr/bin ] && find $startdir/pkg/usr/bin -user root -group bin -exec chown root:root {} \;
}

copy_build_script() {
	mkdir -p $startdir/pkg/usr/src/$pkgname-$pkgver/
	cp $startdir/build-$pkgname.sh $startdir/pkg/usr/src/$pkgname-$pkgver/build-$pkgname.sh
	[ -f $startdir/SLKBUILD ] && cp $startdir/SLKBUILD	$startdir/pkg/usr/src/$pkgname-$pkgver/SLKBUILD
}

create_package() {
	ls -lR $startdir/pkg
	cd $startdir/pkg
	/sbin/makepkg -l y -c n $startdir/$package.txz
	cd $startdir
	md5sum $package.txz > $startdir/$package.md5
}

strip_binaries() {
	cd $startdir/pkg
	find . | xargs file | grep "executable" | grep ELF | cut -f 1 -d : | \
	xargs strip --strip-unneeded 2> /dev/null
	find . | xargs file | grep "shared object" | grep ELF | cut -f 1 -d : | \
	xargs strip --strip-unneeded 2> /dev/null
}
#########End Redundant Code#####################################
#########Begin Non Redundant Code##############################

prepare_directory() {
	mkdir $startdir/src
	mkdir -p $startdir/pkg/usr/src/$pkgname-$pkgver
	for SOURCES in ${source[@]}; do
		protocol=$(echo $SOURCES | sed 's|:.*||')
	        file=$(basename $SOURCES | awk -F= '{print $NF}')
		if [ ! -f "$file" ]; then
			if [ "$protocol" = "http" -o "$protocol" = "https" -o "$protocol" = "ftp" ]; then
				echo -e "\nDownloading $(basename $SOURCES)\n"
        	                wget $SOURCES -O $file
				if [ ! "$?" == "0" ]; then
					echo "Download failed"
					exit 2
				fi 
			else
				echo "$SOURCES does not appear to be a url nor is it in the directory"
				exit 2
			fi
		fi
		cp -LR $file $startdir/src
		if ! [ "$protocol" = "http" -o "$protocol" = "https" -o "$protocol" = "ftp" ]; then
			if ! [[ $NOSRCPACK -eq 1 ]]; then
				cp -LR $startdir/$(basename $SOURCES) $startdir/pkg/usr/src/$pkgname-$pkgver/
			fi
		fi
	done
}

extract_source() {
	cd $startdir/src
	if [[ "$(ls $startdir/src)" ]]; then	
		for FILES in ${source[@]}; do
	        	FILES="$(basename $FILES | awk -F= '{print $NF}')"
			file_type=$(file -biLz "$FILES")
			unset cmd
			case "$file_type" in
				*application/x-tar*)
					cmd="tar -xf" ;;
				*application/x-zip*)
					cmd="unzip" ;;
				*application/zip*)
					cmd="unzip" ;;
				*application/x-gzip*)
					cmd="gunzip -d -f" ;;
				*application/x-bzip*)
					cmd="bunzip2 -f" ;;
				*application/x-xz*)
					cmd="xz -d -f" ;;
				*application/x-lzma*)
					cmd="lzma -d -f" ;;
			esac
			if [ "$cmd" != "" ]; then
				echo "$cmd $FILES"
	        	        $cmd $FILES
			fi
		done
	elif [ ! "$source" ]; then
		echo -n "" # lame fix
	else
		echo "no files in the src directory $startdir/src"
		exit 2
	fi
}

build() {
	cd $startdir/src/$pkgname-$pkgver
	./configure --prefix=/usr --libdir=/usr/lib${LIBDIRSUFFIX} --localstatedir=/var --sysconfdir=/etc --mandir=/usr/man --enable-nasm
	make || return 1
	make install DESTDIR=$startdir/pkg
	mkdir -p $startdir/pkg/usr/doc/$pkgname-$pkgver
	mv $startdir/pkg/usr/share/doc/* $startdir/pkg/usr/doc/$pkgname-$pkgver
	rm -rf $startdir/pkg/usr/share

	rm $startdir/pkg/usr/lib${LIBDIRSUFFIX}/libmp3lame.a
} 

create_slackdesc() {
mkdir $startdir/pkg/install
cat <<"EODESC" >$startdir/pkg/install/slack-desc
lame: lame (MPEG Audio Layer III (MP3) encoder)
lame: 
lame: LAME is considered to be the best mp3 encoder. Some of its features
lame: are:
lame:     * Highly optimised presets
lame:     * Fast encoding
lame:     * CBR, ABR and quality-optimized VBR encoding methods
lame:     * Gapless playback with LAME-header compliant decoders
lame:     * Supported by all major CD rippers
lame:     * Highly tunable
lame: 
EODESC
}

copy_docs() {
	for stuff in ${docs[@]}; do
		if [ ! -d "$startdir/pkg/usr/doc/$pkgname-$pkgver" ]; then
			mkdir -p $startdir/pkg/usr/doc/$pkgname-$pkgver
		fi
		find $startdir/src -type f -iname "$stuff" -exec cp -LR '{}' $startdir/pkg/usr/doc/$pkgname-$pkgver \;
	done
}
create_source_file(){
	[ -f $package.src ] && rm $package.src
	if [ ! -z $sourcetemplate ]; then
		echo $sourcetemplate/SLKBUILD >> $package.src
		echo $sourcetemplate/build-$pkgname.sh >> $package.src
		for SOURCES in ${source[@]}; do
			protocol=$(echo $SOURCES | sed 's|:.*||')
			if ! [ "$protocol" = "http" -o "$protocol" = "https" -o "$protocol" = "ftp" ]; then
				if [ ! -z $sourcetemplate ]; then
					echo $sourcetemplate/$(basename $SOURCES) >> $package.src
				else
					echo $(basename $SOURCES) >> $package.src
				fi
			else
				echo $SOURCES >> $package.src
			fi
		done
	fi
}
post_checks(){
	# Ideas taken from src2pkg :)
	if [ -d "$startdir/pkg/usr/doc/$pkgname-$pkgver" ]; then
		for DIRS in usr/doc/$pkgname-$pkgver usr/doc; do
			cd $startdir/pkg/$DIRS
			if [[ $(find . -type f) = "" ]] ; then
				cd ..
				rmdir $DIRS
			fi
		done
	fi
	# if the docs weren't deleted ...
	if [ -d "$startdir/pkg/usr/doc/$pkgname-$pkgver" ]; then
		cd $startdir/pkg/usr/doc/$pkgname-$pkgver
		#remove zero lenght files
		if [[ $(find . -type f -size 0) ]]; then
			echo "Removing some zero lenght files"
			find . -type f -size 0 -exec rm -f {} \;
		fi
	fi
	# check if we need to add code to handle info pages
	if [[ -d $startdir/pkg/usr/info ]] && [[ ! $(grep install-info $startdir/pkg/install/doinst.sh &> /dev/null) ]] ; then
		echo "Found info files - Adding install-info command to doinst.sh"
		INFO_LIST=$(ls -1 $startdir/pkg/usr/info)
		echo "" >> $startdir/pkg/install/doinst.sh
		echo "if [ -x usr/bin/install-info ] ; then" >> $startdir/pkg/install/doinst.sh
		for page in $(echo $INFO_LIST) ; do
			echo " usr/bin/install-info --info-dir=usr/info usr/info/$page 2>/dev/null" >> $startdir/pkg/install/doinst.sh
		done
		echo "fi" >> $startdir/pkg/install/doinst.sh
	fi
	[[ -e $startdir/pkg/usr/info/dir ]] && rm -f $startdir/pkg/usr/info/dir

	if [ -d $startdir/pkg/etc ]; then
		cd $startdir/pkg/
		for conf in $(find ./etc -type f) ; do
			conf=${conf: 2}
			dotnew=( "${dotnew[@]}" "$conf" )
		done
	fi
	if [[ "$dotnew" ]]; then
        for files in ${dotnew[@]} ; do
                fullfile="${startdir}/pkg/${files}"
                if [ -e "$fullfile" ]; then
                        mv $fullfile ${fullfile}.new
                else
                        echo "$fullfile was not found"
                        exit 2
                fi
        done
        cat<<"EODOTNEW" >>$startdir/pkg/install/doinst.sh
#Added by slkbuild 0.6.4
dotnew() {
        NEW="${1}.new"
        OLD="$1"
        if [ ! -e $OLD ]; then
                mv $NEW $OLD
        elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then
                rm $NEW
        fi
}
EODOTNEW
for i in ${dotnew[@]}; do
echo "dotnew $i" >> $startdir/pkg/install/doinst.sh
done
fi
}

####End Non Redundant Code############################

#Variables

startdir=$(pwd)
SRC=$startdir/src
PKG=$startdir/pkg

pkgname=lame
pkgver=3.98.4
pkgrel=1gv
arch=i486
package=$pkgname-$pkgver-$arch-1gv
source=("http://downloads.sourceforge.net/project/lame/lame/3.98.4/lame-3.98.4.tar.gz")
docs=(readme install copying changelog authors news todo maintainers acm api defines hacking install.configure styleguide usage)
export CFLAGS="-O2 -march=i486 -mtune=i686"
export CXXFLAGS="-O2 -march=i486 -mtune=i686"
export SLKCFLAGS="-O2 -march=i486 -mtune=i686"
export LIBDIRSUFFIX=""
export ARCH="i486"

#Execution

check_for_root
clean_old_builds
prepare_directory
extract_source
set_pre_permissions
build
if [ ! "$?" = "0" ]; then
	echo "build() failed."
	exit 2
fi
create_slackdesc
post_checks
copy_docs
strip_binaries
gzip_man_and_info_pages
set_post_permissions
copy_build_script
create_package
create_source_file
echo "Package has been built."
echo "Cleaning pkg and src directories"
clean_dirs
