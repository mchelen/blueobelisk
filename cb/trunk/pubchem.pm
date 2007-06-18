#! /usr/bin/perl
#
# gets CID from PubChem for the InChI's in the database

use lib (".");
use strict;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use Digest::MD5 qw(md5_hex);
use diagnostics;

sub getCID {
    my $inchi = $_[0];
    my $cid = -1;

    print "Need to fetch CID for $inchi\n";
    my $url =  "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&DB=pccompound&term=\%22$inchi\%22[InChI]";
    `wget -q -O /tmp/tmp.html "$url"`;
    my $pcHtml = `cat /tmp/tmp.html`;
    `rm /tmp/tmp.html`;

    if (!($pcHtml =~ m/cid=(\d*)/g)) {
      print "Could not resolve the cid.\n";
    } else {
      $cid = $1;
      print "CID: $cid";
    }

    return $cid;
}

sub getInChI {
    my $inchi = "";
    my $cid = $_[0];

    #print "Need to fetch InChI for CID $cid\n";
    my $url = "http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid=".$cid;
    `wget -q -O /tmp/tmp.html "$url"`;
    my $pcHtml = `cat /tmp/tmp.html`;
    `rm /tmp/tmp.html`;

    if (!($pcHtml =~ m#\%22(InChI=1/.*)\%22\[InChI\]#g)) {
      #print "Could not resolve the InChI.\n";
    } else {
      $inchi = $1;
      #print "$inchi";
    }

    return $inchi;
}

return 1;
