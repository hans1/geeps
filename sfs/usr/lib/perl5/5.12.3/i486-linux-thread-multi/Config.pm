# This file was created by configpm when Perl was built. Any changes
# made to this file will be lost the next time perl is built.

# for a description of the variables, please have a look at the
# Glossary file, as written in the Porting folder, or use the url:
# http://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary

package Config;
use strict;
# use warnings; Pulls in Carp
# use vars pulls in Carp
@Config::EXPORT = qw(%Config);
@Config::EXPORT_OK = qw(myconfig config_sh config_vars config_re);

# Need to stub all the functions to make code such as print Config::config_sh
# keep working

sub myconfig;
sub config_sh;
sub config_vars;
sub config_re;

my %Export_Cache = map {($_ => 1)} (@Config::EXPORT, @Config::EXPORT_OK);

our %Config;

# Define our own import method to avoid pulling in the full Exporter:
sub import {
    my $pkg = shift;
    @_ = @Config::EXPORT unless @_;

    my @funcs = grep $_ ne '%Config', @_;
    my $export_Config = @funcs < @_ ? 1 : 0;

    no strict 'refs';
    my $callpkg = caller(0);
    foreach my $func (@funcs) {
	die sprintf qq{"%s" is not exported by the %s module\n},
	    $func, __PACKAGE__ unless $Export_Cache{$func};
	*{$callpkg.'::'.$func} = \&{$func};
    }

    *{"$callpkg\::Config"} = \%Config if $export_Config;
    return;
}

die "Perl lib version (5.12.3) doesn't match executable version ($])"
    unless $^V;

$^V eq 5.12.3
    or die "Perl lib version (5.12.3) doesn't match executable version (" .
	sprintf("v%vd",$^V) . ")";


sub FETCH {
    my($self, $key) = @_;

    # check for cached value (which may be undef so we use exists not defined)
    return $self->{$key} if exists $self->{$key};

    return $self->fetch_string($key);
}
sub TIEHASH {
    bless $_[1], $_[0];
}

sub DESTROY { }

sub AUTOLOAD {
    require 'Config_heavy.pl';
    goto \&launcher unless $Config::AUTOLOAD =~ /launcher$/;
    die "&Config::AUTOLOAD failed on $Config::AUTOLOAD";
}

# tie returns the object, so the value returned to require will be true.
tie %Config, 'Config', {
    archlibexp => '/usr/lib/perl5/5.12.3/i486-linux-thread-multi',
    archname => 'i486-linux-thread-multi',
    cc => 'cc',
    d_readlink => 'define',
    d_symlink => 'define',
    dlsrc => 'dl_dlopen.xs',
    dont_use_nlink => undef,
    exe_ext => '',
    inc_version_list => '5.12.2 5.12.1 5.12.0 5.10.1 5.10.0 5.8.8 5.8.7 5.8.6 5.8.5 5.8.4 5.8.3 5.8.2 5.8.1 5.8.0',
    intsize => '4',
    ldlibpthname => 'LD_LIBRARY_PATH',
    libpth => '/usr/local/lib /usr/lib /lib',
    osname => 'linux',
    osvers => '2.6.35.10-smp',
    path_sep => ':',
    privlibexp => '/usr/lib/perl5/5.12.3',
    scriptdir => '/usr/bin',
    sitearchexp => '/usr/lib/perl5/site_perl/5.12.3/i486-linux-thread-multi',
    sitelibexp => '/usr/lib/perl5/site_perl/5.12.3',
    useithreads => 'define',
    usevendorprefix => 'define',
    version => '5.12.3',
};
