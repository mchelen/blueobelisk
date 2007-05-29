#!/usr/bin/perl
#
# get_connotea_tags.pl
#
use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use LWP::Simple;
use Digest::MD5 qw(md5_hex);

if (!$config{"connotea_username"}) {
	log("script complete: no Connotea username and password supplied.");
	exit;
}

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my $connotea_connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $connotea_db = DBI->connect($connotea_connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the connotea cache database.\n");

# here, we should:
# Find the overlap of URIs / DOIs between what has been collected by the pipeline and what's in the Connotea cache
# Transfer tags from one to the other

my %dois = get_hash("SELECT doi_id AS hkey, paper_id AS value FROM papers WHERE !ISNULL(doi_id)");
my %pmids = get_hash("SELECT pubmed_id AS hkey, paper_id AS value FROM papers WHERE !ISNULL(pubmed_id)");
my %posts = get_hash("SELECT DISTINCT url AS hkey, post_id AS value FROM posts");
my %uris = get_hash("SELECT DISTINCT url AS hkey, paper_id AS value FROM links WHERE !ISNULL(paper_id)");

# go through the contents of the Connotea cache and update tags appropriately.
my $sql = $connotea_db->prepare("SELECT * FROM connotea_cache");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $post_hash = $row->{"post_hash"};
	my $tags = $row->{"tags"};
	my $uri = $row->{"uri"};
	my $user = $row->{"user"};
	my $doi = $row->{"doi"};
	my $pmid = $row->{"pmid"};
	my $comment = $row->{"comment"};

	my @tags = split(/\|/, $tags);

	# check for any matches in the database
	if ($dois{$doi}) {
		print STDERR "Found tagged DOI ($doi) by $user\n";
		my $paper_id = $dois{$doi};
		foreach my $tag (@tags) {
			print STDERR "\t$tag\n";
			my $id_tag_hash = md5_hex($paper_id.$tags);
			my $update = $db->prepare("INSERT IGNORE INTO tags (id_tag_hash, paper_id, tag, tagged_by) VALUES (?,?,?,?)");
			$update->execute($id_tag_hash, $paper_id, $tag, "connotea:".$user);
		
			# is there a comment attached?
			if ($tag =~ /pg\:comment/i) {
				# yes
				if ($comment) {
					my $id_comment_hash = md5_hex($paper_id.$comment);
					my $insert = $db->prepare("INSERT IGNORE INTO comments 
					(id_comment_hash, url, paper_id, author, source, comment)
					VALUES
					(?, ?, ?, ?, ?, ?)
					");
					$insert->execute($id_comment_hash, "http://www.connotea.org/comments/uri/".md5_hex($uri), $paper_id, $user, "Connotea", $comment);
				} else {
					print STDERR "Get comment tag but no comment!\n";
				}
			}
		}
	}

	if ($pmids{$pmid}) {
		print STDERR "Found tagged pmid ($pmid) by $user\n";
		my $paper_id = $pmids{$pmid};
		foreach my $tag (@tags) {
			print STDERR "\t$tag\n";
			my $id_tag_hash = md5_hex($paper_id.$tags);
			my $update = $db->prepare("INSERT IGNORE INTO tags (id_tag_hash, paper_id, tag, tagged_by) VALUES (?,?,?,?)");
			$update->execute($id_tag_hash, $paper_id, $tag, "connotea:".$user);
			
			# is there a comment attached?
			if ($tag =~ /pg\:comment/i) {
				# yes
				if ($comment) {
					my $id_comment_hash = md5_hex($paper_id.$comment);
					my $insert = $db->prepare("INSERT IGNORE INTO comments 
					(id_comment_hash, url, paper_id, author, source, comment)
					VALUES
					(?, ?, ?, ?, ?, ?)
					");
					$insert->execute($id_comment_hash, "http://www.connotea.org/comments/uri/".md5_hex($uri), $paper_id, $user, "Connotea", $comment);
				} else {
					print STDERR "Get comment tag but no comment!\n";
				}
			}
		}
	}
	
	if ($uris{$uri}) {
		print STDERR "Found tagged uri ($uri) by $user\n";
		my $paper_id = $uris{$uri};
		foreach my $tag (@tags) {
			print STDERR "\t$tag\n";
			my $id_tag_hash = md5_hex($paper_id.$tags);
			my $update = $db->prepare("INSERT IGNORE INTO tags (id_tag_hash, paper_id, tag, tagged_by) VALUES (?,?,?,?)");
			$update->execute($id_tag_hash, $paper_id, $tag, "connotea:".$user);
			
			# is there a comment attached?
			if ($tag =~ /pg\:comment/i) {
				# yes
				if ($comment) {
					my $id_comment_hash = md5_hex($paper_id.$comment);
					my $insert = $db->prepare("INSERT IGNORE INTO comments 
					(id_comment_hash, url, paper_id, author, source, comment)
					VALUES
					(?, ?, ?, ?, ?, ?)
					");
					$insert->execute($id_comment_hash, "http://www.connotea.org/comments/uri/".md5_hex($uri), $paper_id, $user, "Connotea", $comment);
				} else {
					print STDERR "Get comment tag but no comment!\n";
				}
			}
		}
	}

	if ($posts{$uri}) {
		print STDERR "Found tagged post ($uri) by $user\n";
		my $post_id = $posts{$uri};
		foreach my $tag (@tags) {
			print STDERR "\t$tag\n";
			my $id_tag_hash = md5_hex($post_id.$tags);
			my $update = $db->prepare("INSERT IGNORE INTO tags (id_tag_hash, post_id, tag, tagged_by) VALUES (?,?,?,?)");
			$update->execute($id_tag_hash, $post_id, $tag, "connotea:".$user);
		}
	}
}

sub get_hash {
	my $query = $_[0];
	my %results;

	my $sql = $db->prepare($query);
	$sql->execute();

	while (my $row = $sql->fetchrow_hashref()) {
		my $key = $row->{"hkey"};
		my $value = $row->{"value"};

		$results{$key} = $value;
	}

	return %results;
}
