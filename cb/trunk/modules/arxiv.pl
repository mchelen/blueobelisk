#!/usr/bin/perl
#
# arxivi.pl
# 
# arXiv resolver module for Postgenomic. Takes in an URL, returns a unique id (an arxiv id, in this case)
# 
# UNDERSTANDS: arxiv.org
#

use strict;
use lib ("..");

use helper;

my $url = $ARGV[0];

if ($url =~ /abs\/(.*)\Z/i) {
	my $id = "oai:arXiv.org:".$1;
	print "OAI"."\t".$id."\n";
}
