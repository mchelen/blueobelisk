<?
	# check for login cookie
	global $logged_on;
	$logged_on = false;
	$is_admin = false;
	
	if ($_COOKIE['pg_logged_on']) {
		$validator = validate_cookie($_COOKIE['pg_logged_on']);
		$logged_on = $validator["username"];
		
		$roles = $validator["roles"];
		
		if (in_array("is_admin", $roles)) {$is_admin = true;}
		
		if (!$logged_on) {
			# bad cookie - get rid of it.
			setcookie("pg_logged_on");
			$logged_on = false;
		}
	}
	if ($_GET['logout']) {
		setcookie("pg_logged_on");
		$logged_on = false;
	}
?>