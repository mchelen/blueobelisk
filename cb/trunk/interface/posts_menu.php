<div class='title_submenu'>
<a <? if (!$_SAFE['tag']) {print "class='tab_selected'";} ?> href='<? $page_vars['tag'] = false; plinkto("posts.php", $page_vars); ?>'>All posts</a>
<a <? if ($_SAFE['tag'] == "review") {print "class='tab_selected'";} ?> href='<? plinkto("posts.php", $page_vars, array("tag" => "review")); ?>'>Reviews</a>
<a <? if ($_SAFE['tag'] == "conference") {print "class='tab_selected'";} ?> href='<? plinkto("posts.php", $page_vars, array("tag" => "conference")); ?>'>Conferences</a>
<a <? if ($_SAFE['tag'] == "original_research") {print "class='tab_selected'";} ?> href='<? plinkto("posts.php", $page_vars, array("tag" => "original_research")); ?>'>Research</a>
</div>