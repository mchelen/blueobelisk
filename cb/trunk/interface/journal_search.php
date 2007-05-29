<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "zeitgeist";
	$PAGE_TITLE = $config["name"]." - Journal details";

?>
<? include("header.php"); ?>
<?
$safe_journal_id = mysql_escape_string($_GET['journal_id']);
$last_month = date("Y-m-d", mktime(0,0,0, date(m)-1, date(d),date(Y))); 
	
if ($safe_journal_id) {
?>
<div class='sidebar'>
<?
	$stats = get_journal_stats($safe_journal_id);
?>
<div class='sidebox'>
<div class='sidebox_title'>Tags associated with this publisher</div>
<div class='sidebox_content'>
<?
	$tags = get_tags_for_journal($safe_journal_id, 50);
	print_tagcloud($tags);
?>
</div>
</div>

<div class='sidebox'>
<div class='sidebox_title'>Stats</div>
<div class='sidebox_content'>
<?
if ($stats) {
	print_journal_stats($safe_journal_id, $stats);
}
?>
</div>
</div>

</div>
<div class='content'>
<h1><? print $safe_journal_id; ?></h1>

<table width='100%' cellspacing='10' cellpadding='0'>
<tr>
<td valign='top' width='*'>
<?
	print "<h3>All time most popular books &amp; papers</h3>";
		$papers = get_papers("cited", array("journal" => $safe_journal_id, "limit" => 5));
	foreach ($papers as $paper) {
		print_paper($paper, array("display" => "minimal"));
	}
?>
</td>
<?
	$papers = get_papers("cited", array("journal" => $safe_journal_id, "limit" => 5, "published_after" => $last_month));
	if ($papers) {
?>
<td valign='top' width='50%'>
	<?
		print "<h3>Recently published hot books &amp; papers</h3>";
		foreach ($papers as $paper) {
			print_paper($paper, array("display" => "minimal"));
		}
	?>	
</td>
<?
	}
?>
</tr>
</table>
</div>
<?
} else {
	print_error("No publisher specified", "Sorry, I'm not sure which publisher you're looking for.");
}
?>
<? include("footer.php");?>