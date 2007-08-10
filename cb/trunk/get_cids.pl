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
my $sql = $db->prepare("SELECT inchi FROM inchis");

$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
  my $inchi = $row->{"inchi"};
  my $hasCIDSQL = $db->prepare("SELECT inchi FROM compounds WHERE inchi='$inchi'");
  $hasCIDSQL->execute();
  if ($hasCIDSQL->fetchrow_hashref()) {
    # print "Already got CID for $inchi\n";
  } else {
    print "Need to fetch CID for $inchi\n";
    my $url =  "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&DB=pccompound&term=\%22$inchi\%22[InChI]";
    `wget -q -O /tmp/tmp.html "$url"`;
    my $pcHtml = `cat /tmp/tmp.html`;
    `rm /tmp/tmp.html`;

    if (!($pcHtml =~ m/cid=(\d*)/g)) {
      print "Could not resolve the cid.\n";
      # but should add the INChI nevertheless
      my $insert = $db->prepare("INSERT INTO compounds (inchi, added_on) VALUES (?, CURRENT_TIMESTAMP())");

      print " adding inchi: $inchi\n";
      $insert->execute($inchi);      
    } else {
      my $cid = $1;
      print "CID: $cid";

      # ok, get SMILES and iupac name too
      $url =  "http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid=$cid&disopt=DisplayASN1";
      `wget -q -O /tmp/$cid.mol "$url"`;
      my @molFile = `cat /tmp/$cid.mol`;
      my $name = "";
      my $smiles = "";
      my $urnname = "";
      foreach my $molLine (@molFile) {
          if ($molLine =~ m/name\s"([^"]*)"/) {
            $urnname = $1;
            # print "URN: $urnname\n";
          } elsif ($molLine =~ m/value\ssval\s"([^"]*)"/) {
            if ($urnname eq "Preferred") {
              $name = $1;
              # print "name: $name\n";
            } elsif ($urnname eq "Canonical") {
              $smiles = $1;
              # print "smiles: $smiles\n";
            }
          }
      }
      `rm /tmp/$cid.mol`;

      my $insert = $db->prepare("INSERT INTO compounds (cid, inchi, smiles, name, added_on) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP())");

      print " adding inchi: $inchi\n";
      $insert->execute($cid, $inchi, $smiles, $name);
    }

  }
}

