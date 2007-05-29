#!/usr/bin/perl
#
# gets links from OpenWetWare pages.
# Remember that you won't see changes with the interface until you run generate_summaries.pl .
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url clean_identifier);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# all changes made in the past seven days.
my $url = "http://openwetware.org/index.php?title=Special:Recentchanges&days=14&limit=1000&feed=atom";

my $OPENWETWARE_IMAGE = "images/oww.png";
my %pages_investigated;

my $feed = download_url($url); # override cached version, if exists
#my $feed = download_url($url, 1); # override cached version, if exists

# now parse out the items in the feed....
while ($feed =~ /<entry>(.*?)<\/entry>/sig) {
	my $entry = $1;
	
	my $link = undef;
	my $summary = undef;
	
	if ($entry =~ /<link(?:.*?)href="(.*?)"/sig) {$link = $1;}
	if ($entry =~ /<summary(?:.*?)>(.*?)<\/summary>/sig) {$summary = $1;}	
		
	if ($link) {
		# check to see if summary of changes includes anything that looks like it might be a citation.
		if ($summary =~ /(pmid=)/i) {
			print STDERR "$link\n";
			investigate_page($link);
		}
	}
}

sub investigate_page {
	my $url = $_[0];
	if ($pages_investigated{$url}) {return 0;} # we've already processed this page this session.
	
	my $page = download_url($url); # don't use cached version.
	clear_comments_from($url);
	
	my $title = "OpenWetWare";
	if ($page =~ /<title>(.*?)<\/title>/si) {$title = $1;}
	print STDERR "Title is $title\n";
		
	# search page for citations...
	my $tree = HTML::TreeBuilder->new_from_content($page);
	my @links = $tree->look_down("_tag", "a");
	foreach my $link (@links) {
		my $pub_url = encode("ascii", $link->attr("href"));
		my $rel = $link->attr("rel");
		my $rev = $link->attr("rev");
		my $class = $link->attr("class");
		my $text = $link->as_text;
	
		if ($pub_url =~ /dopt=Abstract&list_uids=(\d+)/i) {
			my $pmid = $1;
			print STDERR "\tGot PMID $1\n";
			my $paper_id = add_paper($pmid);
			
			if ($paper_id) {
				my $hash = md5_hex($paper_id.$url);
				my $insert = $db->prepare("INSERT IGNORE INTO comments (id_comment_hash, paper_id, image, author, source, url, title, pubdate, added_on, comment) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), ?)");
				$insert->execute($hash, $paper_id, $OPENWETWARE_IMAGE, "an OpenWetWare contributor", "OpenWetWare", $url, $title, "This paper has been cited on OpenWetWare.");
			}
		}
	}
	
	$pages_investigated{$url} = 1;
}

sub clear_comments_from {
	my $url = $_[0];
	
	if ($url) {
		my $sql = $db->prepare("DELETE FROM comments WHERE url=?");
		$sql->execute($url);
	}
	
	return 1;
}

sub add_paper {
	my $pmid = $_[0];
	$pmid = clean_identifier($pmid);
	
	my $paper_id = get_paper_id($pmid);
	
	if (!$paper_id) {
 		if ($pmid) {
			print STDERR "Creating entry for paper with PMID $pmid\n" if $DEBUG;
			my $results = `perl parse_links.pl PMID $pmid`;
			# put resulting paper_id in $paper_id
			$paper_id = get_paper_id($pmid);
			print STDERR "Paper_id returned is $paper_id\n";
		}
	} 
	
	if ($paper_id) {
		# insert into comments table
		print STDERR "Inserting comment for paper with PMID $pmid (paper_id $paper_id)\n" if $DEBUG;
	}
	
	return $paper_id;
}

sub get_paper_id {
	my $pmid = $_[0];
	my $return = 0;
	
	my $sql = $db->prepare("SELECT paper_id FROM papers WHERE pubmed_id=?");
	$sql->execute($pmid);
	
	while (my $row = $sql->fetchrow_hashref()) {
		$return = $row->{"paper_id"};
	}
	
	return $return;
}

log("script complete");







