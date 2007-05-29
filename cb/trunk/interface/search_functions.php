<?
# The search function in Postgenomic can use PyLucene or MySQL's 'LIKE' clause.
# In the former case the URL to a PyLucene script is called and the results parsed.
# That's why the parse_search_results() function takes in a text file.
# At some point we should switch over to using OpenSearch as the file format instead of our
# "custom" text file (list of matched filenames followed by three lines of metadata)

function do_search($term, $safe_skip = 0, $max = false, $safe_type = "any") {
	global $config;
	
	$safe_search = reduce_to_ascii($term, true);
	if (!$max) {$max = $config['search_results_per_page'];} # $max is per page, not the limit of the number of results
	
	
	# rather confusingly the "do_search" config variable actually means "use PyLucene?". If do_search is 0 then we use
	# MySQL's built in search functionality instead.
	if ($config['do_search']) {
		# use PyLucene
		$url = $GLOBALS['config']['pylucene_url']."?q=".urlencode($safe_search)."&start=$safe_skip&max=$max&type=$safe_type";	
		$results = download_url($url);
	} else {
		# use MySQL
		$results = do_mysql_search($safe_search, $safe_skip, $max, $safe_type);
	}
	
	return $results;
}

function do_mysql_search($search, $skip = 0, $max = false, $type = "any") {
	# $type can be: any, posts, papers, blogs
	# $skip is number of results to skip
	# $max is number of results to return?
	# $search is actual search term.
	
	$return = "";
		
	$sresults = array();
	$total_results = 0;
	
	if (($type == "posts") || ($type == "any")) {
		$query = "SELECT DISTINCT filename, added_on FROM posts WHERE (title LIKE '%".$search."%' OR summary LIKE '%".$search."%')";
		$results = mysql_query($query);
		while ($row = mysql_fetch_assoc($results)) {
			$sresults[$row['filename']] = $row['added_on'];
			$total_results++;
		}
	}
	if (($type == "papers") || ($type == "any")) {
		$query = "SELECT DISTINCT paper_id, added_on FROM papers WHERE (title LIKE '%".$search."%' OR abstract LIKE '%".$search."%' OR authors LIKE '%".$search."%')";
		$results = mysql_query($query);
		while ($row = mysql_fetch_assoc($results)) {
			$sresults["paper_".$row['paper_id'].".xml"] = $row['added_on'];
			$total_results++;
		}		
	}
	if (($type == "blogs") || ($type == "any")) {
		# bit of a hack here so that blogs always appear at the top of the search results.
		$query = "SELECT DISTINCT feed_url, CURRENT_TIMESTAMP() AS added_on FROM blogs WHERE (title LIKE '%".$search."%' OR description LIKE '%".$search."%')";
		$results = mysql_query($query);
		while ($row = mysql_fetch_assoc($results)) {
			$sresults["feed_info_".md5($row['feed_url'])] = $row['added_on'];
			$total_results++;
		}		
	}
	
	# sort sresults by value
	arsort($sresults);
	
	$counter = 0;
	foreach ($sresults as $sresult => $added_on) {
		if (($counter >= $skip) && ($counter <= ($skip + $max))) {
			$return .= $sresult."\n";
		}
		$counter++;
	}
	
	$return .= "===META=TYPE===".$total_results."===\n";
	$return .= "===META=TOTAL===".$total_results."===\n";	
	$return .= "===META=LIMIT===".$max."===\n";

	return $return;
}

function parse_search_results($results) {
	
	$num_results = 0;
	$total_results = 0;
	$limit = 0;
	
	$return;
	
	if ($results) {
		$lines = explode("\n", $results);
		# filter out blank lines
		$filenames = array();
		foreach ($lines as $line) {
			if (strlen($line) >= 3) {array_push($filenames, $line);}
			
			$matches = array();
			preg_match("/===META=TYPE===(\d+)===/", $line, $matches);
			if ($matches[1]) {$num_results = $matches[1];}
			$matches = array();
			preg_match("/===META=TOTAL===(\d+)===/", $line, $matches);
			if ($matches[1]) {$total_results = $matches[1];}
			$matches = array();
			preg_match("/===META=LIMIT===(\d+)===/", $line, $matches);
			if ($matches[1]) {$limit = $matches[1];}
		}
		
		# first get any posts
		$posts = array();
		if (sizeof($filenames)) {
			$posts_files = get_posts_by_filenames($filenames);
			if (sizeof($posts_files)) {
				$post_ids = array_values($posts_files);
				$post_filenames = array_keys($posts_files);
 				$posts = get_posts("published_on", array("post_id" => $post_ids, "order_by_filenames_array" => $filenames));
				# add rows_returned field to first post (used by pagination algorithm)
				$posts[0]["rows_returned"] = $num_results;
			}
		}
		
		# then any blogs
		$blogs = array();
		if (sizeof($filenames)) {
			$blogs_files = get_blogs_by_filenames($filenames);
			if (sizeof($blogs_files)) {
				$blogs = get_blogs($blogs_files);
				$blogs[0]["rows_returned"] = $num_results;
			}
		}
		
		# and any papers...
		$papers = array();
		if (sizeof($filenames)) {
			$paper_ids = array();
			foreach ($filenames as $filename) {
				$matches = array();
				preg_match("/paper_(\d+)\.xml/i", $filename, $matches);
				if ($matches) {
					array_push($paper_ids, $matches[1]);
				}
			}
			if (sizeof($paper_ids)) {
				$papers = get_papers("cited", array("paper_id" => $paper_ids));
				$papers[0]["rows_returned"] = $num_results;
			}
		}	
		
		$return["posts"] = $posts;
		$return["blogs"] = $blogs;
		$return["papers"] = $papers;
		$return["limit"] = $limit;
		$return["total_results"] = $total_results;
		$return["num_results"] = $num_results;
			
	}
	
	return $return;	
}

?>