#! /usr/bin/perl
use diagnostics;
use strict;

my $inchi = $ARGV[0];
my $url =  "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&DB=pccompound&term=\%22$inchi\%22[InChI]";

# print "InChI: $inchi";
# print "URL: $url";

# exit(0);

`wget -O /tmp/tmp.html "$url"`;
my $pcHtml = `cat /tmp/tmp.html`;

if (!($pcHtml =~ m/cid=(\d*)/g)) {
  print "Could not resolve the cid.\n";
}

my $cid = $1;
print "CID: $cid";

if (!(-e "$cid.png")) {
    my $imageUrl = "http://pubchem.ncbi.nlm.nih.gov/image/imgsrv.fcgi?cid=$cid";
    `wget -O $cid.png "$imageUrl"`;
    `/usr/bin/convert -resize 64x64 $cid.png $cid.out.png`;
}

`rm /tmp/tmp.html`;
