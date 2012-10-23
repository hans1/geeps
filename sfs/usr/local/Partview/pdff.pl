#!/usr/bin/perl  -w  
# pdff.pl Partition Viewer. 2009-10-22 Ecube
# 2010-04-08 Single window
# 2010-04-11 Wait message
# 2010-05-07 Converted to Glade format 
#   gtkdialog3 --glade-xml=/tmp/partview.glade  --program=dialog1
# 2010-05-10 signal handler="exit:Quit" corrected
#
# Usage pdff.pl [-all] | sh

$view_all=0; if($ARGV[0] && $ARGV[0] eq -all) { $view_all=1; }
$title="Mounted Drives"; $winpos=1;

$pid=$ARGV[1];

if($view_all){
  $title="All Drives";  $winpos=0;
  open(FH,"probepart|") or die "cannot run command probepart\n";

  $i=0;  
  while(<FH>){ if(/\/dev\/(sd\w+)\|(\w+)\|/){
    if($2 eq "swap" || $2 eq "none"){next};
    $all[$i]="$1"; $typ[$i++]="$2"; }
  }
  close FH;
 
  open(FH,"mount | grep /dev/ | grep /mnt/ | sort |")  or die "cannot run command mount\n";

  $i=0;  
  while(<FH>){ if(/\/dev\/(sd\w+)/){ $mnt[$i++]="$1";} }
  close FH;

  $j=0;
  for($i=0;$i<@all;$i++){
    $kmt[$i]=1;
    if(($j < @mnt) && ($all[$i] eq $mnt[$j])){ $kmt[$i]=0; $j++ }
  }

  for($i=0;$i<@all;$i++){ 
    if($kmt[$i]){
      $all[$i]=~/\/dev\/(\w+)/; 
      unless( -e "/mnt/$all[$i]"){ system "mkdir /mnt/$all[$i]\n"}
      system "mount -t $typ[$i]  /dev/$all[$i]  /mnt/$all[$i]\n";
    }
  }
}
#-- sort output from df in reverse order ---
open(FH,"df | sort -r |") or die "cannot run command df -h\n";

if($view_all){
  for($i=0;$i<@all;$i++){ 
    if($kmt[$i]){ system "umount /dev/$all[$i]\n"; }
  }
}

$i=0; $head1="- Size -"; $head2="- Free -";

while(<FH>) {   # process the df command
  if( /^\/dev\/(sd\w+)/ || /^\/dev\/(sr\d+)/ || /^\/dev\/(fd\d+)/ ) {
    $part[$i]=$1; @a=split/\s+/; $size[$i]=$a[1];
    $avail[$i]=$a[3]; chop($a[4]); $fraction[$i]=0.01*$a[4];	
    $ch="K";
    if($size[$i] >999.99) { $size[$i]=$size[$i]/1024.0; $ch="M";}
    if($size[$i] >999.99) { $size[$i]=$size[$i]/1024.0; $ch="G";}
    $_=$size[$i]; &round; $size[$i]=$_.$ch; $ch="K";
    if($avail[$i] >999.99) { $avail[$i]=$avail[$i]/1024.0; $ch="M"; }
    if($avail[$i] >999.99) { $avail[$i]=$avail[$i]/1024.0; $ch="G"; }
    $_=$avail[$i]; &round; $avail[$i]=$_.$ch;
    $i++;
  }
} $mount=$i; ### $mount==0 => No partitions mounted
close FH; 

#------- Design the gtkdialog3 Glade script ---------------------------------------------

$gladefile="/tmp/partview.glade";
open(FH,"+>$gladefile") or die " ERROR: cannot open $gladefile\n";

print FH"<\?xml version=\"1.0\"\?>
<glade-interface>
  <!-- interface-requires gtk+ 2.6 -->
  <!-- interface-naming-policy toplevel-contextual -->
  <widget class=\"GtkDialog\" id=\"dialog1\">
    <property name=\"title\">$title</property>
    <property name=\"border_width\">5</property>
    <property name=\"type_hint\">normal</property>
    <property name=\"has_separator\">False</property>
    <child internal-child=\"vbox\">\n";

print FH"
      <widget class=\"GtkVBox\" id=\"dialog-vbox1\">
        <property name=\"visible\">True</property>
        <property name=\"orientation\">vertical</property>
        <property name=\"spacing\">2</property>
        <child>
          <widget class=\"GtkVBox\" id=\"vbox1\">
            <property name=\"visible\">True</property>
            <property name=\"orientation\">vertical</property>
            <property name=\"spacing\">3</property>
            <child>
              <widget class=\"GtkHPaned\" id=\"hpaned1\">
                <property name=\"visible\">True</property>
                <property name=\"can_focus\">True</property>
                <property name=\"position\">100</property>
                <property name=\"position_set\">True</property>\n";
if($mount){
print FH"
                <child>
                  <widget class=\"GtkLabel\" id=\"label1\">
                    <property name=\"visible\">True</property>
                    <property name=\"label\">&lt\;span foreground=\"magenta\" size=\"larger\"&gt\;$head1&lt\;/span&gt\;</property>
                    <property name=\"use_markup\">True</property>
                  </widget>
                  <packing>
                    <property name=\"resize\">False</property>
                    <property name=\"shrink\">True</property>
                  </packing>
                </child>
                <child>
                  <widget class=\"GtkLabel\" id=\"label2\">
                    <property name=\"visible\">True</property>
                    <property name=\"label\">&lt\;span foreground=\"magenta\" size=\"larger\"&gt\;$head2&lt\;/span&gt\;</property>
                    <property name=\"use_markup\">True</property>
                  </widget>
                  <packing>
                    <property name=\"resize\">True</property>
                    <property name=\"shrink\">True</property>
                  </packing>
                </child>\n";

}
print FH"
              </widget>
              <packing>
                <property name=\"position\">0</property>
              </packing>
           </child>\n";

for($i=0;$i<$mount;$i++) {
 
    $lbl="$part[$i] : $size[$i]";
    $bar="$avail[$i]";

print FH"
            <child>
              <widget class=\"GtkHPaned\" id=\"hpaned2\">
                <property name=\"visible\">True</property>
                <property name=\"can_focus\">True</property>
                <property name=\"position\">100</property>
                <property name=\"position_set\">True</property>
                <child>
                  <widget class=\"GtkLabel\" id=\"label3\">
                    <property name=\"visible\">True</property>
                    <property name=\"label\" translatable=\"yes\">$lbl</property>
                  </widget>
                  <packing>
                    <property name=\"resize\">False</property>
                    <property name=\"shrink\">True</property>
                  </packing>
                </child>
                <child>
                  <widget class=\"GtkProgressBar\" id=\"progressbar1\">
                    <property name=\"visible\">True</property>
                    <property name=\"fraction\">$fraction[$i]</property>
                    <property name=\"text\">$bar</property>
                  </widget>
                  <packing>
                    <property name=\"resize\">True</property>
                    <property name=\"shrink\">True</property>
                  </packing>
                </child>
              </widget>
              <packing>
                <property name=\"position\">1</property>
              </packing>
            </child>\n";
}
if(!$view_all) {
  print FH"
           </widget>
           <packing>
           <property name=\"position\">1</property>
           </packing>
         </child>
        <child internal-child=\"action_area\">
          <widget class=\"GtkHButtonBox\" id=\"dialog-action_area1\">
            <property name=\"visible\">True</property>
            <property name=\"layout_style\">end</property>
            <child>
              <widget class=\"GtkButton\" id=\"button1\">
                <property name=\"label\" translatable=\"yes\">All Drives</property>
                <property name=\"visible\">True</property>
                <property name=\"can_focus\">True</property>
                <property name=\"receives_default\">True</property>

                <signal name=\"pressed\" handler=\"echo all_drives\" after=\"yes\"/>
                <signal name=\"released\" handler=\"exit:Quit\" after=\"yes\"/>
              </widget>
              <packing>
                <property name=\"expand\">False</property>
                <property name=\"fill\">False</property>
                <property name=\"position\">0</property>
              </packing>
            </child>
            <child>
              <widget class=\"GtkButton\" id=\"button2\">
                <property name=\"label\">gtk-quit</property>
                <property name=\"visible\">True</property>
                <property name=\"can_focus\">True</property>
                <property name=\"receives_default\">True</property>
                <property name=\"use_stock\">True</property>
                <signal name=\"clicked\" handler=\"exit:Quit\" after=\"yes\"/>
              </widget>
              <packing>
                <property name=\"expand\">False</property>
                <property name=\"fill\">False</property>
                <property name=\"position\">1</property>
              </packing>
            </child>
          </widget>
          <packing>
            <property name=\"expand\">False</property>
            <property name=\"pack_type\">end</property>
            <property name=\"position\">0</property>
          </packing>
        </child>
      </widget>
    </child>
  </widget>
</glade-interface>\n";
}
else {
print FH"
           </widget>
           <packing>
           <property name=\"position\">1</property>
           </packing>
         </child>
        <child internal-child=\"action_area\">
          <widget class=\"GtkHButtonBox\" id=\"dialog-action_area1\">
            <property name=\"visible\">True</property>
            <property name=\"layout_style\">end</property>
            <child>
              <widget class=\"GtkButton\" id=\"button2\">
                <property name=\"label\">gtk-quit</property>
                <property name=\"visible\">True</property>
                <property name=\"can_focus\">True</property>
                <property name=\"receives_default\">True</property>
                <property name=\"use_stock\">True</property>
                <signal name=\"clicked\" handler=\"exit:Quit\" after=\"yes\"/>
              </widget>
              <packing>
                <property name=\"expand\">False</property>
                <property name=\"fill\">False</property>
                <property name=\"position\">1</property>
              </packing>
            </child>
          </widget>
          <packing>
            <property name=\"expand\">False</property>
            <property name=\"pack_type\">end</property>
            <property name=\"position\">0</property>
          </packing>
        </child>
      </widget>
    </child>
  </widget>
</glade-interface>\n";
}
if($view_all) { system "kill $pid\n"; }

sub round { $_=$_*10.0+0.5; $_=0.1*int($_); } 
