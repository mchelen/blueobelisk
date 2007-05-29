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

# get active posts
my %posts;
my %blogs;
my $sql = $db->prepare("SELECT post_id, blog_id, filename FROM posts WHERE active=1");
#my $sql = $db->prepare("SELECT post_id, blog_id, filename FROM posts");
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

	my $post_id = $post;

	my $tree = HTML::TreeBuilder->new_from_content($content);
	my @links = $tree->look_down("_tag", "a");

	foreach my $link (@links) {
		my $url = encode("ascii", $link->attr("href"));
		my $rel = $link->attr("rel");
		my $rev = $link->attr("rev");
		my $class = $link->attr("class");
		my $text = $link->as_text;
		
		$url =~ s/\s//g;
		if (length($url) <= 0) {next;}
		if (!($url =~ /http:\/\/(.+)/)) {next;}

		my ($path, $domain, $directory, $file) = url_breakdown($url);

		my $id_url_hash = md5_hex($post_id.$url);

		my $insert = $db->prepare("INSERT INTO links (post_id, blog_id, id_url_hash, type, url, url_hash, added_on, domain, directory, file, title) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP(), ?, ?, ?, ?) ON DUPLICATE KEY UPDATE type=VALUES(type), title=VALUES(title)");
		
		if ( ($rel =~ /review/i) || ($rev =~ /review/i) )  {
			$insert->execute($post_id, $blogs{$post_id}, $id_url_hash, "review", $url, md5_hex($url), $domain, $directory, $file, $text);
		}
		
		elsif ( ($class =~ /item/i) && ($class =~ /url/i) )  {
			$insert->execute($post_id, $blogs{$post_id}, $id_url_hash, "review", $url, md5_hex($url), $domain, $directory, $file, $text);
		}

		elsif ( ($rel =~ /conference/i) || ($class =~ /conference/i) )  {
			$insert->execute($post_id, $blogs{$post_id}, $id_url_hash, "conference", $url, md5_hex($url), $domain, $directory, $file, $text);
		}

		elsif ($rel =~ /tag/i)  {
			$insert->execute($post_id, $blogs{$post_id}, $id_url_hash, "tag", $url, md5_hex($url), $domain, $directory, $file, $text);

			# put the tag in the tags table
			my $tag = $db->prepare("INSERT IGNORE INTO tags (id_tag_hash, post_id, tag, tagged_by, blog_id) VALUES (?, ?, ?, ?, ?)");
			$tag->execute(md5_hex($post_id.$tag), $post_id, $text, "blog", $blogs{$post_id});
		}

		else {
			$insert->execute($post_id, $blogs{$post_id}, $id_url_hash, "link", $url, md5_hex($url), $domain, $directory, $file, $text);
		}


	}	
}

log("script complete");







