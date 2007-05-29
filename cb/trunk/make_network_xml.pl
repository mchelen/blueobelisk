#!/usr/bin/perl
#
# get links from posts and put them in the database
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


print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!--  An excerpt of an egocentric social network  -->
<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">
<graph edgedefault=\"undirected\">
 
<!-- data schema -->
<key id=\"name\" for=\"node\" attr.name=\"name\" attr.type=\"string\"/>
<key id=\"portrait\" for=\"node\" attr.name=\"portrait\" attr.type=\"string\"/>

<!-- nodes -->
";

# first do nodes...
my $sql = $db->prepare("SELECT title, image, blog_id FROM blogs");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $title = $row->{"title"};
	my $image = $row->{"image"};
	my $blog_id = $row->{"blog_id"};

	printf("<node id=\"%d\">\n\t<data key=\"name\"><![CDATA[%s]]></data>\n\t<data key=\"portrait\">%s</data>\n</node>\n", $blog_id, $title, "http://localhost/interface/".$image);
}

# then edges
my $sql = $db->prepare("SELECT links.blog_id AS source, posts.blog_id AS target FROM links, posts WHERE posts.url_hash = links.url_hash");
$sql->execute();
my %done;
while (my $row = $sql->fetchrow_hashref()) {
	my $source = $row->{"source"};
	my $target = $row->{"target"};
	
	if ($source == $target) {next;}
	if ($done{$source}{$target}) {next;}
	
	printf("<edge source=\"%s\" target=\"%s\"></edge>\n", $source, $target);
	
	$done{$source}{$target} = 1;
}


print '
</graph>
</graphml>
'