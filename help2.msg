
0bPress <F2> key to go to basic help07
If you need particular boot options, type0c puppy07 then a space,
then each boot option. Some boot options:

0bThese help locating files at bootup. Examples:07
0cpdev1=sdc107      The boot partition.
0cpsubdir=puppies/wary50107 Path in which Puppy is installed.
0cpsavemark=207     Partition no. (in boot drive) to save session to.
0cpmedia=usbflash07 Type of media booting from. Choose one of these:
             usbflash usbhd usbcd ataflash atahd atacd atazip scsihd scsicd cd
0cpupsfs=sdc1:/puppies/wary501/puppy.sfs07 Override auto search.
0czdrv=sdc1:/puppies/wary501/zdrv.sfs07    Override auto search.
0cunderdog=sda907   Mount an entire Linux distro (in sda9) underneath Puppy.

0bThe following are for debugging, for experts only:07
0cloglevel=<n>07    Bootup verbosity. 7 is high verbosity for debugging.
0cpfix=rdsh07       Execute 'init' then dropout to prompt in initramfs.
0cpfix=rdsh007      Dropout early, before loading kernel drivers.
0cpfix=rdsh607      Dropout just before mount layered filesystem.

More help here: http://kernel.org/doc/Documentation/kernel-parameters.txt

