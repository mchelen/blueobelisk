#!/usr/bin/perl
#
# uchicago.pl
#
# UNDERSTANDS: journals.uchicago.edu
#

use strict;
use lib ("..");

use helper qw(download_url search_pubmed);
use HTML::TreeBuilder;

my $url = $ARGV[0];


if ($url =~ /uchicago\.edu\/(.*?)\/journal\/issues\/v(?:.*?)\/(\d+?)\//i) {
	print STDERR "Got id $1$2\n";
	my $pii = "$1$2";
	
	my @papers = search_pubmed($pii);
	
	if (scalar(@papers) == 1) {
		if ($papers[0]) {
			print "PMID"."\t".$papers[0]."\n";
		}
	}
}



