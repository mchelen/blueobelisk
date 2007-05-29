<?

function get_all_categories() {
	$query = "SELECT DISTINCT tag FROM tags, blogs WHERE tags.tagged_by = \"admin\" AND !ISNULL(tags.blog_id) AND blogs.blog_id = tags.blog_id AND blogs.active=1 ORDER BY tag ASC";
	$results = mysql_query($query);
	
	$tags = array();
	while ($row = mysql_fetch_assoc($results)) {
		array_push($tags, $row['tag']);
	}
	return $tags;
}

function get_active_blogs($category = false, $timeframe = false, $limit = 50) {
	
	$query = "SELECT posts.blog_id, blogs.title AS blog_name, COUNT(*) AS count FROM posts, blogs WHERE blogs.blog_id = posts.blog_id";
	if ($category) {$query .= " AND posts.blog_id IN (".implode(",", get_blogs_with_tag($category)).")";}
	if ($timeframe) {$query .= " AND posts.pubdate >= '$timeframe'";} 
	$query .=  " GROUP BY posts.blog_id ORDER BY count DESC";
	if ($limit) {$query .= " LIMIT $limit";}

	$results = mysql_query($query);
	
	$blogs = array();
	$mapping = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		$blogs[$row['blog_id']] = $row['count'];
		$mapping[$row['blog_id']] = $row['blog_name'];		
	}
	
	return array("blogs" => $blogs, "mapping" => $mapping);
}

function get_blogs_by_filenames($filenames = array()) {
	# format of filename is feed_info_<hash>
	# where <hash> is the hash of the feed URL.
	$blogs = array();
	$query = "SELECT blog_id, feed_url FROM blogs";
	$results = mysql_query($query);
	while ($row = mysql_fetch_assoc($results)) {
		$id = md5($row['feed_url']);
		$blogs[$id] = $row['blog_id'];
	}
	
	$results = array();
	foreach ($filenames as $filename) {
		$matches = array();
		preg_match("/feed_info_(.+)/i", $filename, $matches);
		$feed_id = $matches[1];
		if ($feed_id) {
			if ($blogs[$feed_id]) {
				array_push($results, $blogs[$feed_id]);
			}
		}
	}
	return $results;
}

function get_blog_id($feed_url) {
	$query = "SELECT blog_id FROM blogs WHERE feed_url='$feed_url'";
	$blog_id = false;

	$results = mysql_query($query);
	while ($row = mysql_fetch_assoc($results)) {
		$blog_id = $row['blog_id'];
	}
	
	return $blog_id;	
}

function get_last_pubdate($blog_id = false, $feed_url = false) {
	if ($blog_id) {
		$query = "SELECT pubdate FROM posts WHERE blog_id='$blog_id'";
	}
	if ($feed_url) {
		$query = "SELECT pubdate FROM posts, blogs WHERE posts.blog_id = blogs.blog_id AND blogs.feed_url='$feed_url'";		
	}

	$pubdate = false;

	$results = mysql_query($query);
	while ($row = mysql_fetch_assoc($results)) {
		$pubdate = $row['pubdate'];
	}
	
	return $pubdate;
}

function get_blogs_linking_blog($blog_id, $limit = 10) {
	
	$post_ids = get_posts_linking_to(false, $blog_id);
	if (!$post_id) {
		return array();
	}
	
	$query = "SELECT DISTINCT blog_id, blogs.title AS blog_name FROM posts, blogs WHERE posts.blog_id = blogs.blog_id AND post_id IN (".implode(",", $post_ids).")";
	if ($limit) {$query .= " LIMIT $limit";}

	$results = mysql_query($query);
	
	$blogs = array();
	$mapping = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		$blogs[$row['blog_id']] = $row['count'];
		$mapping[$row['blog_id']] = $row['blog_name'];		
	}
	
	return array("blogs" => $blogs, "mapping" => $mapping);	
}

function get_blogs($blogs = array(), $filters = array()) {
	global $config;
	
	if (sizeof($blogs) > 0) {
		$query = "SELECT SQL_CALC_FOUND_ROWS blogs.*, blog_stats.*, blogs.blog_id AS blog_id FROM blogs LEFT JOIN blog_stats ON blog_stats.blog_id = blogs.blog_id WHERE blogs.blog_id IN (".implode(",", $blogs).") ";
	} else {
		$query = "SELECT SQL_CALC_FOUND_ROWS blogs.*, blog_stats.*, blogs.blog_id AS blog_id FROM blogs LEFT JOIN blog_stats ON blog_stats.blog_id = blogs.blog_id WHERE 1 ";
	}
		
	if ($filters['show_new_blogs']) {
		$where_clause = "";		
	} else {
		$where_clause = " AND !ISNULL(blog_stats.rank)";
	}
	
	if (!$filters['show_inactive']) {
		$where_clause .= " AND active >= 1";
	}
	
	if ($filters['require_portraits']) {
		$where_clause .= " AND image NOT LIKE '".$config['default_image']."'";
	}
	
	$limit_by = "";

	if (!$filters['limit']) {$filters['limit'] = $GLOBALS["config"]['blogs_per_page'];}
	if ($filters['limit']) {$limit_by .= " LIMIT ".$filters['limit'];}
	if ($filters['min_fog']) {$where_clause .= " AND readability_fog >= ".$filters['min_fog'];}
	if ($filters['max_fog']) {$where_clause .= " AND readability_fog < ".$filters['max_fog'];}	
	if ($filters['skip']) {
		if ($filters['skip'] < 0) {$filters['skip'] = 0;}
		$limit_by = " LIMIT ".$filters['skip'].",".$filters['limit'];
	}
	
	$order_by = " ORDER BY blog_stats.rank ASC";
	
	if ($filters['rank']) {
		$order_by = " ORDER BY blog_stats.rank ASC";
	}	
	if ($filters['latest']) {
		$order_by = " ORDER BY added_on DESC";
	}
	if ($filters['num_posts']) {
		$order_by = " ORDER BY num_posts DESC";
	}
	if ($filters['wordiest']) {
		$order_by = " ORDER BY avg_words_per_post DESC";
	}
	if ($filters['blogloving']) {
		$order_by = " ORDER BY outgoing_bloglove DESC";
	}
	if ($filters['alphabetical']) {
		$order_by = " ORDER BY title ASC";
	}
	
	$query = $query.$where_clause.$order_by.$limit_by;

	$results = mysql_query($query);
	
	$rows = mysql_num_rows($results);
	if ($limit_by) {
		$count_query = "SELECT FOUND_ROWS() AS rows";
		$count_results = mysql_query($count_query);
		while ($row = mysql_fetch_assoc($count_results)) {
			$rows = $row['rows'];
		}
	}
	
	$return = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		$row['rows_returned'] = $rows;
		if ($row['image']) {
			$row['image']	= $config['base_url'].$row['image'];
		}
		array_push($return, $row);
	}

	return $return;
}

?>