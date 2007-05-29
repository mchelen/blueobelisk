<?

# get terms from some content using the Yahoo Term Extraction API
function extract_terms($text) {
	# use the Yahoo! Term Extraction API for the moment
	
	$url = "http://api.search.yahoo.com/ContentAnalysisService/V1/termExtraction";
	$appid = "xnn";
	$context = strip_tags($text);
	$output = "php";
	
	# use CURL so that we can make a POST request instead of a GET
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $url);
	curl_setopt($ch, CURLOPT_POST, true);
	curl_setopt($ch, CURLOPT_HEADER, false);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($ch, CURLOPT_POSTFIELDS, sprintf("appid=%s&context=%s&output=%s", $appid, $context, $output));	
		
	$results = curl_exec($ch);
	
	curl_close($ch);
	
	$array = unserialize($results);

	#print_r($array);
	
	return $array["ResultSet"]["Result"];
}

function clean_terms($terms) {
	# if we've got a cached version of the results from this function use it...
	$id = md5(implode(',', $terms));
	
	$cached = get_cache($id);
	
	if ($cached) {return unserialize($cached);}
		
	# go through the terms in sequence to see what the counts with non-duplicated posts are...
	$posts_seen = array();
	foreach ($terms as $term => $freq) {
		$term = mysql_escape_string($term);
		
		$query = "SELECT DISTINCT post_id FROM terms WHERE term='$term'";
		$results = mysql_query($query);
		
		while ($row = mysql_fetch_assoc($results)) {
			$post_id = $row['post_id'];
			
			if ($posts_seen[$post_id]) {
				$terms[$term]--;
				if ($terms[$term] <= 0) {unset($terms[$term]);}
			}
			
			$posts_seen[$post_id] = true;
		}
	}
	
	arsort($terms);
	
	# cache results
	$cached = serialize($terms);
	cache($id, $cached);
	
	return $terms;
}


function get_terms($limit = 50, $category = false) {
	$query = "SELECT terms.term, bursts.score AS count FROM terms, bursts WHERE bursts.term = terms.term GROUP BY term ORDER BY count DESC LIMIT $limit";
	if ($category) {
		$blogs = get_blogs_with_tag($category);
		$blogs = "'".implode("','", $blogs)."'";
		$query = "SELECT terms.term, bursts.score AS count FROM terms, posts, bursts WHERE bursts.term = terms.term AND posts.post_id = terms.post_id AND posts.blog_id IN ($blogs) GROUP BY term ORDER BY count DESC LIMIT $limit";		
	}
	$results = mysql_query($query);
	$terms = array();
	while ($row = mysql_fetch_array($results)) {
		$terms[$row['term']] = $row['count'];
	}
	return $terms;
}

function get_geotags_for_post($post_id) {
	$query = "SELECT DISTINCT * FROM terms WHERE post_id='$post_id' AND geoname_id > 0";
	$results = mysql_query($query);
	
	$terms = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		array_push($terms, $row['lat']);
		array_push($terms, $row['lng']);
		array_push($terms, $row['term']);
	}
	
	return $terms;
}

function get_terms_for_post($post_id, $limit = 20, $min = 1) {
	$terms = array();
	
	$query = "SELECT DISTINCT t1.post_id, t1.term, COUNT(t2.post_id) AS count FROM terms AS t1, terms AS t2 WHERE t1.post_id='$post_id' AND t2.term = t1.term GROUP BY t1.term LIMIT $limit";
	$results = mysql_query($query);
	
	while ($row = mysql_fetch_assoc($results)) {
		$term = $row['term'];
		$count = $row['count'];
		
		if ($count >= $min) {
			array_push($terms, $term);
		}
	}

	return $terms;
}

function get_terms_for_blog($blog_id, $limit = 20) {
	$terms = array();
	
	$query = "SELECT DISTINCT term, COUNT(*) AS count FROM terms, posts WHERE posts.post_id = terms.post_id AND posts.blog_id = '$blog_id' GROUP BY term ORDER BY posts.pubdate DESC LIMIT $limit";
	$results = mysql_query($query);
	
	while ($row = mysql_fetch_assoc($results)) {
		$term = $row['term'];
		$count = $row['count'];
		
		$terms[$term] = $count;
		
	}

	return $terms;
}

function get_tags_for_paper($paper_id, $include_posts = true) {
	$tags = array();
	$paper_id = mysql_escape_string($paper_id);
	
	$query = "SELECT DISTINCT tag FROM tags WHERE paper_id=$paper_id";
	
	if ($include_posts) {
		
		$posts = get_posts_for_paper($paper_id);
		$post_ids = array();
		if ($posts) {
			foreach ($posts as $post) {array_push($post_ids, $post['post_id']);}
			if ($post_ids) {
				$query .= " OR post_id IN (".implode(',', $post_ids).")";
			}
		}
	}
	
	$results = mysql_query($query);
	while ($row = mysql_fetch_assoc($results)) {
		array_push($tags, $row['tag']);
	}
	
	return $tags;
}

function get_similar_tags($tag, $limit = false, $threshold = 1) {

	$query = "SELECT t1.tag AS tag, COUNT(DISTINCT posts.blog_id) AS count FROM tags AS t1, tags AS t2, posts WHERE t1.post_id = t2.post_id AND t1.tag != t2.tag AND t2.tag='$tag' AND posts.post_id = t1.post_id GROUP BY t1.tag HAVING count >= $threshold ORDER BY count DESC";
	
	if ($limit) {$query .= " LIMIT $limit";}
	
        # print "QUERY: $query\n";

	$results = mysql_query($query);
	
	$tags = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		$tags[$row["tag"]] = $row["count"];
	}
	
	return $tags;
}

function get_blog_categories($blog_id) {
	if (!$blog_id) {return array();}
	$query = "SELECT DISTINCT tag FROM tags WHERE blog_id=$blog_id AND tagged_by=\"admin\"";
	$results = mysql_query($query);
	$tags = array();
	while ($row = mysql_fetch_assoc($results)) {
		array_push($tags, $row['tag']);
	}
	return $tags;
}


# counts by number of unique blogs using tag
# also, returns whole row rather than just tag => count
function get_popular_tags($blogs = false, $limit = 10) {
	if ($blogs) {
		$query = "SELECT tag, COUNT(DISTINCT posts.blog_id) AS count FROM tags, posts WHERE posts.post_id = tags.post_id AND posts.blog_id IN (".implode(",", $blogs).") GROUP BY tag ORDER BY count DESC LIMIT $limit";		
	} else {
		$query = "SELECT tag, COUNT(DISTINCT posts.blog_id) AS count FROM tags, posts WHERE posts.post_id = tags.post_id GROUP BY tag ORDER BY count DESC LIMIT $limit";
	}
	
	$results = mysql_query($query);
	
	$tags = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		array_push($tags, $row);
	}
	
	return $tags;
}

# counts by raw tag number
function get_tags_for_blogs($blogs = false, $limit = false) {
	
	if ($blogs) {
		$query = "SELECT tag, COUNT(*) AS count FROM tags, posts WHERE posts.post_id = tags.post_id AND posts.blog_id IN (".implode(",", $blogs).") GROUP BY tag";
	} else {
		$query = "SELECT tag, COUNT(*) AS count FROM tags WHERE !ISNULL(post_id) GROUP BY tag";		
	}

	if ($limit) {$query .= " ORDER BY count DESC LIMIT $limit";}

	# print "QUERY: $query";

	$results = mysql_query($query);
	
	$tags = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		$tags[$row["tag"]] = $row["count"];
	}
	
	return $tags;
}

function get_papers_with_tag($tag, $include_posts = true) {
	$query = "SELECT DISTINCT paper_id FROM tags WHERE tag = '$tag' AND !ISNULL(paper_id)";
	$results = mysql_query($query);

	$papers = array();

	while ($row = mysql_fetch_assoc($results)) {
		array_push($papers, $row['paper_id']);
	}

	# there might also be tags attached to posts which link to this paper...
	if ($include_posts) {
		$posts = get_posts_with_tag($tag);
		$posts = "'".implode("','", $posts)."'";
		$query = "SELECT DISTINCT paper_id FROM links WHERE post_id IN ($posts) AND !ISNULL(paper_id)";
		$results = mysql_query($query);
		
		while ($row = mysql_fetch_assoc($results)) {
			array_push($papers, $row['paper_id']);
		}
	}

	return $papers;
}

function get_posts_with_term($term) {
	$query = "SELECT DISTINCT post_id FROM terms WHERE term='$term'";
	$results = mysql_query($query);
	
	$posts = array();
	
	while ($row = mysql_fetch_array($results)) {
		array_push($posts, $row['post_id']);
	}
	
	return $posts;
}

function get_stories_with_tag($tag, $include_posts = true) {
	$query = "SELECT DISTINCT story_id FROM tags WHERE tag = '$tag' AND !ISNULL(story_id)";
	$results = mysql_query($query);

	$stories = array();

	while ($row = mysql_fetch_assoc($results)) {
		array_push($stories, $row['story_id']);
	}

	# there might also be tags attached to posts which link to this paper...
	if ($include_posts) {
		$posts = get_posts_with_tag($tag);
		$posts = "'".implode("','", $posts)."'";
		$query = "SELECT DISTINCT story_id FROM links WHERE post_id IN ($posts) AND !ISNULL(story_id)";
		$results = mysql_query($query);
		
		while ($row = mysql_fetch_assoc($results)) {
			array_push($stories, $row['story_id']);
		}
	}

	return $stories;	
}

function validate_terms($terms) {
	# given an array of terms, return the ones that are in Postgenomic
	$return = array();
	
	$query = "SELECT DISTINCT term, COUNT(*) AS count FROM terms WHERE term IN ('".implode("','", $terms)."') GROUP BY term";
	$results = mysql_query($query);

	while ($row = mysql_fetch_assoc($results)) {
		$return[$row['term']] = $row['count'];
	}
	
	return $return;
}

function validate_tags($tags) {
	# given an array of tags, return the ones that are in Postgenomic
	$return = array();
	
	$query = "SELECT DISTINCT tag, COUNT(*) AS count FROM tags WHERE tag IN ('".implode("','", $tags)."') GROUP BY tag";
	$results = mysql_query($query);

	while ($row = mysql_fetch_assoc($results)) {
		$return[$row['tag']] = $row['count'];
	}
	
	return $return;
}

function get_posts_with_tag($tag) {
	$query = "SELECT DISTINCT post_id FROM tags WHERE tag = '$tag' AND !ISNULL(post_id)";
	$results = mysql_query($query);

	$posts = array();

	while ($row = mysql_fetch_assoc($results)) {
		array_push($posts, $row['post_id']);
	}

	return $posts;
}

function get_blogs_using_tag($tag, $limit) {
	$query = "SELECT DISTINCT posts.blog_id, blogs.title AS title FROM posts, tags, blogs WHERE blogs.blog_id = posts.blog_id AND posts.post_id = tags.post_id AND tag = '$tag' LIMIT $limit";
	$results = mysql_query($query);

	$blogs = array();

	while ($row = mysql_fetch_assoc($results)) {
		$blogs[$row['blog_id']] = $row['title'];
	}

	return $blogs;	
}

function get_tags_for_journal($journal, $limit = false) {
	$query = "SELECT DISTINCT tag, COUNT(*) AS count FROM tags, links, papers WHERE papers.journal='$journal' AND papers.paper_id = links.paper_id AND links.post_id = tags.post_id GROUP BY tag";
	if ($limit) {$query .= " ORDER BY count DESC LIMIT $limit";}
	
	$results = mysql_query($query);
	
	$tags = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		$tags[$row['tag']] = $row['count'];
	}
	
	return $tags;
}

function get_blogs_with_no_tags() {
	$query = "SELECT DISTINCT blog_id FROM blogs WHERE blog_id IN (SELECT DISTINCT blog_id FROM tags)";
	$results = mysql_query($query);
	$tagged_blogs = array();
	while ($row = mysql_fetch_assoc($results)) {
		array_push($tagged_blogs, $row['blog_id']);
	}
	
	$query = "SELECT DISTINCT blog_id FROM blogs";
	$results = mysql_query($query);
	$all_blogs = array();
	while ($row = mysql_fetch_assoc($results)) {
		array_push($all_blogs, $row['blog_id']);
	}	

	$diff = array_diff($all_blogs, $tagged_blogs);
	
	return $diff;
}

function get_blogs_with_tag($tag) {
	if (!$tag) {return array();}
	$query = "SELECT DISTINCT blog_id FROM tags WHERE tag = '$tag' AND !ISNULL(blog_id)";
	$results = mysql_query($query);

	$blogs = array();

	while ($row = mysql_fetch_assoc($results)) {
		array_push($blogs, $row['blog_id']);
	}

	return $blogs;
}
?>
