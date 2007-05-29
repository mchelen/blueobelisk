#!/usr/bin/perl
#
# blackwell.pl
#
# UNDERSTANDS: blackwell-synergy
#

use strict;
use lib ("..");

use helper qw(download_url $doi_pattern);

my $url = $ARGV[0];

my $page = download_url($url);

if ($page) {
	if ($page =~ /<meta name="dc\.Type" content="(.*?)">/i) {
		print "TYPE"."\t".$1."\n";
	}

	while ($page =~ /<meta name="dc\.Subject" content="(.*?)">/mig) {
		print "TAG"."\t".$1."\n";
	}

	if ($page =~ /<meta name="dc\.Identifier" content="(.*?)">/i) {
		my $id = $1;
		if ($id =~ /$doi_pattern/i) {
			print STDERR "Got doi $id\n";
			print "DOI"."\t".$id."\n";
		}
	}
}
