<?

function get_links($sort_by = "added_on", $filters = array()) {
        # use the links_summary table to handle all our grouping etc.
        $query = "SELECT SQL_CALC_FOUND_ROWS * FROM links_summary";

        $min_links = 1;
        if ($filters['min_links']) {$min_links = $filters['min_links'];}

        $where_clause = " WHERE linked_by >= $min_links";

        $order_by = " ORDER BY last_linked_on DESC";
        $group_by = "";
        $limit_by = "";

        if ($sort_by == "added_on") {$order_by = " ORDER BY last_linked_on DESC";}
        if ($sort_by == "cited") {$order_by = " ORDER BY linked_by DESC";}

        if ($filters['limit']) {$limit_by = " LIMIT ".$filters['limit'];}
        if ($filters['skip']) {
                if ($filters['skip'] < 0) {$filters['skip'] = 0;}
                $limit_by = " LIMIT ".$filters['skip'].",".$GLOBALS["config"]['links_per_page'];
        }

        if ($filters['category']) {
                $where_clause .= " AND categories LIKE '%".$filters['category']."%'";
        }

        if ($filters['published_after']) {
                $where_clause .= " AND last_linked_on > '".$filters['published_after']."'";
        }

        $posts = array();

        $having = "";

        $query = $query.$where_clause.$group_by.$having.$order_by.$limit_by;
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
                if (!$row['title']) {$row['title'] = "unknown";}
                $post = $row;
                $post['rows_returned'] = $rows;
                array_push($posts, $post);
        }

        return $posts;
}

function get_inchis_links($sort_by = "added_on", $filters = array()) {
	# use the links_summary table to handle all our grouping etc.
	$query = "SELECT SQL_CALC_FOUND_ROWS * FROM inchis, posts, compounds WHERE inchis.post_id = posts.post_id AND compounds.inchi = inchis.inchi";
	
	$order_by = " ORDER BY posts.added_on DESC";
	$group_by = "";
	$limit_by = "";

	if ($sort_by == "posts.added_on") {$order_by = " ORDER BY added_on DESC";}
	# if ($sort_by == "cited") {$order_by = " ORDER BY linked_by DESC";}

	if ($filters['limit']) {$limit_by = " LIMIT ".$filters['limit'];}

	$posts = array();

	$having = "";

	$query = $query.$where_clause.$group_by.$having.$order_by.$limit_by;	
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
		if (!$row['title']) {$row['title'] = "unknown";}
		$post = $row;
		$post['rows_returned'] = $rows;
		$post['cid'] = "1";

                if ($post['inchi']) {
	                $compoundQuery = "SELECT SQL_CALC_FOUND_ROWS * FROM compounds WHERE inchi = '".$post['inchi']."'";
  			$compoundResults = mysql_query($compoundQuery);
                	$compoundDetails = mysql_fetch_assoc($compoundResults);
	                $post['cid'] = $compoundDetails['cid']; # $compoundDetails['cid'];
			$post['cbid'] = $compoundDetails['cbid'];
                        $post['name'] = $compoundDetails['name'];
		}
        
		array_push($posts, $post);
	}
	
	return $posts;
}





?>
