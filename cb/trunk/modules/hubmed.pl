#!/usr/bin/perl
#
# pubmed.pl
# 
# Pubmed module for Postgenomic. Takes in an URL, returns a unique id (a PMID, in this case)
# 
# UNDERSTANDS: hubmed.org
#

use strict;
use lib ("..");

use helper;

my $url = $ARGV[0];

if ($url =~ /(?:display\.cgi)(?:.*)uids=(\d+)/) {
	print "PMID"."\t".$1."\n";
}
