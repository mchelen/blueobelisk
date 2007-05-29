#!/usr/bin/perl
#
# handle BioMed links (which don't have enough CrossRef metadata)
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

        my $query = "SELECT * FROM papers WHERE !ISNULL(journal) AND ISNULL(title) AND doi_id like \"10.1186/%\"";
	my $sql = $db->prepare($query);
        $sql->execute();
	# print STDERR "$query\n";

	while (my $row = $sql->fetchrow_hashref()) {
		my $doi = $row->{"doi_id"};
		my $url = "http://dx.doi.org/".$doi;
                print STDERR "$url\n";
		my $page = download_url($url);
		
		print STDERR "Trying DOI $doi\n";
		if ($page =~ /<dc:title>(.*)<\/dc:title>/) {
			print STDERR "Got title $1\n";
			my $update = $db->prepare("UPDATE papers SET title=? WHERE doi_id=?");
			$update->execute($1, $doi);
		}
	}

log("script complete");







