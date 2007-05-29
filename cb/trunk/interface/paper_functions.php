<?

function get_paper_id_from_doi($doi) {
	$query = "SELECT paper_id FROM papers WHERE doi_id='$doi'";
	$results = mysql_query($query);
	
	$paper_id = 0;
	
	while ($row = mysql_fetch_assoc($results)) {
		$paper_id = $row['paper_id'];
	}
	
	return $paper_id;
}

function get_latest_papers($category = false) {
	$filters = array();
	
	$filters["limit"] = 4;
	if ($category) {$filters["category"] = $category;}
		
	return get_papers("added_on", $filters);
}

function get_top_papers($category = false, $timeframe = false, $filters = array()) {
	
	$filters["limit"] = 8;
	if ($category) {$filters["category"] = $category;}
	if ($timeframe) {$filters["added_after"] = $timeframe;}
		
	return get_papers("cited", $filters);
}

function get_posts_for_paper($paper_id, $ids_only = false) {
	$paper_id = mysql_escape_string($paper_id);
	
	$query = "SELECT DISTINCT post_id FROM links WHERE paper_id='$paper_id'";
	$results = mysql_query($query);
		
	$ids = array();

	while ($row = mysql_fetch_assoc($results)) {	
		array_push($ids, $row['post_id']);
	}
	
	if ($ids_only) {return $ids;}
	
	if (sizeof($ids)) {
		$posts = get_posts("added_on", array("post_id" => $ids, "limit" => 100));
	}
	
	return $posts;
}

function get_comments_for_paper($paper_id) {
	$paper_id = mysql_escape_string($paper_id);
	
	$query = "SELECT * FROM comments WHERE paper_id=$paper_id";
	$results = mysql_query($query);
	
	$comments = array();
	
	while ($row = mysql_fetch_assoc($results)) {	
		array_push($comments, $row);
	}
	
	return $comments;
}

function get_comments_from_source($source) {
	$query = "SELECT DISTINCT paper_id FROM comments WHERE !ISNULL(paper_id) AND source='$source'";
	$results = mysql_query($query);
	
	$comments = array();
	while ($row = mysql_fetch_assoc($results)) {	
		array_push($comments, $row['paper_id']);
	}
	return $comments;	
}

# return an array of Paper objects. Filters can be to limit the number of papers returned,
# to restrict to papers from a particular field or journal, pubdate range etc.
function get_papers($sort_by = "added_on", $filters = array()) {
	$query = "SELECT SQL_CALC_FOUND_ROWS * FROM papers_summary WHERE 1";
	$where_clause = "";
	$order_by = " ORDER BY added_on";
	$group_by = "";
	$limit_by = "";

	if ($sort_by == "added_on") {$order_by = " ORDER BY added_on DESC";}
	if ($sort_by == "pubdate") {$order_by = " ORDER BY pubdate DESC";}
	# bit of a hack here - historically "pubdate" and "published_on" are both used even though they're the same thing
	if ($sort_by == "published_on") {$order_by = " ORDER BY pubdate DESC";}
	if ($sort_by == "cited") {$order_by = " ORDER BY cited_by DESC";}
	if ($sort_by == "journal") {$order_by = " ORDER BY journal";}
	
	if ($filters['min_links']) {
		$having_clause .= " HAVING cited_by >= ".$filters['min_links'];
	}
	
	if ($filters['reviews']) {
		$where_clause .= " AND reviewed >= 1";
	}

	if ($filters['limit']) {
		$limit_by = " LIMIT ".$filters['limit'];
	}
	
	if ($filters['comment_source']) {
		# get list of papers that have comments from this source
		$comments = get_comments_from_source($filters['comment_source']);
		if (sizeof($comments)) {
			$where_clause .= " AND paper_id IN ('".implode("','", $comments)."')";
		} else {
			return array();
		}
	}

	if ($filters['skip']) {
		if ($filters['skip'] < 0) {$filters['skip'] = 0;}
		$limit_by = " LIMIT ".$filters['skip'].",".$GLOBALS["config"]['papers_per_page'];
	}
		
	if ($filters['category']) {
		$blogs = get_blogs_with_tag($filters['category']);
		#$blogs = "'".implode("','", $blogs)."'";
		#$where_clause .= " AND posts.blog_id IN ($blogs)";
		$blog_counter = 0;
		if ($blogs) {$where_clause .= " AND (";}
		foreach ($blogs as $blog) {
			if ($blog_counter >= 1) {$where_clause .= " OR ";}
			#$where_clause .= "FIND_IN_SET($blog, blog_ids)";
			# try a textual IN clause to see if it's any faster:
			$where_clause .= "$blog IN (blog_ids)";
			$blog_counter++;
		}
		if ($blogs) {$where_clause .= ")";}
	}
	if ($filters['tag']) {
		$papers = get_papers_with_tag($filters['tag']);
		$papers = "'".implode("','", $papers)."'";
		$where_clause .= " AND paper_id IN ($papers)";
	}
	if (strtolower($filters['type']) == "books") {
		$where_clause .= " AND !ISNULL(isbn_id)";
	}
	
	if (strtolower($filters['type']) == "papers") {
		$where_clause .= " AND ISNULL(isbn_id)";
	}
	if ($filters['journal']) {
		$journal = $filters['journal'];
		$where_clause .= " AND journal='$journal'";
	}
	if ($filters['published_before']) {
		$date = $filters['published_before'];
		$where_clause .= " AND pubdate < '$date'";
	}
	if ($filters['published_after']) {
		$date = $filters['published_after'];
		$where_clause .= " AND pubdate >= '$date'";
	}
	if ($filters['added_before']) {
		$date = $filters['added_before'];
		$where_clause .= " AND added_on < '$date'";
	}
	if ($filters['added_after']) {
		$date = $filters['added_after'];
		$where_clause .= " AND added_on >= '$date'";
	}
	if (isset($filters['paper_id'])) {
		if (!is_array($filters['paper_id'])) {
			$where_clause .= " AND paper_id = ".$filters['paper_id'];
		} else if (is_array($filters['paper_id'])) {
			$where_clause .= " AND paper_id IN (".implode(",", $filters['paper_id']).")";
		}
	}

	$papers = array();

	$query = $query.$where_clause.$group_by.$having_clause.$order_by.$limit_by;	
	
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
		$row['rows_returned'] = $rows;
		$paper = $row;
		array_push($papers, $paper);
	}
	
	return $papers;
}
?>