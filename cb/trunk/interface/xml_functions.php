<?
	function line_chart_xml() {
		ob_start();
		print "<chart_type>Line</chart_type>";
		print "<axis_category size='12' orientation='diagonal_down' skip='3' />";
		print "<axis_value size='12' orientation='diagonal_down' skip='3' />";
		print "<chart_value bold='false' position='cursor' background_color='000000' color='FFFFFF' />";
		print "<legend_label size='12' bold='false'/>";
		$xml = ob_get_contents();
		ob_end_clean();
		return $xml;	
	}
	
	function digits_to_month($digits) {
		$months["01"] = "Jan";
		$months["02"] = "Feb";
		$months["03"] = "Mar";
		$months["04"] = "Apr";
		$months["05"] = "May";
		$months["06"] = "Jun";
		$months["07"] = "Jul";
		$months["08"] = "Aug";
		$months["09"] = "Sep";
		$months["10"] = "Oct";
		$months["11"] = "Nov";
		$months["12"] = "Dec";		
		
		return $months[$digits];
	}
	
	function post_freq_xml($category = false) {
		$max_weeks_back = 32;
		
		ob_start();
		
		print "<chart>";
		
		print line_chart_xml();
		
		print "<chart_data>";
		
		# generate an XML file that'll graph out the posting frequency in a particular blog category.
		$query = "SELECT MAX(pubdate) AS pubdate, COUNT(DISTINCT post_id) AS count, CEIL(DATEDIFF(CURRENT_TIMESTAMP(), pubdate) / 7) AS datediff FROM posts_summary GROUP BY datediff";		
		$results = mysql_query($query);
		$data = array();
		$labels = array();
		while ($row = mysql_fetch_assoc($results)) {
			$count = $row['count'];
			$week = $row['datediff'];
			$pubdate = digits_to_month(substr($row['pubdate'], 5, 2));
			
			$labels[$week] = $pubdate;
			$data[$week] = $count;
		}
		
		$query = "SELECT COUNT(DISTINCT blog_id) AS count, CEIL(DATEDIFF(CURRENT_TIMESTAMP(), pubdate) / 7) AS datediff FROM posts_summary GROUP BY datediff";		
		$results = mysql_query($query);
		$blog_data = array();
		while ($row = mysql_fetch_assoc($results)) {
			$count = $row['count'];
			$week = $row['datediff'];
			$blog_data[$week] = $count;
		}
		
		# labels
		print "<row>";
		print "<null/>";
		for ($i=$max_weeks_back; $i >= 2; $i--) {
			print "<string>".$labels[$i]."</string>";
		}
		print "</row>";
				
		# posts 
		print "<row>";
		print "<string>Posts published per week</string>";
		for ($i=$max_weeks_back; $i >= 2; $i--) {
			if (!$data[$i]) {$data[$i] = 0;}
			print "<number>".$data[$i]."</number>";
		}
		print "</row>";
		
		# posts 
		print "<row>";
		print "<string>Blogs active per week</string>";
		for ($i=$max_weeks_back; $i >= 2; $i--) {
			if (!$blog_data[$i]) {$blog_data[$i] = 0;}
			print "<number>".$blog_data[$i]."</number>";
		}
		print "</row>";
				
		print "</chart_data>";
		print "</chart>";
		$xml = ob_get_contents();
		ob_end_clean();
		return $xml;
	}

?>