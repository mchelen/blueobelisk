#!/usr/bin/perl
#
# get links from posts and put them in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);
use URI::Escape;
use Statistics::Descriptive;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $last_week = '2006-08-01';
my $last_month = '2006-07-01';

my $sql = $db->prepare("SELECT blog_id, terms.post_id, term, DATEDIFF(CURRENT_TIMESTAMP(), posts.pubdate) AS days_ago FROM terms, posts WHERE posts.post_id = terms.post_id");
$sql->execute();

# burst algorithm
#
# for each pos:
# markov chain - start at start_date (pos = 0), move along to end_date (pos = e)
# score at that point = number of times terms appears / number of posts published on that date
# if pos > (pos - 1) * gamma
# where gamma is some arbitrary constant reflecting how difficult it is to achieve a burst
# then burst_score ++
# if burst_score >= threshold then count it as a proper burst

my $gamma = 0.5; # threshold is (average freq + (gamma x std.dev))
my $min_posts = 2; # needs to be in at least $min_posts posts to be a burst.

my $start_date = 0; # days ago
my $end_date = 3; # days ago
my $bg_period = 30;

my %terms;
my %posts;
my %total;
my %total_posts;
my %valid;

while (my $row = $sql->fetchrow_hashref()) {
	my $term = $row->{"term"};
	my $days_ago = $row->{"days_ago"};
	my $post_id = $row->{"post_id"};
	my $blog_id = $row->{"blog_id"};

	$total_posts{$post_id} = 1;
	$total{$term}++;
	$posts{$days_ago}++;
	$terms{$term}{$days_ago}++;

	if (($days_ago >= $start_date) && ($days_ago <= $end_date)) {
		$valid{$term} = 1;
	}
}
my $total_posts = scalar(keys(%total_posts));

my %bursts;

# go through each possible burst term
foreach my $term (keys(%valid)) {
	my $stats = Statistics::Descriptive::Sparse->new();
	for (my $k=$end_date; $k <= ($end_date + $bg_period); $k++) {
		# get an idea of what term freq to expect
		my $freq = $terms{$term}{$k};
		if (!$freq) {$freq = 0;}
		$stats->add_data($freq);
	}
	
	my $threshold = $stats->mean() + ($gamma * $stats->standard_deviation());
	
	my $freq = 0;
	my $posts = 0;
	for (my $k=$end_date; $k >= $start_date; $k--) {
		# look at what the actual freq is
		$freq += $terms{$term}{$k};
		$posts += $posts{$k};
	}
	
	my $actual_freq = $freq / $posts;
	
	if ($freq < $min_posts) {$actual_freq = 0;} # dismiss any terms that appear in fewer than $min_posts posts
	
	if ($actual_freq > $threshold) {
		my $score = 0;
		if ($threshold <= 0) {$score = 1;} else {$score = $actual_freq / $threshold;}
		$bursts{$term} = $freq;
		print STDERR "$term $freq $score $threshold\n";
	}
}

my $delete = $db->prepare("DELETE FROM bursts");
$delete->execute();

foreach my $term (keys(%bursts)) {
	my $update = $db->prepare("INSERT INTO bursts (term, score) VALUES (?, ?)");
	$update->execute($term, $bursts{$term});
}
