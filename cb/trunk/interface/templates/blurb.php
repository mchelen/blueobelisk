<?
	$blurb["frontpage"] = sprintf("
<h1>Welcome to Chemical blogspace</h1>
<p>Chemical blogspace collects data from tens of scientific chemistry blogs and then does useful and interesting things with it.
<p>With Chemical blogspace, you can:
<ul>
<li>Find, read and subscribe to new <a href='%s'>science blogs</a>
<li>Find out what scientists are saying about the latest <a href='%s'>books</a> and <a href='%s'>papers</a>
<li>Read <a href='%s'>mini-reviews</a>, <a href='%s'>conference reports</a> or even <a href='%s'>original research</a>	
<li>See the buzz surrounding <a href='%s'>different websites</a>
<li>Browse different subject areas - <a href='%s'>chemoinformatics</a>, <a href='%s'>organic chemistry</a>, ... see the 'Explore' options on the top right hand side of the page for more.
</ul>
<p>Chemical blogspace was created by the Research Group for Molecular
Informatics at the CUBIC in Cologne, and powered by the 
<a href='http://postgenomic.com/'>PostGenomic.com</a> software by 
Euan Adie. It is now hosted by OpenMolecules.net, courtesy of 
<a href='http://geoffhutchison.net/'>Geoff Hutchison</a> and the 
<a href='http://www.chem.pitt.edu/'>University of Pittsburgh</a>.",
linkto("blogs.php", $page_vars),
linkto("papers.php", $page_vars, array("area" => "books")),
linkto("papers.php", $page_vars),
linkto("posts.php", $page_vars, array("tag" => "review")),
linkto("posts.php", $page_vars, array("tag" => "conference")),
linkto("posts.php", $page_vars, array("tag" => "original_research")),
linkto("links.php", $page_vars),
linkto("index.php", $page_vars, array("category" => "Chemoinformatics")),
linkto("index.php", $page_vars, array("category" => "Organic Chemistry"))
);

?>
