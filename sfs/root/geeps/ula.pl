#!/usr/bin/perl

use warnings;
use strict;
use v5.12;

use Tk;
use Tk::widgets;



my $mw = MainWindow->new(-background => '#ffffff');
$mw->geometry($mw->screenwidth . 'x' . $mw->screenheight . '-5-20');
$mw->title("Geeps");

#$mw->FullScreen(1);
#$mw->grabGlobal;
#$mw->focusForce;

my $text = $mw->Scrolled(
	'Text',
	-background => 'white',
	-foreground => 'black',
	-height     => '30',
	-takefocus  => '0',
	-width      => '80',
	-scrollbars => 'e',
	-wrap       => 'word'
)->pack(-pady=>100);
$text->Subwidget->Contents(`cat ULA.txt`);
$text->configure(-state => 'disabled');

my $c = $mw->Canvas(-width => 600, -background => 'white', -highlightthickness => 0);
$c->Button(-text => 'I agree', -background => '#ffffff', -relief => 'flat', -command => sub { exit 0; })->pack(-side=>'left', -padx => 60);
$c->Button(-text => 'I disagree', -background => '#ffffff', -relief => 'flat', -command => sub { exit 1; })->pack(-side=>'right', -padx => 60);
$c->pack();

$mw->update();

MainLoop;
