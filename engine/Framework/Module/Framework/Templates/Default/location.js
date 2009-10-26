var number = 1;

function dirname(path) {
    return path.match( /.*\// )[0];
}

// From http://www.netlobo.com/url_query_string_javascript.html
function getUrlParam(name, from) {
	from = (from == null) ? window.location.href : from;

	name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	var regexS = "[\\?&]"+name+"=([^&#]*)";
	var regex = new RegExp( regexS );
	var results = regex.exec(from);
	if( results == null ) return "";
	else return results[1];
}

function update_location(lat, long) {
	update_location.site = update_location.site || getUrlParam('site');
	update_location.base = update_location.base || dirname(location.href);

	var request = new XMLHttpRequest();
	
	request.open('GET', 
		update_location.base + 'index.php?module=Async&controller=JSON&site='
			+ update_location.site + '&latitude=' + lat + '&longitude=' + long, true);        		
	request.setRequestHeader('Content-Type', 'application/x-javascript;');        	
	request.onreadystatechange = function() {
			if (request.readyState == 4 && request.status == 200) {
				update_map(lat, long);
				process_data(request.responseText);
			}
		}
	request.send();
}

function update_map(lat, long) {
	//Move playerMarker					  
	if (typeof playerMarker != 'undefined') playerMarker.setLatLng(new GLatLng(lat, long));
	//bounds.extend(playerMarker.getPoint());
	//map.setZoom(map.getBoundsZoomLevel(bounds)-1);
	//map.setCenter(bounds.getCenter());	
}

function process_data(text) {
	var result = eval('(' + text + ')');
	if (result['function'] == '') {
		clearNotify();
		return;
	}
	
	if (result['function'] == 'notify') {
		createNotify(result['icon'], result['url'], result['label']);
	}
	else if (result['isRawFunction']) {
		eval(result['function']);
	}
}

// Removes any notification icons
function clearNotify() {
	var n = document.getElementById('notify');
	if (n) n.innerHTML = '';
	
	var module = document.getElementById('asyncList');
	if (module) {
		// Go to the main site
		var url = window.location.href.substring(0,
			window.location.href.indexOf("&module"));
		window.location.href = url + '&module=' + module.innerHTML + "&notification=" 
			+ URLEncode(document.getElementById('notificationText').innerHTML);
	}
}

function createNotify(icon, url, label) {
	createNotify.id = createNotify.id || -1;

	// We're already here, so reload the page
	if (document.getElementById('asyncList')) return;
	
	var npcId = document.getElementById('npcId');
	if (npcId) {
		var newId = getUrlParam('npc_id', url);
		if (newId == npcId.innerHTML) {
			if (window.console) window.console.log(url + "\n\t" + newId + " == " + npcId.innerHTML);
			return;
		}
	}
	
	// Create an icon & link
	var n = document.getElementById('notify');
	if (n) {
		n.innerHTML = '<a id="bouncing" href="index.php?controller=Web&site='
			+ update_location.site + '&module=' + url 
			+ '" target="_self"><img src="' + icon + '" /><div></div></a>';
	}

	if (createNotify.id > 0) return;
	
	// bounce it
	var i = document.getElementById('notify');
	i.style.position = "relative";
	bounce.top = 0;
	bounce.dir = -1;
	bounce.angle = 0;
	bounce.rotDir = -1;
	
	createNotify.id = setInterval("bounce();", 65);
}

function bounce() {
	bounce.icon = bounce.icon || document.getElementById('notify');
	bounce.icon.style.top = bounce.top + "px";
	bounce.top = bounce.top + 2 * bounce.dir;
	
	if (bounce.top > 0 || bounce.top < -8) bounce.dir = -bounce.dir;
}

function URLEncode(clearString) {
	var output = '';
	var x = 0;
	clearString = clearString.toString();
	var regex = /(^[a-zA-Z0-9_.]*)/;
	while (x < clearString.length) {
		var match = regex.exec(clearString.substr(x));
		if (match != null && match.length > 1 && match[1] != '') {
			output += match[1];
			x += match[1].length;
		} else {
			if (clearString[x] == ' ')
				output += '+';
			else {
				var charCode = clearString.charCodeAt(x);
				var hexVal = charCode.toString(16);
				output += '%' + ( hexVal.length < 2 ? '0' : '' ) 
					+ hexVal.toUpperCase();
			}
			x++;
		}
	}
	return output;
}