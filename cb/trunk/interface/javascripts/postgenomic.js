function createRequestObject() {
    var ro;
    var browser = navigator.appName;
    if(browser == "Microsoft Internet Explorer"){
        ro = new ActiveXObject("Microsoft.XMLHTTP");
    }else{
        ro = new XMLHttpRequest();
    }
    return ro;
}

var http = createRequestObject();

function sndReqArg(action, obj, arg) {
    http.open('get', 'rpc.php?action='+action+'&obj='+obj+'&arg='+arg);
    http.onreadystatechange = handleResponse;
    http.send(null);
}

function addCustomTag(obj) {
	var tag = obj.value;
	sndReqArg("tag_blog_custom", obj.id, tag);	
	obj.disabled=true;
}

function switchClass(obj) {
	var currentClass = obj.getAttribute('class');
	if (currentClass == 'tag_selected') {
		obj.setAttribute('class', 'tag_select');
		sndReqArg("tag_blog", obj.id, 0);	
	} else {
		obj.setAttribute('class', 'tag_selected');
		sndReqArg("tag_blog", obj.id, 1);
	}
}

function showHideDiv(the_div) {
	if (document.getElementById(the_div).style.display=='none') {
		new Effect.Appear(the_div, {duration: 0.5 });
	} else {
		new Effect.Fade(the_div, {duration: 0.5 });		
	}
}

function handleResponse() {
    if(http.readyState == 4){
        var response = http.responseText;

		if (!response) {
		
		} else {

    	}
	}
}

function start_slideshow(start_frame, end_frame, delay) {
    setTimeout(switch_slides(start_frame,start_frame,end_frame, delay), delay);
}

function switch_slides(frame, start_frame, end_frame, delay) {
    return (function() {
        Effect.Fade('slideshow' + frame);
        if (frame == end_frame) { frame = start_frame; } else { frame = frame + 1; }
        setTimeout("Effect.Appear('slideshow" + frame + "');", 1000);
        setTimeout(switch_slides(frame, start_frame, end_frame, delay), delay + 750);
    })
}