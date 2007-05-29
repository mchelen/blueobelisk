#!/usr/bin/perl
#
# get links from posts and put them in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);

my $page = $ARGV[0];

print STDERR "Fetching $page\n";

my $results = download_url($page, 1); # don't use cached version
print $results;