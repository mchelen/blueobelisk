#!/usr/bin/perl
#
# get links to items on Amazon
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown translate_date);
use helper qw(download_url get_last_id);
use XML::Simple;
use Data::Dumper;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

if (!$config{"amazon_access_key"}) {
	log("Can't continue, no access key supplied.");
	exit;
}

my %book_exists;
my $sql = $db->prepare("SELECT paper_id, isbn_id FROM papers WHERE !ISNULL(isbn_id)");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$book_exists{$row->{"isbn_id"}} = $row->{"paper_id"};
}

my $sql = $db->prepare("SELECT * FROM links WHERE ISNULL(paper_id) AND followed=0 AND domain LIKE '%amazon%'");
$sql->execute();

while (my $row = $sql->fetchrow_hashref()) {
	my $url = $row->{"url"};
	my $directory = $row->{"directory"}.$row->{"file"};
	
	my %details;
	
	print STDERR "Trying $directory\n" if $DEBUG;
	
	if ((!%details) && ($directory =~ /\/dp\/([\d\w]+)/i)) {%details = get_details($1);}
	if ((!%details) && ($directory =~ /\/ASIN\/([\d\w]+)/i)) {%details = get_details($1);}
	if ((!%details) && ($directory =~ /\/detail\/-\/([\d\w]+)/i)) {%details = get_details($1);}
	if ((!%details) && ($directory =~ /ASIN=([\d\w]+)/i)) {%details = get_details($1);}
	if ((!%details) && ($directory =~ /\/gp\/product\/([\d\w]+)/i)) {%details = get_details($1);}	
	
	if (%details) {
		print STDERR "\tGot ".$details{"title"}."\n" if $DEBUG;
		if ($details{"isbn"}) {
			if ($book_exists{$details{"isbn"}}) {
				print STDERR "\tBook is already in the database\n" if $DEBUG;
				link_book($url, $book_exists{$details{"isbn"}});
			} else {
				print STDERR "\tPutting item into database...\n" if $DEBUG;
				my $insert = $db->prepare("INSERT INTO papers (pii_id, isbn_id, title, journal, abstract, authors, added_on, pubdate, image) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP(), ?, ?)");
				$insert->execute(
					$details{"asin"},
					$details{"isbn"},
					$details{"title"},
					$details{"publisher"},
					$details{"description"},
					$details{"author"},
					translate_date($details{"pubdate"}),
					$details{"image"}
				);
				
				my $paper_id = get_last_id($db);
				
				if ($paper_id) {
					$book_exists{$details{"isbn"}} = $paper_id;
					print STDERR "\tLinking ".$details{"isbn"}." to $paper_id\n" if $DEBUG;
					print STDERR "\tPubdate is ".$details{"pubdate"}."\n";
					link_book($url, $paper_id);
				}
			}
		} else {
			print STDERR "\tItem didn't have an ISBN. Skipping.\n" if $DEBUG;
		}
	} else {
		print STDERR "\tCouldn't find details for $url\n" if $DEBUG;
	}
	
	# set followed field in link.
	my $followed = $db->prepare("UPDATE links SET followed=1 WHERE url=?");
	$followed->execute($url);
}

sub link_book {
	my $url = $_[0];
	my $paper_id = $_[1];
	
	my $link = $db->prepare("UPDATE links SET paper_id=? WHERE url=?");
	$link->execute($paper_id, $url);
}

sub get_details {
	my $amazon_item_id = $_[0];
	print STDERR "\tAmazon item id is $amazon_item_id\n";
	my $url = sprintf("http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=%s&Operation=ItemLookup&IdType=ASIN&ItemId=%s&MerchantId=All&ResponseGroup=Medium", $config{"amazon_access_key"}, $amazon_item_id);
	my $results = download_url($url);
	
	my %details = parse_amazon_xml($results);
	
	sleep(1);
	return %details;
}

sub parse_amazon_xml {
 	my $text = $_[0];

	# the line below barfs and dies if there are any funny characters in the input...
 	my $ref = XMLin($text, ForceArray => 1);

 	my %details;
	
	if ($ref) {
		my $item = $ref->{"Items"}[0]->{"Item"}[0];
		$details{"title"} = $item->{"ItemAttributes"}[0]->{"Title"}[0];
		$details{"author"} = $item->{"ItemAttributes"}[0]->{"Author"}[0];
		$details{"isbn"} = $item->{"ItemAttributes"}[0]->{"ISBN"}[0];
		$details{"asin"} = $item->{"ASIN"}[0];
		$details{"publisher"} = $item->{"ItemAttributes"}[0]->{"Publisher"}[0];
		$details{"pubdate"} = $item->{"ItemAttributes"}[0]->{"PublicationDate"}[0];
		$details{"image"} = $item->{"MediumImage"}[0]->{"URL"}[0];
		$details{"description"} = $item->{"EditorialReviews"}[0]->{"EditorialReview"}[0]->{"Content"}[0];
	}
	

	return %details;
}

#log("script complete");







