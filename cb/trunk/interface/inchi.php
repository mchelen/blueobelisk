<? include("functions.php"); ?>
<? include("inchi_functions.php"); ?>
<?
	$PAGE_TYPE = "molecules";
	$PAGE_TITLE = $config["name"]." - Molecules";
?>
<? include("header.php"); ?>

<script language="javascript" type="text/javascript">
tinyMCE.init({
	mode : "textareas",
	theme : "simple"
});
</script>
<div class='content fullwidth'>
<?
	$paper_id = false;
	
	$safe_inchi = mysql_escape_string($_GET["inchi"]);
        $safe_id = mysql_escape_string($_GET["id"]);
	
 	# print "DEBUG: inchi=".$safe_inchi."\n";
	# print "DEBUG: id=".$safe_id."\n";

	if ($safe_inchi) {
		$inchis = get_inchis("added_on", array("inchi" => $safe_inchi, "limit" => 1));
	} else {
		$inchis = get_inchis("added_on", array("id" => $safe_id, "limit" => 1));
	}

        # print "<span class=\"chem:inchi\">".$safe_inchi."</span>";
        # print "DEBUG: " . sizeof($inchis);

	foreach ($inchis as $inchi) {
                print_inchi($inchi, array("tagcloud" => true));
        }

?>
</div>
<? include("footer.php"); ?>
