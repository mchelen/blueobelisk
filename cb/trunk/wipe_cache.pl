#!/usr/bin/perl
#


use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $sql = $db->prepare("DELETE FROM render_cache");
$sql->execute();

my @files = glob($config{"path_to_interface"}."render_cache/*");
foreach my $file (@files) {
	print STDERR $file."\n";
	unlink($file);
}

log("script complete");







