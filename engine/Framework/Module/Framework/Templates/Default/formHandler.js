function postFormChanges(form) {

	var request = new XMLHttpRequest();
	request.open('POST', wwwBase + '/index.php?site=' + site + 
		'&module=' + '&controller=JSON&nodeID='
		+ queueId + '&npcID=' + npcID + userInput, true);
	request.setRequestHeader('Content-Type', 'application/x-javascript;');        	
	request.onreadystatechange = function() {
		if (request.readyState == 4 && request.status == 200) {
			// Extract the JSON object
			var data = eval('(' + request.responseText + ')');
			callback_getMessageQueue(data);
		}
	}
    request.send('');
    userInput = '';
}

function buildURL(form) {
	var URL = 'index.php?site=' . form.site.value
		. '&module=FormHandler&controller=JSON'
		. '&event=' . form.event.value
}