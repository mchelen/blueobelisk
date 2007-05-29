#!/usr/bin/perl
#
# nature.pl
#
# UNDERSTANDS: nature.com(?!\/news)
#

use strict;
use lib ("..");

use helper qw(download_url parse_ris $doi_pattern);
use config qw(url_breakdown);
use HTML::TreeBuilder;

my $url = $ARGV[0];
my ($path, $domain, $directory, $file) = url_breakdown($url);

my $page = download_url($url);

if ($page) {
	my $tree = HTML::TreeBuilder->new_from_content($page);
	my @links = $tree->look_down("_tag", "a");

	foreach my $link (@links) {
		my $href = $domain.$link->attr("href");
		my $text = $link->as_text;
		
		if ($text =~ /Export Citation/i) {
			if ($href =~ /ris\/(.*?)\.ris/i) {
				print STDERR "Getting ris $href\n";
				my $ris = download_url($href);
				my %ris = parse_ris($ris);
				
				if (%ris) {
					if ($ris{"UR"} =~ /dx\.doi\.org\/(.*)/) {
						print STDERR "Got doi $1 from url\n";
						print "DOI"."\t".$1."\n";
					}
				}
			}
		}
	}
}
