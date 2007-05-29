<?
function get_post($post_id) {
	$post_id = mysql_escape_string($post_id);
	
	$query = "SELECT posts.*, blogs.title AS blog_name, blogs.image AS blog_image FROM posts, blogs WHERE blogs.blog_id = posts.blog_id AND posts.post_id = $post_id";
	$results = mysql_query($query);
		
	while ($row = mysql_fetch_assoc($results)) {	
		$post = $row;
	}
	
	return $post;
}

function get_latest_posts($category = false, $limit = 10) {
	$filters = array();
	
	$filters["limit"] = $limit;
	if ($category) {$filters["category"] = $category;}
		
	return get_posts("published_on", $filters);
}

function get_posts_by_filenames($filenames) {
	$query = "SELECT post_id, filename FROM posts WHERE filename IN ('".implode("','", $filenames)."')";
	$results = mysql_query($query);
	
	$posts = array();

	while ($row = mysql_fetch_assoc($results)) {
		$posts[$row['filename']] = $row['post_id'];
	}
	
	return $posts;
}

function get_posts_linking_to($post_id = false, $blog_id = false, $url = false) {
	$posts = array();
	if ($blog_id) {
		$query = "SELECT DISTINCT links.post_id AS the_id FROM links LEFT JOIN posts ON links.url_hash = posts.url_hash WHERE posts.blog_id = $blog_id AND links.blog_id != $blog_id";
	}
	if ($post_id) {
		$query = "SELECT DISTINCT links.post_id AS the_id FROM links, posts WHERE posts.url_hash = links.url_hash AND posts.post_id=".$post_id;
	}
	if ($url) {
		$query = "SELECT DISTINCT post_id AS the_id FROM links WHERE url LIKE '%$url%'";
	}
	
	$results = mysql_query($query);
	
	while ($row = mysql_fetch_assoc($results)) {
		if ($row["the_id"] != $post_id) {
			array_push($posts, $row["the_id"]);
		}
	}
	return $posts;
}

function get_top_posts($category = false, $timeframe = false, $limit = 10) {
	$filters = array();
	
	$filters["limit"] = $limit;
	if ($category) {$filters["category"] = $category;}
	if ($timeframe) {$filters["published_after"] = $timeframe;}
		
	return get_posts("cited", $filters);
}

function process_post_xml($filename, $clean = true) {
	$file = file_get_contents($filename);
	
	$post = array();
	
	$file = preg_replace("/[\n\r]/", "", $file);
	
	$matches = array();
	$found = preg_match("/<description><\!\[CDATA\[(.*?)\]\]><\/description>/im", $file, $matches);
	
	if ($clean) {
		$post['description'] = strip_tags(html_entity_decode($matches[1]), "<a><p><div><br><img>");

		# remove img tags and replace with lightbox anchors
		$post['description'] = preg_replace_callback("/<img(.*?)src=[\'\"\s](.*?)[\'\"\s](.*?)>/i", "img_to_lightbox", $post['description']);

		$post['description'] = strip_tags($post['description'], "<a><p><div><br>");
 	} else {
		$post['description'] = $matches[1];
	}
	return $post;
}

function img_to_lightbox($matches) {
	return lightbox($matches[2]);
}

function get_posts_with_conference() {
	$query = "SELECT DISTINCT post_id FROM links WHERE type='conference'";
	$results = mysql_query($query);
	
	$posts = array();
	
	while ($row = mysql_fetch_array($results)) {
		array_push($posts, $row['post_id']);
	}
	
	$query = "SELECT DISTINCT post_id FROM tags WHERE tag='conference'";
	$results = mysql_query($query);
		
	while ($row = mysql_fetch_array($results)) {
		array_push($posts, $row['post_id']);
	}
	
	
	return array_unique($posts);
}

function get_posts_with_research() {
	$posts = array();
	
	$query = "SELECT DISTINCT post_id FROM tags WHERE (tag='original_research' OR tag='original research')";
	$results = mysql_query($query);
		
	while ($row = mysql_fetch_array($results)) {
		array_push($posts, $row['post_id']);
	}
	
	
	return array_unique($posts);
}

function get_posts_with_review() {
	$query = "SELECT DISTINCT post_id FROM links WHERE type='review'";
	$results = mysql_query($query);
	
	$posts = array();
	
	while ($row = mysql_fetch_array($results)) {
		array_push($posts, $row['post_id']);
	}
	
	$query = "SELECT DISTINCT post_id FROM tags WHERE tag='review'";
	$results = mysql_query($query);
		
	while ($row = mysql_fetch_array($results)) {
		array_push($posts, $row['post_id']);
	}
	
	
	return array_unique($posts);
}

function get_posts($sort_by = "published_on", $filters = array()) {
	$query = "SELECT SQL_CALC_FOUND_ROWS * FROM posts_summary ";
	
	$where_clause = " WHERE !ISNULL(post_id)";
	#$where_clause .= " AND p2.post_id = links.post_id AND p2.blog_id != posts.blog_id";
		
	$order_by = " ORDER BY pubdate DESC";
	$limit_by = "";

	if ($sort_by == "published_on") {$order_by = " ORDER BY pubdate DESC";}
	if ($sort_by == "added_on") {$order_by = " ORDER BY added_on DESC";}
	if ($sort_by == "cited") {$order_by = " ORDER BY linked_by DESC, pubdate DESC";}
	if ($sort_by == "post_freq") {
		if ($filters['post_id']) {
			# we want an order in which elements that appear most frequently in $filters['post_id'] have the highest rankings
			$post_freq = array_count_values($filters['post_id']);
			arsort($post_freq);			
			$order_by = " ORDER BY FIELD(post_id";
			foreach ($post_freq as $post_id => $post_freq) {
				$order_by .= ", $post_id";
			}
			$order_by .= ")";
		}
	}
	$sort_by .= ", title ASC";

	if (!$filters['limit']) {$filters['limit'] = $GLOBALS["config"]['posts_per_page'];}

	if ($filters['limit']) {$limit_by = " LIMIT ".$filters['limit'];}
	
	if ($filters['skip']) {
		if ($filters['skip'] < 0) {$filters['skip'] = 0;}
		$limit_by = " LIMIT ".$filters['skip'].",".$filters['limit'];
	}
	
	if ($filters['base_url']) {
		$where_clause .= " AND url LIKE '".$filters['base_url']."%'";
	}
	
	if ($filters['term']) {
		$tposts = get_posts_with_term($filters['term']);
		$tposts= "'".implode("','", $tposts)."'";
		$where_clause .= " AND post_id IN ($tposts)";
	}
	
	if ($filters['category']) {
		$blogs = get_blogs_with_tag($filters['category']);
		$blogs = "'".implode("','", $blogs)."'";
		$where_clause .= " AND blog_id IN ($blogs)";
	}
	if ($filters['tag']) {
		$tag = $filters['tag'];
		$tposts = array();
		if ($tag == "original_research") {$tposts = get_posts_with_research();}
		elseif ($tag == "conference") {$tposts = get_posts_with_conference();}
		elseif ($tag == "review") {$tposts = get_posts_with_review();}
		else {$tposts = get_posts_with_tag($filters['tag']);}
		
		$tposts= "'".implode("','", $tposts)."'";
		$where_clause .= " AND post_id IN ($tposts)";
		
	}
	if ($filters['review']) {
		$tposts = get_posts_with_review();
		$tposts= "'".implode("','", $tposts)."'";
		$where_clause .= " AND post_id IN ($tposts)";		
	}
	if ($filters['conference']) {
		$tposts = get_posts_with_conference();
		$tposts= "'".implode("','", $tposts)."'";
		$where_clause .= " AND post_id IN ($tposts)";		
	}
	if ($filters['original_research']) {
		$tposts = get_posts_with_research();
		$tposts= "'".implode("','", $tposts)."'";
		$where_clause .= " AND post_id IN ($tposts)";		
	}
	if ($filters['published_before']) {
		$date = $filters['published_before'];
		$where_clause .= " AND pubdate < '$date'";
	}
	if ($filters['published_after']) {
		$date = $filters['published_after'];
		$where_clause .= " AND pubdate >= '$date'";
	}
	if ($filters['blog_id']) {
		$where_clause .= " AND blog_id = ".$filters['blog_id'];
	}
	if (isset($filters['post_id'])) {
		if ($filters['post_id']) {
			if (!is_array($filters['post_id'])) {
				$where_clause .= " AND post_id = ".$filters['post_id'];
			} else if (is_array($filters['post_id'])) {
				$where_clause .= " AND post_id IN (".implode(",", $filters['post_id']).")";
			}
		} else {
			return array();
		}
	}
	if ($filters['min_links']) {
		$where_clause .= " AND linked_by >= ".$filters['min_links'];
	}

	$posts = array();

	$having = "";
	
	$query = $query.$where_clause.$group_by.$having.$order_by.$limit_by;	

        # print "Query: ". $query . "<br />";

	$results = mysql_query($query);

	$rows = mysql_num_rows($results);
	if ($limit_by) {
		$count_query = "SELECT FOUND_ROWS() AS rows";
		$count_results = mysql_query($count_query);
		while ($row = mysql_fetch_assoc($count_results)) {
			$rows = $row['rows'];
		}
	}

	while ($row = mysql_fetch_assoc($results)) {
		$post = $row;
		$post['rows_returned'] = $rows;
		$post['post_request_type'] = "all";
		if ($filters['conference']) {$post['post_request_type'] = "conference";}
		if ($filters['review'])  {$post['post_request_type'] = "review";}
		if ($filters['originaL_research']) {$post['post_request_type'] = "original_research";}			
		array_push($posts, $post);
	}
	
	
	if ($filters['order_by_filenames_array']) {
		$filenames = $filters['order_by_filenames_array'];
		$ordered_posts = array();

		# we need to do some post-ordering
		foreach ($filenames as $filename) {
			# find row with this filename, add it to the array.
			foreach ($posts as $post) {
				if ($post['filename'] == $filename) {
					array_push($ordered_posts, $post);
				}
			}
		}

		$posts = $ordered_posts;
	}
	
	return $posts;
}

?>
