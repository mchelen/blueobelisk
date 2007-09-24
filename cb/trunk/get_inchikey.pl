#! /usr/bin/perl
#
# gets CID from PubChem for the InChI's in the database

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use Digest::MD5 qw(md5_hex);
use diagnostics;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# get inchi's
my %posts;
my %blogs;
my $sql = $db->prepare("SELECT inchi FROM inchis WHERE inchikey = \"\"");

$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
  my $inchi = $row->{"inchi"};
  print "Need to create InChIKey for $inchi\n";
  my $url =  "http://www.chemspider.com/inchi.asmx/InChIToInChIKey?inchi=$inchi";
  `wget -q -O /tmp/tmp.html "$url"`;
  my $pcHtml = `cat /tmp/tmp.html`;
  # print $pcHtml;
  `rm /tmp/tmp.html`;

  if ($pcHtml =~ m/>([^<]*)<\/string/) {
    my $key = $1;
    print "InChIKey=$key";

    my $insert = $db->prepare("UPDATE inchis SET inchikey = '$key' WHERE inchi = '$inchi'");

      print " adding key: $key\n";
    $insert->execute();

  }
}

