<? 
include("functions.php");
include("inchi_functions.php");

# if we don't increase the memory limit from 8Mb the JSON encode script dies a death.
ini_set("memory_limit","64M");

# general variables
$ids = strtolower(mysql_escape_string($_GET['id']));
$type = strtolower(mysql_escape_string($_GET['type']));
$app_id = strtolower(mysql_escape_string($_GET['app_id']));
$start = strtolower(mysql_escape_string($_GET['start']));
$limit = strtolower(mysql_escape_string($_GET['limit']));
$category = strtolower(mysql_escape_string($_GET['category']));

$format = strtolower(mysql_escape_string($_GET['format']));
$callback = strtolower(mysql_escape_string($_GET['callback']));

if ($format == "json") {
	include_once("JSON.php");
}

# paper specific stuff
$ids_only = strtolower(mysql_escape_string($_GET['ids_only']));
# backwards-compatibility:
if ($_GET['action'] == "get") {
	# Pedro's Greasemonkey script
	$ids_only = true;
	$format = "text"; # hack
	$type = "paper";
}

# post specific stuff
$timeframe  = strtolower(mysql_escape_string($_GET['timeframe']));
$order_by = strtolower(mysql_escape_string($_GET['order_by']));
$min_links = strtolower(mysql_escape_string($_GET['min_links']));
$base_url = urldecode(strtolower(mysql_escape_string($_GET['base_url'])));
$post_id = strtolower(mysql_escape_string($_GET['post_id']));
$citing_url = urldecode(strtolower(mysql_escape_string($_GET['citing_url'])));
$citing_paper = urldecode(strtolower(mysql_escape_string($_GET['citing_paper'])));
$citing_cbid = urldecode(strtolower(mysql_escape_string($_GET['citing_cbid'])));
$term = urldecode(strtolower(mysql_escape_string($_GET['term'])));

$blogs_return_limit = 100;
$max_blogs_return_limit = 1000;

# by default cache API requests
$PAGE_CACHE = $config['cache_api_requests'];;

# check to see if we have a cached version
$PAGE_URL = $_SERVER['REQUEST_URI'];
if ($PAGE_CACHE) {
	$cached = get_cache($PAGE_URL);		
	if ($cached) {print $cached; exit;}
	ob_start();
}

if (($type == "paper") || ($type == "papers")) {
	# list papers
	
	# the ids_only part of the API is a bit hacky because it needs to be backwards compatible
	# with the original "API" that allowed Pedro to do the Greasemonkey hack.
	if ($ids_only) {
		# list all papers in the database (just their IDs, though)
		$filters['limit'] = 1000000; # absurdly high limit so that everything is returned
		$papers = get_papers("added_on", $filters);
		if ($papers) {
			
			$doi_ids = array();
			$pubmed_ids = array();
			$arxiv_ids = array();
			$pii_ids = array();
			
			foreach ($papers as $paper) {
				if ($paper['doi_id']) {$doi_ids[$paper["doi_id"]] = $paper["paper_id"];}
				if ($paper['pubmed_id']) {$pubmed_ids[$paper["pubmed_id"]] = $paper["paper_id"];}
				if ($paper['arxiv_id']) {$arxiv_ids[$paper["arxiv_id"]] = $paper["paper_id"];}
				if ($paper['pii_id']) {$pii_ids[$paper["pii_id"]] = $paper["paper_id"];}			
			}
			
			if (!$format) {
				$format = "json";
				include_once("JSON.php");
			}
			
			if ($format == "text") {
				foreach ($doi_ids as $doi => $id) {
					print "$doi\n";
				}
			} elseif ($format == "json") {			
				$json = new Services_JSON();
				
				$ids = array("doi_id" => $doi_ids, "pubmed_id" => $pubmed_ids, "arxiv_id" => $arxiv_ids, "pii_id" => $pii_ids);
						
				if ($ids) {
					$buffer .= $json->encode($ids);
				}
								
				if ($callback) {
					printf("%s(%s)", $callback, $buffer);
				} else {
					print $buffer;			
				}				
			} else {
				# in Atom - not valid.
				return_http_error(405);
				exit;
			}
		}
	}
}

if (($type == "blog") || ($type == "blogs")) {
	# list blogs
	#	start: skip this many in results
	#	limit: override default limit
	#	category: category you want blogs from
	
	# any filters?
	$filters = array();
	
	# basics...
	$filters['limit'] = $blogs_return_limit;
	if (($limit) && ($limit < $max_blogs_return_limit)) {$filters['limit'] = $limit;}
	if (($start) && (is_numeric($start))) {
		$filters['skip'] = $start;
	}	
	
	# category
	$blog_ids = array();
	if ($category) {
		$blog_ids = get_blogs_with_tag($category);
	}
	
	# get blogs
	$blogs = get_blogs($blog_ids, $filters);
	

	# return blogs
	if ($format == "json") {
		$json = new Services_JSON();
		if ($blogs) {
			$buffer .= $json->encode($blogs);
		}	

		if ($callback) {
			printf("%s(%s)", $callback, $buffer);
		} else {
			print $buffer;			
		}
	} else {
		# default is to return results as an Atom feed
		$buffer .= atom_header();
		if ($blogs) {
			foreach ($blogs as $blog) {
				$buffer.= blog_atom_entry($blog);
			}
		}
		$buffer .= atom_footer();
		print $buffer;	
	}		

}

$terms_return_limit = 100;
$posts_return_limit = 100;
$max_posts_return_limit = 1000;

if (($type == "term") || ($type == "terms")) {
	# get top terms for category $safe_category
	#   filter by category
	#   limit number of terms returned
	#	start at term x
	# NOTE ALSO:
	# you can get the posts containing a specific term by calling type=posts&term=<term>
	
	$terms_limit = $terms_return_limit;
	if (($limit) && ($limit <= $terms_return_limit)) {
		$terms_limit = $limit;
	}
		
	if ($start) {
		$terms = get_terms(1000000, $safe_category);
		$terms = array_slice($terms, $start, $terms_limit);
	} else {
		$terms = get_terms($terms_limit, $safe_category);
	}
	
	# get posts for each term.
	$aterms = array();
	foreach ($terms as $term => $weight) {
		$aterm = array();
		$aterm["weight"] = $weight;
		$aterm["posts"] = get_posts_with_term($term);
		$aterms[$term] = $aterm;
	}
	
	if ($format == "json") {
		$json = new Services_JSON();
		if ($aterms) {
			$buffer .= $json->encode($aterms);
		}
		print $buffer;
	} else {
		# return in atom format
		$buffer .= atom_header();
		if ($terms) {
			foreach ($aterms as $term => $details) {
				$buffer.= term_atom_entry($term, $details);
			}
		}
		$buffer .= atom_footer();
		print $buffer;
	}
	
}


if (($type == "post") || ($type == "posts")) {
	# list posts (sparse)
	#	filter by timeframe
	#	filter by popularity
	#	filter by base url (so: get popular posts from URLs like 'flagsandlollipops.com')
	#   citing url (trackbacks, essentially)
	#	start : limit of $posts_return_limit results returned at once, this is the start point skip to pass to get_posts
	#	limit : override default limit (can't be above 100)
	#	post_id : list of posts you want details of
	#	category : category you want posts from
	#	term : posts containing term x

	# any filters?
	$filters = array();
	
	$output_available = 1;
	
	# basics...
	$filters['limit'] = $posts_return_limit;
	if (($limit) && ($limit < $max_posts_return_limit)) {$filters['limit'] = $limit;}
	if (($start) && (is_numeric($start))) {
		$filters['skip'] = $start;
	}
	
	# posts citing another post?
	if ($citing_url) {
		$citing_posts = get_posts_linking_to(false, false, $citing_url);
		if (sizeof($citing_posts) >= 1) {
			$filters['post_id'] = $citing_posts;
		} else {
			$filters['post_id'] = array();
			$output_available = 0;
		}
	}
	
	# posts citing a paper?
	if ($citing_paper) {
		$citing_posts = get_posts_for_paper($citing_paper, true);
		if (sizeof($citing_posts) >= 1) {
			$filters['post_id'] = $citing_posts;			
		} else {
			$filters['post_id'] = array();
			$output_available = 0;
		}
	}

        # posts citing a molecule?
        if ($citing_cbid) {
                $citing_posts = get_posts_for_cbid($citing_cbid, true);
                if (sizeof($citing_posts) >= 1) {
                        $filters['post_id'] = $citing_posts;
                } else {
                        $filters['post_id'] = array();
                        $output_available = 0;
                }
        }
	
	# fetch specific post_ids?
	if ($post_id) {
		$post_id = validate_lists(explode(',', $post_id));
		if (sizeof($post_id) >= 1) {
			$filters['post_id'] = $post_id;
		} else {
			$filters['post_id'] = array();
			$output_available = 0;
		}
	}
	
	# ordering?
	$safe_order_by = "published_on";
	if ($order_by == "cited") {$safe_order_by = "cited";}
	if ($order_by == "published_on") {$safe_order_by = "published_on";}
	if ($order_by == "added_on") {$safe_order_by = "added_on";}
	if ($order_by == "post_freq") {$safe_order_by = "post_freq";}	
	
	# posts containing a specific term (or terms)?
	if ($term) {
		$pterms = explode(",", $term);
		$tposts = array();
		
		if (sizeof($pterms)) {
			foreach ($pterms as $pterm) {
				$tposts = array_merge($tposts, get_posts_with_term($pterm));
			}
		}
		
		if (sizeof($tposts) >= 1) {
			$filters['post_id'] = $tposts;
		} else {
			$filters['post_id'] = array();
			$output_available = 0;
		}
	}
	
	# category
	if ($category) {$filters['category'] = $category;}
	
	# timeframe
	$safe_timeframe = $timeframe;
	if (!in_array($safe_timeframe, array("3m", "1w", "1m", "1y", "10y"))) {$safe_timeframe = "10y";}
	if ($safe_timeframe == "1w") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d) - 7,date(Y))); }	
	if ($safe_timeframe == "1m") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m) - 1, date(d),date(Y))); }
	if ($safe_timeframe == "3m") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m) - 3, date(d),date(Y))); }
	if ($safe_timeframe == "1y") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d),date(Y) - 1)); }
	if ($safe_timeframe == "10y") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d),date(Y) - 10)); }
	$filters['published_after'] = $safe_pubdate_start;
	
	# popularity
	$safe_min_links = $min_links;
	if ((!$safe_min_links) || (!is_numeric($safe_min_links))) {$safe_min_links = 0;}
	$filters['min_links'] = $safe_min_links;
		
	# base url
	if ($base_url) {$filters['base_url'] = $base_url;}
		
	# get posts
	$posts = get_posts($safe_order_by, $filters);
	
	# return posts
	if ($format == "json") {
		$json = new Services_JSON();
		if ($posts) {
			$buffer .= $json->encode($posts);
		}		
		
		if ($callback) {
			printf("%s(%s)", $callback, $buffer);
		} else {
			print $buffer;			
		}
	} else {
		$buffer .= atom_header();
		if ($output_available) {
			if ($posts) {
				foreach ($posts as $post) {
					$buffer.= post_atom_entry($post);
				}
			}
		}
		$buffer .= atom_footer();
		print $buffer;
	}
}

# if caching was switched on then save the page we just generated.
if ($PAGE_CACHE) {
	$page = ob_get_contents();
	ob_end_flush(); flush();
	
	# put cached page in database
	cache($PAGE_URL, $page);
}

?>
