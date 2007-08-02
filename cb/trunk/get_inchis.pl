#!/usr/bin/perl
#
# get inchis from posts and put them in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# get active posts
my %posts;
my %blogs;
my $sql = $db->prepare("SELECT post_id, blog_id, filename FROM posts WHERE active=1");
#my $sql = $db->prepare("SELECT post_id, blog_id, filename FROM posts WHERE blog_id = 52");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$posts{$row->{"post_id"}} = $row->{"filename"};
	$blogs{$row->{"post_id"}} = $row->{"blog_id"};
}

foreach my $post (keys(%posts)) {
	my %details = parse_post_xml($posts{$post});
	my $content = $details{"description"};
	$content =~ s/\&lt\;/</g;
	$content =~ s/\&gt\;/>/g;
	$content =~ s/\&amp\;/\&/g;

        print "post: $post\n";
        # print "content: $content\n";

	my $post_id = $post;

	my $tree = HTML::TreeBuilder->new_from_content($content);

        # support for <span class="smiles|inchi"> (microformat) and
        #   <span class="chem:smiles|inchi"> and proper RDFa like
        #   <span property="chem:inchi">

	my @links = $tree->look_down("_tag", "span");

	foreach my $link (@links) {
		my $class = $link->attr("class");
                my $property = $link->attr("property");
		my $inchi = $link->as_text;

		if ( ($class =~ /inchi/i) || ($class =~ /chem:inchi/i) || ($property =~ /chem:inchi/i))  {
                        if ($inchi =~ /^InChI=[^\s]/) {
                                my $id_inchi_hash = md5_hex($post_id.$inchi);
                                my $insert = $db->prepare("INSERT INTO inchis (id_inchi_hash, blog_id, post_id, inchi, added_on) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP())");
 
                                print "post: $post\n";
                                print " adding inchi: $inchi\n";

          			$insert->execute($id_inchi_hash, $blogs{$post_id}, $post_id, $inchi);
       			} elsif ($inchi =~ /^1\/[^\s]/) {
                                $inchi = "InChI=$inchi";
                                my $id_inchi_hash = md5_hex($post_id.$inchi);
                                my $insert = $db->prepare("INSERT INTO inchis (id_inchi_hash, blog_id, post_id, inchi, added_on) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP())");

                                print "post: $post\n";
                                print " adding inchi: $inchi\n";

                                $insert->execute($id_inchi_hash, $blogs{$post_id}, $post_id, $inchi);
                        }
		}

		elsif ( ($class =~ /smiles/i) || ($class =~ /chem:smiles/i) || ($property =~ /chem:smiles/i))  {
			# print "post: $post\n";
			# print "  found smiles: $inchi\n";

			my $smiles = $inchi;
			my $inchi = `bash /home/egonw/bin/smi2inchi "$smiles" | grep InChI`;
			$inchi =~ s/\n|\r//g;

			# print "  -> inchi: $inchi\n";

			if ($inchi =~ /^InChI=[^\s]/) {		
				my $id_inchi_hash = md5_hex($post_id.$inchi);
                        	my $insert = $db->prepare("INSERT INTO inchis (id_inchi_hash, blog_id, post_id, inchi, added_on) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP())");

                                print "post: $post\n";
                                print " adding inchi: $inchi\n";

                                $insert->execute($id_inchi_hash, $blogs{$post_id}, $post_id, $inchi);
			}

                }

	}	

        # support for <img alt="InChI=1/...">

        my @links = $tree->look_down("_tag", "img");

        foreach my $link (@links) {
                # print "link: $link\n";

                my $inchi = $link->attr("alt");

                if ($inchi =~ /^InChI=1\/[^\s]/) {
                        my $id_inchi_hash = md5_hex($post_id.$inchi);
                        my $insert = $db->prepare("INSERT INTO inchis (id_inchi_hash, blog_id, post_id, inchi, added_on) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP())");

                        print "post: $post\n";
                        print " adding inchi: $inchi\n";

                        $insert->execute($id_inchi_hash, $blogs{$post_id}, $post_id, $inchi);
                }
        }

}

log("script complete");

