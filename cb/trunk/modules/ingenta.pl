#!/usr/bin/perl
#
# ingenta.pl
#
# UNDERSTANDS: ingenta
#

use strict;
use lib ("..");

use helper qw(download_url $doi_pattern search_pubmed);

my $url = $ARGV[0];

my $page = download_url($url);

if ($page) {
	if ($page =~ /<meta name="DC\.title" content="(.*?)"\/>/i) {
		my $title = $1;
		my @results = search_pubmed($title);

		if (scalar(@results) == 1) {
			print STDERR "Got pmid ".$results[0]."\n";
			print "PMID"."\t".$results[0]."\n";
		}
	}
}
