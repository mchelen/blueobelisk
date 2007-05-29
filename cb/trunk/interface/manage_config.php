<? include("functions.php"); ?>
<?
if ((!$is_admin) || (!$logged_on)) {
	header("Location: index.php");		
}
?>
<? include("header.php"); ?>
<?
function print_var($var) {
	global $config;
	print "<tr><td><b>$var</b></td><td><input type='text' value='".$config[$var]."' size='64'></td></tr>";
}

function describe_var($var, $desc) {
		print_var($var);
		print "<tr><td>&nbsp;</td><td><p><i>$desc<p><br/></i></td></tr>";	
}

function heading($heading) {
	print "<tr><td colspan='2'><hr/><p><h1>$heading</h1></td></tr>";		
}

?>
<div class='content fullwidth'>
<h1>Site configuration</h1>
<?
	$seen = array();
	$vars = array_keys($config);
?>
<table width='100%' cellspacing='3' cellpadding='0'>
<?
	$descriptions = array(
		"heading_1" => "Basics",
		"name" => "Name of the site, appears in the window title.",
		"header_name" => "Text that appears in the left hand side of the header.",
		"email" => "Email address to send suggested blogs to.",
		"copyright_notice" => "Text to appear at bottom of every page.",
		"heading_2" => "Database",
		"db_name" => "The name of the database (e.g. pg_posts)",
		"db_host" => "The machine where the database is located (localhost?)",
		"db_user" => "A MySQL user who has access to the database.",
		"db_password" => "The password for db_user.",
		"heading_10" => "Misc."
	);
	
	foreach ($descriptions as $var => $desc) {
		array_push($seen, $var);
		if (preg_match("/heading_(\d*)/i", $var)) {
			heading($desc);
		} else {
			describe_var($var, $desc);
		}
	}

	foreach ($vars as $var) {
		if (!in_array($var, $seen)) {
			print_var($var);
		}
	}
?>
</table>
</div>
<?
	include("footer.php");
?>