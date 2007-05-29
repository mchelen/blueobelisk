#!/usr/bin/perl
#
# karger.pl
#
# UNDERSTANDS: karger.com
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
		
		if ($text =~ /Medline Abstract/i) {
			if ($href =~ /dopt=Abstract/i) {
				if ($href =~ /list_uids=(\d+)/i) {print "PMID"."\t".$1."\n"; print STDERR "Got pmid $1\n";}
			}
		}
	}
}
