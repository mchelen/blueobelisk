#!/usr/bin/perl
#
# pnas.pl
#
# PNAS uses the same software as aappublications etc.
#
# UNDERSTANDS: pnas.org
# UNDERSTANDS: aappublications.org
# UNDERSTANDS: physiology.org
# UNDERSTANDS: psychiatryonline.org
# UNDERSTANDS: jneurosci.org
# UNDERSTANDS: jcb.org
# UNDERSTANDS: nejm.org
# UNDERSTANDS: oxfordjournals.org
# UNDERSTANDS: oupjournals.org
# UNDERSTANDS: pubmedcentral.gov
# UNDERSTANDS: pubmedcentral.nih.gov
#

use strict;
use lib ("..");

use helper qw(download_url);
use HTML::TreeBuilder;

my $url = $ARGV[0];

my $page = download_url($url);

if ($page) {
	if ($page =~ /meta name="citation_doi" content="(.*?)"/si) {
		print "DOI"."\t".$1."\n";
		exit;
	}
	
	my $tree = HTML::TreeBuilder->new_from_content($page);
	my @links = $tree->look_down("_tag", "a");

	foreach my $link (@links) {
		my $href = $link->attr("href");
		my $text = $link->as_text;
		
		if ($text =~ /PubMed Citation/i) {
			if ($href =~ /link_type=PUBMED/i) {
				if ($href =~ /access_num=(\d+)/) {print "PMID"."\t".$1."\n"; print STDERR "Got pmid $1\n"; exit;}
			}
		}
	}

	my @options = $tree->look_down("_tag", "option");
	foreach my $option (@options) {
		my $value = $option->attr("value");
		my $text = $option->as_text;
		
		if ($text =~ /PubMed record/i) {
			if ($value =~ /dopt=Abstract/i) {
				if ($value =~ /list_uids=(\d+)/) {print "PMID"."\t".$1."\n"; print STDERR "Got pmid $1\n"; exit;}
			}
		}
	}
}