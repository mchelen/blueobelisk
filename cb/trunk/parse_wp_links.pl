#!/usr/bin/perl
#
# get links from posts and put them in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown trim);
use helper qw(download_url non_html);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);
use HTML::Entities;
use pubchem;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# do a brute force update of the link page titles, using the cache?
my $shoehorn = 0;

# get existing names
my %titles;
my $sql = $db->prepare("SELECT links.url, posts.post_id, posts.blog_id FROM links, posts WHERE posts.post_id = links.post_id AND id_inchi_hash IS NULL AND active = 1");
#my $sql = $db->prepare("SELECT url, post_id, blog_id FROM links WHERE id_inchi_hash IS NULL");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
  my $url = $row->{"url"};
  my $post_id = $row->{"post_id"};
  my $blog_id = $row->{"blog_id"};
  if ($url =~ m/wikipedia.org\/wiki/ && !($url =~ m/google.com/) &&
      !($url =~ m/wiki\/InChI/i) && !($url =~ m/wiki\/Simplified/) &&
      !($url =~ m/wiki\/Template/i)) {
    # figure out name
    my $name = "";
    if ($url =~ m#/wiki/(.*)#) {
      $name = $1;
      $name =~ s/\_/ /g;
      $name = lc $name;
    }

    my $likelyChemical = 0;
    my $inchi = "";
    my $cid = "";
    #if ($url =~ m/caffeine/i) {
      print "WP URL: $url\n";
      `wget -q -O wp.html "$url"`;
      my @content = `cat wp.html`;
      my $readingInChI = 0;
      foreach my $line (@content) {
        if ($line =~ m#(InChI=1/[^\s]*)#) {
          $readingInChI = 1;
        }
        if ($line =~ m#/wiki/Simplified_molecular_input_line_entry_specification#) {
          $likelyChemical = 1;
        }
        if ($line =~ m#http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi\?cid=(\d*)#) {
          $likelyChemical = 1;
          $cid = $1;
        }
        if ($line =~ m#href="/wiki/Chemical_formula"#) {
          $likelyChemical = 1;
        }
        if ($readingInChI == 1) {
          #print "line: $line";
          $inchi .= $line;
          if ($line =~ m#</#) {
            $inchi =~ s/\s//g;
            $inchi =~ s#<br[^/]*/>##g;
            $inchi =~ s#</?td>##g;
            if ($inchi =~ /href/) {
              # OK, this is not good.
              $inchi = "";
            }
            $readingInChI = 0;
          }
        }
      }
    #} # closes m/Mauveine/ or likewise
    
    # do we know anything about this compound
    my $compoundKnown = 0;
    if ($inchi) {
      my $query2 = "SELECT inchi, cid FROM compounds WHERE inchi = '$inchi'";
      print "Q: $query2\n";
      my $sql2 = $db->prepare($query2);
      $sql2->execute();
      while (my $row = $sql2->fetchrow_hashref()) {
        $compoundKnown = 1;
        if (!$cid && $row->{"cid"}) {
          print "Retrieved CID from cb db: $cid\n";
          $cid = $row->{"cid"};
        }
      }
    } elsif ($cid) {
      my $query2 = "SELECT inchi, cid FROM compounds WHERE cid = '$cid'";
      my $sql2 = $db->prepare($query2);
      $sql2->execute();
      while (my $row = $sql2->fetchrow_hashref()) {
        $compoundKnown = 1;
        if (!$inchi && $row->{"inchi"}) {
          print "Retrieved InChI from cb db: $inchi\n";
          $inchi = $row->{"inchi"};
        }
      }
    }

    if ($likelyChemical) {
      print "Chemical?: $url -> ";
      if ($inchi) {
        print "$inchi";
        if (!$cid) {
          $cid = getCID($inchi);
        }
        print " -> CID:$cid";
      } elsif ($cid) {
        print "CID:$cid";
        if (!$inchi) {
          $inchi = getInChI($cid);
        }
        print " -> $inchi" if ($inchi);
      } else {
        print "but no InChI/CID";
      }
      print "\n";
      if ($inchi) {
        my $id_inchi_hash = md5_hex($post_id.$inchi);

        print "name: $name\n";
        print "post: $post_id\n";
        print "blog: $blog_id\n";
        print " adding inchi: $inchi\n";

        my $query = "UPDATE links SET id_inchi_hash = '$id_inchi_hash' WHERE url = '$url' AND blog_id = '$blog_id' AND post_id = '$post_id'";
        #print "Q: $query\n";
        my $insert = $db->prepare($query);         
        $insert->execute();
        $query = "INSERT INTO inchis (id_inchi_hash, blog_id, post_id, inchi, added_on) VALUES (?, ?, ?, ?,CURRENT_TIMESTAMP())";
        #print "Q: $query\n";
        $insert = $db->prepare($query);
        $insert->execute($id_inchi_hash, $blog_id, $post_id, $inchi);

        print "known: $compoundKnown\n";
        if ($compoundKnown != 0) {
          print "  Already know this compound; not adding into compounds\n";
        } else {
          print "  Adding to compounds table...\n";
          $query = "INSERT INTO compounds (cid, inchi, name, added_on) VALUES (?, ?, ?, CURRENT_TIMESTAMP())";
          my $insert = $db->prepare($query);
          $insert->execute($cid, $inchi, $name);
        }
      }
    }
  }
}

log("script complete");
