<html>
<head>
	<style>
	.hotnotbox {
		width:  100px;
		float:  left;
		text-align: center;
	}
	
	</style>
</head>
<body>
<h2>Scienceblogger Hot or Not</h2>
<p>Who's hottest? You decide! (if it's just too difficult <a href='hotornot.php'>click here to refresh the images</a>)
<?
	# little bit of PHP to store some information in a text file.
	$vote = mysql_escape_string($_GET['vote']);
	if (is_numeric($vote)) {
		$scores = fopen("scores.txt", "a");
		$line = $vote."\t".$_SERVER['REMOTE_ADDR']."\n";
		fwrite($scores, $line);
		fclose($scores);
	}
?>
<script>
	var scores = new Array();
	var blogs = new Array();
	
	var running_total = 0;
	var running_count = 0;
<?
	# let's get some up to the minute stats while we're at it...
	$file = file_get_contents("scores.txt");
	$lines = preg_split('/[\r\n]/i', $file);
	
	$seen = array();
	$scores = array();
	
	foreach ($lines as $line) {
		$matches = array();
		preg_match("/(\d+)\t(.+)/i", $line, $matches);
		$blog_id = $matches[1];
		$ip = $matches[2];
	
		if (!$seen[$ip][$blog_id]) {
			$seen[$ip][$blog_id] = true;
			$scores[$blog_id]++;
		}
	}
	
	include("dbconnect.php");
	foreach ($scores as $key => $val) {
		printf("scores[%d] = %d\n", $key, $val);
		$query = "UPDATE blog_stats SET hotness=$val WHERE blog_id=$key";
		mysql_query($query);
	}
	
	# print an array of blog_ids ordered by score, too
	arsort($scores);

	$counter = 0;
	foreach ($scores as $key => $val) {
		printf("blogs[%d] = %d\n", $counter, $key);
		$counter++;
	}

?>
	function process_blogs(obj) {
		// get first portrait

		var first = get_image(obj, false);
		document.write('<div class=\"hotnotbox\"><h2>vs.</h2></div>');
		var second = get_image(obj, first);
		
		document.write("<div style='clear:both;'>&nbsp;</div>");
		print_scores(obj);

	}

	function print_scores(obj) {
		for (k=0; k < blogs.length; k++) {
			look_for = blogs[k];
			for (i=0; i < obj.length; i++) {
				blog_id = obj[i].blog_id;
				if (blog_id == look_for) {
					document.write('<div><a onclick=\"javascript:running_count++;running_total = (running_total + ' + scores[blog_id ]+ ');\"><img src=\"' + obj[i].image + '\"/></a> ' + scores[blog_id] + ' ' + obj[i].title + '</div>\n');
				}
			}
		
		}
	}
	
	function get_image(obj, ignore_index) {
		var rand = Math.floor(Math.random()*(obj.length))
		if (rand == ignore_index) {return get_image(obj, ignore_index);}
		
		var default_image_regexp = new RegExp("default\.png", "i");
		var match = default_image_regexp.exec(obj[rand].image);
		if (match) {return get_image(obj, ignore_index);}

		document.write('<div class=\"hotnotbox\">');
		document.write('<a href=\"hotornot.php?vote=' + obj[rand].blog_id + '\">');
		document.write('<img src=\"' + obj[rand].image + '\" alt=\"' + obj[rand].title + '\"/>');
		document.write('<br/><p>' + obj[rand].title);
		document.write('</a>');
		
		if (scores[obj[rand].blog_id]) {
			document.write("<p>Hotness: " + scores[obj[rand].blog_id]);
		} else {
			document.write("<p>Hotness: 0");
		}
		
		document.write('</div>');
		return rand;	
	}
	
</script>
<script type='text/javascript' src='http://neutron.nature.com/interface/api.php?format=JSON&type=blog&callback=process_blogs&limit=500'></script>
<input type='button' value='Reset running total' onclick='javascript:running_total=0;running_count=0;'/>
<input type='button' value='Display running total' onclick='javascript:alert(running_total + " " + running_count);'/>
</body>
</html>