
0bPress <F3> key to go to advanced help07
If you need particular boot options, type0c puppy07 then a space,
then each boot option. Some boot options:

0cacpi=off07     Default on for PCs >2001, may give boot/shutdown probs.
0cpfix=ram07     Run totally in RAM ignore saved sessions,
0cpfix=<n>07     number of saved sessions to ignore (multisession-CD),
0cpfix=nox07     commandline only, do not start X,
0cpfix=copy07    copy .sfs files to RAM (slower boot, faster running),
0cpfix=nocopy07  do not copy .sfs files to RAM (faster boot, slower running),
0cpfix=fsck07    do filesystem check on slackosave (and host partition),
0cpfix=clean07   file cleanup (simulate version upgrade),
0cpfix=purge07   more radical file cleanup (to fix broken system).
0cplang=<xxxx>07 Locale -- not normally required as asked after bootup.
0cpkeys=<xx>07   Keyboard layout, choices: azerty be-latin1 br-abnt2 br-abnt
    br-latin1-abnt2 br-latin1-us by cf croat cz de de-latin1 dk dvorak dvorak-l
    dvorak-r es et fi fr gr hu101 hu il it jp106 lt mk nl no pl pt-latin1 ro ru
                       se sg sk-qwerty sk-qwertz slovene sv-latin1 uk us wangbe
Examples: 
0cpuppy acpi=off pfix=fr07    Ignore ACPI, French keyboard layout.
0cpuppy pfix=nox,ram07       Run in RAM, do not start X.

