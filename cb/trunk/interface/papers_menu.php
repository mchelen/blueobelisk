<div class='title_submenu'>
<a <? if (!$_SAFE['area']) {print "class='tab_selected'";} ?> href='<? $page_vars['tag'] = false; plinkto("papers.php", $page_vars); ?>'>Everything</a>
<a <? if ($_SAFE['area'] == "papers") {print "class='tab_selected'";} ?> href='<? plinkto("papers.php", $page_vars, array("area" => "papers")); ?>'>Papers</a>
<a <? if ($_SAFE['area'] == "books") {print "class='tab_selected'";} ?> href='<? plinkto("papers.php", $page_vars, array("area" => "books")); ?>'>Books</a>
</div>