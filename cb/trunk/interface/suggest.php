<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "suggest";
	$PAGE_TITLE = $config["name"]." - Suggest blogs";
?>
<? include("header.php"); ?>
<div class='content'>
<?
	$connotea_tags = false;
	# suggest blogs based on your profiles on other sites (Connotea, at the moment.)	
	if ($_SAFE['connotea_username']) {
		# get tags used by connotea_username
		$connotea_tags = connotea_get_tags_for_user($_SAFE['connotea_username']);
		if (!$connotea_tags) {
			print "<p>Couldn't get results from Connotea. Did you enter a valid username? If so, give it thirty seconds then try again.";
		}
	}
	
	$bloglines_terms = false;
	if ($_SAFE['bloglines_email']) {
		set_time_limit(60 * 60 * 1);
		$counter = 0;
		
		# only get items from past three days
		$last_week = time() - (60 * 60 * 24 * 3);

		$items = download_url("http://rpc.bloglines.com/getitems?d=$last_week&s=0", $_SAFE['bloglines_email'], $_SAFE['bloglines_password']);
						
		if ($items) {
			# we need to parse out all of the content...
			$matches = array();
			preg_match_all("/\<\!\[CDATA\[(.*?)\]\]\>/is", $items, $matches);
					
			$data = $matches[1];
			$all_data = implode(" ", $data);
			
			# don't pass too much data at any one time to the term extraction API....
			$start = 0;
			$apilen = 150000;
			
			while (strlen(substr($all_data, $start, $apilen)) > 0) {
				$chunk = substr($all_data, $start, $apilen);

				# get terms for content...
				$terms = extract_terms(strip_tags($chunk));

				foreach ($terms as $term) {
					$bloglines_terms[$term]++;
				}
								
				$start += $apilen;
			}
					
		}
		
	} elseif ($_SAFE['bloglines_username']) {
		set_time_limit(60 * 60 * 1);
		$counter = 0;

		# get list of feed homepages...
		$page = download_url("http://rpc.bloglines.com/blogroll?html=1&id=".$_SAFE['bloglines_username']);
		if ($page) {			
			# extract URLs from $page
			$matches = array();
			preg_match_all("/a href=\"(.*?)\"/i", $page, $matches);
			
			$urls = $matches[1];
			$bloglines_terms = array();
			
			# then follow them all...
			foreach ($urls as $url) {
				$content = false;
				$counter++;
				if ($counter <= 50) {
					$content = download_url($url, false, false, 5);
				}
				
				if ($content) {
					
					# remove text between script and style tags
					$content = preg_replace("/<script>(.*?)<\/script>/i", " ", $content);
					$content = preg_replace("/<style>(.*?)<\/style>/i", " ", $content);

					# get terms for content...
					$terms = extract_terms(strip_tags($content));
			
					foreach ($terms as $term) {
						$bloglines_terms[$term]++;
					}
				}
			}
		} else {
			print "Couldn't get results from Bloglines - did you enter a valid username?";
		}
	}
	
?>
<h3>Connotea</h3>
<p>Matches tags in your Connotea library to tags on feeds.
<table>
<tr>
<td width='80' valign='top'>
<img src='images/comment_connotea.jpg'>
</td>
<td width='*'>
<form method='get' action='suggest.php'>
<p>Username: <input type='text' name='connotea_username' value='<? print $_SAFE['connotea_username']; ?>'/>
<p><input name='use_weighting' type='checkbox' <? if ($_SAFE['use_weighting']) {print "checked";} ?>> Use tag weighting (tags used more frequently in your library are weighted higher)
<p><input type='submit' value='Go'/>
</form>	
</td>
</tr>
</table>
<h3 align='center'>OR</h3>
<h3>Bloglines</h3>
<p>Matches terms found in your Bloglines subscriptions to terms found in feeds here.
<p>Note: only the first fifty subscriptions will be examined - this is because otherwise performance suffers.
<table>
<tr>
<td width='80' valign='top'>
<img src='images/bloglines.gif'>
</td>
<td width='*'>
<form method='post' action='suggest.php'>
<p>Username: <input type='text' name='bloglines_username' value='<? print $_SAFE['bloglines_username']; ?>'/>
<p align='center'<b>OR</b>
<p>It's much faster if we can use the Bloglines API, but this requires the email address associated with your subscriptions and your Bloglines password:
<p>Email address: <input type='text' name='bloglines_email' value='<? print $_SAFE['bloglines_email']; ?>'/>
<p>Password: <input type='password' name='bloglines_password' value='<? print $_SAFE['bloglines_password']; ?>'/>
<p><br/>
<p><input name='use_weighting_bloglines' type='checkbox' <? if ($_SAFE['use_weighting_bloglines']) {print "checked";} ?>> Use term weighting (terms found more frequently in your subscriptions are weighted higher)
<p><input type='submit' value='Go'/>
</form>	
</td>
</tr>
</table>
<?
	$blog_ids = array();
	$blog_names = array();
	$blog_tags = array();

	if ($connotea_tags) {
		$valid_tags = validate_tags(array_keys($connotea_tags));
		
		if (!$valid_tags) {
			print "<h3>Sorry</h3>";
			print "<p>None of the tags in ".$_SAFE['connotea_username']."'s library are in the Postgenomic index.";
			print_r($connotea_tags);
		} else {
			print "<h3>Matched Connotea tags</h3>";
			print_tagcloud($valid_tags);

			# try and match up tags with blogs in the database
			foreach ($connotea_tags as $tag => $freq) {
				$post_ids = get_posts_with_tag($tag);

				# what blogs are these posts from?
				if ($post_ids) {
					$done = array();
					$posts = get_posts("cited", array("post_id" => $post_ids));
					if ($posts) {
						foreach ($posts as $post) {
							if ($done[$post['blog_id']]) {next;} else {

								if ($_SAFE['use_weighting']) {
									$blog_ids[$post['blog_id']] += $freq;
								} else {
									$blog_ids[$post['blog_id']]++;								
								} 

								$blog_names[$post['blog_id']] = $post['blog_name'];
								if ($blog_tags[$post['blog_id']]) {
									$blog_tags[$post['blog_id']] .= "|TAG|";
								}
								$blog_tags[$post['blog_id']] .= "$tag";
								$done[$post['blog_id']] = true;
							}
						}
					}
				}		
			}
		}
	}
	
	if ($bloglines_terms) {
		$valid_terms = validate_terms(array_keys($bloglines_terms));
		
		if (!$valid_terms) {
			print "<h3>Sorry</h3>";
			print "<p>None of the terms in ".$_SAFE['bloglines_username']."'s subscriptions are in the Postgenomic index.";
			print_r($bloglines_terms);
		} else {
			print "<h3>Matched Bloglines terms</h3>";
			print_termcloud($valid_terms);

			# try and match up tags with blogs in the database
			foreach ($valid_terms as $term => $freq) {
				$post_ids = get_posts_with_term($term);

				# what blogs are these posts from?
				if ($post_ids) {
					$done = array();
					$posts = get_posts("cited", array("post_id" => $post_ids));
					if ($posts) {
						foreach ($posts as $post) {
							if ($done[$post['blog_id']]) {next;} else {

								if ($_SAFE['use_weighting_bloglines']) {
									$blog_ids[$post['blog_id']] += $freq;
								} else {
									$blog_ids[$post['blog_id']]++;								
								} 

								$blog_names[$post['blog_id']] = $post['blog_name'];
								if ($blog_tags[$post['blog_id']]) {
									$blog_tags[$post['blog_id']] .= "|TAG|";
								}
								$blog_tags[$post['blog_id']] .= "$term";
								$done[$post['blog_id']] = true;
							}
						}
					}
				}		
			}
		}
	}
	
	arsort($blog_ids, SORT_NUMERIC);
	
	if ($blog_ids) {
		print "<h3>Recommended blogs</h3>";
		foreach ($blog_ids as $blog_id => $weight) {
			print "<div class='blogbox'>";
			print "<div class='blogbox_title'><a href='".linkto("blog_search.php", $page_vars, array("blog_id" => $blog_id))."'>".$blog_names[$blog_id]."</a></div>";
			print "<div class='tagbox'>";
			$tags = explode("|TAG|", $blog_tags[$blog_id]);
			foreach ($tags as $tag) {
				print "<a href='".linkto("tag_search.php", $page_vars, array("tag" => $tag))."'>$tag</a> ";
			}
			print "</div></div>";
		}	
	} 
?>


</div>
<?
include("footer.php");
?>