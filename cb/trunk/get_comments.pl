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

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $comments_dir = "comments/";

# two ways of getting comments:
#
# 1) getting id of relevant papers and checking for comments on that ID (e.g. for Cell)
#
# or, much better if available
#
# 2) collecting comments in a feed / screen scraping them and putting them in the database if they match any existing papers
#

do_science("http://www.sciencemag.org/cgi/eletters?lookup=by_date&days=30"); # collect e-letters from Science
do_biomedcentral("http://www.biomedcentral.com/latestcomments/"); # collect comments from BioMedCentral 
do_cell(); # get comments for Cell papers in the database

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

sub do_science {
	print STDERR "science " if $DEBUG;
	
	my $url = $_[0];
	my $page = download_url($url,1);
	$page =~ s/[\n\r]//g;
	
	while ($page =~ /<!-- begin author sidebar -->(.*?)<\/tr>/mig) {
		my $chunk = $1;
		print STDERR ".";
		
		my $id = undef;
		my $author = undef;
		my $doi = undef;
		my $comment = undef;
		my $title = undef;
		my $url = undef;
		my $paper_url = undef;
					
		if ($chunk =~ /<A HREF="\/cgi\/eletter-submit\/(.*?)\?(?:.*?)">Re: (.*?)<\/A>/i) {
			$id = $1;
			$title = $2;
			
			$url = "http://www.sciencemag.org/cgi/eletters/$id";
			$paper_url = "http://www.sciencemag.org/cgi/content/summary/$id";
			
			$id =~ s/\//\./g;
			$doi = "10.1126/science.$id";
		}
		
		if ($chunk =~ /<FONT SIZE="-2" FACE="verdana,arial,helvetica,sans-serif">(.*?)(?:[,\s]*)<BR>/i) {
			$author = trim($1);
		}
		
		if ($chunk =~ /<!-- article ID: (?:.*?) -->(.*?)<\/FONT>/i) {
			$comment = trim($1);
		}
		
		if ( ($title && $doi) && ($comment)) {
			my %comment;
			
			print STDERR ".";
			
			$comment{"author"} = $author;
			$comment{"title"} = $title;
			$comment{"comment"} = $comment;
			$comment{"paper_doi_id"} = $doi;
			$comment{"paper_url"} = $paper_url;
			$comment{"url"} = $url;
			$comment{"date"} = translate_date();
			
			save_comment("science", \%comment);
		}
	}
	
}

sub do_cell {
	print STDERR "cell " if $DEBUG;
	my $sql = $db->prepare("SELECT DISTINCT pii_id, pubmed_id, doi_id FROM papers WHERE !ISNULL(pii_id) AND journal LIKE 'Cell%'");
	$sql->execute();
	
	while (my $row = $sql->fetchrow_hashref()) {
		my $pii = $row->{"pii_id"};
		my $pubmed_id = $row->{"pubmed_id"};
		my $doi_id = $row->{"doi_id"};
		
		$pii =~ s/[\-\(\)]//g;
		$pii = "PII".uc($pii);
		my $url = "http://www.cell.com/content/article/comments?uid=$pii";

		my $page = download_url($url, 0);
		
		if ($page =~ /We are having temporary difficulties with the site, please try again in a few minutes/) {
			print STDERR "x" if $DEBUG;
		} else {
			$page =~ s/[\n\r]//g;
			while ($page =~ /<a name="comment(?:\d*)"><\/a>(.*?)<\/span>(?:.*?)<br>(.*?)<span class="contentHeadline">(?:.*?)<\/span><br>(.*?)<\/span>/ig) {
				
				my $title = $1;
				my $author = $2;
				my $date = undef;
				my $comment = $3;
				my $comment_url = $url;
				
				if ($author) {
					while ($author =~ /\s\s/) {
						$author =~ s/\s\s/ /g;
					}
					my @lines = split(/<br>/i, $author);
					foreach my $line (@lines) {
						if ($line =~ /(\d{2}) (\w*?) (2\d{3})/) {
							$date = translate_date("$1 $2 $3");
						} elsif ($line =~ /([\w\s]*?),(?:.*?)/) {
							$author = $1;
						} elsif (length($line) >= 4) {
							$author = $line;
						}
					}
				}
				
				if ($title && $author) {
					my %comment;
									
					print STDERR "." if $DEBUG;
					$comment{"title"} = $title;
					$comment{"date"} = $date;
					$comment{"author"} = $author;
					$comment{"comment"} = $comment;
					$comment{"url"} = $comment_url;
					$comment{"paper_pubmed_id"} = $pubmed_id;
					$comment{"paper_doi_id"} = $doi_id;					
					
					save_comment("cell", \%comment);
				} else {
					print STDERR "?" if $DEBUG;
				}
			}
		}
	}
}

sub do_biomedcentral {
	print STDERR "biomedcentral " if $DEBUG;
	
	my $url = $_[0];
	my $page = download_url($url, 1);
	$page =~ s/[\n\r]//g;
	
	while ($page =~ /<tr>(.*?)<\/tr>/ig) {
		my $chunk = $1;
		
		my $paper = undef;
		my $title = undef;
		my $date = undef;
		my $author = undef;
		my $comment = undef;
		my $comment_url = undef;
		
		if ($chunk =~ /<div class="bodytext">(?:.*?)<b>(.*?)<\/b>(?:.*?)\((.*?)\)(?:.*?)<br>(.*?)\[<a class="hiddenlink" href="(.*?)"/i) {
			$title = $1;
			$author = $2;
			$comment = $3;
			$comment_url = $4;
						
			$author =~ s/<img(.*?)>//g;
			if ($author =~ /(.*?), (\d\d)(\w\w\w)(\d\d\d\d)/i) {
				$author = $1;
				$date = "$2 $3 $4";
				$date = translate_date($date);
			}
		}
		
		if ($chunk =~ /Comment on:(?:\s*)<a class="hiddenlink" href="(.*?)"/i) {
			$paper = $1;
		}
		
		if ($paper && $title) {
			my %comment;
			
			$comment{"title"} = $title;
			$comment{"date"} = $date;
			$comment{"author"} = $author;
			$comment{"comment"} = $comment;
			$comment{"url"} = $comment_url;
			$comment{"paper_url"} = $paper;
			
			print STDERR "." if $DEBUG;
			
			save_comment("biomedcentral", \%comment);
		}
	}
}




log("script complete");







