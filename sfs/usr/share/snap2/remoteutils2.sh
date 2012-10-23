#!/bin/bash
#    Copyright 2011 Lloyd Standish
#    http://www.crnatural.net/snap2
#    lloyd@crnatural.net

#    This file is part of snap2.

#    snap2 is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    snap2 is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with snap2.  If not, see <http://www.gnu.org/licenses/>.
# store return value in variable, then check error code
# zero means success
version=4.13
# this version number is not necessarily the same as the snap2 version
# it changes only when this file is updated
# unrecognized getopts action: printf "Usage: %s: -a action [-v version]\n" $(basename $0) >&2

function findoldest()
{
basepath=$1 #$dst/recent
max=$2
export oldest
for oldest in `seq 0 $max`; do
	if [ ! -d $basepath.$((oldest+1)) ]; then
		break
	fi
done
checkdir=$basepath.$((oldest+1))
if [ -d $checkdir ]; then
	if [ -d $checkdir~ ]; then
		rm -fr $checkdir~
	fi
	mv $checkdir $checkdir~
fi

}
passedversion=
settingsdir=
passeddir=
earlierdir=
isremote=""
z=''

while getopts 'a:v:s:d:c:r' OPTION
do
	case $OPTION in
	a)	action="$OPTARG"
		;;
	v)	passedversion="$OPTARG"
		;;
	d)	passeddir="$OPTARG"
		;;
	c)	earlierdir="$OPTARG"
		;;
	s)	settingsdir="$OPTARG"
		;;
	r)	isremote="remote "
		;;
	?)	printf "Usage: %s: -a action [-v version]\n" $(basename $0)
		exit 1
		;;
	esac
done
shift $(($OPTIND - 1))


if [ "$passedversion" != "$version" ]; then
	echo "Incorrect version number for remoteutils2.sh"
	echo "current=$version, required=$passedversion"
	exit 4
fi

if [ "$isremote" != "" ]; then
	settingsdir="$settingsdir-remote"
fi
remotehome="$HOME"
	
#if [ "$action" = "addkey" ]; then
#	mkdir -p "$HOME/.ssh"
#	touch "$HOME/.ssh/authorized_keys"
#	if [ ! -w "$HOME/.ssh/authorized_keys" ]; then
#		echo "The file $HOME/.ssh/authorized_keys is not writable by user $USER. Please change the ownership of this file and try again."
#		echo "Press ENTER to close this window"
#		read i
#		exit 1
#	fi
#	echo "$1 $2 $3" >> "$HOME/.ssh/authorized_keys"
#	exit 0
#fi


if [ ! -d "$HOME/.snap2/$settingsdir" ]; then
#    echo "${remote}settings directory not found, creating..."
    if ! mkdir "$HOME/.snap2/$settingsdir"; then
	echo "${isremote}settings directory not found and could not be created."
    	exit 1
    fi
fi

if [ ! -f "$HOME/.snap2/$settingsdir/settings" ]; then
    echo "${isremote}settings file not found"
    exit 5
fi

. "$HOME/.snap2/$settingsdir/settings"

#if [ "$action" = "progressbar" ]; then
#	while true; do
#		for i in $(seq 0 10 90); do
#			if ! ps -p $1 -o comm= > /dev/null; then
#				echo 100
#				break 2
#			else
#				echo $i
#			fi
#			sleep 0.3
#		done
#	done
if [ "$action" = "cksnap2remote" ]; then
# always run locally
# probably unnecessary for below: -o stricthostkeychecking=no
	ssh $remotelogin@$remotehost ls $remotehome/.snap2/remoteutils2.sh > /dev/null
	echo $?	> $passeddir
elif [ "$action" = "makesnap2remote" ]; then
# always run locally
	ssh $remotelogin@$remotehost mkdir -p $remotehome/.snap2
	echo $?	> $passeddir
elif [ "$action" = "copymeremote" ]; then
# always run locally
	scp /usr/share/snap2/remoteutils2.sh $remotelogin@$remotehost:$remotehome/.snap2/
	echo $?	> $passeddir
#elif [ "$action" = "savekeyremote" ]; then
# always run locally
#	ssh $remotelogin@$remotehost $remotehome/.snap2/remoteutils2.sh -s $settingsdir -v $passedversion -a addkey -r $1 $2 $3
#	echo $?	> $passeddir
elif [ "$action" = "logchoose" ]; then
	xml=""
	for file in `ls -dt $dst/*.[0-9] $dst/*.[1-9][0-9] 2>/dev/null; ls -d $dst/mirror 2>/dev/null`
	do
		datetime=`ls --time-style=long-iso -ld $file | cut -d ' ' -f 6-7`
#		if [ -f "$file/snapshot.log" ]; then
#			mv -f "$file/snapshot.log" "$file/backuplog.txt"
#		elif [ -f "$file/snapshot.log.gz" ]; then
#			mv -f "$file/snapshot.log.gz" "$file/backuplog.txt.gz"
#		fi
#		if [ -f "$file/mirror.log" ]; then
#			mv -f "$file/mirror.log" "$file/backuplog.txt"
#		elif [ -f "$file/mirror.log.gz" ]; then
#			mv -f "$file/mirror.log.gz" "$file/backuplog.txt.gz"
#		fi
		if [ -f "$file/backuplog.txt" -o -f "$file/backuplog.txt.gz" ] ; then
#				icon='<pixmap icon_size="2"><input file stock="gtk-file"></input></pixmap>'
			datetime="(log available) $datetime"
		fi
		file=`basename $file`
#		var=`echo $file | sed 's/\./_/'`
		xml="${xml}<item>$file $datetime</item>"
	done
	echo "$xml"
	exit 0
elif [ $action = "compare" ]; then
	if [ ! $earlierdir -o ! -d $dst/$earlierdir -o ! $passeddir -o ! -d $dst/$passeddir ]; then
		echo "ERROR: $dst/$earlierdir or $dst/$passeddir do not exist"
		exit 1
	else
		rsync -vanu${z} $dst/$earlierdir/* $dst/$passeddir/ | sed '/\/$/d'
	fi
elif [ "$action" = "showlog" ]; then
	snaplogtemp="/tmp/snaplogtemp-$$"
#	: > $snaplogtemp
	file="$dst/$passeddir"
	if [ -f "$file/backuplog.txt.gz" ]; then
		if [ ! `which gunzip` ]; then
			echo "Sorry, this log file is compressed and gunzip is unavailable." > $snaplogtemp
		else
		 	gunzip -c "$file/backuplog.txt.gz" > $snaplogtemp
		fi
	elif [ -f "$file/backuplog.txt" ]; then
		cp "$file/backuplog.txt" $snaplogtemp
	fi
	cat $snaplogtemp
	rm -f $snaplogtemp
elif [ "$action" = "deldir" ]; then
	rm -fr $dst/$passeddir 2>&1
	exit $?
elif [ "$action" = "getreference" ]; then
#if [ "$1" == "-genkeys" ]; then
#	ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ""
#	echo "Press ENTER to continue."
#	read i
#	exit 0
#fi
	rsync=`which rsync`
	if [ "$?" -ne 0 -o ! -x "$rsync" ]; then
		echo "rsync not found on remote server, or is not executable.  snap2 requires rsync."
		exit 1
	fi

	if [ ! -d "$dst" ]; then
		if [ -n "$bol_makedestroot" ]; then
			mkdir -p $dst
		else
			echo "Destination root $dst not found, and the 'bol_makedestroot' setting does not allow its creation.  Check that you have the correct backup media or create $dst"
			exit 1
		fi
	fi
	
	for snaptype in recent daily weekly monthly
	do
		lastsecs=
		thissecs=
		for file in `ls -dt $dst/$snaptype.* 2>/dev/null`
		do
			thissecs=`date -r $file +%s`
			if [ "$lastsecs" ]; then
				if [ "$lastsecs" -lt "$thissecs" ]; then
					echo "Snapshot class $snaptype out of sequence starting with directory $file!"
					exit 1
				fi
			fi
			lastsecs=$thissecs
		done
	done
	
	reference="none"
#	while true
	for snaptype in recent daily weekly monthly
	do
		newest=`ls -dtr $dst/$snaptype.* 2>/dev/null | tail -n 1 | sed 's/^.*\.//'`
		if [ -d "$dst/$snaptype.$newest" ]; then
			reference="$snaptype.$newest"
			break
		fi
	done
	if [ "$newest" = "0" ]; then
		echo "Error: snapshot backups on the remote server were not rotated properly the previous time backup was done.  The last backup is in directory $reference.  It should be $snaptype.1. This indicates that backup rotation was not completed, and the backup itself may be incomplete. Please review, and either delete $reference, or rename it to $snaptype.1.  $reference can be deleted using 'Backup Tools' on the 'Logs and Reports' tab."
		exit 1
#	elif [ "$reference" != "none" ]; then
#		cp -al $dst/$reference $dst/recent.0
	fi
	if [ "$reference" = "none" -a -d "$dst/mirror" ]; then
		reference="mirror"
	fi
	echo "$reference"
elif [ "$action" = "rotatebackups" ]; then
	# Rotate the current list of recent backups, if we can.
	findoldest $dst/recent $recent
#	oldest=`ls -dt $dst/recent.* | tail -n 1 | sed 's/^.*\.//'`
	for i in `seq $oldest -1 0`; do
		mv $dst/recent.$i $dst/recent.$((i+1)) 2>/dev/null
	done
	# finally, make the new snapshot reflect the current date.
	[ -d "$dst/recent.1" ] && touch $dst/recent.1
	# if we've rotated the last backup off the stack, promote it to daily if older than one day.
	if [ -d $dst/recent.$((recent+1)) ]; then
		secsoldest=`date -r $dst/recent.$((recent+1)) +%s`
		secsnewestnext=`date -r $dst/daily.1 +%s 2>/dev/null`
		echo "'Recent' snapshot stack rolled over..."
		# 57600 seconds = 16 hours
		if [ ! -d "$dst/daily.1" -o $((secsoldest-secsnewestnext)) -gt 57600 ]; then
			echo "Promoting to daily!"
			mv $dst/recent.$((recent+1)) $dst/daily.0
		
			# Rotate the current list of daily backups, if we can.
			findoldest $dst/daily $daily
#			oldest=`ls -dt $dst/daily.* 2>/dev/null | tail -n 1 | sed 's/^.*\.//'`
			for i in `seq $oldest -1 0`; do
				mv $dst/daily.$i $dst/daily.$((i+1)) 2>/dev/null
			done
		
			# if we've rotated the last backup off the stack, maybe promote it.
			if [ -d $dst/daily.$((daily+1)) ]; then
				secsoldest=`date -r $dst/daily.$((daily+1)) +%s`
				secsnewestnext=`date -r $dst/weekly.1 +%s 2>/dev/null`
				echo "'Daily' snapshot stack rolled over..."
				# check for backup at least one week minus 8 hours older than last weekly
				if [ ! -d "$dst/weekly.1" -o $((secsoldest-secsnewestnext)) -gt 576000 ]; then
					echo "Promoting to weekly!"
				#promote to weekly!
					mv $dst/daily.$((daily+1)) $dst/weekly.0
		
					# Rotate the current list of weekly backups, if we can.
					findoldest $dst/weekly $weekly
#					oldest=`ls -dt $dst/weekly.* 2>/dev/null | tail -n 1 | sed 's/^.*\.//'`
					for i in `seq $oldest -1 0`; do
						mv $dst/weekly.$i $dst/weekly.$((i+1)) 2>/dev/null
					done
					# if we've rotated the last backup off the stack, maybe promote it.
					if [ -d $dst/weekly.$((weekly+1)) ]; then
						secsoldest=`date -r $dst/weekly.$((weekly+1)) +%s`
						secsnewestnext=`date -r $dst/monthly.1 +%s 2>/dev/null`
						echo "'Weekly' snapshot stack rolled over..."
						# 22 days = 1900800 secs
						if [ ! -d "$dst/monthly.1" -o $((secsoldest-secsnewestnext)) -gt 1900800 ]; then
						echo "Promoting to monthly!"
	
						#promote to monthly!
							mv $dst/weekly.$((weekly+1)) $dst/monthly.0
							# Rotate the current list of monthly backups, if we can.
							findoldest $dst/monthly $monthly
#							oldest=`ls -dt $dst/monthly.* 2>/dev/null | tail -n 1 | sed 's/^.*\.//'`
							for i in `seq $oldest -1 0`; do
								mv $dst/monthly.$i $dst/monthly.$((i+1)) 2>/dev/null
							done
							# if we've rotated the last backup off the stack, remove it.
							[ -d $dst/monthly.$((monthly+1)) ] && rm -rf $dst/monthly.$((monthly+1))
						else
							echo "Discarding"
							rm -rf $dst/weekly.$((weekly+1))
						fi	
					fi
				else
					echo "Discarding"
					rm -rf $dst/daily.$((daily+1))
				fi
			fi
		else
			echo "Discarding"
			rm -rf $dst/recent.$((recent+1))
		fi
		if ls $dst/*.0 > /dev/null 2>&1; then
			echo "Error rotating backups: there exists a backup with extension '.0', Please delete or rename."
			exit 1
		fi
	fi
fi
exit 0
