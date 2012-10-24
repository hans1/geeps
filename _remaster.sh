#!/bin/sh
mksquashfs wiper-fs/ wiper/puppy_slacko_5.3.3.sfs -noappend
genisoimage -b isolinux.bin -c boot.cat -D -l -R -v -no-emul-boot -boot-load-size 4 -boot-info-table -o "wiper.iso" wiper
