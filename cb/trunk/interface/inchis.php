<? include("functions.php"); ?>
<? include("inchi_functions.php"); ?>
<?
	$PAGE_TYPE = "inchis";
	$PAGE_TITLE = $config["name"]." - Chemical Compounds";
	$PAGE_CACHE = 1;
?>
<? include("header.php"); ?>
<!-- ? include("blogs_menu.php"); ? -->
<div class='sidebar'>
<div class='sidebox'>
<div class='sidebox_title'>Subscribe</div>
<div class='sidebox_content'>
<?
if ($safe_category) {
	print "<p>Subscribe to new inchis from the ".strtolower($safe_category)." category:";
}

feedbox("New molecules", "atom.php?category=$safe_category&type=latest_inchis");
?>
</div>
</div>
<!-- ?
	print_searchbox("InChIs");
? -->
</div>
<div class='content'>
<p>To have your blog items show up on this page, just use semantic markup for InChI's and SMILES, 
<a href="http://chem-bla-ics.blogspot.com/2006/12/including-smiles-cml-and-inchi-in.html">using
microformats or RDFa</a>. For example, write &lt;span class="chem:smiles">CCCOC&lt;span> instead 
of just CCCOC, or &lt;span class="chem:inchi">InChI=1/bla&lt;span> instead of InChI=1/bla.

<?

	$safe_skip = false;
	$safe_skip = mysql_escape_string($_GET["skip"]);
	if (!is_numeric($safe_skip)) {$safe_skip = false;}
	
	$filters = array();
	$filters['limit'] = $GLOBALS["config"]['blogs_per_page'];
	if ($safe_skip) {$filters['skip'] = $safe_skip;} else {$filters['skip'] = 0;}
		
	$blogs = get_inchis(get_blogs_with_tag($safe_category), $filters);
	
	print_pagination($blogs, $safe_skip, "inchis.php", $GLOBALS["config"]['blogs_per_page']);
	
	foreach ($blogs as $blog) {
		print_inchi($blog, array("tagcloud" => true));
	}

	print_pagination($blogs, $safe_skip, "inchis.php", $GLOBALS["config"]['blogs_per_page']);
	
?>
</div>
<? include("footer.php"); ?>
