#!/usr/bin/perl
#
# update feed description field in the database, using flatfiles from the feeds/ dir.
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_feed_xml);
use XML::Simple;
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my %hashes;

my $sql = $db->prepare("SELECT blog_id, feed_url FROM blogs");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$hashes{md5_hex($row->{"feed_url"})} = $row->{"blog_id"};
}

my @files = glob("posts/feed_info*");
foreach my $file (@files) {
	my %details = parse_feed_xml($file);
	
	# sometimes the description gets mucked up...
	if (length($details{"description"}) >= 320) {$details{"description"} = "";}
	if ($details{"description"} =~ /no such attr/i) {$details{"description"} = "";}
	if ($details{"description"} =~ /internal server error/i) {$details{"description"} = "";}	
	
	# everything after the feed_info_ part is the feed url hash...
	my $hash;

	if ($file =~ /_info_(.*)/) {$hash = $1;} 

	print $hash."\n";
	my $blog_id = $hashes{$hash};

	if ($blog_id) {
		my $sql = $db->prepare("UPDATE blogs SET description=? WHERE blog_id=?");
		$sql->execute($details{"description"}, $blog_id);
		
		my $sql = $db->prepare("UPDATE blogs SET image=? WHERE ISNULL(image)");
		
		if ((rand(10) <= 5) && ($config{"default_image_alternate"})) {
			$sql->execute($config{"default_image_alternate"});
		} else {
			$sql->execute($config{"default_image"});	
		} 
	}
}

log("script complete");
