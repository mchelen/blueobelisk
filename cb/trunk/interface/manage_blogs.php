<? include("functions.php"); ?>
<?
if ((!$is_admin) || (!$logged_on)) {
	header("Location: index.php");		
}
?>
<? include("header.php"); ?>
<? require_once('magpierss/rss_fetch.inc'); ?>
<div class='sidebar'>
<h3>Load workspace</h3>
<p><a href='manage_blogs.php?workspace=false'>Blogs with no tags</a>
<?
$query = "SELECT DISTINCT tag FROM tags WHERE !ISNULL(blog_id) AND tagged_by='admin' ORDER BY tag 
ASC";
$results = mysql_query($query);
while ($row = mysql_fetch_assoc($results)) {
	printf("<p><a href='manage_blogs.php?workspace=%s'>%s blogs</a>", $row['tag'], $row['tag']);
}
?>
</div>
<div class='content'>
<?
if ($_SAFE['restore_blog_id']) {
	if (is_numeric($_SAFE['restore_blog_id'])) {
		$query = "UPDATE blogs SET active=1 WHERE blog_id=".$_SAFE['restore_blog_id'];
		mysql_query($query);
	}
}

if ($_SAFE['remove_blog_id']) {
	if (is_numeric($_SAFE['remove_blog_id'])) {
		$query = "UPDATE blogs SET active=0 WHERE blog_id=".$_SAFE['remove_blog_id'];
		mysql_query($query);	
	}
}

if ($_POST['blogs']) {
	$blogs = $_POST['blogs'];
	$blogs = preg_split("/[\s\r\n]+/i", $blogs);
	if (sizeof($blogs) >= 1) {
		foreach ($blogs as $blog) {
			$url = mysql_escape_string($blog);
			# try fetching it with Magpie
			$rss = @fetch_rss($url);
			if ($rss->channel) {
				$title = mysql_escape_string($rss->channel['title']);
				$home_url = mysql_escape_string($rss->channel['link']);
				
				if ($title && $home_url) {
					$blog_image = $config['default_image'];
					if ($config['default_image_alternate']) {
						if (rand(0,10) <= 5) {
							$blog_image = $config['default_image_alternate'];
						}
					}
					print "<h3>$url validated</h3>";
					$query = "INSERT INTO blogs (title, url, feed_url, added_on, image) VALUES ('$title', '$home_url', '$url', CURRENT_TIMESTAMP(), '".$blog_image."')";
					$results = mysql_query($query);
				} else {
					print "<h3>$url missing link or title</h3>";
				}
			} else {
				print "<h3>$url not a valid feed</h3>";
			}
		}
	}
}
?>
<h1>Add Blogs</h1>
<form action='manage_blogs.php' method='POST'>
<p>Type or paste one or more feed URLs here, separated by newlines.
<p>Note that new blogs won't appear on the site until the next time that the pipeline is run.
<div style='margin: 5px;'>
<textarea name='blogs' style='width: 600px; height: 200px; border: 1px solid black; padding: 6px;'></textarea><br/>
<input type='submit' name='submit' value='Submit'/>
</div>
</form>
<h3>Blog Workspace</h3>
<?
	$workspace = $_GET['workspace'];
	if ($_POST['workspace']) {$workspace = $_POST['workspace'];}
	$workspace = mysql_escape_string($workspace);
	if (!$workspace) {$workspace = 'false';}
	
	$blog_ids = array();
	if ($workspace != 'false') {
		$blog_ids = get_blogs_with_tag($workspace);
	} else {
		$blog_ids = get_blogs_with_no_tags();
	}
	
	if (sizeof($blog_ids)) {
		$blogs = get_blogs($blog_ids, array("latest" => true, "limit" => 1000, "show_new_blogs" => true, "show_inactive" => true));
	
		foreach ($blogs as $blog) {
			print_blog($blog, array("add_tag" => true, "workspace" => $workspace));
		}
	} else {
		print "No such blogs";
	}
	
?>
</div>
<? include("footer.php"); ?>
