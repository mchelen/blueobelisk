<?
function find_connotea_users_with($tag, $limit = 10) {
	$query = "SELECT user, COUNT(*) AS count FROM connotea_cache WHERE tags LIKE '%$tag%' GROUP BY user ORDER BY count DESC LIMIT $limit";
	$results = mysql_query($query);
	
	$users = array();
	
	while ($row = mysql_fetch_assoc($results)) {
		$users[$row['user']] = 1;
	}
	
	return $users;
}

function connotea_get_tags_for_user($username) {
	global $config;
	
	$url = "http://www.connotea.org/data/tags/user/$username";
	
	$results = download_url($url, $config['connotea_username'], $config['connotea_password']);
	
	$matches = array();
	
	preg_match_all("/<rdf:value>(.*?)<\/rdf\:value>(?:.*?)<postCount>(\d+)<\/postCount>/si", $results, $matches);

	$tags = $matches[1];
	$counts = $matches[2];
	
	$return = array();
	
	for ($i=0; $i < sizeof($tags); $i++) {
		$return[mysql_escape_string($tags[$i])] = mysql_escape_string($counts[$i]);
	}
	
	return $return;
}
?>