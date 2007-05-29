#!/usr/bin/perl
#
# bmj.pl
#
# UNDERSTANDS: bmjjournals.com
#

use strict;
use lib ("..");

use helper qw(download_url);
use HTML::TreeBuilder;

my $url = $ARGV[0];

my $page = download_url($url);

if ($page) {
	my $tree = HTML::TreeBuilder->new_from_content($page);
	my @links = $tree->look_down("_tag", "a");

	foreach my $link (@links) {
		my $href = $link->attr("href");
		my $text = $link->as_text;
		
		if ($text =~ /PubMed Citation/i) {
			if ($href =~ /link_type=PUBMED/i) {
				if ($href =~ /access_num=(\d+)/) {print "PMID"."\t".$1."\n"; print STDERR "Got pmid $1\n";}
			}
		}
	}
}
