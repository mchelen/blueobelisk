#!/usr/bin/perl
#
# generate_stats.pl
#
# generate some unchanging stats (blog rankings, journal paper shares etc.)
# there's no point in working these out dynamically as they only change when there's been a pipeline update
#

use lib (".");
use strict;
use DBI;
use config qw(%config quick_parse_post_xml log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);
use Lingua::EN::Fathom;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# blog stats
#
# total incoming links & a ranking derived from that
# incoming links per post
# number of posts
# average / highest incoming links per post
# most popular posts
# word counts for posts
# posting frequency
# outgoing links

my $age_limit = 90; # only count posts from last two months
my $only_ranks = 0;

# start transaction....
my $sql = $db->prepare("START TRANSACTION");
$sql->execute();

my $sql = $db->prepare("DELETE FROM blog_stats");
$sql->execute() if (!$only_ranks);
my $sql = $db->prepare("DELETE FROM journal_stats");
$sql->execute();

my %blogs;
my %titles;
my $sql = $db->prepare("SELECT DISTINCT blog_id, title FROM blogs");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$blogs{$row->{"blog_id"}} = 0;
	$titles{$row->{"blog_id"}} = $row->{"title"};
}

my %blog_love;
my %link_love;

my $text = new Lingua::EN::Fathom;
	
foreach my $blog_id (keys(%blogs)) {
	if ($only_ranks) {next;}
	my $incoming_links = 0;
	my $outgoing_links = 0;
	my $incoming_bloglove = 0;
	my $outgoing_bloglove = 0;
	my $num_posts = 0;
	my $concat_text = "";
	my $average_words_per_post = 0;
	my $percent_complex_words = 0;
	my $readability_flesch = 0;
	my $readability_kincaid = 0;
	my $readability_fog = 0;
	
	$sql = $db->prepare("SELECT COUNT(DISTINCT links.url_hash) AS outgoing_links FROM links, posts WHERE links.post_id = posts.post_id AND posts.blog_id=? AND DATEDIFF(CURRENT_TIMESTAMP(), posts.pubdate) <= ?");
	$sql->execute($blog_id, $age_limit);
	while (my $row = $sql->fetchrow_hashref()) {$outgoing_links = $row->{"outgoing_links"};}
	
	$sql = $db->prepare("SELECT COUNT(DISTINCT links.url_hash) AS incoming_links FROM links, posts WHERE posts.url_hash = links.url_hash AND posts.blog_id=? AND DATEDIFF(CURRENT_TIMESTAMP(), posts.pubdate) <= ?");
	$sql->execute($blog_id, $age_limit);
	while (my $row = $sql->fetchrow_hashref()) {$incoming_links = $row->{"incoming_links"};}
	
	$sql = $db->prepare("SELECT COUNT(DISTINCT posts.blog_id) AS outgoing_bloglove FROM links, posts WHERE links.blog_id=? AND links.url_hash = posts.url_hash AND posts.blog_id != ? AND DATEDIFF(CURRENT_TIMESTAMP(), posts.pubdate) <= ?");
	$sql->execute($blog_id, $blog_id, $age_limit);
	while (my $row = $sql->fetchrow_hashref()) {$outgoing_bloglove = $row->{"outgoing_bloglove"};}
		
	$sql = $db->prepare("SELECT COUNT(DISTINCT links.blog_id) AS incoming_bloglove FROM links, posts WHERE posts.url_hash = links.url_hash AND posts.blog_id = ? AND DATEDIFF(CURRENT_TIMESTAMP(), posts.pubdate) <= ?");
	$sql->execute($blog_id, $age_limit);
	while (my $row = $sql->fetchrow_hashref()) {$incoming_bloglove = $row->{"incoming_bloglove"};}

	# now get stats on posts from the past $age_limit days.
	my $sql = $db->prepare("SELECT DISTINCT filename FROM posts WHERE DATEDIFF(CURRENT_TIMESTAMP(), pubdate) <= ? AND blog_id = ?");
	$sql->execute($age_limit, $blog_id);
	while (my $row = $sql->fetchrow_hashref()) {
		$num_posts++;
		my $filename = $row->{"filename"};
		if (-e $filename) {
			my %post = quick_parse_post_xml($filename);
			if (!$post{"description"}) {print STDERR "Couldn't get description for $filename\n";}
			$concat_text .= $post{"description"}."\n";
			print STDERR ".";
		}
	}
	
	# the text analysis is horribly slow, so we might cache results and only change things if the number of 
	# posts has changed significantly since the last time that the analysis was run.
	$text->analyse_block($concat_text);
	
	$readability_fog = $text->fog();
	$readability_flesch = $text->flesch();
	$readability_kincaid = $text->kincaid();
	if ($num_posts) {
		$average_words_per_post = int($text->num_words() / $num_posts);
	}
	$percent_complex_words = $text->percent_complex_words();

	
	print $titles{$blog_id}."\n".
"Num posts: $num_posts
Bloglove (in): $incoming_bloglove
Bloglove (out): $outgoing_bloglove
Flesch: $readability_flesch
Kincaid: $readability_kincaid
Fog: $readability_fog
Avg. words per post: $average_words_per_post
% complex words: $percent_complex_words
Incoming: $incoming_links
Outgoing: $outgoing_links\n";

	my $sql = $db->prepare("INSERT INTO blog_stats (
		blog_id,
		num_posts,
		incoming_bloglove,
		outgoing_bloglove,
		incoming_links,
		outgoing_links,
		avg_words_per_post,
		percent_complex_words,
		readability_flesch,
		readability_kincaid,
		readability_fog
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
	$sql->execute($blog_id, $num_posts, $incoming_bloglove, $outgoing_bloglove, $incoming_links, $outgoing_links, $average_words_per_post, $percent_complex_words, $readability_flesch, $readability_kincaid, $readability_fog);
}	

# journal stats
#
# ranking based on incoming comments per paper
# number of papers
# average / highest comments per paper

my %incoming_links;
my %incoming_bloglove;

my $no_direct_links = 1;

my $sql = $db->prepare("SELECT DISTINCT journal, COUNT(DISTINCT post_id) AS incoming_links, COUNT(DISTINCT blog_id) AS incoming_bloglove FROM papers, links WHERE links.paper_id  = papers.paper_id AND !ISNULL(journal) GROUP BY journal");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $count = $row->{"incoming_links"};
	my $bloglove = $row->{"incoming_bloglove"};
	my $journal = $row->{"journal"};
	$incoming_links{$journal} = $count;
	$incoming_bloglove{$journal} = $bloglove;
}

foreach my $journal (keys(%incoming_links)) {
	my $num_papers = 0;
	my %pubdates;
	# we already have incoming blog links. Get raw number of papers.
	my $sql = $db->prepare("SELECT pubdate FROM papers WHERE journal=?");
	$sql->execute($journal);
	while (my $row = $sql->fetchrow_hashref()) {
		$num_papers++;
		my $pubdate = $row->{"pubdate"};
		my $year = substr($pubdate, 0, 4);
		my $month = substr($pubdate, 5, 2);
		$pubdates{"$year-$month"}++;
	}
	
	# convert pubdates hash to string
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	
	my $current_month = $mon;
	my $current_year = $year;
	
	my $pubdates;
	
	for (my $i=0; $i < 12; $i++) {
		my $padded_month = sprintf("%02s", $current_month);
		my $padded_year = 1900 + $current_year;
		
		my $time = $padded_year."-".$padded_month;
		
		if ($pubdates{$time}) {
			$pubdates .= $pubdates{$time};
		} else {
			$pubdates .= "0";
		}

		$pubdates .= " ";

		$current_month--;
		if ($current_month < 1) {$current_month = 12; $current_year--;}
	}
	
	# now put everything into the database.
	my $insert = $db->prepare("INSERT INTO journal_stats (journal, num_papers, pubdates, incoming_links, incoming_bloglove) VALUES (?, ?, ?, ?, ?)");
	$insert->execute($journal, $num_papers, $pubdates, $incoming_links{$journal}, $incoming_bloglove{$journal});
}

# calculate ranks
my $sql = $db->prepare("SELECT blog_id FROM blog_stats ORDER BY incoming_bloglove DESC, incoming_links DESC");
$sql->execute();
my $counter = 1;
while (my $row = $sql->fetchrow_hashref()) {
	my $blog_id = $row->{"blog_id"};
	my $update = $db->prepare("UPDATE blog_stats SET rank=? WHERE blog_id=?");
	$update->execute($counter, $blog_id);
	$counter++;
}
my $sql = $db->prepare("SELECT journal FROM journal_stats ORDER BY incoming_links DESC, incoming_bloglove DESC");
$sql->execute();
my $counter = 1;
while (my $row = $sql->fetchrow_hashref()) {
	my $journal = $row->{"journal"};
	my $update = $db->prepare("UPDATE journal_stats SET rank=? WHERE journal=?");
	$update->execute($counter, $journal);
	$counter++;
}

# commit transaction
my $sql = $db->prepare("COMMIT");
$sql->execute();










