#!/usr/bin/perl
#
# fix Feedburner permalinks
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# fix Feedburner permalinks
my $sql = $db->prepare("SELECT post_id, url FROM posts WHERE url LIKE '%feeds.feedburner.com%'");
$sql->execute();

while (my $row = $sql->fetchrow_hashref()) {
	my $url = $row->{"url"};
	my $post_id = $row->{"post_id"};
	
	# follow the link, see where we get redirected to
	my $header = `curl -s -I $url`;
	
	if ($header =~ /Location: ([^\s]*)/i) {
		my $real_url = $1;
		if ($real_url =~ /http:\/\/(scienceblogs.*)/) {
			$real_url = "http://www.$1";
		}
		print STDERR "Redirected to [$real_url]\n";
		my $update = $db->prepare("UPDATE posts SET url=?, url_hash=? WHERE post_id = ?");
		$update->execute($real_url, md5_hex($real_url), $post_id);
	} else {
		if ($header =~ /HTTP\/1\.1 404/i) {
			warn("Got 404 for $url\n");
		} else {
			die("Couldn't get redirection for $url. Stopping in case it's a server denial thing:\n$header\n");
		}
	}
}