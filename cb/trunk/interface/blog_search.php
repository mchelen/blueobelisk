<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "blogs";
	$PAGE_TITLE = $config["name"]." - Blog details";
?>
<? include("header.php"); ?>
<? include("blogs_menu.php"); ?>
<?
	$safe_blog_id = mysql_escape_string($_GET['blog_id']);
	$details = get_blogs(array($safe_blog_id), array("show_new_blogs" => true));
	$details = $details[0];
?>
<div class='sidebar'>
<div class='sidebox'>
<div class='sidebox_title'>Subscribe to this blog</div>
<div class='sidebox_content'>
<a href="http://www.bloglines.com/sub/<? print $details['feed_url']; ?>">
<img src="http://www.bloglines.com/images/sub_modern9.gif" border="0" alt="Subscribe with Bloglines" />
</a>
<a href="http://fusion.google.com/add?feedurl=<? print urlencode($details['feed_url']); ?>"><img src="http://buttons.googlesyndication.com/fusion/add.gif" width="104" height="17" border="0" alt="Add to Google"></a>
<a href="http://www.newsgator.com/ngs/subscriber/subext.aspx?url=<? print $details['feed_url']; ?>"><img runat="server" src="http://www.newsgator.com/images/ngsub1.gif" alt="Subscribe in NewsGator Online" border="0" /></a>
</div>
</div>
<div class='sidebox'>
<div class='sidebox_title'>Stats</div>
<div class='sidebox_content'>
<p>Statistics are based on posts from the past ninety days.
<p><br/>
<?
	print_blog_stats($safe_blog_id);
?>
</div>
</div>	
</div>
<div class='content'>
<?	
	if ($safe_blog_id) {
		if ($details) {
			print_blog($details, array("link" => true, "tagcloud" => true));			
		} else {
			print_error("Couldn't get blog details", "Sorry, I couldn't retrieve the details of the blog that you're looking for.");
		}
		
		$posts = get_posts("published_on", array("blog_id" => $safe_blog_id, "limit" => 3));
		if ($posts) {
			print "<div class='blogbox_postboxes'>";
			print "<h3>Most recent posts</h3>";			
			foreach ($posts as $post) {
				print_post($post);
			}		
			print "</div>";
		}
						
		$posts = get_posts("cited", array("blog_id" => $safe_blog_id, "limit" => 3));
		
		if ($posts) {
			print "<div class='blogbox_postboxes'>";
			print "<h3>Most popular posts</h3>";
			foreach ($posts as $post) {
				print_post($post);
			}
			print "</div>";
		}
		
		$posts = array();
		
		$post_ids = get_posts_linking_to(false, $safe_blog_id);
		
		if ($post_ids) {
			print "<div class='blogbox_postboxes'>";			
			print "<h3>Latest posts linking here</h3>";			
			$posts = get_posts("published_on", array("post_id" => $post_ids, "limit" => 3));
			foreach ($posts as $post) {
				print_post($post);
			}
			print "</div>";
		}
	} else {
		print_error("No blog specified", "Sorry, I'm not sure which blog you're looking for.");
	}
	
?>
</div>
<? include("footer.php");?>