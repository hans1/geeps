#!/usr/bin/perl

use warnings;
use strict;
use v5.12;

use Tk;
use Tk::widgets qw/PNG/;


my $bg = '#a1cee9';

my $mw = MainWindow->new(-background => $bg);
$mw->geometry($mw->screenwidth . 'x' . $mw->screenheight . '-5-20');
$mw->title("Geeps");

#$mw->FullScreen(1);
#$mw->grabGlobal;
#$mw->focusForce;

my $logo = $mw->Canvas(-width => 184, -height => 209, -background => $bg, -highlightthickness => 0);
my $logopic = $mw->Photo(-file => "GeepMascott.png");
$logo->createImage(0, 0, -anchor => 'nw', -image => $logopic);
$logo->place(-anchor => 'ne', -x => $mw->screenwidth() - 20, -y => 20);

my $text = $mw->Scrolled(
	'Text',
	-background => '#ffffff',
	-foreground => 'black',
	-height     => '30',
	-takefocus  => '0',
	-width      => '80',
	-scrollbars => 'e',
	-wrap       => 'word'
)->pack(-pady=>50);
$text->Subwidget->Contents(`cat ULA.txt`);
$text->configure(-state => 'disabled');

my $c = $mw->Canvas(-width => 600, -background => $bg, -highlightthickness => 0);
$c->Button(-text => 'I agree', -background => '#ffffff', -relief => 'flat', -command => sub { exit 0; })->pack(-side=>'left', -padx => 60);
$c->Button(-text => 'Cancel', -background => '#ffffff', -relief => 'flat', -command => sub { exit 1; })->pack(-side=>'right', -padx => 60);
$c->pack();

$mw->update();

MainLoop;
