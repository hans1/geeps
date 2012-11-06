#!/usr/bin/perl

use warnings;
use strict;
use v5.12;

use Tk;
use Tk::widgets qw/JPEG PNG Balloon/;

my ($dev, $label, $size, $type, $fs) = @ARGV;


my $mw = MainWindow->new(-background => '#ffffff');
$mw->title("Wipe Drive $label ($dev)");

my $label1 = $mw->Label(-text => "Really wipe drive $label?", -background => '#ffffff'); $label1->grid(-columnspan => 2);
my $label2 = $mw->Label(-text => "Device: $dev  Size: $size  Type: $fs", -background => '#ffffff'); $label2->grid(-columnspan => 2);
my $wipebtn = $mw->Button(-text => 'Wipe', -background => '#ffffff', -relief => 'flat', -command => sub { wipe() });
my $cancelbtn = $mw->Button(-text => 'Cancel', -background => '#ffffff', -relief => 'flat', -command => sub { exit });
$wipebtn->grid($cancelbtn);


sub wipe {
	my $label3 = $mw->Label(-text => "Wiping drive, please wait...", -background => '#ffffff'); $label3->grid(-columnspan => 2);
	$mw->update();

	system('dd', 'if=/dev/zero', 'of='.$dev, 'bs=1048576');
	system('mkdosfs', $dev);
	# sleep(1);

	$label3->gridForget();
	$mw->Label(-text => "Drive wiped successfuly!", -background => '#ffffff')->grid(-row => 3, -column => 0, -columnspan => 2);
	$wipebtn->gridForget($cancelbtn);
	$mw->Button(-text => 'Ok', -background => '#ffffff', -relief => 'flat', -command => sub { exit })->grid(-row => 2, -column => 0, -columnspan => 2);
	$mw->update();
}

$mw->update();

MainLoop;
