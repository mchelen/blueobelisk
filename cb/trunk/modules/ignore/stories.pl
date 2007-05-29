#!/usr/bin/perl
#
# stories.pl
# 
# UNDERSTANDS: nature.com\/news
# UNDERSTANDS: newscientist.com
# UNDERSTANDS: the-scientist.com
# UNDERSTANDS: eurekalert
# UNDERSTANDS: washingtonpost.com

use strict;
use lib ("..");

use helper qw(download_url);
use config qw(url_breakdown trim);
use HTML::TreeBuilder;

my $url = $ARGV[0];

my ($path, $domain, $directory, $file) = url_breakdown($url);

my $page = download_url($url);

if ($page) {
	my $tree = HTML::TreeBuilder->new_from_content($page);
	my @titles = $tree->look_down("_tag", "title");

	# get title
	if (@titles) {
		my $title = $titles[0]->as_text;
		print STDERR "Got title ".$title."\n";
		print "STORY"."\t".$title."\n";
	}

	# get summary

	my @scripts = ($tree->look_down("_tag", "script"), $tree->look_down("_tag", "style"));
	foreach my $script (@scripts) {
  		$script->delete();
	}

	my $content = $tree->as_HTML();

	# remove anchors and <p>s
	$content =~ s/<a(?:[^>]*)>([^<]*)<\/a>/\1/ig;
	$content =~ s/<p(?:[^>]*)>//ig;
	$content =~ s/<\/p(?:[^>]*)>//ig;
	$content =~ s/\&(\w{1,8})\;/ /ig;

	# look for two sentences following on from one another without any tags...
	while ($content =~ />([^<]{256,})</ig) {
		my $match = trim($1);
		$match =~ s/[\n\r\t]//g;
		$match =~ s/\s\s/ /g;
		
		my $start = 0;
		my $pos = 255;

		while (substr($match,$start,1) =~ /[\W]/i) {$start++; print STDERR "+";}
		while (substr(substr($match,$start),$pos,1) =~ /[\w]/i) {$pos--; print STDERR "-";}

		if ($start >= $pos) {next;}

		$match = substr($match,$start,$pos);	

		print "SUMMARY"."\t".$match."\n";
		last;
	}
}
