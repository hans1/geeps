#!/usr/bin/perl

use warnings;
use strict;
use v5.12;

use Tk;
use Tk::widgets qw/JPEG PNG Balloon/;



my $mw = MainWindow->new(-background => '#ffffff');
$mw->geometry($mw->screenwidth . 'x' . $mw->screenheight . '-5-20');
$mw->title("Geeps");

#$mw->FullScreen(1);
#$mw->grabGlobal;
#$mw->focusForce;

my $topy = ($mw->screenheight
		+ 10 # top margin
		- 10 # middle margin
		- 128 # drivedeck height
		- 10 # bottom margin
	) / 2 - 300; # centered to that area minus /2 of instructions height


my $slidedeck = $mw->Canvas(-width => $mw->screenwidth, -height => 600, -background => '#ffffff');

$slidedeck->Button(-text => '<-', -background => '#ffffff', -relief => 'flat', -command => \&prev_slide)->pack(-side => 'left', -fill => 'both');

my $slide = $slidedeck->Canvas(-width => 800, -height => 600, -borderwidth => 0, -highlightthickness => 0);

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

$slidedeck->Button(-text => '->', -background => '#ffffff', -relief => 'flat', -command => \&next_slide)->pack(-side => 'left', -fill => 'both');

$slidedeck->place(-anchor => 'n', -x => $mw->screenwidth / 2, -y => $topy);



my $menu = $mw->Menubutton(-text => 'Menu', -relief => 'raised');
$menu->command(-label => 'Wipe drive', -command => sub{});
my $extras = $menu->cascade(-label => 'Extras');
$extras->command(-label => 'Web Browser', -command => sub { system('seamonkey&'); });
$extras->command(-label => 'Terminal', -command => sub { system('urxvt&'); });
$menu->command(-label => 'Quit', -command => sub { system('wmpoweroff&'); });

$menu->place(-anchor => 'nw', -x => 10, -y => $topy);



my $drivedeck;

my %drvfnames = (drive => 'hdd_mount1.png', usbdrv => 'hdd_usb.png');
my %drvs = map { $_ => $mw->Photo(-file => $drvfnames{$_}); } keys %drvfnames;
sub drive_button {
	my ($dev, $type, $fs, $label) = @_;
	return unless $drvs{$type};

	my $size = '';
	open my $f, "/root/.pup_event/drive_$dev/AppInfo.xml" or die "$!";
	while (<$f>) {
		next unless /<Summary>.*Size: (\S+)</;
		$size = $1;
	}
	close $f;

	my $btn = $drivedeck->Button(
		-image => $drvs{$type},
		-background => '#ffffff', -relief => 'flat', -borderwidth => 0, -highlightthickness => 0,
		-command => sub { system("/root/.pup_event/drive_$dev/AppRun $type $fs"); }
	);
	$mw->Balloon()->attach($btn, -balloonmsg => "$label ($size)\n($type $dev $fs)");
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

	if (@drives == @curdrives) {
		my $d = 0;
		for (0..$#drives) {
			$d += ($drives[$_]->[0] ne $curdrives[$_]->[0]);
		}
		return unless $d;
	}
	@curdrives = @drives;

	$drivedeck->destroy() if $drivedeck;
	$drivedeck = $mw->Canvas(-width => $mw->screenwidth, -height => 128, -background => '#ffffff');
	$drivedeck->delete('all');
	for my $d (@drives) {
		drive_button(@$d);
	}
	$drivedeck->place(-anchor => 's', -x => $mw->screenwidth / 2, -y => $mw->screenheight - 10);

	$mw->update();
}
set_drives();

$mw->update();

# $mw->bind('all' => '<Key-Escape>' => sub {exit;});
$mw->bind('all' => '<Key-Left>' => \&prev_slide);
$mw->bind('all' => '<Key-Right>' => \&next_slide);
$mw->repeat(500, \&set_drives);

MainLoop;
