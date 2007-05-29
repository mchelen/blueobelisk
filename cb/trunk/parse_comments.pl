#!/usr/bin/perl
#
# get comments from journals that use them and store them on disk
# then check to see if any match the papers we have in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown trim translate_date);
use helper qw(download_url clean_identifier);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use XML::Simple;
use Encode qw(encode);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $ADD_COMMENTED_PAPERS = 1;
my $ID_BLACKLIST = "conf/blacklist.txt"; # DOIs that we tried looking up but failed

my $comments_dir = "comments/";

my %existing;
# get existing comments
my $sql = $db->prepare("SELECT id_comment_hash FROM comments");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $id_comment_hash = $row->{"id_comment_hash"};
	$existing{$id_comment_hash} = 1;
}

my @files = glob($comments_dir."comment_*");
foreach my $file (@files) {
	my %comment = parse_comment_xml($file);
	my $paper_id = check_ids(\%comment);
	
	if ($paper_id) {
		insert_comment($paper_id, \%comment);
	} else {
		# comment is on a paper not in the database... we should add it if the config says we should.
		
		my $type = "";
		my $id = "";
		
		if ($ADD_COMMENTED_PAPERS) {
			if ($comment{"subject_doi_id"}) {
				print STDERR "Adding paper ".$comment{"subject_doi_id"}."\n";
				my $doi = clean_identifier($comment{"subject_doi_id"});
				my $results = `perl parse_links.pl DOI $doi`;
				$type = "doi"; $id = $doi;
			}
			elsif ($comment{"subject_pubmed_id"}) {
				print STDERR "Adding paper ".$comment{"subject_pubmed_id"}."\n";
				my $pmid = clean_identifier($comment{"subject_pubmed_id"});
				my $results = `perl parse_links.pl PMID $pmid`;
				$type = "pubmed"; $id = $pmid;
			}
			elsif ($comment{"subject_arxiv_id"}) {
				print STDERR "Adding paper ".$comment{"subject_arxiv_id"}."\n";
				my $oai = clean_identifier($comment{"subject_arxiv_id"});
				my $results = `perl parse_links.pl OAI $oai`;
				$type = "arxiv"; $id = $oai;
			}
			
			if ($type) {
				my $paper_id = check_ids(\%comment);
				if ($paper_id) {
					insert_comment($paper_id, \%comment);				
				} else {
					# add id to the blacklist
					open(FILE, ">>$ID_BLACKLIST");
					print FILE "$type\t$id\n";
					print STDERR "Wrote $id to blacklist.\n" if $DEBUG;
					close(FILE);
				}
			}
		}
	}
}

# as a side-effect, fix images in the comments table.
my %images = (
"F1000 Biology", "images/f1000_comment.png",
"Connotea", "images/comment_connotea.png",
"biomedcentral", "images/bmc_comment.png",
"Nature Highlights", "images/hilight_comment.png"
);

foreach my $source (keys(%images)) {
	my $image = $images{$source};
	my $sql = $db->prepare("UPDATE comments SET image=? WHERE source=?");
	$sql->execute($image, $source);
}

sub insert_comment {
	my $paper_id = $_[0];
	my %comment = %{$_[1]};
	
	if ($paper_id < 1) {return;}
	
	print STDERR "Got comment for paper $paper_id\n" if $DEBUG;
	
	if ($existing{md5_hex($paper_id.$comment{"description"})}) {return;}
	
	my $insert = $db->prepare("INSERT IGNORE INTO comments 
		(id_comment_hash, paper_id, source, url, title, comment, pubdate, added_on, author) VALUES 
		(?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)");
	$insert->execute(md5_hex($paper_id.$comment{"description"}), $paper_id, $comment{"source"}, $comment{"url"}, $comment{"title"}, $comment{"description"}, $comment{"pubdate"}, $comment{"author"});
}

sub check_ids {
	# get IDs of papers in the database.
	my $sql = $db->prepare("SELECT paper_id, doi_id, pubmed_id, pii_id, arxiv_id FROM papers");
	$sql->execute();
	my %ids;
	while (my $row = $sql->fetchrow_hashref()) {
		my $doi = $row->{"doi_id"};
		my $pii = $row->{"pii_id"};
		my $arxiv = $row->{"arxiv_id"};
		my $pubmed = $row->{"pubmed_id"};
		my $paper_id = $row->{"paper_id"};

		if ($doi) {$ids{"doi"}{$doi} = $paper_id;}
		if ($pii) {$ids{"pii"}{$pii} = $paper_id;}
		if ($pubmed) {$ids{"pubmed"}{$pubmed} = $paper_id;}
		if ($arxiv) {$ids{"arxiv"}{$arxiv} = $paper_id;}
	}
		
	# get 'blacklisted' IDs - those that we've tried to retrieve and failed.
	open(FILE, $ID_BLACKLIST);
	my @lines = <FILE>;
	close(FILE);
	foreach my $line (@lines) {
		chomp($line);
		my @elements = split(/\t/, $line);
		my $type = $elements[0];
		my $id = $elements[1];
		
		$type =~ s/\s//g;
		$id =~ s/\s//g;
		
		# fake a match so that it gets skipped.
		$ids{$type}{$id} = -1;
	}
	
	my %comment = %{$_[0]};
	my $paper_id = 0;
	# look for identifier matches
	if ($ids{"doi"}{$comment{"subject_doi_id"}}) {$paper_id = $ids{"doi"}{$comment{"subject_doi_id"}};}
	elsif ($ids{"pii"}{$comment{"subject_pii_id"}}) {$paper_id = $ids{"pii"}{$comment{"subject_pii_id"}};}
	elsif ($ids{"pubmed"}{$comment{"subject_pubmed_id"}}) {$paper_id = $ids{"pubmed"}{$comment{"subject_pubmed_id"}};}
	elsif ($ids{"arxiv"}{$comment{"subject_arxiv_id"}}) {$paper_id = $ids{"arxiv"}{$comment{"subject_arxiv_id"}};}

	return $paper_id;
}

sub parse_comment_xml {
  my $file = $_[0];
  my $ref = XMLin($file);

  my %feed;

  my @fields = ("source", "subject_doi_id", "subject_url", "subject_pubmed_id", "subject_arxiv_id", "title", "author", "pubdate", "description", "url");

  foreach my $field (@fields) {
    my $value = $ref->{$field};

    if (!$ref->{$field}) {$value = "unknown";}
    if ($value =~ /\AHASH\(/) {$value = "unknown";}

	# force a cleanup for historical reasons.
	if ($field eq "subject_doi_id") {$value = clean_identifier($value);}
	if ($field eq "subject_pubmed_id") {$value = clean_identifier($value);}
	if ($field eq "subject_arxiv_id") {$value = clean_identifier($value);}
	
    $feed{$field} = encode("ascii", $value);
    $feed{$field."_raw"} = $value;
  }
  
  return %feed;
}

log("script complete");







