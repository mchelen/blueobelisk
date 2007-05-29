<?

function get_latest_inchis($category = false, $limit = false) {
	$filters = array();
	
	if ($limit) {
              $filters["limit"] = $limit;
        } else {
              $filters["limit"] = 4;
        }
	if ($category) {$filters["category"] = $category;}
		
	return get_inchis("added_on", $filters);
}

function get_top_inchis($category = false, $timeframe = false, $filters = array()) {
	
	$filters["limit"] = 8;
	if ($category) {$filters["category"] = $category;}
	if ($timeframe) {$filters["added_after"] = $timeframe;}
		
	return get_inchis("cited", $filters);
}

function get_posts_for_inchi($paper_id, $ids_only = false) {
	$paper_id = mysql_escape_string($paper_id);
	
        # print "DEBUG: getting posts for InChI: $paper_id<br />\n";

	$query = "SELECT DISTINCT post_id FROM inchis WHERE inchi='$paper_id'";
	$results = mysql_query($query);
		
	$ids = array();

	while ($row = mysql_fetch_assoc($results)) {	
		array_push($ids, $row['post_id']);
	}
	
	if ($ids_only) {return $ids;}
	
	if (sizeof($ids)) {
                # print "DEBUG: getting posts: $ids<br />\n";
		$posts = get_posts("added_on", array("post_id" => $ids, "limit" => 100));
                # print "DEBUG: ".$posts[0] . "\n";
	}
	
	return $posts;
}

function get_posts_for_cbid($paper_id, $ids_only = false) {
        $paper_id = mysql_escape_string($paper_id);

        # print "DEBUG: getting posts for InChI: $paper_id<br />\n";

        $query = "SELECT DISTINCT post_id FROM inchis, compounds WHERE inchis.inchi=compounds.inchi AND cbid='$paper_id'";
        $results = mysql_query($query);

        $ids = array();

        while ($row = mysql_fetch_assoc($results)) {
                array_push($ids, $row['post_id']);
        }

        if ($ids_only) {return $ids;}

        if (sizeof($ids)) {
                # print "DEBUG: getting posts: $ids<br />\n";
                $posts = get_posts("added_on", array("post_id" => $ids, "limit" => 100));
                # print "DEBUG: ".$posts[0] . "\n";
        }

        return $posts;
}


# return an array of Paper objects. Filters can be to limit the number of papers returned,
# to restrict to papers from a particular field or journal, pubdate range etc.
function get_inchis($sort_by = "added_on", $filters = array()) {

        # print "DEBUG: called get_inchis.<br />\n";

	$query = "SELECT DISTINCT SQL_CALC_FOUND_ROWS * FROM inchis, posts, compounds ";
	$where_clause = "WHERE inchis.post_id = posts.post_id AND compounds.inchi = inchis.inchi";
	$order_by = " ORDER BY posts.added_on DESC";
	$group_by = "";
	$limit_by = "";

	if ($sort_by == "added_on") {$order_by = " ORDER BY inchis.added_on DESC";}
	
	if ($filters['min_links']) {
		$having_clause .= " HAVING cited_by >= ".$filters['min_links'];
	}
	
	if ($filters['limit']) {
		$limit_by = " LIMIT ".$filters['limit'];
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
        if ($filters['inchi']) {
                $inchi = $filters['inchi'];
                $where_clause .= " AND inchi = \"$inchi\"";
        }
        if ($filters['id']) {
                $id = $filters['id'];
                $where_clause .= " AND compounds.cbid = \"$id\"";
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

        # print "DEBUG: query = $query<br />\n";	
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
                # print "DEBUG Rows found: " . $row . "<br />";
		$row['rows_returned'] = $rows;
		$paper = $row;
                # print "DEBUG ".$paper['title']."\n";
                # fetch some additional properties
                $query = "SELECT SQL_CALC_FOUND_ROWS * FROM compounds WHERE inchi = '".$paper['inchi']."'";
                # print "DEBUG query: " . $query . "<br />";
                $compoundDetails = mysql_query($query);
                while ($detail = mysql_fetch_assoc($compoundDetails)) {
    			# print "DEBUGX:". $detail['cbid'] ."\n";
                 	$paper['smiles'] = $detail['smiles'];
			$paper['name'] = $detail['name'];
                        $paper['cid'] = $detail['cid'];
                        $paper['cbid'] = $detail['cbid'];
                }
                # print "DEBUG: ".$paper['id']."\n";

		array_push($papers, $paper);
	}
	
	return $papers;
}
?>
