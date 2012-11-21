#!/usr/bin/perl

use warnings;
use strict;
use v5.12;

use Tk;
use Tk::widgets qw/JPEG PNG Balloon/;
use Tk::ProgressBar;

my ($dev, $label, $size, $type, $fs) = @ARGV;

my $cpid;
sub cleanup { kill(15, $cpid) if defined $cpid; }
END { cleanup(); }


my $mw = MainWindow->new(-background => '#ffffff');
$mw->title("Wipe Drive $label ($dev)");
$mw->protocol('WM_DELETE_WINDOW', sub { cleanup(); kill(7, $$); });

my $label1 = $mw->Label(-text => "Really wipe drive $label?", -background => '#ffffff'); $label1->grid(-columnspan => 2);
my $label2 = $mw->Label(-text => "Device: $dev  Size: $size  Type: $fs", -background => '#ffffff'); $label2->grid(-columnspan => 2);
my $wipebtn = $mw->Button(-text => 'Wipe', -background => '#ffffff', -relief => 'flat', -command => sub { wipe() });
my $cancelbtn = $mw->Button(-text => 'Cancel', -background => '#ffffff', -relief => 'flat', -command => sub { cleanup(); kill(7, $$); });
$wipebtn->grid($cancelbtn);


sub wipe {
	my $label3 = $mw->Label(-text => "Wiping drive...", -background => '#ffffff'); $label3->grid(-columnspan => 2);
	my $progressbar = $mw->ProgressBar(-relief => 'flat'); $progressbar->grid(-columnspan => 2);
	my $pgnow = 0; my $max = `blockdev --getsize64 $dev | tr -dc 0-9`;
	$progressbar->configure(-from => 0, -to => 250, -variable => \$pgnow);
	$mw->update();

	$cpid = open(my $fh, '-|');
	if ($cpid == 0) {
		$SIG{USR1} = sub{};
		$| = 1;
		close(STDERR);
		open(STDERR, ">&STDOUT");
		exec('dd', 'if=/dev/zero', 'of='.$dev, 'bs=1048576') or die "$!";
	} else {
		use POSIX ":sys_wait_h";

		$SIG{INT} = \&cleanup;
		$SIG{TERM} = \&cleanup;

		sleep(1);
		while (waitpid($cpid, WNOHANG) <= 0) {
			kill(10, $cpid); # SIGUSR1
			# 1097280+0 records in
			# 1097280+0 records out
			# 561807360 bytes (562 MB) copied, 2.7611 s, 203 MB/s
			<$fh>; <$fh>;
			my $line = <$fh>;
			chomp $line;
			my ($bytes, $mbytes, $time, $speed) = ($line =~ /^(\d+) bytes \(([\d.]+) MB\) copied, ([\d.]+) s, ([\d.]+) MB\/s/);
			$pgnow = 200 * $bytes / $max;
			my $remaining = ($max - $bytes) / ($speed * 1048576);
			my $remainingh = $remaining / 3600;
			my $remainingm = ($remaining % 3600) / 60;
			my $remainings = $remaining % 60;
			my $remtime = sprintf('%d:%02d:%02d', $remainingh, $remainingm, $remainings);
			$label3->configure(-text => "Wiping drive... $speed MB/s, $remtime remaining");
			$mw->update();
			sleep(1);
		}
		$cpid = undef;
	}

	system('mkdosfs', $dev);
	# sleep(1);

	$label3->gridForget();
	$progressbar->gridForget();
	$mw->Label(-text => "Drive wiped successfuly!", -background => '#ffffff')->grid(-row => 3, -column => 0, -columnspan => 2);
	$wipebtn->gridForget($cancelbtn);
	$mw->Button(-text => 'Ok', -background => '#ffffff', -relief => 'flat', -command => sub { exit })->grid(-row => 2, -column => 0, -columnspan => 2);
	$mw->update();
}

$mw->update();

MainLoop;
