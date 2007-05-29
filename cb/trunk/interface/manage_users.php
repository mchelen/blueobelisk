<? include("functions.php"); ?>
<?
if ((!$is_admin) || (!$logged_on)) {
	header("Location: index.php");		
}
?>
<? include("header.php"); ?>
<div class='content fullwidth'>
<h1>Manage Users</h1>
</div>
<?
	include("footer.php");
?>