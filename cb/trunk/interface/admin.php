<? include("functions.php"); ?>
<?
	if ((!$is_admin) || (!$logged_on)) {
		header("Location: index.php");		
	}
	
	$PAGE_TYPE = "admin";
	$PAGE_TITLE = "Postgenomic - Admin";
?>
<? include("header.php"); ?>
<div class='content fullwidth'>
<h1>Admin Tasks</h1>
<h3>Site</h3>
<p><a href='<? plinkto("manage_config.php", $page_vars); ?>'>Manage site configuration</a>
<h3>Blogs</h3>
<p><a href='<? plinkto("manage_blogs.php", $page_vars); ?>'>Manage Blogs</a>
<h3>Users</h3>
<p><a href='<? plinkto("manage_users.php", $page_vars); ?>'>Manage Users</a>
</div>
<? include("footer.php"); ?>