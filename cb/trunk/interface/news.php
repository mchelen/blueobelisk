<? include("functions.php"); ?>
<?
	$PAGE_CACHE = 0;
	$PAGE_TYPE = "news";
?>
<? include("header.php"); ?>
<?
	$last_week = date("Y-m-d", mktime(0,0,0, date(m), date(d)-7,date(Y))); 
	$last_month = date("Y-m-d", mktime(0,0,0, date(m)-1, date(d),date(Y))); 

	$terms = get_terms(32, $safe_category);
	$terms = clean_terms($terms);
	$all_terms = $terms;
	
	# get posts for each term, remove duplicate posts and then order by post number.
	$posts_seen = array();
	$term_posts = array();
	$term_posts_count = array();
	foreach (array_keys($terms) as $term) {
		# get posts for this story...
		$filters['term'] = $term;
		$filters['limit'] = 5;
				
		$last_fortnight = date("Y-m-d", mktime(0,0,0, date(m), date(d)-14,date(Y))); 
		$filters['published_after'] = $last_fortnight;
		
		$posts = get_posts("published_on", $filters);
		
		$assigned_posts = array();
		
		foreach ($posts as $post) {
			if ($posts_seen[$post['post_id']]) {
				# skip it, we've already seen this post.
			} else {
				array_push($assigned_posts, $post);
				$posts_seen[$post['post_id']] = true;
				$term_posts_count[$term]++;
			}
		}
		
		$term_posts[$term] = $assigned_posts;		
	}
	
?>
<div class='sidebar'>
<div class='sidebox'>
<div class='sidebox_title'>Latest Buzz</div>
<div class='sidebox_content'>
<? print_termcloud($all_terms); ?>
</div>
</div>
</div>
<div class='content'>
<h1>Stories</h1>
<div class='newspage_tabs'>
<?
	# order list of terms by term_posts_count
	arsort($term_posts_count);
	$terms = array_keys($term_posts_count);
	
	for ($i=0; $i <= 5; $i++) {
		if ($terms[$i]) {
			if ((!($i % 2)) && ($i > 0)) {
				print "<div class='newspage_footer'>&nbsp;</div>\n";
			}
			
			$term = $terms[$i];
			
			$posts = $term_posts[$term];
			
			print "<div class='newspage_tab_container'>\n";
			print "<div class='newspage_tab'>\n";
			print "<div class='tab_title'>".$terms[$i]."</div>";
			
			if ($posts) {		
				$counter = 0;				
				foreach ($posts as $post) {
					$counter++;
					$filters = array();
						
					# first story should have an image and the summary - further stories just have a title
					if ($counter >= 2) {$filters['short'] = true;} else {$filters['image'] = true;}
					print_post($post, $filters);
					if ($counter == 1) {
						print "<div class='postbox_postboxes'>";
					}
				}
				if ($counter) {
					print "</div>"; # ends the postbox_postboxes div
				}
			}
			
			printf("<a href='%s'>read more posts on this topic...</a>", linkto("posts.php", $page_vars, array("term" => $terms[$i])));
			print "</div>\n";
			print "</div>";
		}
	}
	print "<div class='frontpage_footer'>&nbsp;</div>";

?>
</div>
</div>
<? include("footer.php"); ?>