#!/usr/bin/perl
#
# generate_stats.pl
#
# generate some unchanging stats (blog rankings, journal paper shares etc.)
# there's no point in working these out dynamically as they only change when there's been a pipeline update
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# let's only summarize links from the past x days.
my $age_limit = 90;

# we have two "summary" tables, for links and posts
my $sql = $db->prepare("DELETE FROM links_summary");
$sql->execute();
my $sql = $db->prepare("DELETE FROM posts_summary");
$sql->execute();
my $sql = $db->prepare("DELETE FROM papers_summary");
$sql->execute();

# repopulate the tables with data
my $sql = $db->prepare("SET group_concat_max_len = 4096");
$sql->execute();
my $sql = $db->prepare("
INSERT INTO links_summary 
(categories, url_hash, post_titles, linked_by, url, domain, titles, page_title, last_linked_on) 
SELECT 
GROUP_CONCAT(DISTINCT t2.tag) AS categories,
links.url_hash, GROUP_CONCAT(DISTINCT CONCAT(p2.title,'===',p2.url,'===',p2.post_id,'===',blogs.title,'===',blogs.url,'===',blogs.blog_id) SEPARATOR '|||') AS post_titles, COUNT(DISTINCT links.blog_id) AS linked_by, links.url, domain, GROUP_CONCAT(DISTINCT TRIM(links.title) SEPARATOR ', ') AS title, links.page_title AS page_title, MAX(p2.pubdate) AS last_linked_on FROM links LEFT JOIN posts ON posts.url_hash = links.url_hash, posts AS p2, blogs, tags AS t2 WHERE blogs.blog_id = p2.blog_id AND p2.post_id = links.post_id AND ISNULL(posts.post_id) AND links.type = 'link' AND ISNULL(links.paper_id) AND length(trim(links.title)) >= 3 AND t2.blog_id = p2.blog_id AND DATEDIFF(CURRENT_TIMESTAMP(), p2.pubdate) <= ? GROUP BY links.url_hash
");
$sql->execute($age_limit);

my $sql = $db->prepare("
INSERT INTO posts_summary 
(post_id, blog_id, title, url, url_hash, summary, filename, author, pubdate, added_on, blog_name, blog_image, linked_by)	
SELECT posts.post_id, posts.blog_id, posts.title, posts.url, posts.url_hash, posts.summary, posts.filename, posts.author, posts.pubdate, posts.added_on, blogs.title AS blog_name, blogs.image AS blog_image, COUNT(DISTINCT IF(ISNULL(links.blog_id),NULL,IF(links.blog_id = posts.blog_id,NULL,links.blog_id))) AS linked_by FROM blogs, posts LEFT JOIN links ON links.url_hash = posts.url_hash WHERE blogs.blog_id = posts.blog_id GROUP BY posts.url_hash	
");
$sql->execute();

my $sql = $db->prepare("
INSERT INTO papers_summary
(paper_id, isbn_id, image, doi_id, pubmed_id, arxiv_id, pii_id, journal, title, abstract, authors, pubdate, added_on, url, cited_by, reviewed, blog_ids)
SELECT 
papers.paper_id,
papers.isbn_id,
papers.image,
papers.doi_id,
papers.pubmed_id,
papers.arxiv_id,
papers.pii_id,
papers.journal,
papers.title,
papers.abstract,
papers.authors,
papers.pubdate,
papers.added_on,
links.url AS url, 
COUNT(DISTINCT links.blog_id) AS cited_by,
SUM(IF(links.type = 'review', 1, 0)) AS reviewed,
GROUP_CONCAT(DISTINCT links.blog_id SEPARATOR ',') AS blog_ids
FROM papers LEFT JOIN links ON links.paper_id = papers.paper_id GROUP BY papers.paper_id;
");
$sql->execute();
