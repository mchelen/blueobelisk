<?
	# handle some $_GET variables that are universal
	$safe_order_by = mysql_escape_string($_GET['order_by']);
	$safe_category = mysql_escape_string($_GET['category']);
	
	if ( ($safe_category == "Any") || ($safe_category == "false") ) {$safe_category = false;}
	
	# clean all GET and POST vars
	$_SAFE = array();
	$input = array_merge($_GET, $_POST);
	foreach ($input as $key => $val) {
		$val = mysql_escape_string($val);
		$_SAFE[$key] = $val;
	}
	
	# check that category is valid
	global $global_categories;
	$global_categories = get_all_categories();
	if (!in_array($safe_category, $global_categories)) {$safe_category = false;}
	
	# include any extra conf files
	get_extra_conf($safe_category);	
		
	global $page_vars;
	
	$page_vars["order_by"] = $safe_order_by;
	$page_vars["category"] = $safe_category;
?>