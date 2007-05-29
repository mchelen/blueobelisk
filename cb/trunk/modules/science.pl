#!/usr/bin/perl
#
# science.pl
#
# UNDERSTANDS: sciencemag.org
#

use strict;
use lib ("..");

use helper qw(download_url $doi_pattern);

my $url = $ARGV[0];

# rewrite URL to get to abstract if necessary
$url =~ s/content\/full\//content\/abstract\//g;

my $page = download_url($url);

if ($page) {
	if ($page =~ /<meta name="citation_doi" content="(.*?)"/i) {
		my $doi = $1;
		if ($doi =~ /$doi_pattern/ig) {
			print STDERR "Got doi $doi\n";
			print "DOI"."\t".$doi."\n";
			exit;
		}
	}
}

# try and guess the DOI from the URL.. bit dodgy, this...
if ($url =~ /cgi\/content\/(?:full|abstract)\/(.*?)\/(.*?)\/(.*?)\?/i) {
	my $doi = "10.1126/science.$1.$2.$3";
	print "DOI"."\t".$doi."\n";			
}

