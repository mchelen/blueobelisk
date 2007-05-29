#!/usr/bin/perl
#
# find_f1000_reviews.pl
#
# check PubMed for F1000 reviews of papers. Does this semi-regularly (a la get_connotea_tags.pl)
#
use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");


# get list of papers in F1000 Biology
my $URL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&usehistory=n&tool=postgenomic&term=loprovf1000[filter]%20OR%20loprovf1000m[filter]&retstart=_START_&retmax=1000";

my $complete = 0;
my $pos = 0;
my %pmids;
while (!$complete) {
	my $search = $URL;
	$search =~ s/_START_/$pos/;
	print STDERR "Retrieving from $pos...\n" if $DEBUG;
	my $results = download_url($search, 1);

	if ($results) {
		my $counter = 0;
		while ($results =~ /Id>(\d+)</g) {
			my $pmid = $1;
			$pmids{$pmid} = 1;
			$counter++;
		}
		if ($counter < 1000) {
			print STDERR "Finishing having retrieved $counter pmids.\n" if $DEBUG;
			$complete = 1;
		}
	} else {
		print STDERR "Didn't get any results (from $pos)\n" if $DEBUG;
		$complete = 1;
	}
	$pos += 1000;
}

$URL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?db=pubmed&cmd=llinks&id=PMID_GOES_HERE";

my %dbpmids;
my $sql = $db->prepare("SELECT DISTINCT pubmed_id FROM papers");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $pubmed_id = $row->{"pubmed_id"};
	$dbpmids{$pubmed_id} = 1;
}

foreach my $pmid (keys(%pmids)) {
	if ($dbpmids{$pmid}) {
		# OK... this is a match
		print STDERR "." if $DEBUG;
	} else {
		delete $pmids{$pmid};
	}
}

my $pmids = join(',', keys(%pmids));

my %already_reviewed;
my $sql = $db->prepare("SELECT DISTINCT paper_id FROM comments WHERE !ISNULL(paper_id)");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $paper_id = $row->{"paper_id"};
	$already_reviewed{$paper_id} = 1;
}

if (!$pmids) {$pmids = "''";}
my $sql = $db->prepare("SELECT paper_id, pubmed_id FROM papers WHERE pubmed_id IN ($pmids) AND !ISNULL(pubmed_id)");
$sql->execute();

# get pmid of papers that we've confirmed have the correct linkout
while (my $row = $sql->fetchrow_hashref()) {
	my $pubmed_id = $row->{"pubmed_id"};
	my $paper_id = $row->{"paper_id"};

  	if ($already_reviewed{$paper_id}) {
		print STDERR "Already have review for $paper_id\n" if $DEBUG;
		next;
  	}
  
  	my $search = $URL;
  	$search =~ s/PMID_GOES_HERE/$pubmed_id/;

  	print STDERR "Checking $pubmed_id ($paper_id)...\n";
  	my $results = download_url($search);
  
	if ($results) {
		if ($results =~ /faculty/ig) {print STDERR "\tLooks promising...\n";}
    		
    		# we could use XML::Simple and parse the results, yadda yadda, but there's a simpler way:
    		if (($results =~ /Url>([^\s]*)(facultyof1000)([^<]*)<\/Url/i) || ($results =~ /Url>([^\s]*)(f1000medicine)([^<]*)<\/Url/i)) {
      			# yes, there's an F1000 review for this paper.
      			my $link = $1.$2.$3;
      			print STDERR "\tFound F1000 link at $link\n";
      
      			# insert the relevant details into the database.
      			my $id_comment_hash = md5_hex($paper_id.$link);
			my $insert = $db->prepare("INSERT IGNORE INTO comments (id_comment_hash, paper_id, source, url, comment, added_on) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP())");
			$insert->execute($id_comment_hash, $paper_id, "F1000 Biology", $link, "");
		} else {
      			print STDERR "\tNo F1000 links.\n";
    		}
	} else {
		print STDERR "\tCouldn't get results.\n";
  	}
	
	sleep($config{"pubmed_wait"});
}
