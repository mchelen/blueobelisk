#!/usr/bin/perl
#
# handle ACS links (which don't have enough CrossRef metadata)
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use HTML::Entities;
use Encode qw(encode);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my @acs_journals = (
"Accounts of Chemical Research",
"Analytical Chemistry",
"Biochemistry",
"Biomacromolecules",
"Chemical Reviews",
"Chemistry of Materials",
"Crystal Growth & Design",
"Crystal Growth &amp; Design",
"Inorganic Chemistry",
"Journal of Chemical Documentation",
"Journal of Chemical Information and Computer Sciences",
"Journal of Chemical Information and Modeling",
"Journal of Combinatorial Chemistry",
"Journal of Medicinal Chemistry",
"Journal of Natural Products",
"Journal of the American Chemical Society",
"Langmuir",
"Macromolecules",
"Molecular Pharmaceutics",
"Nano Letters",
"Organic Letters",
"Organometallics",
"The Journal of Organic Chemistry"
);

foreach my $journal (@acs_journals) {
	my $sql = $db->prepare("SELECT * FROM papers WHERE journal=? AND ISNULL(title) AND !ISNULL(doi_id)");
	$sql->execute($journal);
	
	while (my $row = $sql->fetchrow_hashref()) {
		my $doi = $row->{"doi_id"};
		my $url = "http://pubs3.acs.org/acs/journals/doilookup?in_doi=".$doi;
                # print STDERR "URL: $url\n";
		my $page = download_url($url);
		
                # print STDERR "$page";
		print STDERR "Trying DOI $doi\n";
		if ($page =~ /<span class="textbold">(.*?)<\/span>/) {
			print STDERR "Got title $1\n";
			my $update = $db->prepare("UPDATE papers SET title=? WHERE doi_id=?");
			$update->execute($1, $doi);
		} else {
			# couldn't get a title for the page, set the title to !NULL, anyway, so that this script won't look at it again.
                        print STDERR "No title found\n";
			my $update = $db->prepare("UPDATE papers SET title=? WHERE doi_id=?");
			$update->execute("Unknown ACS publication", $doi);
		}
	}
}

log("script complete");







