</div>
<?
	if ($config['use_urchin']) {
?>
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "<? if ($config['urchin_code']) {print $config['urchin_code'];} else {print "UA-54928-6";} ?>";
urchinTracker();
</script>
<?
	}
?>
<div class='footer' style='clear: both; margin-top: 20px;'>
<? print $config['copyright_notice']; ?>
</div>
</body>
</html>
<?
	# if caching was switched on then save the page we just generated.
	if ($PAGE_CACHE) {
		$page = ob_get_contents();
		ob_end_flush(); flush();
		
		# put cached page in database
		cache($PAGE_URL, $page);
	}
?>