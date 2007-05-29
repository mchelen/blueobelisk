#!/usr/bin/perl
#
# handle PubMed links (which don't have enough CrossRef metadata)
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

my @journals = (
"Journal of Molecular Biology"
);

	my $sql = $db->prepare("SELECT * FROM papers WHERE ISNULL(journal) AND ISNULL(title) AND !ISNULL(pubmed_id)");
	$sql->execute();
	
	while (my $row = $sql->fetchrow_hashref()) {
		my $pmid = $row->{"pubmed_id"};
		my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=pubmed&cmd=Retrieve&dopt=AbstractPlus&list_uids=$pmid&query_hl=22&itool=pubmed_DocSum";
                print STDERR "URL: $url\n";
		my $page = download_url($url);
		
		print STDERR "Trying PMID $pmid\n";
		if ($page =~ /<h2>(.*?)<\/h2>/) {
			if (!m/Related\slinks/) {
				print STDERR "Got title $1\n";
				my $update = $db->prepare("UPDATE papers SET title=? WHERE pubmed_id=?");
				$update->execute($1, $pmid);
			}
		}
                # example: <span title="Journal of molecular biology"><a href="javascript:AL_get(this, 'jour'
                if ($page =~ /<span\stitle="(.*?)"><a\shref="javascript:AL_get\(this, 'jour'/) {
                        print STDERR "Got journal $1\n";
                        my $update = $db->prepare("UPDATE papers SET journal=? WHERE pubmed_id=?");
                        $update->execute($1, $pmid);
                }
	}

log("script complete");







