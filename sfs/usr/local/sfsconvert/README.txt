Puppy Linux Version 4.3x with 2.6.29 kernel, uses sfs version 4.x and cannot load older sfs version 3.x (used by many previous puppy versions)
What SFS converter does is to auto detect and convert v 3.x to v 4.x or the other way around.

Quote Barry Kauler:
SFS V 3.x vs 4.x

We have a problem coming up, as Linux kernels 2.6.29 and greater require .sfs files built with version 4.0 of 'mksquashfs', whereas older kernels use Squashfs version 3.x (3.3 in our 2.6.25.16 kernel).

If someone downloads a SFS file and it doesn't work, the person needs to know why. There needs to be a message informing them that it is the wrong version. I have put in some basic support for this:

initrd
The 'init' script now rejects SFS files of the wrong version. Previously, if you downloaded an SFS file to /mnt/home and selected it in the BootManager then rebooted, it would get mounted as a Unionfs layer, or would fail to mount -- but the user would still see it selected in the BootManager but it hasn't "loaded" -- and they would be mystified.
At this early boot stage, the wrong version is now detected and will not even be attempted to load.

BootManager
Now, wrong versions are screened out, so they aren't offered as candidates in the left pane. So, the user can't even choose a wrong SFS file to be loaded.

ROX-Filer
When you click on a SFS file, it gets mounted and you can view it's contents. Now, the wrong version is detected and an information notice is displayed.

mksquashfs, unsquashfs
Pup 4.3 has both mksquashfs 3.3 and 4.0, named 'mksquashfs3' and 'mksquashfs4'. There is a symlink 'mksquashfs' to the correct one for the current kernel. The same thing has been done for 'unsquashfs'.
So, 4.3 has the tools to expand and create either type, so it will be easy to create an app to convert a SFS from one type to the other