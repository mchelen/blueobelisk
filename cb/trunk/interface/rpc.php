<?
	include("functions.php");
	
	// responds to AJAX requests. We need to check for valid cookies etc. here
	if ($logged_on) {
		$action = mysql_escape_string($_GET['action']);
		$obj = mysql_escape_string($_GET['obj']);
		$arg = mysql_escape_string($_GET['arg']);
		

		if ($action == 'tag_blog_custom') {
			$bits = explode(":", $obj);
			$blog_id = $bits[0];
			$tag = $arg;
			
			$id_tag_hash = md5($blog_id.$tag);
			$query = "INSERT INTO tags (id_tag_hash, blog_id, tag, tagged_by) VALUES ('$id_tag_hash', '$blog_id', '$tag', 'admin')";
			$results = mysql_query($query);		
		}
		
		if ($action == 'tag_blog') {
			$bits = explode(":", $obj);
			$blog_id = $bits[0];
			$tag = urldecode($bits[1]);
					
			if ($arg) {
				# add tag to blog
				$id_tag_hash = md5($blog_id.$tag);
				$query = "INSERT INTO tags (id_tag_hash, blog_id, tag, tagged_by) VALUES ('$id_tag_hash', '$blog_id', '$tag', 'admin')";
				$results = mysql_query($query);
			} else {
				# delete tag from blog
				$query = "DELETE FROM tags WHERE tag='$tag' AND blog_id='$blog_id'";
				$results = mysql_query($query);
			}
		}
	}
?>