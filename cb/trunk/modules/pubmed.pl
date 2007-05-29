#!/usr/bin/perl
#
# pubmed.pl
# 
# Pubmed module for Postgenomic. Takes in an URL, returns a unique id (a PMID, in this case)
# 
# UNDERSTANDS: ncbi.nlm.nih.gov/entrez
# UNDERSTANDS: www.ncbi.nlm.nih.gov/entrez
#

use strict;
use lib ("..");

use helper;

my $url = $ARGV[0];

if ($url =~ /db=pubmed/ig) {
	if ($url =~ /list_uids=(\d+)(.*)/ig) {
		if ($2 =~ ",") {next;}
		print "PMID"."\t".$1."\n";
		print STDERR "Got pmid $1\n";
	}
}
