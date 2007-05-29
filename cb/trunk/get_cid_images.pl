#! /usr/bin/perl
#
# gets CID from PubChem for the InChI's in the database

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use Digest::MD5 qw(md5_hex);
use diagnostics;

my $imageDir = "/mnt/wiki/images/compounds/";

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# get inchi's
my %posts;
my %blogs;
my $sql = $db->prepare("SELECT cid FROM compounds WHERE cid != ''");

$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
  my $cid = $row->{"cid"};
  if (!(-e "$imageDir".$cid.".png")) {
    print "Need to grab an image for CID $cid\n";
    my $imageUrl = "http://pubchem.ncbi.nlm.nih.gov/image/imgsrv.fcgi?cid=$cid";
    `wget -q -O $cid.png "$imageUrl"`;
    `/usr/bin/convert -resize 64x64 $cid.png $cid.out.png`;
    `mv $cid.out.png $cid.png`;
    `mv $cid.png $imageDir$cid.png`;
    # `rm $cid.png`;
  }
}

