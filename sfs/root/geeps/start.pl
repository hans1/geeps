#!/usr/bin/perl

use warnings;
use strict;

use Tk;
use Tk::widgets qw/JPEG PNG/;



my $mw = MainWindow->new(-background => '#ffffff');
$mw->geometry($mw->screenwidth . 'x' . $mw->screenheight . '+0+0');
$mw->title("Geeps");

#$mw->FullScreen(1);
#$mw->grabGlobal;
#$mw->focusForce;



my $slidedeck = $mw->Canvas(-width => $mw->width, -height => 600, -background => '#ffffff');

$slidedeck->Button(-text => '<-', -background => '#ffffff', -command => \&prev_slide)->pack(-side => 'left', -fill => 'both');

my $slide = $slidedeck->Canvas(-width => 800, -height => 600);

my @picfnames = qw(geeps1c8.png geeps2c8.png geeps3c8.png geeps4c8.png);
my @pics = map { $mw->Photo(-file => $_); } @picfnames;
my $pici = 0;
sub set_slide {
	my ($i) = @_;
	$slide->delete('all');
	$slide->createImage(0, 0, -anchor => 'nw', -image => $pics[$i]);
	$slide->pack(-side => 'left');
}
sub prev_slide {
	$pici = ($pici - 1) % 4; set_slide($pici);
}
sub next_slide {
	$pici = ($pici + 1) % 4; set_slide($pici);
}
set_slide($pici);

$slidedeck->Button(-text => '->', -background => '#ffffff', -command => \&next_slide)->pack(-side => 'left', -fill => 'both');

$slidedeck->pack();



my $drivedeck = $mw->Canvas(-width => $mw->width, -height => $mw->height - 600, -background => '#ffffff');

my %drvfnames = (drive => 'hdd_mount1.png', usbdrv => 'hdd_usb.png');
my %drvs = map { $_ => $mw->Photo(-file => $drvfnames{$_}); } keys %drvfnames;
sub drive_button {
	my ($label, $dev, $type, $fs) = @_;
	next unless $drvs{$type};
	my $btn = $drivedeck->Button(
		-image => $drvs{$type},
		-command => sub { system("/root/.pup_event/drive_$dev/AppRun $type $fs"); }
	);
	$mw->Balloon()->attach($btn, -balloonmsg => "$label\n($type $dev $fs)");
	$btn->pack(-side => 'right');
}

my @curdrives = ();
sub set_drives {
	my @drives = ();
	open my $f, "/root/Choices/ROX-Filer/PuppyPin" or die "$!";
	while (<$f>) {
		chomp;
		next unless m#pup_event#;
		my ($label, $type, $fs, $dev) = m#label="(.*?)".*args="(.*?) (.*?)">/root/\.pup_event/drive_(.*?)<#;
		push(@drives, [$dev, $type, $fs, $label]);
	}
	close $f;

	$drivedeck->delete('all');
	for my $d (@drives) {
		drive_button(@$d);
	}
}
set_drives();

$drivedeck->pack();

$mw->update();

$mw->bind('all' => '<Key-Escape>' => sub {exit;});
$mw->bind('all' => '<Key-Left>' => \&prev_slide);
$mw->bind('all' => '<Key-Right>' => \&next_slide);

MainLoop;
