#! /usr/bin/perl
#
# gets CID from PubChem for the InChI's in the database

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use Digest::MD5 qw(md5_hex);
use diagnostics;

my $pti = $config{"path_to_interface"};

my $imageDir = $pti."images/compounds/";

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# get inchi's
my %posts;
my %blogs;
my $sql = $db->prepare("SELECT cid FROM compounds WHERE cid != ''");

$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
  my $cid = $row->{"cid"};
  if (!(-e "$imageDir".$cid.".cml") && $cid > 0) {
    print "Need to get a CML for CID $cid\n";
    my $url = "http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid=$cid\&disopt=DisplaySDF";
    `wget -q -O $cid.mol "$url"`;
    `/home/egonw/progs/bin/babel $cid.mol -ocml $cid.cml`;
    `cat $cid.cml | grep -v "<?xml" > $cid.out.cml`;
    `mv $cid.out.cml $imageDir$cid.cml`;
    `rm $cid.mol`;
  }
}

