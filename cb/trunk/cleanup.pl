#!/usr/bin/perl
#
# cleanup unwanted files
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_feed_xml parse_post_xml);
use XML::Simple;
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# "deactivate" all posts so that we're only checking the most recent ones
my $sql = $db->prepare("UPDATE posts SET active=0");
$sql->execute();

# delete the contents of the temp directory
my @files = glob("temp/*");
foreach my $file (@files) {
	if (-d $file) {
		# skip directories
	} else {
		unlink($file);
	}
}

log("cleanup complete");
