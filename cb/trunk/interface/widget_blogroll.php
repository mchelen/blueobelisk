<? include("config.php"); ?>
<? include("cache_functions.php"); ?>
<?
	# check to see if we've a cached version of this widget.
	# by default cache is on
	$PAGE_CACHE = 1;
	
	if ($config['render_cache_to'] == "db") {require_once("dbconnect.php");}

	# check to see if we have a cached version
	$PAGE_URL = $_SERVER['REQUEST_URI'];
	if ($PAGE_CACHE) {
		$cached = get_cache($PAGE_URL);		
		if ($cached) {print $cached; exit;}
		ob_start();
	}
?>
<? require_once("dbconnect.php"); ?>
<?
	# clean all GET and POST vars
	$_SAFE = array();
	$input = array_merge($_GET, $_POST);
	foreach ($input as $key => $val) {
		$val = mysql_escape_string($val);
		$_SAFE[$key] = $val;
	}
	
	include("functions.php");
	
	$url = "http://www.bloglines.com/export?id=";
	
	$blog_ids = array();
			
	print "function print_widget() {\n";
	if ($_SAFE["username"]) {
		$url .= $_SAFE["username"];
		
		$page = download_url($url); # get OPML of public subscriptions
		
		if ($page) {
			# parse out all the feed URLs and see if they match anything in the database
			$matches = array();
			
			preg_match_all("/xmlUrl=[\'\"](.*?)[\"\']/i", $page, $matches);
			
			for ($i=0; $i < sizeof($matches[1]); $i++) {
				$blog = $matches[1][$i];

				$blog_id = get_blog_id($blog);

				if ($blog_id) {
					array_push($blog_ids, $blog_id);
				}
			}			
		}
	} elseif ($_SAFE['category']) {
		$blog_ids = get_blogs_with_tag($_SAFE['category']);
	}
	
	if (sizeof($blog_ids) || $_SAFE['all']) {
		# at least one blog on the public blogroll is also in Postgenomic
		$blogs = get_blogs($blog_ids, array("limit" => 20, "require_portraits" => true));
		print "document.write(\"";
		
		$counter = 0;
		
		$large_images = 2;
		$small_images = sizeof($blogs) - $large_images;
		$half = ceil($small_images / 2) + $large_images;
		
		$width = ($large_images * 64) + (ceil($small_images / 2) * 32);
		
		print "<table border='0' cellspacing='0' cellpadding='0' width='$width'>";
		print "<tr>";
		for ($i=0; $i < $large_images; $i++) {
			$blog = $blogs[$i];
			$size = 64;
			print "<td>";
			printf("<a href='%s'><img border='0' src='%s' height='%d' width='%d' /></a>", $blog['url'], $blog['image'], $size, $size);						
			print "</td>";
		}
		print "<td>";
		
		print "<table border='0' cellspacing='0' cellpadding='0' width='100%'>";
		print "<tr>";
		for ($i=$large_images; $i < sizeof($blogs); $i++) {
			$blog = $blogs[$i];
			$size = 32;
			
			if ($i == $half) {print "</tr><tr>";}
			
			print "<td>";
			printf("<a href='%s'><img border='0' src='%s' height='%d' width='%d' /></a>", $blog['url'], $blog['image'], $size, $size);						
			print "</td>";
		}
		print "</tr>";
		print "</table>";
		print "</td>";
						
		print "</tr>";
		print "</table>";
		
		print "\");";
	}
	
	print "}";
	print "print_widget();"
		
?>
<?
# if caching was switched on then save the page we just generated.
if ($PAGE_CACHE) {
	$page = ob_get_contents();
	ob_end_flush(); flush();
	
	# put cached page in database
	cache($PAGE_URL, $page);
}
?>