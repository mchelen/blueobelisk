<?
	include("functions.php");
	header("Content-type: application/xml");
	#header("Content-type: application/atom+xml");
	$type = mysql_escape_string($_GET['type']);
	$category = mysql_escape_string($_GET['category']);
	$tag = mysql_escape_string($_GET['tag']);
	$journal = mysql_escape_string($_GET['journal']);
	$min_links = mysql_escape_string($_GET['min_links']);
	$safe_fulltext = mysql_escape_string($_GET['fulltext']);
	
	# args for OpenSearch results
	$search = mysql_escape_string($_GET['search']);
	$search_skip = mysql_escape_string($_GET['search_skip']);
	$search_skip_os = mysql_escape_string($_GET['search_skip_os']);
	if ($search_skip_os) {$seach_skip = $search_skip_os - 1;}
	$search_limit = mysql_escape_string($_GET['search_limit']);
	if (!$search_limit) {$search_limit = $config['search_results_per_page'];}	
	$search_page_os = mysql_escape_string($_GET['search_page_os']);
	if ($search_page_os) {$search_skip = ($search_page_os - 1) * $search_limit;}
	$search_type = mysql_escape_string($_GET['search_type']);

	
	# by default cache feed requests
	$PAGE_CACHE = $config['cache_atom_requests'];

	# check to see if we have a cached version
	$PAGE_URL = $_SERVER['REQUEST_URI'];
	if ($PAGE_CACHE) {
		$cached = get_cache($PAGE_URL);		
		if ($cached) {print $cached; exit;}
		ob_start();
	}	
	
	if ($type == "search") {
		# return OpenSearch results.
		if ($search) {
			$safe_search = reduce_to_ascii($search, true);
			if (!$search_skip) {$search_skip = 0;}
			if (!$search_limit) {$search_limit = false;} # $search_limit here means "how many items per page"?
			if (!$search_type) {$search_type = "any";}
			
			$results = do_search($safe_search, $search_skip, $search_limit, $search_type);
			$return = parse_search_results($results);
			if (isset($return["total_results"])) {
				$total_results = $return["total_results"];
				$num_results = $return["num_results"];
				$posts = $return["posts"];
				$blogs = $return["blogs"];
				$papers = $return["papers"];
				$search_per_page = $return["limit"];
				
				$search_description = $config['base_url']."opensearch_xml.php";
				
				$buffer .= atom_header("Search results for $safe_search", $type);
				
				$buffer .= "
<opensearch:totalResults>$num_results</opensearch:totalResults>
<opensearch:startIndex>".($search_skip + 1)."</opensearch:startIndex>
<opensearch:itemsPerPage>$search_per_page</opensearch:itemsPerPage>
<opensearch:link rel=\"search\" href=\"$search_description\" type=\"application/opensearchdescription+xml\"/>
<opensearch:Query rel=\"request\" searchTerms=\"$safe_search\" />
				";
				
				# now print the actual results.
				if (sizeof($blogs)) {
					foreach ($blogs as $blog) {
						$buffer.= blog_atom_entry($blog);
					}					
				}
				if (sizeof($papers)) {
					foreach ($papers as $paper) {
						$buffer.= paper_atom_entry($paper);
					}					
				}
				if (sizeof($posts)) {
					foreach ($posts as $post) {
						$buffer.= post_atom_entry($post);
					}					
				}
				
				$buffer .= atom_footer();
				
				print $buffer;
			} else {
				# search didn't work for some reason. Return internal server error.
				return_http_error(500);
			}
		} else {
			# return Bad Request
			return_http_error(400);
		}	
	}

        if ($type == "latest_inchis") {
                $filters = array();

                $title = "Chemical blogspace - latest molecules";

                # get links
                $filters['limit'] = 10;

                if (is_numeric($min_links)) {
                        $filters['min_links'] = $min_links;
                        $title .= " (min $min_links blogs)";
                }

                $links = get_inchis_links("added_on", $filters);
                # return posts
                $buffer .= atom_header($title, $type);
                if ($links) {
                        foreach ($links as $link) {
                                $buffer.= inchi_atom_entry($link);
                        }
                }
                $buffer .= atom_footer();
                print $buffer;
        }

	
	if ($type == "latest_blogs") {
		$filters = array();

		$blog_ids = array();
		
		$title = "Chemical blogspace - new blogs";		
		if ($category) {
			$title = "Chemical blogspace - new ".strtolower($category)." blogs";
			$blog_ids = get_blogs_with_tag($category);
		}
				
		# get links
		$filters['limit'] = 10;
		$filters['latest'] = true;
				
		$blogs = get_blogs($blog_ids, $filters);
		# return posts
		$buffer .= atom_header($title, $type);
		if ($blogs) {
			foreach ($blogs as $blog) {
				$buffer.= blog_atom_entry($blog);
			}
		}
		$buffer .= atom_footer();
		print $buffer;		
	}


	
	if ($type == "latest_links") {
		$filters = array();

		$title = "Chemical blogspace - latest links";		
		if ($category) {
			$title = "Chemical blogspace - latest ".strtolower($category)." links";
			$filters['category'] = $category;
		}
				
		# get links
		$filters['limit'] = 50;
		
		if (is_numeric($min_links)) {
			$filters['min_links'] = $min_links;
			$title .= " (min $min_links blogs)";
		}
		
		$links = get_links("added_on", $filters);
		# return posts
		$buffer .= atom_header($title, $type);
		if ($links) {
			foreach ($links as $link) {
				$buffer.= link_atom_entry($link);
			}
		}
		$buffer .= atom_footer();
		print $buffer;		
	}
		
	if ($type == "latest_papers") {
		$filters = array();

		$title = "Chemical blogspace - latest papers";		
		if ($category) {
			$title = "Chemical blogspace - latest ".strtolower($category)." papers";
			$filters['category'] = $category;
		}
		
		if ($journal) {
			$filters['journal'] = $journal;
			$title .= " (from $journal)";
		}
		
		# get papers
		$filters['limit'] = 50;
		
		$papers = get_papers("added_on", $filters);
		# return posts
		$buffer .= atom_header($title, $type);
		if ($papers) {
			foreach ($papers as $paper) {
				$buffer.= paper_atom_entry($paper);
			}
		}
		$buffer .= atom_footer();
		print $buffer;		
	}
	
	if ($type == "popular_papers") {
		$filters = array();

		$title = "Chemical blogspace - recent hot papers";		
		if ($category) {
			$title = "Chemical blogspace - recent hot ".strtolower($category)." papers";
			$filters['category'] = $category;
		}
		
		if ($journal) {
			$filters['journal'] = $journal;
			$title .= " (from $journal)";
		}
		
		# get papers
		$filters['limit'] = 10;
		$filters['min_links'] = 1;
		$last_month = date("Y-m-d", mktime(0,0,0, date(m) - 1, date(d),date(Y)));
		$filters['published_after'] = $last_month;
		
		$papers = get_papers("cited", $filters);
		# return posts
		$buffer .= atom_header($title, $type);
		if ($papers) {
			foreach ($papers as $paper) {
				$buffer.= paper_atom_entry($paper);
			}
		}
		$buffer .= atom_footer();
		print $buffer;		
	}
	
	if ($type == "popular_posts") {
		$filters = array();

		$title = "Chemical blogspace - recently popular posts";		
		if ($category) {
			$title = "Chemical blogspace - recently popular ".strtolower($category)." posts";
			$filters['category'] = $category;
		}
		
		# get posts
		$filters['limit'] = 10;
		$filters['min_links'] = 1;
		$last_month = date("Y-m-d", mktime(0,0,0, date(m) - 1, date(d),date(Y)));
		$filters['published_after'] = $last_month;
		
		$posts = get_posts("cited", $filters);
		# return posts
		$buffer .= atom_header($title, $type);
		if ($posts) {
			foreach ($posts as $post) {
				$buffer.= post_atom_entry($post);
			}
		}
		$buffer .= atom_footer();
		print $buffer;		
	}
	
	if ($type == "latest_posts") {
		$filters = array();

		$title = "Chemical blogspace - latest posts";		
		if ($category) {
			$title = "Chemical blogspace - latest ".strtolower($category)." posts";
			$filters['category'] = $category;
		}
		
		# get posts
		$filters['limit'] = 50;
		
		if ($tag == "review") {
			# we're looking for posts with reviews...
			$filters['review'] = true;
			$title = "Latest ".strtolower($category)." reviews";
		} else if ($tag == "conference") {
				# we're looking for posts with reviews...
				$filters['conference'] = true;
				$title = "Latest ".strtolower($category)." conference reports";
		} else if ($tag == "original_research") {
				# we're looking for posts with reviews...
				$filters['original_research'] = true;
				$title = "Latest ".strtolower($category)." original research";
		}
		
		$posts = get_posts("published_on", $filters);
		# return posts
		$buffer .= atom_header($title, $type);
		if ($posts) {
			foreach ($posts as $post) {
				$pfilters = array();
				if ($safe_fulltext) {$pfilters['fulltext'] = true;}
				$buffer.= post_atom_entry($post, $pfilters);
			}
		}
		$buffer .= atom_footer();
		print $buffer;		
	}

	# if caching was switched on then save the page we just generated.
	if ($PAGE_CACHE) {
		$page = ob_get_contents();
		ob_end_flush(); flush();

		# put cached page in database
		cache($PAGE_URL, $page);
	}
	
?>
