<?
	header("Content-type: text/xml");
	include("config.php");
	global $config;

	print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
<ShortName>Postgenomic</ShortName>
<LongName>Postgenomic</LongName>
<Description>Use Postgenomic to search science blogs and the papers that they cite.</Description>
<Tags>postgenomic science blog aggregator pubmed paper academic</Tags>
<Contact><? print $config["email"]; ?></Contact>
<Url type="application/atom+xml" 
       template="<? print $config["base_url"]; ?>atom.php?type=search&amp;search={searchTerms}&amp;search_skip_os={startIndex?}&amp;search_page_os={startPage?}&amp;search_limit={count?}"/>
	<Url type="text/html" 
	       template="<? print $config["base_url"]; ?>search.php?search={searchTerms}"/>
</OpenSearchDescription>