#!/usr/bin/perl
#
# dxdoi.pl
# 
# DOI resolver module for Postgenomic. Takes in an URL, returns a unique id (a DOI, in this case)
# 
# UNDERSTANDS: dx.doi.org/(.+)
#

use strict;
use URI::Escape;

use lib ("..");

use helper;

my $url = $ARGV[0];

if ($url =~ /dx\.doi\.org\/(.+)/i) {
	# we need to unescape the doi
	
	
	
	print "DOI"."\t".uri_unescape($1)."\n";
}
