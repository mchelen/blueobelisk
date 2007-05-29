<? 
include("functions.php");
include("inchi_functions.php");

# if we don't increase the memory limit from 8Mb the JSON encode script dies a death.
ini_set("memory_limit","64M");

# general variables
$ids = strtolower(mysql_escape_string($_GET['id']));
$type = strtolower(mysql_escape_string($_GET['type']));

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

if (($type == "inchi") || ($type == "inchis")) {
	# list papers
	
	# the ids_only part of the API is a bit hacky because it needs to be backwards compatible
	# with the original "API" that allowed Pedro to do the Greasemonkey hack.
	if ($ids_only) {
		# list all papers in the database (just their IDs, though)
		$filters['limit'] = 1000000; # absurdly high limit so that everything is returned
		$papers = get_inchis("added_on", $filters);

		if ($papers) {
			
			$doi_ids = array();
			$pubmed_ids = array();
			$post_ids = array();
			
			foreach ($papers as $paper) {
				if ($paper['inchi']) {$doi_ids[$paper["inchi"]] = $paper["cbid"];}
				if ($paper['cid']) {$pubmed_ids[$paper["cid"]] = $paper["cbid"];}
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
				
				$ids = array("InChI" => $doi_ids, "CID" => $pubmed_ids);
						
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

# if caching was switched on then save the page we just generated.
if ($PAGE_CACHE) {
	$page = ob_get_contents();
	ob_end_flush(); flush();
	
	# put cached page in database
	cache($PAGE_URL, $page);
}

?>
