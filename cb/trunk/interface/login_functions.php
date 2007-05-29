<?

function login($username, $password) {
	setcookie("pg_logged_on", $username."|PASS|".md5($password));
	header("Location: index.php");		
}

function validate_cookie($string) {
	$string = mysql_escape_string($string);
	
	$bits = explode("|PASS|", $string);
	$username = $bits[0];
	$hash = $bits[1];
	
	$roles = array();
	
	$query = "SELECT * FROM users LEFT JOIN roles ON users.user_id = roles.user_id WHERE name='$username' AND MD5(password)='$hash'";
	$results = mysql_query($query);

	$valid = false;
	while ($row = mysql_fetch_assoc($results)) {
		$valid = $row['name'];
		array_push($roles, $row['role']);
	}
	
	return array("username" => $valid, "roles" => $roles);
}

?>