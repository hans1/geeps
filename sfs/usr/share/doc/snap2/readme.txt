    Copyright 2011 Lloyd G. Standish
    http://www.crnatural.net/snap2
    lloyd@crnatural.net

    This file is part of snap2.

    snap2 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snap2 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with snap2.  If not, see <http://www.gnu.org/licenses/>.

For changes in this version, see http://www.crnatural.net/snap2

-----------------------------------------------------------------------

OVERVIEW

snap2 is a desktop PC backup program based on rsync, but it is much more than
simply an easy-to-use graphical frontend to rsync.  It features automatically-
rotating 'snapshot' type backups, allowing comparison and recovery of any of
several past versions of files. It also supports simple mirror backups (one
backup copy only).  Backup can be to a second hard drive, USB flash drive, or
to a remote host (via Internet).

The package includes a simple GUI for conveniently configuring the backup and
optionally running it.  However the preferred way to run snap2 is via a cron
job. snap2 has an 'Automatic Backup Scheduler' function to easily set up cron
jobs for automatic backup.

FEATURES

Hard links are used to copy identical files between successive snapshot backups,
resulting in a tremendous savings in backup storage space. Furthermore, during a
backup, rsync only transmits 'deltas' (changes in files), and those changes are
transmitted compressed.  This results in a great savings in bandwidth.

In spite of the hard link trickery, backups always appear (and are accessed and
used) as full backups.  There is no compression.  No special software is
necessary to access the backups. Any file manager can be used to browse the
backups, and file comparison software can be used to visualize changes between
versions.

In sum, with snap2 you get the convenience of full backups with the speed and disk
economy of incremental backups, combined with a simple graphical interface.

snap2 can be used to backup every file on a partition, but the program is designed
to allow SELECTIVE BACKUPS of data files only, skipping files that are readily
and conveniently available for recovery (such as files belonging to the operating
sytem). In a selective backup system, when you need to recover after a
catastrophic event (such as hard drive failure), you FIRST reinstall the OS, and
THEN copy your data files back from your backups.

Although I encourage snap2 users to not back up every file, this does not mean
that backups need be small.  snap2 can handle backups consisting of hundreds of
thousands of files spanning many gigabytes.  Since only new and modified data is
actually transmitted, backup is amazingly fast, even when backing up to a remote
host (over the Internet).

For more information and advice on using snap2 effectively for selective backups,
please visit http://www.crnatural.net/snap2.

-----------------------------------------------------------------------

SNAPSHOT VS MIRROR BACKUPS

This program does backups of sets of source directories using rsync.  There are
2 backup methods:

1. mirror
2. snapshot

For a given source directory, use either the 'mirror' method or the 'snapshot'
method - not both.

'MIRROR' TYPE BACKUPS
A mirror backup is just a single copy of the files in the source directories.
Each time you run a mirror backup, the backup 'mirror' is updated to exactly
reflect your files.  Thus, if you delete files from your source directories
and then run the mirror backup again, the files will also be deleted from the
backup.

(If you want the ability to recover deleted files and previous versions
of files, use the 'snapshot' method instead.)

When a mirror type backup is made, only new and modified files are transmitted/
stored, making backups fast and efficient.

"mirror" top-level backup directories are added on the 'Mirror Backup Paths'
section of the DIRECTORIES TO BACK UP tab.  All files in and under these
directories will be backed up, unless they match an exclusion pattern (see
below).

'SNAPSHOT' TYPE BACKUPS
This method is used to create a *series* of backups, to allow recovery of files
to any of several different points in time.  It should be chosen when you may
want to recover files that you have deleted on the source directories, or when
you may need a previous version of a file.

The latest snapshot is always named 'recent.1'.  The next-oldest is named
'recent.2', etc. Each snapshot backup appears to be a FULL BACKUP of all your
files, including FULL DIRECTORY STUCTURE.

As you run subsequent snapshot backups, snap2 automatically renames the 'recent.x'
backups to create 'daily', 'weekly', and 'monthly' snapshots, 'spaced out' in time
as you would expect. (However, 'monthly' snapshots will generally be made every 4
weeks, not every month.) For more information, see SNAPSHOT BACKUPS IN DEPTH below.

The surprising thing is that snapshot backups generally take up only slightly more
disk space than mirror backups, and are nearly as fast.  How?

Like mirror backups, only new and modified files are transmitted/stored to disk!
All files that do not change from one snapshot backup to the next are reproduced
using HARD LINKS rather than by copying.  Therefore they do not occupy additional
hard disk space, except for a few bytes to store the hard links. This makes
snapshot backups fast and efficient. Often 5 gigabytes of snapshot backups
(25 snapshots of about 200 megabytes each) can be stored to a 1 gig USB drive,
with room to spare.

"snapshot" backup directories are added in the 'Snapshot Backup Paths' section of
the DIRECTORIES TO BACK UP tab.  All files in and under these directories will be
backed up, unless they match an exclusion pattern (see below.)

There is a default backup exclusions file ($HOME/.snap2/$settingsdir/exclude/default),
used for both mirror and snapshot backups. If the configuration option 'Add Default
Exclusions' is checked (ADVANCED tab), it will be used in addition to
any directory-specific exclusions.

---------------------------------------------------------------------

SNAPSHOT BACKUPS IN DEPTH

Each snapshot backup starts with creaton of hard links to a backup "reference"
(newest previous backup).  These hard links are just new filenames that point
to the original data on disk.

Any new files are then added, and changed files are stored in place of the
corresponding hard links. The result is that the size of each snapshot is only
that of the hard links, plus any new or changed files.

After snapshot backups have been run for some time, the backup directories will
look similar to this:

loyd@debiandesk:/media/BACKUP8GIG/snapbackups$ ls -l
total 96
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-23 21:12 daily.1
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-22 08:35 daily.2
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-21 08:35 daily.3
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-18 08:35 daily.4
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-17 08:35 daily.5
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-16 08:35 daily.6
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-14 08:35 daily.7
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-13 08:35 daily.8
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-12 08:35 daily.9
drwxr-xr-x 3 lloyd lloyd 4096 2009-10-07 23:06 mirror
drwxr-xr-x 4 lloyd lloyd 4096 2009-05-25 08:35 monthly.1
drwxr-xr-x 4 lloyd lloyd 4096 2009-04-19 08:35 monthly.2
drwxr-xr-x 4 lloyd lloyd 4096 2009-03-19 08:35 monthly.3
drwxr-xr-x 4 lloyd lloyd 4096 2009-02-08 22:24 monthly.4
drwxr-xr-x 4 lloyd lloyd 4096 2009-10-15 22:36 recent.1
drwxr-xr-x 4 lloyd lloyd 4096 2009-10-13 20:59 recent.2
drwxr-xr-x 4 lloyd lloyd 4096 2009-10-07 23:04 recent.3
drwxr-xr-x 4 lloyd lloyd 4096 2009-09-07 13:51 recent.5
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-27 08:35 recent.6
drwxr-xr-x 4 lloyd lloyd 4096 2009-08-06 08:35 weekly.1
drwxr-xr-x 4 lloyd lloyd 4096 2009-07-30 08:35 weekly.2
drwxr-xr-x 4 lloyd lloyd 4096 2009-07-22 08:35 weekly.3
drwxr-xr-x 4 lloyd lloyd 4096 2009-07-14 18:00 weekly.4

This directory listing is taken directly from my USB drive, to which I backed-up
for several months. Each directory contains a full backup of my home directory,
and appears to contain about 1.5 gigs of files each (total 30 gigs). However,
thanks to hard link magic, which allows storing of only new and modified files,
the actual total size on disk of all these backups is only about 6 gigs.

snap2 rotates and 'spaces out' the backups automatically, so that there is at
least 24 hours between each 'daily' backup, a week between each 'weekly' backup,
and 4 weeks between each 'monthly' backup'. The maximum number of each recent,
daily, weekly and monthly backup is configurable.


HOW SNAPSHOT BACKUPS ARE ROTATED and 'PROMOTED'
A fresh backup always starts as "recent.1"  The next-newest recent backup is
"recent.2", etc. When the maximum number of recent backups is reached, the oldest
"recent" backup is rotated-off, to be either "promoted" to be a new "daily"
backup, or discarded. If the rotated-off "recent" backup is at least 24 hours
newer than the newest "daily" backup, it is "promoted" to be a new "daily"
backup. Otherwise it is discarded.

The newest daily backup is daily.1  When the maximum number of "daily" backups
is reached, the oldest "daily" backup is rotated-off, to be either "promoted"
to be a new "weekly" backup, or discarded. If the rotated-off "daily" backup
is at least 1 week newer than the newest "weekly" backup, it is "promoted" to
be a new "weekly" backup. Otherwise it is discarded.

'Weekly' backups work similarly to "recent" and "daily" backups. With 'monthly'
the oldest backup is never promoted.  It is always discarded.

--------------------------------------------------------------

RUNNING THE BACKUP

To execute the GUI interactive program, for setting up and running backups:

snap2 [settingsdir]

'settingsdir' is an optional argument, used to specify an alternate settings
directory to first load settings from.  The default is 'default.set'.

To execute backups non-interactively from a desktop menu entry (program pauses
after execution to show any error messages), the command is:

snap2shell <snapshot | mirror> [settingsdir]

'settingsdir' is an optional argument, used to specify an alternate settings
directory.

The GUI snap2 will set up cron tasks (via crontab) to run snap2engine
non-interactively (no pause after completion). Look on the 'ADVANCED' tab.

If you wish to set up cron tasks manually, the command is:

snap2engine <snapshot | mirror> [settingsdir] [user]

As above, 'settingsdir' is an optional argument, used to specify an alternate
settings directory. 'user' (the Linux user that is doing the backup) must be
provided in cron tasks, since processes run by cron do not receive the USER
variable from the environment.

Since all configuration can be easily done with the GUI snap2 program, no
further documentation will be provided here.  Those who wish to modify the
various configuration variables manually should consult the settings file
at $HOME/.snap2/default.set/settings.

Again, more information is available on the webpage at
http://www.crnatural.net/snap2

Lloyd G. Standish
June 14, 2010
lloyd@crnatural.net
