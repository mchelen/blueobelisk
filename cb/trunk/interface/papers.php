<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "papers";
	$PAGE_TITLE = $config["name"]." - Books & Papers";
	$PAGE_CACHE = 1;
?>
<? include("header.php"); ?>
<? include("papers_menu.php"); ?>
<?
	$filters = array();
	$safe_timeframe = mysql_escape_string($_GET['timeframe']);
	$safe_min_links = mysql_escape_string($_GET['min_links']);

	$safe_comment_source = mysql_escape_string($_GET['comment_source']);
	if ($safe_comment_source == 'false') {$safe_comment_source = null;}
	
	if (!$safe_order_by) {$safe_order_by = "added_on";}
	if ($safe_order_by == "pubdate") {$safe_order_by = "published_on";} # for historical compatibility
	if (!in_array($safe_order_by, array("added_on", "cited", "published_on"))) {$safe_order_by = "added_on";}
		
	if (!in_array($safe_timeframe, array("3d", "1w", "1m", "1y", "100y", "3m"))) {
		$safe_timeframe = "100y";
	}
	
	if (!$safe_timeframe) {$safe_timeframe = "1m";}
	if ((!isset($safe_min_links)) || (!is_numeric($safe_min_links))) {$safe_min_links = 0;}
	
	$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d) - 7,date(Y))); 
	if ($safe_timeframe == "3d") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d) - 3,date(Y))); }
	if ($safe_timeframe == "1w") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d) - 7,date(Y))); }
	if ($safe_timeframe == "1m") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m) - 1, date(d),date(Y))); }
	if ($safe_timeframe == "3m") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m) - 3, date(d),date(Y))); }
	if ($safe_timeframe == "1y") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d),date(Y) - 1)); }
	if ($safe_timeframe == "100y") {$safe_pubdate_start = date("Y-m-d", mktime(0,0,0, date(m), date(d),date(Y) - 100)); }
			
	$safe_journal = mysql_escape_string($_GET['journal']);
	if ($safe_journal == "false") {$safe_journal = false;}
	$safe_skip = false;
	$safe_skip = mysql_escape_string($_GET["skip"]);
	if (!is_numeric($safe_skip)) {$safe_skip = false;}
		
	if ( ($safe_category) && ($safe_category != "Any") ) {$filters['category'] = $safe_category;}
	
	$filters['limit'] = $GLOBALS["config"]['papers_per_page'];
	
	if ($safe_journal) {$filters['journal'] = $safe_journal;}	
	if ($safe_skip) {$filters['skip'] = $safe_skip;}
	
	#$filters['reviews'] = true;
	$filters['published_after'] = $safe_pubdate_start;
	$filters['min_links'] = $safe_min_links;
	$filters['comment_source'] = $safe_comment_source;
	
	if ($_SAFE['area']) {$filters['type'] = $_SAFE['area'];}

	if ($_SAFE['area']) {$page_vars["area"] = $_SAFE['area'];}
	if ($safe_journal) {$page_vars["journal"] = $safe_journal;}
	if (isset($safe_min_links)) {$page_vars['min_links'] = $safe_min_links;}
	if ($safe_timeframe) {$page_vars['timeframe'] = $safe_timeframe;}
	if ($safe_comment_source) {$page_vars['comment_source'] = $safe_comment_source;}
?>
<div class='sidebar'>
	<div class='sidebox'>
	<div class='sidebox_title'>Limits</div>
	<div class='sidebox_content'>
	<p>Sort by <a href='<? plinkto("papers.php", $page_vars, array("order_by" => "added_on")); ?>' <? if ($safe_order_by == "added_on") {print "class='selected'";} ?>>date added</a>,
	<a href='<? plinkto("papers.php", $page_vars, array("order_by" => "published_on")); ?>' <? if ($safe_order_by == "published_on") {print "class='selected'";} ?>>date published</a>
	or <a href='<? plinkto("papers.php", $page_vars, array("order_by" => "cited")); ?>' <? if ($safe_order_by == "cited") {print "class='selected'";} ?>>popularity</a>
	<p>And only show papers commented on..<br/>
	<p>by at least 
	<a <? if ($safe_min_links == 1) {print "class='selected'";} ?> href='<? plinkto("papers.php", $page_vars, array("min_links" => 1)); ?>'>1</a>, 
	<a <? if ($safe_min_links == 2) {print "class='selected'";} ?>href='<? plinkto("papers.php", $page_vars, array("min_links" => 2)); ?>'>2</a> or
	<a <? if ($safe_min_links == 4) {print "class='selected'";} ?>href='<? plinkto("papers.php", $page_vars, array("min_links" => 4)); ?>'>4</a> blogs
	or <a <? if ($safe_min_links == 0) {print "class='selected'";} ?>href='<? plinkto("papers.php", $page_vars, array("min_links" => 0)); ?>'>show all types of commentary</a>
	<br/>

	<p>published in the last...<br/>
	<a <? if ($safe_timeframe == "1w") {print "class='selected'";}?> href='<? plinkto("papers.php", $page_vars, array("timeframe" => "1w")); ?>'>week</a>,
	<a <? if ($safe_timeframe == "1m") {print "class='selected'";}?> href='<? plinkto("papers.php", $page_vars, array("timeframe" => "1m")); ?>'>month</a>,
	<a <? if ($safe_timeframe == "3m") {print "class='selected'";}?> href='<? plinkto("papers.php", $page_vars, array("timeframe" => "3m")); ?>'>quarter</a>,	
	<a <? if ($safe_timeframe == "1y") {print "class='selected'";}?> href='<? plinkto("papers.php", $page_vars, array("timeframe" => "1y")); ?>'>year</a> or
	<a <? if ($safe_timeframe == "100y") {print "class='selected'";}?> href='<? plinkto("papers.php", $page_vars, array("timeframe" => "100y")); ?>'>show all papers</a>	
<?
		print "<h3>Limit to journal</h3>";
		
		if ($safe_journal) {print " <p>limiting to results from <span class='selected'>$safe_journal</span> (<a href='".linkto("papers.php", $page_vars, array("journal" => false))."'>remove limit</a>)";}
				
		$journals = get_journals($safe_category, 100, "count DESC");
		natcasesort($journals);

		print "<p><select name='journal' onchange='
		location = \"".linkto("papers.php", $page_vars, array("journal" => ""))."&journal=\" + this.options[this.selectedIndex].value;
		'>";
		print "<option value='false'>Any</option>";
		foreach ($journals as $journal) {
			$selected = "";
			if ($safe_journal == $journal) {$selected = "selected";}
			print "<option $selected value='".urlencode($journal)."'>".substr($journal,0,30)."</option>";
		}
		print "</select>";
		if ($safe_category) {
			print "<p>Note that only journals with papers that have been commented on by blogs in this category will appear in the box above.";
		}
?>	
</div>
</div>
<div class='sidebox'>
<div class='sidebox_title'>Subscribe</div>
<div class='sidebox_content'>
<? 
	if ($safe_category && $safe_journal) {
		print "<p>Subscribe to ".strtolower($safe_category)." papers from $safe_journal:";
	} else if ($safe_category) {
		print "<p>Subscribe to papers in the ".strtolower($safe_category)." category:";
	} else if ($safe_journal) {
		print "<p>Subscribe to papers from $safe_journal:";
	}

	feedbox("Latest papers", "atom.php?category=$safe_category&journal=$safe_journal&type=latest_papers"); 		
	feedbox("Recent hot papers", "atom.php?category=$safe_category&journal=$safe_journal&type=popular_papers");
?>
</div>
</div>
<div class='sidebox'>
<div class='sidebox_title'>Show papers with comments from...</div>
<div class='sidebox_content'>
<?
		if ($safe_comment_source) {print " <p>limiting to papers with comments from <b>$safe_comment_source</b> (<a href='".linkto("papers.php", $page_vars, array("comment_source" => false))."'>remove limit</a>)";}
?>
<div class='basic_thumbnail'><a href='<? plinkto("papers.php", $page_vars, array("comment_source" => "Nature Highlights")); ?>'><img border='0' src='images/hilight_comment.png'/></a></div>
<div class='basic_thumbnail'><a href='<? plinkto("papers.php", $page_vars, array("comment_source" => "F1000 Biology")); ?>'><img border='0' src='images/f1000_comment.png'/></a></div>
<div class='basic_thumbnail'><a href='<? plinkto("papers.php", $page_vars, array("comment_source" => "Connotea")); ?>'><img border='0' src='images/comment_connotea.jpg'/></a></div>
<!--
<div class='basic_thumbnail'><a href='<? plinkto("papers.php", $page_vars, array("comment_source" => "biomedcentral")); ?>'><img border='0' src='images/bmc_comment.png'/></a></div>
<div class='basic_thumbnail'><a href='<? plinkto("papers.php", $page_vars, array("comment_source" => "Cell")); ?>'><img border='0' src='images/cell_comment.png'/></a></div>
<div class='basic_thumbnail'><a href='<? plinkto("papers.php", $page_vars, array("comment_source" => "Science")); ?>'><img border='0' src='images/science_comment.png'/></a></div>
-->
<div class='postbox_footer'>&nbsp;</div>
</div>
</div>
<?
	print_searchbox("Papers");
?>
</div>
<div class='content'>
<?
	$papers = get_papers($safe_order_by, $filters);
	
	# pagination control
	if ($papers) {
		print_pagination($papers, $safe_skip, "papers.php", $GLOBALS["config"]['papers_per_page']);
		foreach ($papers as $paper) {
			print_paper($paper, array("display" => "minimal"));
		}
		print_pagination($papers, $safe_skip, "papers.php", $GLOBALS["config"]['papers_per_page']);		
	} else {
		print "No papers found.";
	}

?>
</div>
<? include("footer.php"); ?>