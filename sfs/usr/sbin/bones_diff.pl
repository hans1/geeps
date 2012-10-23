#!/usr/bin/perl 
# 2009-12-02 Olov woofdiff.pl original version
# 2009-12-03 Olov add option [-v] (verbose output)
# 2009-12-11 Olov verbose output sorted
# BK genealised, specify project name as first param...
# 2009-12-19 Olov Full file path for output
# Usage example: bones_diff.pl [-v] woof 20091120071211 20091202081304

$verbose=0; 
if($ARGV[0] eq "-v") { $verbose=1; shift }
if(@ARGV != 3) { die" +++ INCORRECT INPUT +++ Three arguments required!
 Usage example: bones_diff.pl woof 20091120071211 20091202081304\n"; }
$projectname="$ARGV[0]";
$filename0="$projectname-$ARGV[1].tar.gz";
$filename1="$projectname-$ARGV[2].tar.gz";
print"\n$filename0\n"; print"$filename1\n";
open(FH0,"tar tvf $filename0|") || die"ERROR: cannot run tar tvf $filename0\n";
open(FH1,"tar tvf $filename1|") || die"ERROR: cannot run tar tvf $filename1\n";

# while(<FH0>)  { s/woof-\w+//; if(!/\/$/ && !/->/) { push(@ar0,$_) } } close FH0;
# while(<FH1>)  { s/woof-\w+//; if(!/\/$/ && !/->/) { push(@ar1,$_) } } close FH1;

while(<FH0>)  { 
  s/$projectname-\w+//;  if(/->/) { s/\d{4}-\d{2}-\d{2} \d{2}:\d{2}// };
  if(!/\/$/) { push(@ar0,$_) }; 
} close FH0;
while(<FH1>)  { 
  s/$projectname-\w+//;  if(/->/) { s/\d{4}-\d{2}-\d{2} \d{2}:\d{2}// };
  if(!/\/$/) { push(@ar1,$_) };
}  close FH1;
    
@del = @add = @del_1 = @add_1 = (); %count = ();
foreach $element (@ar0) { $count{$element}++ }
foreach $element (@ar1) { $count{$element}+=2 }
foreach $element (keys %count) {
  if($count{$element} == 1) { push(@del , $element); 
  $element=~/\d{2}:\d{2} \/(.+)$/; push(@del_1 , "$1\n") };
  if($count{$element} == 2) { push(@add , $element); 
  $element=~/\d{2}:\d{2} \/(.+)$/; push(@add_1 , "$1\n") };
}
@del_1=sort(@del_1); @add_1=sort(@add_1);

@update = @del_2 = @add_2 = (); %count = ();
foreach $element (@del_1) { $count{$element}++ }
foreach $element (@add_1) { $count{$element}+=2 }
foreach $element (keys %count) {
  if($count{$element} == 1) { push(@del_2 , $element) };
  if($count{$element} == 2) { push(@add_2 , $element) };
  if($count{$element} == 3) { push(@update , $element) };
}

if(@del_2){ print "\n ----  Files deleted from $filename0 ----\n @del_2\n";}
else{ print "\n ----  No files deleted from $filename0 ----\n @del_2\n";}
if(@add_2){print " ---- Files added to $filename1 ----\n @add_2\n";}
else{ print " ---- No files added to $filename1 ----\n @add_2\n";}
if(@update){print " ---- Updated  files ----\n @update\n";}
else{ print " ---- No pdated  files ----\n @update\n";}
if(!$verbose) { print "  ---- For detailed information use option -v ----\n\n"; }
if($verbose) {
  $df=@del+@add; print "diff = $df\n"; 
  print "  Previous version or deleted  files : $filename0\n";
  foreach $x (@del) {$x=~/([^\/\n]+)$/; $aa{$&}=$x; } foreach $key (sort keys %aa){ print "$aa{$key}"};
  print "  Current version or added files : $filename1\n";
  foreach $x (@add) {$x=~/([^\/\n]+)$/; $aa{$&}=$x; } foreach $key (sort keys %aa){ print "$aa{$key}"};
  print"\n";
}





