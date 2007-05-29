<?
	include_once("dbconnect.php");
	include_once("blog_functions.php");
	include_once("template_functions.php");				
	include_once("paper_functions.php");
	include_once("atom_functions.php");
	include_once("tag_functions.php");
	include_once("post_functions.php");
	include_once("link_functions.php");
	include_once("format_functions.php");
	include_once("connotea_functions.php");
	include_once("xml_functions.php");
	include_once("cache_functions.php");
	include_once("search_functions.php");
	include_once("login_functions.php");
	
	include_once("handle_vars.php");
	include_once("handle_users.php");

# we could be collecting images from posts involved in term bursts with the get_bursts_images.pl script...
# still working on this.
function get_images_from($post_ids) {
	if (!$post_ids) {return array();}
	if ($post_ids[0]["post_id"]) {
		# we've been passed an array of post objects, not post_ids. Convert them.
		$real_post_ids = array();
		foreach ($post_ids as $post) {
			array_push($real_post_ids, $post['post_id']);
		}
		$post_ids = $real_post_ids;
	}
	
	$images = array();
			
	$query = "SELECT src FROM bursts_images WHERE post_id IN ('".implode("','", $post_ids)."')";
	$results = mysql_query($query);	
	while ($row = mysql_fetch_assoc($results)) {array_push($images, $row['src']);}
	
	return $images;
}

function download_url($url, $username = false, $password = false, $timeout = false) {
	global $config;
	
	$results = false;
	$use_curl = $config['use_curl'];
	
	if (($username) && ($password)) {
		# $url = preg_replace("/http:\/\//i", "http://".$username.":".$password."@", $url);
		$use_curl = true;
	}
	
	if ($use_curl) {
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_HEADER, 0);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		if ($username) {
			curl_setopt($ch, CURLOPT_USERPWD, "$username:$password"); 
		}
		if ($timeout) {
			curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);	
		}
		curl_setopt($ch, CURLOPT_USERAGENT, "Postgenomic WWW::Connotea");
		$results = curl_exec($ch);
		curl_close($ch);
	} else {
		$results = file_get_contents($url);
	}	
	
	return $results;
}

function get_content_type($filename) {
	# attempt to guess content type based on the filename
	if (preg_match("/(.+)\.png/", $filename)) {return "image/png";}
	if (preg_match("/(.+)\.gif/", $filename)) {return "image/gif";}
	if (preg_match("/(.+)\.jpg/", $filename)) {return "image/jpeg";}
	if (preg_match("/(.+)\.jpeg/", $filename)) {return "image/jpeg";}

	return "text/html";
}

function get_domains($category = false, $limit = 25) {
	$query = "SELECT DISTINCT domain, COUNT(*) AS count FROM links_summary GROUP BY domain ORDER BY count DESC LIMIT $limit";	

	$results = mysql_query($query);
	$domains = array();

	while ($row = mysql_fetch_assoc($results)) {
		array_push($domains, $row['domain']);
	}

	return $domains;	
}
	
function get_journals($category = false, $limit = 25, $order_by = "count DESC", $filters = array()) {
	if ($filters['skip']) {
		$limit = $filters['skip'].",".$limit;
	}
	
	if ($category) {
		$query = "SELECT DISTINCT papers.journal, COUNT(*) AS count, journal_stats.* FROM papers, links, posts, tags, journal_stats WHERE journal_stats.journal = papers.journal AND tags.tag='$category' AND tags.blog_id = posts.blog_id AND posts.post_id = links.post_id AND links.paper_id = papers.paper_id AND !ISNULL(papers.journal) GROUP BY papers.journal ORDER BY $order_by LIMIT $limit";
	} else {
		$query = "SELECT DISTINCT papers.journal, COUNT(*) AS count, journal_stats.* FROM papers, journal_stats WHERE journal_stats.journal = papers.journal AND !ISNULL(papers.journal) GROUP BY papers.journal ORDER BY $order_by LIMIT $limit";
	}

	$results = mysql_query($query);
	$journals = array();

	while ($row = mysql_fetch_assoc($results)) {
		if ($filters['return_full']) {
			array_push($journals, $row);
		} else {
			array_push($journals, $row['journal']);
		}
	}

	return $journals;
}

function get_rank_from_stats($item, $stats) {
	# what position does $item appear in assoc array $stats ordered by value?
	arsort($stats);
	
	$counter = 0;
	
	foreach ($stats as $key => $val) {
		$counter++;
		if ($key == $item) {return $counter;}
	}
	
	return $counter;
}


# extreme string cleaning: use only as a last resort if iconv is unavailable
function reduce_to_ascii($string, $alphanumeric_only = false)
{
	$clean = "";
	for ($i=0; $i < strlen($string); $i++) {
    	$char = substr($string,$i,1);
        if ((ord($char) <= 126) && (ord($char) >= 1)) {$clean .= $char;}
 	}

	if ($alphanumeric_only) {
		$clean = preg_replace("/[^A-Za-z\s0-9]/i", "", $clean);
	}

 	return $clean;
}

function validate_lists($list) {
	$new_list = array();
	if ($list) {
		foreach ($list as $item) {
			if (is_numeric($item)) {
				array_push($new_list, $item);
			}
		}
	}
	return $new_list;
}

function return_http_error($error = 400) {
	if ($error == 401) {
		header("HTTP/1.1 401");
	} else if ($error == 403) {
		header("HTTP/1.1 403");		
	} else {
		header("HTTP/1.1 $error");		
	}
}

?>
