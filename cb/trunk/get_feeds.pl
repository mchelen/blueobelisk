#!/usr/bin/perl
#
# retrieve feeds from active blogs, save them to the disk for processing
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG);
use XML::Simple;
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $sql = $db->prepare("SELECT blog_id, title, feed_url, active FROM blogs ORDER BY blog_id ASC");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $outfile = "feeds/".md5_hex($row->{"feed_url"});
	my $blog_id = $row->{"blog_id"};
	my $feed_url = $row->{"feed_url"};
	$feed_url =~ s/\s//g;
	my $active = $row->{"active"};

	if (!$feed_url) {
		# no feed URL - bah, mark feed as inactive
		$active = 0;
		my $update = $db->prepare("UPDATE blogs SET active=0 WHERE blog_id=?");
		$update->execute($blog_id);
	}

	if ($active) {
		#my $run = sprintf("curl -L -m 30 -e %s -A \"%s\" -z %s -o %s %s", $config{"referrer"}, $config{"user_agent"}, $outfile, $outfile, $feed_url);
		print STDERR $row->{"blog_id"}.": ".$row->{"title"}."\n";
		#system($run);
		my $feed = download_url($feed_url, 1, 0, $outfile);
		
		if ($feed) {
			open(FEED, ">$outfile");
			print FEED $feed;
			close(FEED);
		}
	} else {
		# remove deactivated feeds from the feeds dir
		if (-e $outfile) {system("rm $outfile");}
	}
}

log("script complete");

