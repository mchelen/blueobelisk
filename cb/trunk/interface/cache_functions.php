<?
function cache($id, $content) {
	global $config;
	
	if ($config['render_cache_to'] == "none") {return false;}	
	if ($config['render_cache_to'] == "db") {
		$content = mysql_escape_string($content);
		$query = "INSERT INTO render_cache (cache_id, contents) VALUES ('$id', '$content') ON DUPLICATE KEY UPDATE contents=VALUES(contents)";
		$results = mysql_query($query);	
	} else {
		$id = md5($id);
 		$file = fopen("render_cache/$id", "w");
		fwrite($file, $content, strlen($content));
		fclose($file);
	}
}

function remove_cache($id) {
	global $config;
		
	if ($config['render_cache_to'] == "none") {return false;}	
	if ($config['render_cache_to'] == "db") {
		$query = "DELETE FROM render_cache WHERE cache_id='$id'";
		$results = mysql_query($query);	
	} else {
		$id = md5($id);
		unlink("render_cache/$id");
	}
}

function get_cache($id) {
	global $config;

	$return = false;
	
	if ($config['render_cache_to'] == "none") {return false;}		
	if ($config['render_cache_to'] == "db") {
		$query = "SELECT contents FROM render_cache WHERE cache_id='$id'";
		$results = mysql_query($query);	
		while ($row = mysql_fetch_assoc($results)) {
			$return = $row['contents'];
		}
	} else {
		# look on disk
		$id = md5($id);
		if (is_readable("render_cache/$id")) {
			$return = file_get_contents("render_cache/$id");
		}
	}
	
	return $return;
}
?>