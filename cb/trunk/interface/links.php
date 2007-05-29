<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "links";
	$PAGE_TITLE = $config["name"]." - Links";
	$PAGE_CACHE = 1;
?>
<? include("header.php"); ?>
<?
	$safe_timeframe = mysql_escape_string($_GET['timeframe']);
	$safe_min_links = mysql_escape_string($_GET['min_links']);
	if (!in_array($safe_order_by, array("added_on", "cited"))) {$safe_order_by = "added_on";}
	
	if (!$safe_order_by) {$safe_order_by = "added_on";}
		
	if (!in_array($safe_timeframe, array("3d", "1w", "1m", "3m"))) {
		$safe_timeframe = "1w";
	}
	
	if (!$safe_timeframe) {$safe_timeframe = "1m";}
	if ((!$safe_min_links) || (!is_numeric($safe_min_links))) {$safe_min_links = 2;}
	
	$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d) - 7,date(Y))); 
	if ($safe_timeframe == "3d") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d) - 3,date(Y))); }
	if ($safe_timeframe == "1w") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d) - 7,date(Y))); }
	if ($safe_timeframe == "1m") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m) - 1, date(d),date(Y))); }
	if ($safe_timeframe == "3m") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m) - 3, date(d),date(Y))); }

	$filters = array();
	$safe_skip = false;
	$safe_skip = mysql_escape_string($_GET["skip"]);
	if (!is_numeric($safe_skip)) {$safe_skip = false;}
	if ( ($safe_category) && ($safe_category != "Any") ) {$filters['category'] = $safe_category;}
	if ($safe_skip) {$filters['skip'] = $safe_skip;}
		
	$filters['limit'] = $GLOBALS["config"]['links_per_page'];
	$filters['min_links'] = $safe_min_links;
	$filters['published_after'] = $safe_pubdate_start;
	
	if ($filters['min_links']) {$page_vars['min_links'] = $filters['min_links'];}
	if ($filters['published_after']) {$page_vars['timeframe'] = $safe_timeframe;}
		
?>
<div class='sidebar'>
	<div class='sidebox'>
	<div class='sidebox_title'>Limits</div>
	<div class='sidebox_content'>
<p>Sort by <a href='<? plinkto("links.php", $page_vars, array("order_by" => "added_on")); ?>' <? if ($safe_order_by == "added_on") {print "class='selected'";} ?>>date added</a>
or <a href='<? plinkto("links.php", $page_vars, array("order_by" => "cited")); ?>' <? if ($safe_order_by == "cited") {print "class='selected'";} ?>>popularity</a>
<?
	if ($safe_journal) {print " limiting to results from <b>$safe_journal</b> (<a href='".linkto("papers.php", $page_vars, array("journal" => false))."'>remove limit</a>)";}
?>
<p>And only show items linked to..<br/>
<p>by at least 
<a <? if ($safe_min_links == 1) {print "class='selected'";} ?> href='<? plinkto("links.php", $page_vars, array("min_links" => 1)); ?>'>1</a>, 
<a <? if ($safe_min_links == 2) {print "class='selected'";} ?>href='<? plinkto("links.php", $page_vars, array("min_links" => 2)); ?>'>2</a>,
<a <? if ($safe_min_links == 4) {print "class='selected'";} ?>href='<? plinkto("links.php", $page_vars, array("min_links" => 4)); ?>'>4</a> or
<a <? if ($safe_min_links == 8) {print "class='selected'";} ?>href='<? plinkto("links.php", $page_vars, array("min_links" => 8)); ?>'>8</a>
blogs<br/>

<p>from the past..<br/>
<a <? if ($safe_timeframe == "3d") {print "class='selected'";}?> href='<? plinkto("links.php", $page_vars, array("timeframe" => "3d")); ?>'>three days</a>,
<a <? if ($safe_timeframe == "1w") {print "class='selected'";}?> href='<? plinkto("links.php", $page_vars, array("timeframe" => "1w")); ?>'>week</a>, 
<a <? if ($safe_timeframe == "1m") {print "class='selected'";}?> href='<? plinkto("links.php", $page_vars, array("timeframe" => "1m")); ?>'>month</a> or
<a <? if ($safe_timeframe == "3m") {print "class='selected'";}?> href='<? plinkto("links.php", $page_vars, array("timeframe" => "3m")); ?>'>three months</a>
</div>
</div>
<div class='sidebox'>
<div class='sidebox_title'>Subscribe</div>
<div class='sidebox_content'>
<? 
	if ($safe_category) {
		print "<p>Subscribe to links in the ".strtolower($safe_category)." category:";
	}

	feedbox("Latest links", "atom.php?category=$safe_category&type=latest_links");
	feedbox("Latest links (min 2 blogs)", "atom.php?category=$safe_category&type=latest_links&min_links=2");
	feedbox("Latest links (min 4 blogs)", "atom.php?category=$safe_category&type=latest_links&min_links=4");
	feedbox("Latest links (min 8 blogs)", "atom.php?category=$safe_category&type=latest_links&min_links=8");
?>
</div>
</div>
</div>
<div class='content'>
<?
	$links = get_links($safe_order_by, $filters);

	if ($links) {
		print_pagination($links, $safe_skip, "links.php", $GLOBALS["config"]['links_per_page']);	
		foreach ($links as $link) {print_link($link);}
		print_pagination($links, $safe_skip, "links.php", $GLOBALS["config"]['links_per_page']);	
	} else {	
		print "No links found.";
	}

?>	
</div>
<? include("footer.php"); ?>