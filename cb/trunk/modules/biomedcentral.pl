#!/usr/bin/perl
#
# biomedcentral.pl
#
# UNDERSTANDS: biomedcentral.com
# UNDERSTANDS: genomebiology.com
# UNDERSTANDS: biology-direct.com
# UNDERSTANDS: beilstein-journals.org
# UNDERSTANDS: scfbm.org
# UNDERSTANDS: \/content\/(\d{1,3})\/(\d{1,3})\/(\d{1,3})
#

use strict;
use lib ("..");

use helper qw(download_url);

my $url = $ARGV[0];

my $page = download_url($url);

if ($page) {
	if ($page =~ /<dc:identifier>info:doi\/(.*)<\/dc:identifier>/i) {
		print "DOI"."\t".$1."\n";
		print STDERR "Got doi $1\n";
	}
	if ($page =~ /<dc:identifier>info:pmid\/(.*)<\/dc:identifier>/i) {
		print "PMID"."\t".$1."\n";
		print STDERR "Got pmid $1\n";
	}
}
