#!/usr/bin/perl
#
# get comments from journals that use them and store them on disk
# then check to see if any match the papers we have in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown trim translate_date);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);
use XML::Simple;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $comments_dir = "comments/";
my $dir = "misc/XML_rhighlts";

process_dir($dir);

sub process_file {
	# parse an NPG research hilights file and extract relevant details (author, pubdate, text, title, paper...)
  	my $file = $_[0];
  	
	open(FILE, $file) or die("Couldn't open $file");
	my @lines = <FILE>;
	close(FILE);
	
	my $title = undef;
	my $author = undef;
	my $url = undef;
	my $comment = undef;
	my $paper_doi = undef;
	
	my $lines = "@lines";
	$lines =~ s/[\n\r]//g;
	
	if ($lines =~ /<doi>(.*?)<\/doi>/i) {
		$url = "http://www.nature.com/doifinder/".$1;
	}
	
	if ($lines =~ /<fnm>(.*?)<\/fnm><snm>(.*?)<\/snm>/i) {
		$author = "$1 $2 ";
	}
	
	if ($lines =~ /<bdy>(.*?)<\/bdy>/i) {
		$comment = $1;
	}
	
	if ($lines =~ /<atl>(.*?)<\/atl>/i) {
		$title = $1;
	}
	
	while ($lines =~ /<refdoi>(.*?)<\/refdoi>/gi) {
		$paper_doi = $1;

		if ($title && $paper_doi) {
			my %comment;
			print STDERR ".";
			$comment{"author"} = $author;
			$comment{"comment"} = $comment;
			$comment{"title"} = $title;
			$comment{"url"} = $url;
			$comment{"paper_doi_id"} = $paper_doi;
		
			save_comment("Nature Highlights", \%comment);
		}
	}
}

sub process_dir {
	my $dir = $_[0];
	
	my @files = glob($dir."/*");
	
	foreach my $file (@files) {
		if (-d $file) {
			process_dir($file);
		} else {
			process_file($file);
		}
	}	
}

sub save_comment {
	my $source = $_[0];
	my %data = %{$_[1]};

	my $id = md5_hex($source.$data{"url"}.$data{"title"}.$data{"author"}.$data{"paper_doi_id"}.$data{"paper_pubmed_id"}.$data{"paper_arxiv_id"}.$data{"paper_url"});
	
	my $filename = $comments_dir."comment_".$id;

	if (-e $filename) {
		# comment is already on disk, so do nothing
	} else {
		# if we don't have a DOI or pubmed id (preferably both) for a subject paper then look it up now.
		if ( (!$data{"paper_pubmed_id"}) && (!$data{"paper_doi_id"}) ) {
			if ($source eq "biomedcentral") {
				my $url = $data{"paper_url"};
				my @results = `perl modules/biomedcentral.pl "$url"`;
				my %results;
				# read results into the results hash.
				foreach my $result (@results) {
					if ($result =~ /(.*)\t(.*)/ig) {
						$results{$1} = $2;
					}
				}			
				
				$data{"paper_doi_id"} = $results{"DOI"};
				$data{"paper_pubmed_id"} = $results{"PMID"};	
			}
		}
		
		open(COMMENT, ">$filename") or log_error("Couldn't open $filename to save comment.", 1);
		print COMMENT 
"<?xml version=\"1.0\" encoding=\"ascii\"?>
<comment>
	<source>".$source."</source>
	<subject_url>".$data{"paper_url"}."</subject_url>
	<subject_doi_id>".$data{"paper_doi_id"}."</subject_doi_id>
	<subject_pubmed_id>".$data{"paper_pubmed_id"}."</subject_pubmed_id>
	<subject_arxiv_id>".$data{"paper_arxiv_id"}."</subject_arxiv_id>
	<title><![CDATA[".$data{"title"}."]]></title>
	<pubdate>".$data{"date"}."</pubdate>
	<url><![CDATA[".$data{"url"}."]]></url>
	<author><![CDATA[".$data{"author"}."]]></author>
	<description><![CDATA[".$data{"comment"}."]]></description>
</comment>
";
	
		close(COMMENT);
	}
}


log("script complete");







