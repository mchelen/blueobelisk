#!/usr/bin/perl
#
# get links from posts and put them in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown trim);
use helper qw(download_url non_html);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);
use HTML::Entities;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# do a brute force update of the link page titles, using the cache?
my $shoehorn = 0;

# URLs to skip (should be regular expressions)
my @skip = (
"feedburner",
"photos.\.blogger",
"technorati",
"pheedo"	
);

# get existing names
my %titles;
my $sql = $db->prepare("SELECT url_hash, page_title FROM links");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$titles{$row->{"url_hash"}} = $row->{"page_title"};
}
my $sql = $db->prepare("SELECT url_hash, title FROM posts");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$titles{$row->{"url_hash"}} = $row->{"title"};
}
my $sql = $db->prepare("SELECT url_hash, papers.title AS title FROM papers, links WHERE papers.paper_id = links.paper_id AND !ISNULL(links.paper_id)");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$titles{$row->{"url_hash"}} = $row->{"title"};
}
# don't bother with pages that only have one link, if we're shoehorning
my $sql = $db->prepare("SELECT url_hash, domain, COUNT(*) AS count FROM links WHERE ISNULL(page_title) GROUP BY url_hash");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $count = $row->{"count"};
	if ($count < 2) {
		my $domain = $row->{"domain"};
		my $url_hash = $row->{"url_hash"};
		if ($shoehorn) {$titles{$row->{"url_hash"}} = $domain;}
	}
}	

# prepare the update statement
my $update = $db->prepare("UPDATE links SET page_title=? WHERE url_hash=?");

if ($shoehorn) {
	foreach my $url_hash (keys(%titles)) {
		my $title = $titles{$url_hash};
		$update->execute($title, $url_hash);
	}
	exit;
}

# get links without names
my $sql = $db->prepare("SELECT url, url_hash, domain, file FROM links WHERE ISNULL(page_title)");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $url = $row->{"url"};
	my $url_hash = $row->{"url_hash"};
	my $domain = $row->{"domain"}; # the default name for the link will be the domain. Hopefully it won't come to that, though...
	my $title = $domain;
	my $file = $row->{"file"};
	
	# handle Wikipedia URLs
	if ($domain =~ /wikipedia/i) {
		my $wikipage = $file;
		$wikipage =~ s/_/ /g;
		if ($wikipage =~ /(.*)#(.*)/) {$wikipage = $1;}
		$wikipage = urldecode($wikipage);
		$title = $wikipage;
	}
	
	# eliminate Feedburner URLs and non-HTML results.
	foreach my $pattern (@skip) {
		if ($url =~ /$pattern/i) {$titles{$url_hash} = $domain;}
	}
	if (non_html($url)) {$titles{$url_hash} = $domain;}
	
	if ($titles{$url_hash}) {
		$title = $titles{$url_hash};
		# don't need to retrieve page, we already have a title for this URL
		$update->execute($title, $url_hash);		
	} else {
		# don't cache result, don't use a proxy when downloading page
		my $results = download_url($url, 1, 1);

		if ($results =~ /<title>(.*?)<\/title>/i) {$title = $1;}

		$title = trim(encode("ascii", urldecode(decode_entities($title))));
		$title = substr($title, 0, 254);

		$titles{$url_hash} = $title;
		$update->execute($title, $url_hash);
	}
	
		print STDERR "$url : $title\n";
}

log("script complete");







