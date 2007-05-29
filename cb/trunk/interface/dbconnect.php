<?
	include_once("config.php");	

	mysql_connect($config['db_host'], $config['db_user'], $config['db_password']);
	
	@mysql_select_db($config['db_name']) or die( "<h1>Chemical blogspace</h1><p>The database is currently down. Please try again in 15 minutes. The database machine is since a forced downtime last weekend being unstable, and since I have only remote access to it right now, it is a bit tricky to debug. Please see the <a href=\"http://chemicalblogspace.blogspot.com/\">Chemical blogspace Blog</a> for more information.</p>");

?>
