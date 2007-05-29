<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "zeitgeist";
	$PAGE_TITLE = $config["name"]." - Zeitgeist";
	$PAGE_CACHE = 1;
?>
<? include("header.php"); ?>
<? include("stats_menu.php"); ?>
<div class='content fullwidth'>
<?
	$safe_area = mysql_escape_string($_GET['area']);
	if (!in_array($safe_area, array("blogs", "journals"))) {$safe_area = false;}
?>
<?
	if ($safe_area == "blogs") {
?>
<h1>Blogs</h1>
<h3>Top 50 Science Blogs</h3>
<p>Rankings are based on the number of incoming links from other indexed science blogs and some secret Postgenomic sauce. Only links from the past ninety days are counted.
<p><br/>
<table width='100%' cellspacing='0' cellpadding='0'>
<tr>
<td width='50%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 25));
	if (sizeof($blogs)) {tabulate_blogs($blogs);}
?>
</td>
<td width='50%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 25, "skip" => 25));
	if (sizeof($blogs)) {tabulate_blogs($blogs);}
?>
</td>
</tr>
</table>
<h3>Readability</h3>
<p>Readability is assessed for posts published in the past ninety days using the <a href='http://en.wikipedia.org/wiki/Gunning-Fog_Index'>Gunning-Fog index</a>. The index is an indication of the number of years of formal education that a person requires in order to easily understand the text on the first reading.
<p>You can see more readability stats by clicking through to individual blogs and checking out the sidebar.
<p><br/>
<table width='100%' cellspacing='0' cellpadding='0'>
<tr>
<td width='25%' valign='top'><? printf("<h2>6 to 10<br/>%s</h2>", convert_fog(8)); ?></td>
<td width='25%' valign='top'><? printf("<h2>10 to 14<br/>%s</h2>", convert_fog(12)); ?></td>
<td width='25%' valign='top'><? printf("<h2>14 to 17<br/>%s</h2>", convert_fog(15)); ?></td>
<td width='25%' valign='top'><? printf("<h2>17 to 20<br/>%s</h2>", convert_fog(17)); ?></td>
</tr>		
<tr>
<td width='25%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 10, "min_fog" => 6, "max_fog" => 10));
	if (sizeof($blogs)) {tabulate_blogs($blogs, "readability_fog");}
?>	
</td>
<td width='25%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 10, "min_fog" => 10, "max_fog" => 14));
	if (sizeof($blogs)) {tabulate_blogs($blogs, "readability_fog");}
?>	
</td>
<td width='25%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 10, "min_fog" => 14, "max_fog" => 17));
	if (sizeof($blogs)) {tabulate_blogs($blogs, "readability_fog");}
?>	
</td>
<td width='25%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 10, "min_fog" => 17, "max_fog" => 20));
	if (sizeof($blogs)) {tabulate_blogs($blogs, "readability_fog");}
?>	
</td>
</tr>
</table>
<h3>Other stats</h3>
<p>Most Active lists the blogs with the highest number of posts published over the past ninety days. Wordiest lists the blogs with the highest average number of words per post. Friendliest lists the blogs which link out to other blogs most frequently.
<p>Note that these statistics are calculated using the RSS feed from each blog. These feeds don't always carry the full post and may have had hyperlinks removed.
<p><br/>
<table width='100%' cellspacing='0' cellpadding='0'>
<tr>
<td width='33%' valign='top'><h2>Most Active</h2></td>
<td width='33%' valign='top'><h2>Wordiest</h2></td>
<td width='33%' valign='top'><h2>Friendliest</h2></td>
</tr>
<tr>
<td width='33%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 20, "num_posts" => true));
	if (sizeof($blogs)) {tabulate_blogs($blogs, "num_posts");}
?>
</td>
<td width='33%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 20, "wordiest" => true));
	if (sizeof($blogs)) {tabulate_blogs($blogs, "avg_words_per_post");}
?>
</td>
<td width='33%' valign='top'>
<?
	$blogs = get_blogs(array(), array("limit" => 20, "blogloving" => true));
	if (sizeof($blogs)) {tabulate_blogs($blogs, "outgoing_bloglove");}
?>
</td>
</tr>
</table>
<?
	} else if ($safe_area == "journals") {
?>
<h1>Publishers</h1>
<h3>Top 50 Publishers by Citations</h3>
<p>Rankings are based on the number of incoming links from indexed science blogs and some secret Postgenomic sauce.
<p><br/>
<table width='100%' cellspacing='0' cellpadding='0'>
<tr>
<td width='50%' valign='top'>
<?
	$journals = get_journals(false, 25, "rank ASC", array("return_full" => true));
	if (sizeof($journals)) {tabulate_journals($journals);}
?>
</td>
<td width='50%' valign='top'>
<?
	$journals = get_journals(false, 25, "rank ASC", array("return_full" => true, "skip" => 25));
	if (sizeof($journals)) {tabulate_journals($journals);}
?>
</td>
</tr>
</table>
<h3>Top 20 Publishers by Papers</h3>
<p>Rankings are based on the number of relevant books and papers in the database.
<p><br/>
<table width='100%' cellspacing='0' cellpadding='0'>
<tr>
<td width='50%' valign='top'>
<?
	$journals = get_journals(false, 10, "num_papers DESC", array("return_full" => true));
	if (sizeof($journals)) {tabulate_journals($journals, "num_papers");}
?>
</td>
<td width='50%' valign='top'>
<?
	$journals = get_journals(false, 10, "num_papers DESC", array("return_full" => true, "skip" => 10));
	if (sizeof($journals)) {tabulate_journals($journals, "num_papers");}
?>
</td>
</tr>
</table>
<h3>All Time Most Popular Books &amp; Papers</h3>
<p>These are the ten most cited books or papers in the database. Note that only blog posts are counted as citations - comments and external links (like F1000 reviews or Nature Highlights) are ignored.
<p>You can see a breakdown of popular books or papers by publisher by clicking on a publisher name.
<p><br/>
<?
	$papers = get_papers("cited", array("limit" => 10));
	foreach ($papers as $paper) {
		print_paper($paper, array("display" => "minimal"));
	}
?>
<?
	} else if ($safe_area == "trends") {
?>
<h1>Trends</h1>
<?
	} else {
?>
<h1>Overview</h1>
<p>Please note that these statistics refer to the entire Postgenomic database, not just the currently selected category.
<?
	# generate input XML for graphing component.
	$xml = post_freq_xml($safe_category);
	
	$file = fopen("xml/sample.xml", "w");
	if ($file) {
		fwrite($file, $xml);
		fclose($file);
	} else {
		print "<p>An error occurred: Couldn't write out the XML for the Flash graph. Perhaps your webserver doesn't have write permission in the xml subdirectory of the interface?";
	}
	
?>
<h3>Posting Frequency</h3>
<div style='width: 600px; margin-left: auto; margin-right: auto;'>
<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
	codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" 
	id="charts" 
    WIDTH="600" 
    HEIGHT="400"
	   wmode="transparent" 
	ALIGN="center">
<PARAM NAME=movie VALUE="flash/charts.swf?library_path=flash/charts_library&xml_source=xml/sample.xml">
<PARAM NAME=quality VALUE=high>
<PARAM NAME=bgcolor VALUE=#FFFFFF>
<PARAM NAME=wmode VALUE=transparent>
<EMBED src="flash/charts.swf?library_path=flash/charts_library&xml_source=xml/sample.xml"
       quality=high 
       bgcolor="#FFFFFF"  
       WIDTH="600" 
       HEIGHT="400"
       NAME="charts" 
	   wmode="transparent" 
       swLiveConnect="true" 
       TYPE="application/x-shockwave-flash" 
       PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer">
</EMBED>
</OBJECT>
</div>
<h3>Stats overview</h3>
<table width='100%' cellspacing='0' cellpadding='0'>
<tr>
	<td width='33%' valign='top'><h3>Top Blogs</h3></td>
	<td width='33%' valign='top'><h3>Top Publishers</h3></td>
	<td width='33%' valign='top'><h3>Top Tags</h3></td>
</tr>
<tr>
	<td width='33%' valign='top'>
		<?
			$blogs = get_blogs(array(), array("limit" => 25));
			if (sizeof($blogs)) {tabulate_blogs($blogs);}
		?>		
	</td>
	<td width='33%' valign='top'>
		<?
			$journals = get_journals(false, 25, "rank ASC", array("return_full" => true));
			if (sizeof($journals)) {tabulate_journals($journals);}
		?>
	</td>
	<td width='33%' valign='top'>
		<?
			$tags = get_popular_tags(false, 25);
			if (sizeof($tags)) {tabulate_tags($tags);}
		?>		
	</td>
</tr>
</table>
<?
	}
?>
</div>
<? include("footer.php"); ?>