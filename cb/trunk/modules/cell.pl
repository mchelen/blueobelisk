#!/usr/bin/perl
#
# cell.pl
# 
# understands Cell and any number of Cell-like ScienceDirect journals (Neuron, for example)
#
# UNDERSTANDS: uid=PII*
#

use strict;
use lib ("..");

use helper qw(download_url search_pubmed);
use HTML::TreeBuilder;

my $url = $ARGV[0];

# we can extract the PII / DOI in Pubmed from the PIIS in the URL.
if ($url =~ /uid=PIIS(\d{15}[\d\w])/) {
	my $pii = $1;
	$pii = "S".substr($pii,0,4)."-".substr($pii,4,4)."(".substr($pii,8,2).")".substr($pii,10,5)."-".substr($pii,15,1);
	print STDERR "Got PII $1 => $pii\n";
	my @papers = search_pubmed("$pii");

	if (scalar(@papers) == 1) {
		print "PMID"."\t".$papers[0]."\n";
	}
} else {
	print STDERR "Couldn't get PII\n";
}
exit;


# otherwise... try it the hacky way
my $page = download_url($url);

if ($page) {
	my $tree = HTML::TreeBuilder->new_from_content($page);
	my @h1s = $tree->look_down("_tag", "h1");

	foreach my $h1 (@h1s) {
		my $class = $h1->attr("class");
		if ($class =~ /article_title/i) {
			my $title = $h1->as_text;
			print STDERR "Got title $title\n";
			# search Pubmed for papers with this title
			my @papers = search_pubmed($title." Cell");

			if (scalar(@papers) == 1) {
				print "PMID"."\t".$papers[0]."\n";
			}
		}
	}
}
