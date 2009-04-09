var rowID = 0;
var message;
var currentChar = 0;
var intervalObject;
var messageContainer;
var messageQueue = Array();
var messageNumber = -1;
var npcID;
var initialOptions = '';

var userInput = '';

function getMessageQueue(queueId) {
	if (userInput != '') {
		userInput = '&answer_string=' + URLEncode(userInput);
	}

	// Note the queueId is analagous to the nodeId
	var request = new XMLHttpRequest();
	request.open('GET', wwwBase + '/index.php?site=' + site + '&module=IMNode&controller=JSON&nodeID='
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

function callback_getMessageQueue(queue) {
    messageQueue = queue;
    messageNumber = -1;
    processCurrentMessage();
}

function processCurrentMessage() {
    messageNumber++;
    
    if (messageNumber < messageQueue['phrases'].length) {
        message = messageQueue['phrases'][messageNumber];
        if (message['isNPC']) setNPCMessage();
        else setTimeout(printPlayerMessage, message['delay']);
    } else if (messageQueue['requiresInput']) {
    	prepUserInput();
    } else if (messageQueue['options'].length > 0) {
        setTimeout(makeOptions, messageQueue['optionDelay']);
    }
}

function prepOptions(id, text) {
	select = document.getElementById('playerMessageSelection');
	select.innerHTML = select.innerHTML
		+ '<option value="' + id + '">' + text + "</option>\n";

	initialOptions = initialOptions 
		+ '<a href="#" onclick="parent.selectOption(' + "'" + id 
		+ "'" + ')">' + text + '</a><br/>';
		
	var opt = new Array();
	opt['queueId'] = id;
	opt['phrase'] = '<p class="PC">' + text + '</p>';
	messageQueue['options'].push(opt);
}

function postSelection() {
	select = document.getElementById('playerMessageSelection');
	if (select.selectedIndex == 0) return;
	
	/*
	if (window.iPhone) {
		window.iPhone.utils.hideURLBar();
	//	document.getElementById('footer').style.top = '220px';
	}
	*/

	selectOption(select.options[select.selectedIndex].value);
}

var startedOptions = false;
function startOptions() {
	if (startedOptions) return;
	
	startedOptions = true;
	document.getElementById('message').style.display = 'none';
	document.getElementById('playerMessageSendButton').style.display = 'none';
	document.getElementById('playerMessageSelection').style.display = 'inline';
	
	makeRow('right', '...', messageQueue['player_icon']);
}

function makeOptions() {
	document.getElementById('message').style.display = 'none';
	document.getElementById('playerMessageSendButton').style.display = 'none';

    var msg = '<option value="">Say...</option>';
    for (var i = 0; i < messageQueue['options'].length; i++) {
        option = messageQueue['options'][i];
        msg = msg + '<option value="' + option['queueId'] + '">'
        	+ option['phrase'] + '</option>';
    }
    document.getElementById('playerMessageSelection').innerHTML = msg;
    makeRow('right', '...', messageQueue['player_icon']);
	document.getElementById('playerMessageSelection').style.display = 'inline';
}    

function selectOption(queueId) {
    for (var i = 0; i < messageQueue['options'].length; i++) {
        if (queueId == messageQueue['options'][i]['queueId']) {
            setRowMessage('right', messageQueue['options'][i]['phrase'], messageQueue['player_icon']);
            break;
        }
    }
    document.getElementById('message').style.display = 'inline';
	document.getElementById('playerMessageSendButton').style.display = 'inline';
	document.getElementById('playerMessageSelection').style.display = 'none';
    getMessageQueue(queueId);
}

function prepUserInput() {
	messageContainer = document.getElementById('message');
	messageContainer.disabled = false;
	messageContainer.value = "Enter answer";
	messageContainer.focus();
	messageContainer.select();
	
	var msgButton = document.getElementById('playerMessageSendButton');
	msgButton.onclick = processUserInput;
	msgButton.disabled = false;
}

function processUserInput() {
	var msgButton = document.getElementById('playerMessageSendButton');
	msgButton.disabled = true;
	msgButton.onclick = playerMessageSendButton;
	
	messageContainer = document.getElementById('message');
	messageContainer.disabled = true;
	message['phrase'] = messageContainer.value;
	
	userInput = messageContainer.value;

	makeRow('right', userInput, messageQueue['player_icon']);
	document.getElementById('rawMessage').innerHTML = userInput;
	postPlayerMessage();
	getMessageQueue(messageQueue['id']);
}

function setNPCMessage() {
    makeRow('left', '...', messageQueue['npc_icon']);
    setTimeout(writeNPCMessage, message['delay']);
}

function writeNPCMessage() {
    setRowMessage('left', message['phrase'], messageQueue['npc_icon']);
    processCurrentMessage();
}

function printPlayerMessage() {
	messageContainer = document.getElementById("message");
	messageContainer.value = " ";
	
	makeRow('right', '...', messageQueue['player_icon']);
	
	intervalObject = setInterval(typeMessage, 75);
	currentChar = 0;
	document.getElementById('rawMessage').innerHTML = message['phrase'];
	message['phrase'] = message['phrase'].replace(/(<([^>]+)>)/ig, "");
}

function typeMessage() {
    if (currentChar < message['phrase'].length) {
		messageContainer.value = 
			message['phrase'].substring(0, ++currentChar);
	} else {
	    clearInterval(intervalObject);
        var button = document.getElementById("playerMessageSendButton");
        button.disabled = false;
	}
}

function postPlayerMessage() {
    var button = document.getElementById("playerMessageSendButton");
    button.disabled = true;
    
    var msg = document.getElementById('rawMessage').innerHTML;
    
    setRowMessage('right', /*message['phrase']*/ msg, 
	messageQueue['player_icon']);

    messageContainer.value = " ";
    processCurrentMessage();
}

var currentY = -150;
function makeRow(alignment, msg, icon_url) {
    rowID++;
    var container = document.getElementById('dialog');

    container.innerHTML = container.innerHTML +  '<tr><td align="' + alignment + '" id="r' + rowID + '">' + createIcon(alignment, icon_url) + msg + '</td></tr>';

    if (window.iPhone && rowID > 1) {
	scrollDown(rowID);
    }
    else document.getElementById("viewAnchor").scrollIntoView(true);
}

function scrollDown(rowID) {
	var y = getHeight(document.getElementById('r' + (rowID - 1)), true, true);
	scrollDownBy(y);
}
	
function scrollDownBy(y) {
	currentY = currentY + y;
	window.iPhone.utils.scrollToY(-currentY);
	//document.getElementById('header').style.top = '0';
	//document.getElementById('footer').style.top = '368px';
}

function setRowMessage(alignment, msg, icon_url) {
	var row = document.getElementById('r' + rowID);
	
	row.innerHTML = createIcon(alignment, icon_url) + msg;
}    

function createIcon(alignment, icon_url) {
    if (alignment == 'left') { padding = "right"; }
    else { padding = "left"; }
    return '<img alt="icon" width="48" src="' + icon_url +'" style="float:' + alignment +';padding-' + padding + ':5px;"/>';
}

function findPosY(obj) {
    var curtop = 0;
    if(obj.offsetParent)
        while(1)
        {
          curtop += obj.offsetTop;
          if(!obj.offsetParent)
            break;
          obj = obj.offsetParent;
        }
    else if(obj.y)
        curtop += obj.y;
    return curtop;
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////
// USED FOR GETTING THE COMPUTED HEIGHT OF AN ELEMENT IN PIXELS
///////////////////////////////////////////////////////////////////////////////////////////////////
var getHeight = function (/* Object */ el, /* boolean */ includePadding, /* boolean */ includeBorder) {
    var height;
    el = (typeof(el) === "string") ? document.getElementById(el) : el;
    
    if (document.defaultView && window.getComputedStyle) { /* FF, Safari, Opera and others */
        var style = document.defaultView.getComputedStyle(el, null);
        if (style.getPropertyValue("display") === "none")
            return 0;
        height = parseInt(style.getPropertyValue("height"));
        
        if (window.opera && !document.getElementsByClassName) {
            /* Opera 9.25 includes the padding and border when reporting the width/height - subtract that out */
            height -= parseInt(style.getPropertyValue("padding-top"));
            height -= parseInt(style.getPropertyValue("padding-bottom"));
            height -= parseInt(style.getPropertyValue("border-top-width"));
            height -= parseInt(style.getPropertyValue("border-bottom-width"));
        }
        
        if (includePadding) {
            height += parseInt(style.getPropertyValue("padding-top"));
            height += parseInt(style.getPropertyValue("padding-bottom"));
        }
        
        if (includeBorder) {
            height += parseInt(style.getPropertyValue("border-top-width"));
            height += parseInt(style.getPropertyValue("border-bottom-width"));
        }
    } else if (el.currentStyle) { /* IE and others */
        if (el.currentStyle["display"] === "none")
            return 0;
        var bRegex = /thin|medium|thick/; /* Regex for css border width keywords */
        height = el.offsetHeight; /* Currently the height including padding + border */
    
        if (!includeBorder) {
            var borderTopCSS = el.currentStyle["borderTopWidth"];
            var borderBottomCSS = el.currentStyle["borderBottomWidth"];
            var temp = document.createElement("DIV");
            if (el.offsetHeight > el.clientHeight && el.currentStyle["borderTopStyle"] !== "none") {
                if (!bRegex.test(borderTopCSS)) {
                    temp.style.width = borderTopCSS;
                    el.parentNode.appendChild(temp);
                    height -= temp.offsetWidth;
                    el.parentNode.removeChild(temp);
                } else if (bRegex.test(borderTopCSS)) {
                    temp.style.width = "10px";
                    temp.style.border = borderTopCSS + " " + el.currentStyle["borderTopStyle"] + " #000000";
                    el.parentNode.appendChild(temp);
                    height -= Math.round((temp.offsetWidth-10)/2);
                    el.parentNode.removeChild(temp);
                }
            }
            if (el.offsetHeight > el.clientHeight && el.currentStyle["borderBottomStyle"] !== "none") {
                if (!bRegex.test(borderBottomCSS)) {
                    temp.style.width = borderBottomCSS;
                    el.parentNode.appendChild(temp);
                    height -= temp.offsetWidth;
                    el.parentNode.removeChild(temp);
                } else if (bRegex.test(borderBottomCSS)) {
                    temp.style.width = "10px";
                    temp.style.border = borderBottomCSS + " " + el.currentStyle["borderBottomStyle"] + " #000000";
                    el.parentNode.appendChild(temp);
                    height -= Math.round((temp.offsetWidth-10)/2);
                    el.parentNode.removeChild(temp);
                }
            }
        }
    
        if (!includePadding) {
            var paddingTopCSS = el.currentStyle["paddingTop"];
            var paddingBottomCSS = el.currentStyle["paddingBottom"];
            var temp = document.createElement("DIV");
            temp.style.width = paddingTopCSS;
            el.parentNode.appendChild(temp);
            height -= temp.offsetWidth;
            temp.style.width = paddingBottomCSS;
            height -= temp.offsetWidth;
            el.parentNode.removeChild(temp);
        }
    }
    
    return height;
};
