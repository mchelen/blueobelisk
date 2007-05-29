#!/usr/bin/perl
#
# get_connotea_cache.pl
#
# This script uses the Connotea API to see how many people are bookmarking the items we added this time round with
# the pipeline, and what tags they used.
#
# We can incorporate this information into the scoring systems, apart from anything else.
#
use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);

if (!$config{"connotea_username"}) {
	log("script complete: no Connotea username and password supplied.");
	exit;
}

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $max_results = 5000; # don't get more than 5000 results from Connotea.
my $max_days = 14; # don't go more than 14 days back.

# find our "stop" point. This might break if a user can post the same URI more than once - better check that.
# (update: users can't)
my %stop_hashes;
my $sql = $db->prepare("SELECT post_hash FROM connotea_cache");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$stop_hashes{$row->{"post_hash"}} = 1;
}

# get the latest posts from Connotea
my $per_page = 500;
my $URL = sprintf("http://%s:%s\@www.connotea.org/data/?num=$per_page&start=_START_", $config{"connotea_username"}, $config{"connotea_password"});

my $complete = 0;
my $pos = 0;
my %created;
while (!$complete) {
	my $search = $URL;
	$search =~ s/_START_/$pos/g;
	
	print STDERR "Retrieving results from Connotea, starting at $pos, ".scalar(keys(%created))." days back\n" if $DEBUG;
	if ($pos > 0) {sleep($config{"connotea_wait"});}
	my $results = download_url($search, 1);
	
	if ($results =~ /Connotea Unavailable/i) {
		$complete = 1;
		print STDERR "Connotea unavailble - heavy load?\n" if $DEBUG;
		next;			
	}
	
	#open(TEST, "connotea_test.xml");
	#my @results = <TEST>; my $results = "@results";
	#close(TEST);

	if ($results) {
		$results =~ s/\s/_/g;
		while ($results =~ /Post_rdf:about=\"(.*?)\">(.*?)<\/Post/ig) {
			my $post = $2;
			my $uri;
			my $creator;
			my $doi;
			my $pmid;
			my @tags;
			my $created;
			my $comment;
			
			while ($post =~ /URI_rdf:about=\"(.*?)\"/g) {$uri = $1;}
			while ($post =~ /dc:creator>(.*?)<\/dc:creator/g) {$creator = $1;}
			while ($post =~ /dc:subject>(.*?)<\/dc:subject/g) {push(@tags, $1);}
			while ($post =~ /dc:identifier>doi:(.*?)<\/dc:identifier/g) {$doi = $1;}
			while ($post =~ /dc:identifier>PMID:(.*?)<\/dc:identifier/g) {$pmid = $1;}
			while ($post =~ /created>(.*?)<\/created/g) {$created = $1;}
			if ($post =~ /<comment>(?:.*?)<entry>(.*?)<\/entry>(?:.*?)<\/comment>/) {
				$comment = $1;
				$comment =~ s/_/ /g;
			}

			if ($created) {
				$created{substr($created,0,10)} = 1;
			}

			if (scalar(keys(%created)) >= $max_days) {
				$complete = 1;
				print STDERR "w" if $DEBUG;
			}
			
			if ($uri & $creator) {
				# it's a valid post
				#print STDERR md5_hex($creator.$uri).": got post from $creator with tags @tags\n" if $DEBUG;
				print STDERR "." if $DEBUG;
				if ($stop_hashes{md5_hex($creator.$uri)}) {
					$complete = 1;
					print STDERR "x" if $DEBUG;
				} else {
					my $insert = $db->prepare("INSERT IGNORE INTO connotea_cache (post_hash, tags, uri, user, comment, doi, pmid, created, added) VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP())");
					$insert->execute(md5_hex($creator.$uri), join('|',@tags), $uri, $creator, $comment, $doi, $pmid, $created);
				}
			}
		}
	} else {
		$complete = 1;
		print STDERR "Couldn't retrieve $search .\n" if $DEBUG;
	}

	$pos += $per_page;
	if ($pos >= $max_results) {
		$complete = 1;
		print STDERR "Finished retrieval at pos $pos\n" if $DEBUG;
	}
}
