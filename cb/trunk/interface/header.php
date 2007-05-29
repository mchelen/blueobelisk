<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<?
	# we're expecting:
	#
	# $PAGE_TITLE (to set the page title)
	# $PAGE_TYPE (to set relevant RSS feeds and Javascript includes)
	
	if (!$PAGE_TITLE) {$PAGE_TITLE = $config['name'];}
	if ($safe_category) {
		$PAGE_TITLE .= " - ".$safe_category;
	}
	if (!$PAGE_TYPE) {$PAGE_TYPE = "index";}
?>
<html xmlns:chem="http://www.blueobelisk.org/chemistryblogs/">
<head profile="http://a9.com/-/spec/opensearch/1.1/">
	<title><? if ($title) {print $title;} else {print $PAGE_TITLE;} ?></title>
	<link type="application/opensearchdescription+xml" rel="search" title="Postgenomic" href="<? print $config['base_url']; ?>opensearch_xml.php"/>
<?
	print_template_css($safe_category);
?>

        <link rel="shortcut icon" href="images/favicon.png" type="image/x-png" />
        <meta name="verify-v1" content="U1NlPZ+cBv2Fr/oliNtdmTGu8eX0NLlXfL0ps8LfAqo=" />

	<link rel="stylesheet" type="text/css" href="lightbox.css"/>
	<!-- tinymce must always be loaded before script.aculo.us -->
	<!--
	<script type="text/javascript" src="javascripts/tiny_mce/tiny_mce.js"></script>
	-->
	<!-- for fancy effects... -->
	<script type="text/javascript" src="javascripts/prototype.js"></script>
	<script type="text/javascript" src="javascripts/scriptaculous.js"></script>	
	<script type="text/javascript" src="javascripts/lightbox.js"></script>
	<script type="text/javascript" src="javascripts/postgenomic.js"></script>
	
	<!-- the Postgenomic blog is postgenomic.com specific, really... -->
	<link rel='alternate' type='application/atom+xml' 
              title='The Chemical blogspace Blog'
              href='http://chemicalblogspace.blogspot.com/feeds/posts/default'/>
<?	
	feedbox("Latest posts, all categories", "atom.php?type=latest_posts", true);
	if ($config['collect_papers']) {feedbox("Latest papers, all categories", "atom.php?type=latest_papers", true);}
	if ($config['collect_links']) {feedbox("Latest links (min 2 blogs), all categories", "atom.php?type=latest_links&min_links=2", true);}	
?>

</head>
<body>	
<div class='title_banner'>

	<div class='title_category'>
	Explore 
	<select id='category_select' name='category' onchange='javascript:location = "<?
	
	if ($PAGE_TYPE == "posts") {
		plinkto("posts.php");
	}
	else if ($PAGE_TYPE == "links") {
		plinkto("links.php");
	}
	else if ($PAGE_TYPE == "papers") {
		plinkto("papers.php");
	}
        else if ($PAGE_TYPE == "molecules") {
                plinkto("inchis.php");
        }
	else if ($PAGE_TYPE == "blogs") {
		plinkto("blogs.php");
	}
	else if ($PAGE_TYPE == "stats") {
		plinkto("stats.php");
	}
	else if ($PAGE_TYPE == "news") {
		plinkto("news.php");
	}
	else {
		plinkto("index.php");
	}
	
	?>?category="+ this.options[this.selectedIndex].value<?
	if ($_SAFE['area']) {print " + \"&area=".$_SAFE['area']."\"";}	
	?>'>
		<option>Any</option>
	<?
		foreach ($global_categories as $tag) {
			$selected = "";
			if ($safe_category == $tag) {$selected = "selected";}
			printf("<option %s value='%s'>%s</option>", $selected, $tag, $tag);
		}
	?>
	</select>

	</div>
	
<div class='title_logo'>
<a href='<? plinkto("index.php"); ?>'>
<?
	print $config['header_name']; 
?>
</a>
</div>
</div>
<div class='title_menu'>
<div class='title_login'>

<?
	if ($logged_on) {
		print "<div class='login_button'><a href='".linkto("index.php", $page_vars, array("logout" => true))."'>Logged in as <b>$logged_on</b> (log out)</a></div>";
	} else {
		#print "<a href='".linkto("login.php", $page_vars)."'>log in or register</a>";
	}
?>
</div>
<?
	function print_menu_item($page, $page_title, $page_type = false, $override = array()) {
		global $page_vars;
		global $PAGE_TYPE;
		$selected = "class='title_menu_button'";
		if ($PAGE_TYPE == $page_type) {
			$selected = "class='title_menu_button_selected'";
		}
		print "<div $selected><a href='".linkto($page, $page_vars, $override)."'>$page_title</a>&nbsp;</div>";
	}

	$frontpage_name = "Home";
	#if (strlen($safe_category)) {
	print_menu_item("index.php", "Home", "index");
	#	$frontpage_name = "All categories";
	#	print_menu_item("index.php", $frontpage_name, "main_index", array("category" => false));	
	#} else {
	#	print_menu_item("index.php", $frontpage_name, "index", array("category" => false));
	#}
	
	if ($config['collect_papers']) {print_menu_item("papers.php", "Literature", "papers");}
	if ($config['collect_links']) {print_menu_item("links.php", "Links", "links");}
	print_menu_item("posts.php", "Posts", "posts");
        print_menu_item("inchis.php", "Molecules", "molecules");
	print_menu_item("blogs.php", "Blogs", "blogs");
	# print_menu_item("search.php", "Search", "search");
	print_menu_item("stats.php", "Zeitgeist", "zeitgeist");
	print_menu_item("http://chemicalblogspace.blogspot.com/2007/05/special-markup-howto-1.html", "Markup Help", "markup");
        print_menu_item("http://chemicalblogspace.blogspot.com/", "News", "news");
	if ($config['do_wiki']) {print_menu_item("wiki/doku.php", "Help", "wiki");}
	
	if ($logged_on && $is_admin) {
		print_menu_item("admin.php", "Admin", "admin");
	}
?>
</div>
<!--[if gte IE 5]>
<style>
table {width: auto;}
</style>
<![endif]-->
<?
	# caching - some pages should be cached where possible as they don't change until the pipeline is run again.
	#$PAGE_CACHE = 0;
	$PAGE_URL = $_SERVER['REQUEST_URI'];
	if ($PAGE_CACHE) {
		$cached = get_cache($PAGE_URL);
		ob_flush(); flush();		
		if ($cached) {print $cached; exit;}
		ob_start();
	}
?>
<div class='layout'>
