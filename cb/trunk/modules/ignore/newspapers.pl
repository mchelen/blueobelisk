#!/usr/bin/perl
#
# stories.pl
# 
# UNDERSTANDS: nytimes.com(.*)\/health\/(.*)
# UNDERSTANDS: nytimes.com(.*)\/science\/(.*)
# UNDERSTANDS: nytimes.com(.*)\/technology\/(.*)

use strict;
use lib ("..");

use helper qw(download_url google_search);
use config qw(url_breakdown trim);
use HTML::TreeBuilder;

my $url = $ARGV[0];

my @results = google_search("site:".$url);

if (scalar(@results) >= 2) {
	print STDERR "Multiple results returned\n";
} elsif (scalar(@results <= 0)) {
	print STDERR "No results returned\n";
} else {
	my %return = %{$results[0]};
	
	my $title = $return{"title"};
	my $content = $return{"snippet"};
	
	$content =~ s/[\n\r]//g;
	$content =~ s/\s\s/ /g;
	
	$content =~ s/<a(?:[^>]*)>([^<]*)<\/a>/\1/ig;
	$content =~ s/<p(?:[^>]*)>//ig;
	$content =~ s/<(\/)*br(?:[^>]*)>//ig;
	$content =~ s/<\/p(?:[^>]*)>//ig;
	$content =~ s/\&(\w{1,8})\;/ /ig;
	
	print "STORY"."\t".$title."\n";
	print "SUMMARY"."\t".$content."\n";
	
	print STDERR "STORY"."\t".$title."\n";
	print STDERR "SUMMARY"."\t".$content."\n";
}