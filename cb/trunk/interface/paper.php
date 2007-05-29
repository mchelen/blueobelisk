<? include("functions.php"); ?>
<?
	$PAGE_TYPE = "papers";
	$PAGE_TITLE = $config["name"]." - Books & Papers details";
?>
<? include("header.php"); ?>
<? include("papers_menu.php"); ?>
<script language="javascript" type="text/javascript">
tinyMCE.init({
	mode : "textareas",
	theme : "simple"
});
</script>
<div class='content fullwidth'>
<?
	$paper_id = false;
	
	$safe_doi = mysql_escape_string($_GET["doi"]);
	$safe_paper_id = mysql_escape_string($_GET["paper_id"]);
	
	if ($safe_doi) {$safe_paper_id = get_paper_id_from_doi($safe_doi);}
	if ( ($safe_paper_id) && (is_numeric($safe_paper_id)) ) {$paper_id = $safe_paper_id;}
	
	if ($paper_id >= 1) {
		$papers = get_papers("added_on", array("paper_id" => $paper_id));
		
		if (sizeof($papers) == 1) {
			$paper = $papers[0];
			print_paper($paper, array("magnify" => true, "link_through" => true));
		} else {
			print_error("Couldn't find paper", "Sorry, we couldn't find the paper that you're looking for.");			
		}
	} else {
		print_error("Couldn't find paper", "Sorry, we couldn't find the paper that you're looking for.");
	}

?>
</div>
<? include("footer.php"); ?>