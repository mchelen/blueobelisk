<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "posts";
	$PAGE_TITLE = $config["name"]." - Post details";
?>
<? include("header.php"); ?>
<? include("posts_menu.php"); ?>
<?
	$safe_post_id = mysql_escape_string($_GET['post_id']);
?>
<?
	$terms = get_terms_for_post($safe_post_id, 100, 2);
	
	if (sizeof($terms)) {
		print "<div class='sidebar'>";
		
		print "<div class='sidebox'>";
		print "<div class='sidebox_title'>Shared Terms</div>";
		print "<div class='sidebox_content'>";
		print "<p>Click on the terms below to see more posts on that topics.";
		print "<div class='tagcloud'>";
		foreach ($terms as $term) {
			print "<a class='tagcloud_2' href='".linkto("posts.php", $page_vars, array("term" => $term))."'>$term</a> ";
		}
		print "</div>";
		print "</div>";
		print "</div>";
		
		print "</div>";
	}
?>
<div class='content <? if (!sizeof($terms)) {print "fullwidth";} ?>'>
<?
	$posts = get_posts("added_on", array("post_id" => array($safe_post_id)));
	foreach ($posts as $post) {
		print_post($post, array("magnify" => true, "image" => true, "fulltext" => $config['use_post_fulltext']));
	}
	
	$post_ids = get_posts_linking_to($safe_post_id, false);
	
	print "<div class='postbox_postboxes'>";
	if ($post_ids) {
		print "<h3>Posts linking to this one</h3>";
		$posts = get_posts("added_on", array("post_id" => $post_ids));
		foreach ($posts as $post) {
			print_post($post, array("image" => true));
		}
	}
	print "</div>";
?>
</div>
<?
include("footer.php");
?>