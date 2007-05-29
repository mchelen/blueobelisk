<? include("functions.php"); ?>
<?
	$safe_tag = mysql_escape_string($_GET['tag']);
	
	$PAGE_TYPE = "search";
	$PAGE_TITLE = $config["name"]." - Items tagged $safe_tag";
?>
<? include("header.php"); ?>
<?
	
	print "<div class='sidebar'>";

	$similar = get_similar_tags($safe_tag, 50);
	
	if ($similar) {
		print "<div class='sidebox'>";
		print "<div class='sidebox_title'>Similar tags</div>";
		print "<div class='sidebox_content'>";
		print "<p class='description'>Posts tagged with \"$safe_tag\" are also tagged with...</p>";
		print_tagcloud($similar);
		print "</div>";
		print "</div>";
	}
	
	$users = find_connotea_users_with($safe_tag, 10);
	
	if ($users) {
		print "<div class='sidebox'>";
		print "<div class='sidebox_title'>Connotea users</div>";
		print "<div class='sidebox_content'>";
		print "<p class='description'>Connotea users who tag items with \"$safe_tag\" include...</p>";
		foreach ($users as $key => $value) {
			print "<p><a href='http://www.connotea.org/user/$key'>$key</a>";
		}
		print "</div>";
		print "</div>";
	}
	
	$blogs = get_blogs_using_tag($safe_tag, 25);
	
	if ($blogs) {
		print "<div class='sidebox'>";
		print "<div class='sidebox_title'>Blogs</div>";
		print "<div class='sidebox_content'>";
		print "<p class='description'>Blogs containing posts tagged \"$safe_tag\" include...</p>";
		foreach ($blogs as $key => $value) {
			print "<p><a href='".linkto("blog_search.php", $GLOBALS['page_vars'], array("blog_id" => $key))."'>$value</a>";
		}
		print "</div>";
		print "</div>";
	}
	
	print "</div>";
	
	print "<div class='content'>";
		
	if ($safe_tag) {
	
		print "<h1>Items tagged with \"$safe_tag\"</h1>";
			
		$paper_ids = array();
		$paper_ids = get_papers_with_tag($safe_tag, true);
		
		if ($paper_ids) {
			print "<h3>Papers</h3>";

			$papers = get_papers("cited", array("paper_id" => $paper_ids));
		
			foreach ($papers as $paper) {
				print_paper($paper, array("display" => "minimal"));
			}
		}

		$post_ids = get_posts_with_tag($safe_tag);
		
		if ($post_ids) {		
			print "<h3>Posts</h3>";
			
			$posts = get_posts("cited", array("post_id" => $post_ids));
			
			foreach ($posts as $post) {
				print_post($post);
			}
		}
		
		
		print "</div>";
	} else {
		print_error("No tag specified", "You must specify a tag to search for.");
	}

?>
<? include("footer.php"); ?>
