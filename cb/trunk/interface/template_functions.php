<?

function get_template_dir() {
	if (!$config['template_dir']) {$config['template_dir'] = "templates/";}
	return $config['template_dir'];	
}

function get_extra_conf($safe_category) {
	$template_dir = get_template_dir();
	if (!$safe_category) {return false;}
	$custom_path = $template_dir.strtolower(preg_replace("/[^\w]/i", "", $safe_category))."/".strtolower(preg_replace("/[^\w]/i", "", $safe_category)).".conf";
	
	if (file_exists($custom_path)) {
		$data = file_get_contents($custom_path);
		parse_config_file($data);
	}	
}

function get_blurb($page, $safe_category = false) {
	$template_dir = get_template_dir();
	include_once($template_dir."blurb.php");
	
	if ($safe_category) {
		$custom_path = $template_dir.strtolower(preg_replace("/[^\w]/i", "", $safe_category))."/blurb.php";
		if (file_exists($custom_path)) {
			# if there's a custom blurb.php then use it to overwrite the existing one where appropriate.
			include_once($custom_path);
		} 
	}
	
	return $blurb[$page];
}

function print_template_css($safe_category = false) {
	global $config;
	
	# if we haven't set a custom template dir use the default.
	$template_dir = get_template_dir();
	
	# is there a template available for this category?
	if ($safe_category) {
		$category_template = $template_dir.strtolower(preg_replace("/[^\w]/i", "", $safe_category))."/";
	} else {
		$category_template = $template_dir;
	}
	# Postgenomic uses several CSS files for different sections of the site...
	# Different categories can have different CSS files.
	
	$css = array("basic", "header", "posts", "papers", "blogs", "links", "search", "zeitgeist");
	
	foreach ($css as $file) {
		$custom_path = $category_template.$file.".css";
		
		# by default use the basic version.
		$use = $template_dir.$file.".css";
		
		if (file_exists($custom_path)) {
			# use the custom version
			$use = $custom_path;
		}
		
		print "\t<link rel='stylesheet' type='text/css' href='$use'/>\n";
	}
}
?>