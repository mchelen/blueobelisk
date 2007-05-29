#!/usr/bin/perl
#
# This script syncs that OPML file with the database.
#
# This should give us: 
# 	* the blogs to index
# 	* their categories
# 	* their names, URLs and feed URLs
# 	
# The blogs will be added to the database (if they're not already there) and marked as active.
#
# Blogs already in the database but not in the OPML file are marked as not active. You should be 
# able to delete them completely using the admin interface.
# 

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG);
use XML::Simple;
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

open(OPML, $config{"feeds"}) or log_error("Couldn't open feeds file", 1);
my @lines = <OPML>;
close(OPML);
my $opml= XMLin("@lines", ForceArray => 1);

clear_tags();
deactivate_blogs();
get_blogs($opml->{body}->[0]->{outline}, [], 0);

log("script complete");

sub clear_tags {
	my $sql = $db->prepare("DELETE FROM tags WHERE !ISNULL(blog_id) AND tagged_by='admin'");
	$sql->execute();
}

sub deactivate_blogs {
	my $sql = $db->prepare("UPDATE blogs SET active=0");
	$sql->execute();
}

sub get_blogs {
	my $root = $_[0];
	my @parents = @{$_[1]};
	my $counter = $_[2];

	if ($root) {
		my @categories = @{$root};
		foreach my $category (@categories) {
			if ($category->{"type"} eq "rss") {
				# add / activate this blog in the database

				my $xmlUrl = $category->{"xmlUrl"};
				my $htmlUrl = $category->{"htmlUrl"};
				my $blog_title = urldecode($category->{"text"});
				$xmlUrl =~ s/\s//g;
				$htmlUrl =~ s/\s//g;

				if ($xmlUrl && $htmlUrl) {
					my $sql = $db->prepare("INSERT INTO blogs (title,url,feed_url,added_on,image) VALUES (?,?,?,CURRENT_TIMESTAMP(),?) ON DUPLICATE KEY UPDATE active=1, title=VALUES(title)");
					$sql->execute($blog_title, $htmlUrl, $xmlUrl, "images/portraits/default.png");

					# categorize the blog correctly
					my $blog_id = get_blog_id($category->{"xmlUrl"});	

					if ($blog_id) {					
						foreach my $parent (@parents) {
							my $id_tag_hash = md5_hex($blog_id.$parent);
							my $sql = $db->prepare("INSERT IGNORE INTO tags (id_tag_hash, blog_id, tag, tagged_by) VALUES (?, ?,?,?)");
							$sql->execute($id_tag_hash, $blog_id, $parent, "admin");
						}
					}
				} else {
					log_error("OPML contains blog without a required URL (feed or html) - $blog_title");
				}
			} else {
				$parents[$counter] = $category->{"text"};
			}
			get_blogs($category->{outline}, \@parents, ($counter + 1));
		}
	}
	return 1;
}

sub get_blog_id {
	my $feed_url = $_[0];
	my $id = 0;

	my $sql = $db->prepare("SELECT blog_id FROM blogs WHERE feed_url=?");
	$sql->execute($feed_url);
	while (my $row = $sql->fetchrow_hashref()) {
		$id = $row->{"blog_id"};
	}
	return $id;
}
