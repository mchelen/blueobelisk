#!/usr/bin/perl
#
# scripts that get run once a week
#

use lib (".");
use config qw(%config);

if ($config{"collect_comments"}) {
	system("perl get_comments.pl"); # get comments from various sources
	system("perl parse_comments.pl"); # match them to papers in the db (and create the paper if it doesn't already exist)
}

system("perl utils/get_technorati_portrait.pl"); # get technorati portraits for bloggers

if ($config{"collect_comments"}) {
	system("perl find_f1000_reviews.pl"); # find any F1000 reviews assigned to papers in the db
}

system("perl generate_summaries.pl"); # update summary tables.
system("perl generate_stats.pl"); # generate stats.
system("perl generate_xml.pl"); # generate flatfiles of new papers.
system("perl wipe_cache.pl"); # wipe cache of interface

if ($config{"do_search"}) {
	system("python index.py"); # index those flatfiles
}

system("perl cleanup.pl"); # clean up the cache
