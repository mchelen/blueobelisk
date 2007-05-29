<? include("config.php"); ?>
<? include("cache_functions.php"); ?>
<?
	# check to see if things are cached...
	if ($config['render_cache_to'] == "db") {require_once("dbconnect.php");}

	# check to see if we have a cached version
	$PAGE_URL = $_SERVER['REQUEST_URI'];
	if ($PAGE_CACHE) {
		$cached = get_cache($PAGE_URL);		
		if ($cached) {print $cached; exit;}
		ob_start();
	}
?>

<style>
body {
	margin:  0px;
	padding: 5px;
}
.tagcloud {
	margin-top: 10px;
	line-height: 150%;
}
.tagcloud a {
	padding: 2px;
	margin: 2px;
	background-color: #FFE6F9;
	border-right: 1px solid #FFBFEF;
	border-bottom: 1px solid #FFBFEF;
	text-decoration: none;
}
.tagcloud a:hover {
	color: #FF6600;
	border-right: 1px solid #FFE680;
	border-bottom: 1px solid #FFE680;
	background-color:  #FFF2BF;
}

.tagcloud_0 {font-size: 0.7em; color: #990099;}
.tagcloud_1 {font-size: 0.8em; color: #CC0099;}
.tagcloud_2 {font-size: 0.9em; color: #E60066;}
.tagcloud_3 {font-size: 1em; color: #E60066;}
.tagcloud_4 {font-size: 1.1em; color: #E60066;}
.status_message {
	padding: 2px;
	margin: 4px;
}
</style>
<?
	include("functions.php");
		
	$safe_category = mysql_escape_string($_GET['up_category']);
	
	# hack to get round the variable parsing done by functions.php
	if ($safe_category == "any") {$safe_category = "all";}
	if (!$safe_category) {$safe_category = "all";}
	
	# print "<div class='status_message'>Showing buzz from <b>$safe_category</b> blogs</div>";
	
	if ($safe_category == "all") {$safe_category = false;}
	
	$terms = get_terms(32, $safe_category);
	$terms = clean_terms($terms);

	print_termcloud($terms, array("target" => "_main"));

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