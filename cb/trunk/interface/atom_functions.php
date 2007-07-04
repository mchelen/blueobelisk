<?

function make_array_atom_safe($array) {
	$clean = array();
	foreach ($array as $key => $val) {
		$clean[$key] = make_var_atom_safe($val);
	}
	
	return $clean;
}

function make_var_atom_safe($var, $force_reduce = false) {
	$clean = "";
	if (($config['php_iconv']) && (!$force_reduce)) {
		$clean = iconv('', 'UTF-8', htmlentities(strip_tags($var)));
	} else {
		$clean = reduce_to_ascii(htmlentities(strip_tags($var)));
	}	
	return $clean;
}

function term_atom_entry($term, $details) {
	global $config;

	$link = $config['base_url'].linkto("posts.php", array(), array("term" => $term));
	$posts = implode(",", $details["posts"]);
	
	$return .= 
"
<entry>
	<title>$term</title>
	<link>$link</link>
	<content>$posts</content>
</entry>
";
	
	return $return;
}

function inchi_atom_entry($link) {
        global $config;

        $link = make_array_atom_safe($link);

        if (!$link['titles']) {$link['titles'] = substr($link['url'],0,64)."...";} else {$link['titles'] = ucfirst($link['titles']);}

        $posts = explode("|||", $link['post_titles']);

        foreach ($posts as $post) {
                $bits = explode("===", $post);
                $summary .= "<p> <a href='".$bits[1]."'>".$bits[0]."</a> from <a href='".slinkto("blog_search.php", $page_vars, array("blog_id" => $bits[5]))."'>".$bits[3]."</a>";
        }

        # don't strip html tags...
        $summary = reduce_to_ascii(htmlentities($summary));

        if ($link['name']) {
		$title = $link['name'];
        } else {
		$title = $link['inchi'];
        }

        $base_url = $_GET['base_url'];
        $return .= "
<entry>
        <title>".$title."</title>
        <link rel='alternate' href=\"".$base_url."inchi.php?id=".$link['cbid']."\"/>
        <id>".slinkto("link.php", array(), array("url_hash" => md5($link['inchi'])))."</id>
        <updated>".$link['added_on']."</updated>
        <content type='xhtml'><xh:div>";
 
        $return .= "The article <xh:i>".$link['title']."</xh:i> discusses: ".$link['inchi'].".";
        $return .= "<!-- CID: ".$link['cid']." --><xh:br />\n";
        $return .= "<xh:img src=\"".$base_url."images/compounds/".$link['cid'].".png\" />\n";
 
        $return .="</xh:div></content>";

        $pti = $_GET['path_to_interface'];
        $filename = $pti."images/compounds/".$link['cid'].".cml";
        if (file_exists($filename)) {
		# include($filename);
		$cml = "";
		exec("cat $filename",$cml);
		foreach($cml as $line) {
			$return .= $line;
		}
        }

        $return .= "
</entry>
";
        return $return;
}

function link_atom_entry($link) {
	global $config;
	
	$link = make_array_atom_safe($link);
	
	if (!$link['titles']) {$link['titles'] = substr($link['url'],0,64)."...";} else {$link['titles'] = ucfirst($link['titles']);}

	$posts = explode("|||", $link['post_titles']);

	foreach ($posts as $post) {
		$bits = explode("===", $post);
		$summary .= "<p> <a href='".$bits[1]."'>".$bits[0]."</a> from <a href='".slinkto("blog_search.php", $page_vars, array("blog_id" => $bits[5]))."'>".$bits[3]."</a>";
	}
	
	# don't strip html tags...
	$summary = reduce_to_ascii(htmlentities($summary));
	
	$return .= 
"
<entry>
	<title><![CDATA[".$link['page_title']."]]></title>
	<link rel='alternate' href=\"".$link['url']."\"/>
	<id>".slinkto("link.php", array(), array("url_hash" => md5($link['url'])))."</id>
	<updated>".$link['last_linked_on']."</updated>
	<content type='html'>$summary</content>
	<gd:rating value='".$link['linked_by']."' min='0' max='100'/>
</entry>
";
	return $return;
}



function atom_header($title = "Postgenomic API results", $type = "", $url = false) {
	global $config;
	if (!$url) {$url = $config['base_url'];}
	
	$id = $config['base_url']."-".md5($title);
	
	$updated = date("Y-m-d")."T".date("H:i:s")."Z";
	
	$title = make_var_atom_safe($title);
	
	return "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<feed xmlns=\"http://www.w3.org/2005/Atom\" xmlns:gd=\"http://schemas.google.com/g/2005\" xmlns:opensearch=\"http://a9.com/-/spec/opensearch/1.1/\" xmlns:xh=\"http://www.w3.org/1999/xhtml\">
		
<title>$title</title>
<link href='$url'/>
<updated>$updated</updated>
<author>
	<name>Republished content</name>
	<email>".$config['email']."</email>
	<uri>".$config['base_url']."</uri>
</author>
<link rel='alternate' type='text/html' href='$url'/>
<link rel='self' type='application/atom+xml' href='".$config['base_url']."atom.php?type=$type'/>
<id>$id</id>
";
}

function atom_footer() {
	return "</feed>";
}

function atom_date($timestamp) {
	$date = substr($timestamp,0,10);
	$time = substr($timestamp,11,8);
	
	return $date."T".$time."Z";
}

function paper_atom_entry($paper) {
		global $config;

		$summary = $paper['abstract'];

		if ($config['local_alternates']) {
			$paper['url'] = slinkto("paper.php", array(), array("paper_id" => $paper['paper_id']));
		}

		$paper = make_array_atom_safe($paper);
		$summary = make_var_atom_safe($summary);
		
		$return .= 
	"
	<entry>
		<title><![CDATA[".$paper['title']."]]></title>
		<author><name>".$paper['journal']."</name></author>
		<link rel='alternate' href=\"".$paper['url']."\"/>
		<id>".slinkto("paper.php", array(), array("paper_id" => $paper['paper_id']))."</id>
		<updated>".atom_date($paper['added_on'])."</updated>
		<summary><![CDATA[$summary]]></summary>
		<contributor>
			<name>".$paper['journal']."</name>
			<uri>".slinkto("journal_search.php", array(), array("journal_id" => $paper['journal']))."</uri>
		</contributor>
		<gd:rating value='".$paper['cited_by']."' min='0' max='100'/>
	</entry>
	";
		return $return;	
}

function post_atom_entry($post, $filters = array()) {
	global $config;
	
	$summary = $post['summary'];
	$summary .= "...";
	$summary = make_var_atom_safe($summary);
	$summary = sprintf("<![CDATA[%s]]>", $summary);
	
	if ($filters['fulltext']) {
		$flatfile = $GLOBALS['config']['path_to_pipeline'].$post['filename'];
		$xml = process_post_xml($flatfile, false);
		$summary = $xml['description'];
	}

	if ($config['local_alternates']) {
		$post['url'] = slinkto("post.php", array(), array("post_id" => $post['post_id']));
	}

	$post = make_array_atom_safe($post);
	
	$image = "";
	$default_image_pattern = "/default\.png/i";
	if (($post['blog_image']) && (!preg_match($default_image_pattern, $post['blog_image']))) {$image = sprintf("<link rel='related' title='portrait' type='%s' href='%s%s'/>", get_content_type($post['blog_image']), $config['base_url'], $post['blog_image']);}

	$geopt = "";
	if ($post['post_request_type'] == "conference") {
		# get geoterms for this post
		$tags = get_geotags_for_post($post['post_id']);
		
		if ($tags) {
			for ($i=0; $i < sizeof($tags); $i += 3) {
				$geopt .= sprintf("<gd:geoPt lat='%s' lng='%s' label='%s' />", $tags[$i], $tags[($i + 1)], make_var_atom_safe($tags[($i + 2)]));
			}
		}
	}
	
	$return .= 
"
<entry>
	<title><![CDATA[".$post['title']." (".$post['blog_name'].")]]></title>
	<author><name>".$post['blog_name']."</name></author>
	<link rel='alternate' href=\"".$post['url']."\"/>
	$image
	<id>".slinkto("post.php", array(), array("post_id" => $post['post_id']))."</id>
	<updated>".atom_date($post['added_on'])."</updated>
	<published>".atom_date($post['added_on'])."</published>
	<summary type='html'>$summary</summary>
	$geopt
	<contributor>
		<name>".$post['blog_name']."</name>
		<uri>".slinkto("blog_search.php", array(), array("blog_id" => $post['blog_id']))."</uri>
	</contributor>
	<gd:rating value='".$post['linked_by']."' min='0' max='100'/>
</entry>
";
	return $return;
}

function blog_atom_entry($blog) {
	global $config;
	
	$summary = $blog['description'];

	if ($config['local_alternates']) {
		$blog['url'] = slinkto("blog_search.php", array(), array("blog_id" => $blog['blog_id']));
	}
	
	$image = "";
	$default_image_pattern = "/default\.png/i";
	if (($blog['image']) && (!preg_match($default_image_pattern, $blog['image']))) {$image = sprintf("<link rel='related' title='portrait' type='%s' href='%s%s'/>", get_content_type($blog['image']), $config['base_url'], $blog['image']);}
	
	$summary = make_var_atom_safe($summary);
	$blog = make_array_atom_safe($blog);
	
	$return .= 
"
<entry>
	<title><![CDATA[".strip_tags($blog['title'])."]]></title>
	<link rel='alternate' href=\"".$blog['url']."\"/>
	$image
	<id>".slinkto("blog_search.php", array(), array("blog_id" => $blog['blog_id']))."</id>
	<updated>".atom_date($blog['added_on'])."</updated>
	<summary><![CDATA[$summary]]></summary>
	<gd:rating value='".$blog['incoming_bloglove']."' min='0' max='1000'/>
</entry>
";
	return $return;
}

?>
