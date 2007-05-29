<? include("functions.php"); ?>
<?
	$safe_username = mysql_escape_string($_POST["username"]);
	$safe_password = mysql_escape_string($_POST["password"]);
	$new_user = mysql_escape_string($_POST["new_user"]);
	
	$error_message = false;
	
	if ($new_user) {
		$query = "SELECT * FROM users WHERE name='$safe_username'";
		$results = mysql_query($query);
		
		while ($row = mysql_fetch_assoc($results)) {
			$valid_user = 1;
			$password = $row['password'];
			if ($password == $safe_password) {$valid_password = 1;}
		}
		
		if ($valid_password) {
			# they've either already registered and forgotten about it or checked the "I'm a new user" box by mistake.
			login($safe_username);
		} elseif ($valid_user) {
			$error_message = "Sorry, that username already exists - could you pick another one?";
		} else {
			# create a new user with the given username and password
			$query = "INSERT INTO users (name, password) VALUES ('$safe_username', '$safe_password')";
			$results = mysql_query($query);
			login($safe_username, $safe_password); # go ahead and log the user in when done.
		}
	} elseif ($safe_username) {
		# check to see that the password matches the username.
		$query = "SELECT * FROM users WHERE name='$safe_username'";
		$results = mysql_query($query);

		$valid_user = 0;
		$valid_password = 0;
		$email = false;
		while ($row = mysql_fetch_assoc($results)) {
			$valid_user = 1;
			$password = $row['password'];
			if ($password == $safe_password) {$valid_password = 1;}
			$email = $row['email'];
		}
		
		if (!$valid_user) {
			# no such username exists
			$error_message = "Sorry, that username wasn't found in the database. Are you a new user? If so, simply check the 'I'm a new user' checkbox underneath the password box.";
		} elseif (!$valid_password) {
			$error_message = "Sorry, that's not the correct password.";
		} else {
			login($safe_username, $safe_password);
		}		
	}
?>
<? include("header.php"); ?>
<div class='content fullwidth'>
<?
	if ($error_message) {
		print "<div class='message'>";
		print $error_message;
		print "</div>";
	}
?>
<h1>Log in or Register</h1>
<p>If you already have a username and password for Postgenomic then enter them here.
<p>If you haven't already registered then enter your desired username and password and then check the "I'm a new user" checkbox.
<div class='loginform'>
<form action="login.php" method="POST">
<table width='100%' cellpadding='0' cellspacing='5'>
<tr><td width='120'>Username:</td><td><input class='textbox' type="text" name="username"/><br/>
</td></tr><tr><td>
Password:</td><td><input class='textbox' type="password" name="password"/>
</td></tr><tr><td colspan='2'>
<input class='textbox' type='checkbox' name="new_user">I'm a new user</input>
</td></tr><tr><td colspan='2'>
<input type='submit' value="Go"/>
</td></tr>
</table>
</form>
</div>
</div>
<? include("footer.php"); ?>