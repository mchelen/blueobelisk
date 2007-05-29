#!/usr/bin/perl
#
# update MySQL database from remote server
#

use lib (".");
use strict;

my $config = $ARGV[0];

if (!$config) {die("Must specify config file as first argument.");}

our %config = read_config($config);

my $dumpfile = "current.dump";

my $do_download = 0;

if ($do_download) {
	my $server = $ARGV[1];
	if (!$server) {die("Must specify remote server as second argument.");}

	print STDERR "Connecting to $server...";

	my $results = download_url($server.$dumpfile);
	if ($results) {
		open(FILE, ">".$config{"path_to_interface"}.$dumpfile);
		print FILE $results;
		close(FILE);
	} else {
		print STDERR "Couldn't find $dumpfile on $server.\n";
		exit;
	}	
}

if (-e $config{"path_to_interface"}.$dumpfile) {
	my $cmd = sprintf("mysql -u %s --password=%s %s < %s", $config{"db_user"}, $config{"db_password"}, $config{"db_name"}, $config{"path_to_interface"}.$dumpfile);
	print STDERR "Doing:\n$cmd\n";
	system($cmd);
	
	# clearing render cache
	my @cache = glob($config{"path_to_interface"}."render_cache/*");
	foreach my $file (@cache) {
		print STDERR "Clearing $file\n";
		unlink($file);
	}
} else {
	print STDERR "Couldn't see dumpfile, skipping db update.\n";
}


sub read_config {
	my $file = $_[0];
	
	open(FILE, $file) or die("Couldn't open config file, sorry.");
	my @lines = <FILE>;
	close(FILE);
	
	my %config;
	
	foreach my $line (@lines) {
		chomp($line);
		if ($line =~ /(.+?)=(.+)/i) {
			$config{$1} = $2;
			print STDERR "$1 == $2\n";
		}
	}
	
	return %config;
}

sub download_url {
	my $url = $_[0];
	
	$url =~ s/&#038;/&/g;
	
	my $agent = $config{"user_agent"};
	
	my $results = `curl -L -g -m 30 -A "$agent" "$url"`;
	
	return $results;
}