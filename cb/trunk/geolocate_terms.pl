#!/usr/bin/perl
#
# get links from posts and put them in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urlencode urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my %posts;

# try and geolocate conference reports based on their important terms.
my $sql = $db->prepare("SELECT post_id FROM links WHERE type='conference'");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$posts{$row->{"post_id"}} = 1;
}
my $sql = $db->prepare("SELECT post_id FROM tags WHERE tag='conference'");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$posts{$row->{"post_id"}} = 1;
}

# don't do posts that we've already checked.
my $sql = $db->prepare("SELECT DISTINCT post_id FROM terms WHERE geoname_id < 0");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	delete $posts{$row->{"post_id"}};
}

# now send their terms to the GeoNames webservice to see if we get any hits.
foreach my $post_id (keys(%posts)) {
	my $sql = $db->prepare("SELECT DISTINCT term FROM terms WHERE post_id=?");
	$sql->execute($post_id);
	while (my $row = $sql->fetchrow_hashref()) {
		my $term = $row->{"term"};
				
		# if it looks like a noun, check it out with the webservice...
		my %location;
		if (is_noun($term, $post_id)) {
			%location = geolocate($term);	
		}
		
		if ($location{"success"}) {
			# we got a location. Update the database accordingly.
			print STDERR "Geolocated $term\n" if $DEBUG;
			my $update = $db->prepare("UPDATE terms SET lat=?, lng=?, geoname_id=? WHERE term=?");
			$update->execute($location{"lat"}, $location{"lng"}, $location{"id"}, $term);
		} else {
			# meh, no luck. Update the database accordingly.
			my $update = $db->prepare("UPDATE terms SET geoname_id=? WHERE term=?");
			$update->execute("-1", $term);
		}
	}
}

sub is_noun {
	my $term = $_[0];
	my $post_id = $_[1];

	my $filename = undef;

	my $sql = $db->prepare("SELECT filename FROM posts WHERE post_id=?");
	$sql->execute($post_id);
	while (my $row = $sql->fetchrow_hashref()) {
		$filename = $row->{"filename"};
	}
	
	if ($filename) {
		my %post = parse_post_xml($filename);
		
		my $description = $post{"description"};
		
		# strip out certain punctuation elements
		$description =~ s/['",\.]//g;
		
		# find the term in the fulltext. Try and work out if it's a noun....
		if ($description =~ /($term)/i) {
			print STDERR "Found [$1] in context\n";
			my $context = $1;
			if ($context =~ /[A-Z]([a-z]+)/) {
				return 1;
			}
		} else {
			print STDERR "Couldn't find context of [$term]\n";
		}
	}
	
	return 0;
}

sub geolocate {
	my $term = urlencode($_[0]);
	my $url = "http://ws.geonames.org/search?fclass=P&fclass=A&q=$term";

	my %location;
	$location{"success"} = 0;

	my $results = download_url($url, 1);
	sleep($config{"geonames_wait"});
	
	$results =~ s/\s//g;
	
	if ($results =~ /(?:.*?)<geoname>(.*?)<\/geoname>(?:.*)/i) {
		my $top_result = $1;
		
		my ($lat, $lng, $id) = (undef, undef, undef);
		
		if ($top_result =~ /<lat>(.*?)<\/lat>/i) {$lat = $1;}
		if ($top_result =~ /<lng>(.*?)<\/lng>/i) {$lng = $1;}
		if ($top_result =~ /<geonameId>(.*?)<\/geonameId>/i) {$id = $1;}
		
		if ($lat && $lng && $id) {
			$location{"lat"} = $lat;
			$location{"lng"} = $lng;
			$location{"id"} = $id;
			$location{"success"} = 1;
		}
	}
	
	return %location;
}

log("script complete");







