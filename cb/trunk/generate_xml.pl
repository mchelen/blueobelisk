#!/usr/bin/perl
#
# generate_xml.pl
#
# generate xml versions of papers so that they can be indexed by Lucene
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $sql = $db->prepare("SELECT * FROM papers");
$sql->execute();

while (my $row = $sql->fetchrow_hashref()) {
	my $paper_id = $row->{"paper_id"};
	my $journal = $row->{"journal"};
	my $title = $row->{"title"};
	my $abstract = $row->{"abstract"};
	my $authors = $row->{"authors"};
	my $doi = $row->{"doi_id"};
	my $pubmed = $row->{"pubmed_id"};
	my $pii = $row->{"pii_id"};
	my $arxiv = $row->{"arxiv_id"};
	my $pubdate = $row->{"pubdate"};
	
	my $jpath = pathify($journal);
	my $path = "papers/$jpath/paper_$paper_id.xml";

	if (-e $path) {
		# file already exists
		print STDERR "." if $DEBUG;
	} else {
		if (!(-e "papers/$jpath")) {
			# we need to create the jpath directory
			system("mkdir papers/$jpath");
		}
		
		my $buffer =
"<?xml version=\"1.0\" encoding=\"ascii\"?>
<paper>
	<paper_id>$paper_id</paper_id>
	<title><![CDATA[$title]]></title>
	<description><![CDATA[$abstract]]></description>
	<date>$pubdate</date>
	<authors><![CDATA[$authors]]></authors>
	<journal><![CDATA[$journal]]></journal>
	<doi><![CDATA[$doi]]></doi>
	<pii><![CDATA[$pii]]></pii>
	<pubmed><![CDATA[$pubmed]]></pubmed>
	<arxiv><![CDATA[$arxiv]]></arxiv>
</paper>";

		open(FILE, ">$path") or die("Couldn't write paper to $path");
		print FILE $buffer;
		close(FILE);
		
		print STDERR "o" if $DEBUG;
	}
}

sub pathify {
	my $journal = $_[0];
	my $dir = "unknown";
	$journal = lc($journal);
	$journal =~ s/[^a-z^0-9]//g;	
	
	if (length($journal) >= 3) {$dir = $journal;}
	return $dir;
}

