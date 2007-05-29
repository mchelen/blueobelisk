<?
	# produce a sitemap for Google.
	
	header("Content-type: text/xml");
	print '<?xml version="1.0" encoding="UTF-8"?>';
?>
<urlset xmlns="http://www.google.com/schemas/sitemap/0.84">
<?
	include("config.php");

	# we don't include posts.php and links.php here because they're disallowed by robots.txt anyway.
	add_url("index.php", "daily", "0.8");
	add_url("blogs.php", "weekly", "0.1");	
	add_url("stats.php", "weekly", "0.3");	
	add_url("blog_search.php", "daily", "0.9");
	add_url("search.php", "monthly", "0.5");
	add_url("post.php", "yearly", "0.1");
	add_url("paper.php", "monthly", "0.6");
	add_url("papers.php", "daily", "0.1");
		
	if ($config['do_wiki']) {
		add_url("wiki/doku.php", "weekly", "0.8");
	}
	
	function add_url($url, $update = "daily", $priority = "0.5") {
		global $config;
		$url = htmlentities($config["base_url"].$url);
?>
<url>
   <loc><? print $url; ?></loc>
   <changefreq><? print $update; ?></changefreq>
   <priority><? print $priority; ?></priority>
</url>
<?
	}
?>
</urlset>