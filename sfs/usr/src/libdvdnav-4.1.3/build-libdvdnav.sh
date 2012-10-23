#!/bin/bash
#Automatically Created by slkbuild 0.2
#Maintainer: Thorsten Muehlfelder <thenktor@gmx.de>
#Maintainer: George Vlahavas (vlahavas~at~gmail~dot~com)
#url: http://www2.mplayerhq.hu/MPlayer/releases/dvdnav/

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


check_for_menu_compliance() {
	if [ -d "$startdir/pkg/usr/share/applications" ]; then
		cd $startdir/pkg/usr/share/applications
		for desktop in *.desktop; do
			Icon=$(grep -e "^Icon=" $desktop | sed 's/Icon=//')
			if [[ "$Icon" ]]; then
				if [ ! "$Icon" == "${Icon%.*}" ]; then
					sed '/Icon/s/\..*$//' -i $desktop
					Icon=$(grep -e "^Icon=" $desktop | sed 's/Icon=//')
				fi
				if [ -d "$startdir/pkg/usr/share/pixmaps" ]; then
					cd $startdir/pkg/usr/share/pixmaps
					for pixmaps in *; do
						[ -d $pixmaps ] && continue
						[ ! "${pixmaps##*.}" == "png" -a ! "${pixmaps##*.}" == "svg" ] && continue
				 		if [ "${pixmaps%.*}" == "$Icon" ]; then
				 			DIR=$(file $pixmaps | awk -F, '{print $2}' | sed 's/ //g')
							[ o"$DIR" == "o" ] && DIR="scalable"
							mkdir -p $startdir/pkg/usr/share/icons/hicolor/$DIR/apps
							mv $pixmaps $startdir/pkg/usr/share/icons/hicolor/$DIR/apps
							if [[ ! "$(ls $startdir/pkg/usr/share/pixmaps)" ]]; then
								rm -rf $startdir/pkg/usr/share/pixmaps
							fi
						fi
					done
				fi
				if [ -d "$startdir/pkg/usr/share/icons" ]; then
					cd $startdir/pkg/usr/share/icons
					for icons in *; do
				 		if [ "${icons%.*}" == "$Icon" ]; then
							[ ! "${pixmaps##*.}" == "png" -a ! "${pixmaps##*.}" == "svg" ] && continue
				 			DIR=$(file $icons | awk -F, '{print $2}' | sed 's/ //g')
							[ o"$DIR" == "o" ] && DIR="scalable"
							mkdir -p $startdir/pkg/usr/share/icons/hicolor/$DIR/apps
							mv $icons $startdir/pkg/usr/share/icons/hicolor/$DIR/apps
						fi
					done
				fi
			fi
		done
	fi
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
		cp -R $file $startdir/src
		if ! [ "$protocol" = "http" -o "$protocol" = "https" -o "$protocol" = "ftp" ]; then
			cp -R $startdir/$(basename $SOURCES) $startdir/pkg/usr/src/$pkgname-$pkgver/
		fi
	done
}

extract_source() {
	cd $startdir/src
	if [[ "$(ls $startdir/src)" ]]; then	
		for FILES in ${source[@]}; do
	        	FILES="$(basename $FILES | awk -F= '{print $NF}')"
			file_type=$(file -biz "$FILES")
			unset cmd
			case "$file_type" in
				*application/x-tar*)
					cmd="tar -xf" ;;
				*application/x-zip*)
					cmd="unzip" ;;
				*application/x-gzip*)
					cmd="gunzip -d -f" ;;
				*application/x-bzip*)
					cmd="bunzip2 -f" ;;
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
	sed -i "s/-O3/-O2 -march=i686 -mtune=i686/" configure2
	./configure2 --prefix=/usr --disable-static
	make || return 1
	make install DESTDIR=$startdir/pkg
} 

create_slackdesc() {
mkdir $startdir/pkg/install
cat <<"EODESC" >$startdir/pkg/install/slack-desc
libdvdnav: libdvdnav - DVD navigation library
libdvdnav: 
libdvdnav: libdvdnav is a library that allows easy use of sophisticated DVD
libdvdnav: navigation features such as DVD menus, multiangle playback and even
libdvdnav: interactive DVD games.
libdvdnav: 
libdvdnav: 
libdvdnav: 
libdvdnav: 
libdvdnav: 
libdvdnav: 
EODESC
}

copy_docs() {
	for stuff in ${docs[@]}; do
		if [ ! -d "$startdir/pkg/usr/doc/$pkgname-$pkgver" ]; then
			mkdir -p $startdir/pkg/usr/doc/$pkgname-$pkgver
		fi
		find $startdir/src -type f -iname "$stuff" -exec cp -R '{}' $startdir/pkg/usr/doc/$pkgname-$pkgver \;
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
#Added by slkbuild 0.2
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

pkgname=libdvdnav
pkgver=4.1.3
pkgrel=1tm
arch=i686
package=$pkgname-$pkgver-$arch-1tm
source=("http://www2.mplayerhq.hu/MPlayer/releases/dvdnav/libdvdnav-4.1.3.tar.bz2")
sourcetemplate=http://thenktor.dyndns.org/packages/libdvdnav
docs=(readme install copying changelog authors news todo maintainers)
export CFLAGS="-O2 -march=i686 -mtune=i686"
export CXXFLAGS="-O2 -march=i686 -mtune=i686"

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
check_for_menu_compliance
strip_binaries
gzip_man_and_info_pages
set_post_permissions
copy_build_script
create_package
create_source_file
echo "Package has been built."
echo "Cleaning pkg and src directories"
clean_dirs
