<html>
<body>
<? require_once('magpierss/rss_fetch.inc'); ?>
<?
	# localhost/interface
	# $key = "ABQIAAAAJ44sG0vEGRZek8xL4FKnzRQKK-E0OnXjJkHgP4noyXmw63CBXhQIuqpEUkQ_kk6BJNml36Fvc84j0g";
	
	# neutron.nature.com/interface
	$key = "ABQIAAAAJ44sG0vEGRZek8xL4FKnzRRHKpWlcGeLGgH6nHj3nVDnHYiPLRSwF6IyZVmlQCSaaNaUapnKt_6w3A";
?>
<div id="map" style="width: 750px; height: 500px;"></div>
    <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=<? print $key; ?>"
      type="text/javascript"></script>
    <script type="text/javascript">

    //<![CDATA[
	// Creates a marker at the given point with the given number label
	function createMarker(point, text) {
	  var marker = new GMarker(point);
	  GEvent.addListener(marker, "click", function() {
	    marker.openInfoWindowHtml(text);
	  });
	  return marker;
	}


    function load() {
      if (GBrowserIsCompatible()) {
        var map = new GMap2(document.getElementById("map"));
        map.setCenter(new GLatLng(37.4419, -122.1419), 2);
		map.addControl(new GSmallMapControl());
<?
	# note: you need Magpie 0.8+ to do this, as previous versions wont pick up different namespaces
	# the plain old atom feed will do
	$url = "http://neutron.nature.com/interface/atom.php?category=&type=latest_posts&tag=conference";
	$rss = fetch_rss($url);

	if ($rss->items) {
		foreach ($rss->items as $item) {
			$contributor = $item['contributor'];

			if ($item['gd']) {
				$gd = $item['gd'];
				if ($gd['geopt@lat']) {
					$number = $gd['geopt#'];

					for ($i=1; $i <= $number; $i++) {
						$iterator = $i;
						if ($i > 1) {$iterator = "#".$i;} else {$iterator = "";}
						$geopt = "geopt".$iterator;
						printf("var point = new GLatLng(%s, %s);\n", $gd[$geopt.'@lat'], $gd[$geopt.'@lng']);
						printf("map.addOverlay(createMarker(point, '<div style=\"width: 180px;\"><b>%s</b><br/><i>%s</i><br/><i>%s</i><br/><a href=\"%s\">read post</a></div>'));\n", addslashes($item['title']), addslashes($contributor), addslashes($gd[$geopt.'@label']), $item['link']);	
					}
				}
			}
		}
	} else {
		print "// Couldn't load RSS feed\n";
	}
		?>
      }
    }
	
	load();
    //]]>
    </script>
</body>
</html>