<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "search";
	$PAGE_TITLE = $config["name"]." - Search";
?>
<? include("header.php"); ?>
<?

	$safe_skip = 0;
	$safe_skip = mysql_escape_string($_GET["skip"]);
	$safe_type = mysql_escape_string($_GET["type"]);
	if (!$safe_type) {$safe_type = "any";}

	if (!is_numeric($safe_skip)) {$safe_skip = 0;}

	if ($_GET['search']) {
		$safe_search = reduce_to_ascii($_GET['search'], true);
		$results = do_search($safe_search, $safe_skip, $max, $safe_type);
	}

?>
<div class='content fullwidth'>
<?
	$return = parse_search_results($results);
	$total_results = $return["total_results"];
	$num_results = $return["num_results"];
	$posts = $return["posts"];
	$blogs = $return["blogs"];
	$papers = $return["papers"];
?>
<div class='searchbox'>
<div class='searchbox_title'>Search</div>
<div class='searchbox_content'>
<form action='search.php' method='GET'>
<input class='textbox' style='width: 80%;' type='text' name='search' <? if ($safe_search) {print "value='$safe_search'";} ?>/> <input type='submit' value='Search' />
<p>
<input type='radio' style='background-color: transparent;' <? if ($safe_type == "any") {print "checked";} ?> name='type' value='any'>Anything
<input type='radio' style='background-color: transparent;' <? if ($safe_type == "posts") {print "checked";} ?> name='type' value='posts'>Posts
<input type='radio' style='background-color: transparent;' <? if ($safe_type == "papers") {print "checked";} ?> name='type' value='papers'>Papers
<input type='radio' style='background-color: transparent;' <? if ($safe_type == "blogs") {print "checked";} ?> name='type' value='blogs'>Blogs
</form>
</div>
</div>
<?
	if ($total_results) {
		print "<h1>Searched for ".$safe_search;
		
		if ($safe_type != "any") {
			print " in $safe_type</h1>";
			if ($total_results > $num_results) {
				print " (<a href='search.php?search=".$_GET['search']."&type=any'>remove this limit</a> to see ".($total_results - $num_results)." more results)";
			}
		} else {
			print "</h1>";
		}
		
		# search for any tags
		$tags = get_similar_tags($safe_search, 12, 1);
		if ($tags) {
			print "<div class='tagbox'>Items tagged <a href='".linkto("tag_search.php", $GLOBALS['page_vars'], array("tag" => $safe_search))."'>$safe_search</a> were also tagged: ";
			foreach ($tags as $tag => $val) {
				print "<a href='".linkto("tag_search.php", $GLOBALS['page_vars'], array("tag" => $tag))."'>$tag</a> ";
			}
			print "</div>";
		}
		
		if ($num_results) {
			print_pagination($num_results, $safe_skip, "search.php", $GLOBALS["config"]['posts_per_page'], array("search" => $safe_search, "type" => $safe_type));
			foreach ($blogs as $blog) {
				print_blog($blog);
			}
			foreach ($papers as $paper) {
				print_paper($paper, array("display" => "minimal"));
			}
			foreach ($posts as $post) {
				print_post($post, array("image" => true));
			}
			print_pagination($num_results, $safe_skip, "search.php", $GLOBALS["config"]['posts_per_page'], array("search" => $safe_search, "type" => $safe_type));
		}
	} else {
		if ($safe_search) {
			print "<h1>No results returned for ".$safe_search."</h1>";
		}
	}
?>
</div>
<? include("footer.php"); ?>
