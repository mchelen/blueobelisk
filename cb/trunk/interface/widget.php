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
<? require_once('magpierss/rss_fetch.inc'); ?>
<? 
	$base_url = $_GET['base_url'];
	#$base_url = urlencode($base_url);
	$base_url = urldecode(mysql_escape_string($base_url));
		
	$citing = $_GET['citing'];
	$citing = urldecode(mysql_escape_string($citing));
	
	$style = $_GET['style'];
	$style = strtolower(mysql_escape_string($style));
	
	$limit = $_GET['limit'];
	$safe_limit = 10;
	if (is_numeric($limit)) {$safe_limit = $limit;}
	
	# convert atom feed to simple html (+ Postgenomic logo) that can be included on a blog.
	if ($base_url) {
		#$url = "http://neutron.nature.com/interface/api.php?type=post&order_by=cited&limit=$safe_limit&base_url=$base_url";
		$url = $config['base_url']."api.php?type=post&order_by=cited&limit=$safe_limit&base_url=$base_url";
	} else {
		$url = $config['base_url']."api.php?type=post&order_by=cited&limit=$safe_limit&citing=$citing";
	}
	
	print "function print_widget() {\n";
	print "// $url\n";
	$widget_id = uniqid("widget_");
	print "document.write(\"<div class='pg_widget' id='$widget_id'>\");";
	$rss = @fetch_rss($url);
	if (!sizeof($rss->items)) {
		print "document.write(\"Sorry, couldn't retrieve RSS.\");";
	} else {
		print "document.write(\"<ul class='pg_widget_ul'>\");";
		foreach ($rss->items as $item) {
			print "document.write(\"";
			printf("<li class='pg_widget_bullet'><a class='pg_widget_link' href='%s'>%s</a>", $item['link'], addslashes($item['title']));
			if ($citing) {
				printf(" at <span class='pg_widget_blog'>%s</span>", $item['contributor']);
			}
			print "</li>";
			print "\");";
		}
		print "document.write(\"</ul>\");";
	}
	
	print "document.write(\"<br/><i>Powered by <a class='pg_widget_link' href='http://cb.openmolecules.net/'>Chemical blogspace</a></i>\");";
	print "document.write(\"</div>\");";

	print "}\n";
	
	if ($style) {include_style($style, $widget_id);}
	
	print "print_widget();"
?>
<?

function include_style($style, $widget_id) {
	$styles = array();
	if ($style == "elegant") {
		$styles["pg_widget"] = "padding: 10px; color: #999999;";
		$styles["pg_widget_link"] = "color: #666666;";
		$styles["pg_widget_ul"] = "padding-left: 0; margin-left: 0; border-bottom: 1px solid #DEDEDE;";
		$styles["pg_widget_bullet"] = "list-style: none; margin: 0; padding: 0.25em; border-top: 1px solid #DEDEDE;";		
	}
	
	if (sizeof($styles) >= 1) {
		print "document.write(\"<style>";
		foreach ($styles as $key => $val) {
			if ($key == "pg_widget") {
				print "#$widget_id { $val } ";
			} else {
				print "#$widget_id .$key { $val } ";
			}
		}
		print "</style>\");";
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
