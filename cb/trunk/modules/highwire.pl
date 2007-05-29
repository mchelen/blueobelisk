#!/usr/bin/perl
#
# highwire.pl
#
# UNDERSTANDS: nejm.org
#

use strict;
use lib ("..");

use helper qw(download_url parse_ris);
use config qw(url_breakdown);

my $url = $ARGV[0];

my ($path, $domain, $directory, $file) = url_breakdown($url);

my $id;
if ($url =~ /cgi\/(?:(?:content\/(?:summary|short|extract|abstract|full))|reprint)\/(.+)/i) {
      $id = $1;
}
    
die "Couldn't extract Highwire ID\n" unless $id;

# REMEMBER TO CHANGE THIS AT SOME POINT TO MAKE IT MORE FLEXIBLE
my $ris_host = "nejm";

my $article_host = $domain;

my $ris_url = new URI("http://" . $article_host ."/cgi/citmgr?type=refman&gca=" . $ris_host . ";" . $id);

my $page = download_url($ris_url);
my %ris = parse_ris($page);

if (%ris) {
	if ($ris{"N1"} =~ /(.*)/) {
		print STDERR "Got doi $1 from ris\n";
		print "DOI"."\t".$1."\n";
		exit;
	}
}