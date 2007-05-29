#!/usr/bin/perl
#
# sciencedirect.pl
#
# UNDERSTANDS: sciencedirect
#

use strict;
use lib ("..");

use helper qw(download_url);
use HTML::TreeBuilder;

my $url = $ARGV[0];

$url =~ s/&amp;/&/g;
$url =~ s/#038;//g;

my $page = get_page($url);

if ($page =~ /href="(.*?)">View Abstract/i) {
	my $url = "http://www.sciencedirect.com".$1;
	get_page($url);
}

sub get_page {
	my $url = $_[0];
	
	print STDERR "Getting $url\n";
	my $page = download_url($url);

	if ($page) {
		my $tree = HTML::TreeBuilder->new_from_content($page);
		my @links = $tree->look_down("_tag", "a");

		foreach my $link (@links) {
			my $href = $link->attr("href");
			my $target = $link->attr("target");

			if ($target =~ /doilink/i) {
				if ($href =~ /dx.doi.org\/(.*)/i) {
					print "DOI"."\t".$1."\n"; 
					print STDERR "Got doi $1\n";
					exit;
				}
			}
		}
	}
	
	return $page;
}