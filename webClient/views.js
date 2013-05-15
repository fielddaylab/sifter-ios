function ActionButton(html, callback)
{
    /* 
     * Default Color: #DDDDDD; (light gray)
     * Hovered: Darken uniformly (-111111)
     * Selected: Set blue (|0000FF)
     */
    var self = this; // <- I hate javascript.
    this.hover = function()
    {
        self.hovered = true;
        if(self.selected) self.html.style.backgroundColor = '#CCCCFF';
        else self.html.style.backgroundColor = '#CCCCCC';
    };
    this.unhover = function()
    {
        self.hovered = false;
        if(self.selected) self.html.style.backgroundColor = '#DDDDFF';
        else self.html.style.backgroundColor = '#DDDDDD';
    };
    this.select = function()
    {
        self.selected = true;
        if(self.hovered) self.html.style.backgroundColor = '#CCCCFF';
        else self.html.style.backgroundColor = '#DDDDFF';
    };
    this.deselect = function()
    {
        self.selected = false;
        if(self.hovered) self.html.style.backgroundColor = '#CCCCCC'
        else self.html.style.backgroundColor = '#DDDDDD';
        self.callback(self);
    };
    this.hovered = false;
    this.selected = false;

    this.html = html;
    this.callback = callback;
    this.html.addEventListener('mouseover', this.hover, false);
    this.html.addEventListener('mouseout', this.unhover, false);
    this.html.addEventListener('mousedown', this.select, false);
    this.html.addEventListener('mouseup', this.deselect, false);
}

function ListNote(callback, object, noteId)
{
	var self = this; // <- I hate javascript.
	this.object = object;
	this.callback = callback;

    
	this.getImageHtml = function() {
	
		this.noteHtml = "";
		// get image from note
		this.noteImage = getImageToUse(object);
	
		// construct html with note image
		console.log(this.noteImage);
		if (this.noteImage != "") {
			this.noteHtml =  "<div id='item_note" + this.noteImage + "' class='item_note'><img id ='image" + noteId + "' src='" + this.noteImage + "' style='cursor:pointer;'/></div>";
  
			var refreshIntervalId;
			refreshIntervalId = setInterval(function () { 
				
	
				if (document.getElementById("image"+noteId) != null) {
					document.getElementById("image"+noteId).addEventListener("click", function() {console.log("clicked!: " + self); self.callback(self)});
					console.log("event listener added: " + "image"+noteId);
				}
				clearInterval(refreshIntervalId);
		
			}, 300);
		}
	
		return this.noteHtml;
	}
}

function NoteView(html, object)
{
    this.html = html;
    this.object = object;
    
    console.log("NoteView: " + object);

    this.constructHTML = function()
    {
        if(!this.object) return; 

        //Ok. This next bit of codes is going to look ridiculous... but since the DOM has no easy way of heirarchical access, its the best I can think of.
        //I recommend opening 'index.html' and finding the xml defining 'note_view_construct' (the DOM node cloned to be this.html) as reference (vim command ':sp index.html')
		var splitDateCreated = this.object.created.split(/[- :]/);
		var dateCreated = new Date(splitDateCreated[0], splitDateCreated[1]-1, splitDateCreated[2], splitDateCreated[3], splitDateCreated[4], splitDateCreated[5]);

		// Apply each element to the Date function


	 /*<div id='note_view_construct' class='note_view'>
        <div id='note_view_left_construct' class='note_view_left'></div>
        <div id='note_view_right_construct' class='note_view_right'>
            <div id='note_view_info_construct' class='note_view_info'></div>
            <div id='note_view_comments_construct' class='note_view_comments'></div>
            <div id='note_view_input_construct' class='note_view_input'></div>
        </div>
    </div>*/
    
    
    // assume (since we control the uploading) - make sure jacob follows this as well:
    	// 1st piece of content is caption
    	// 2nd piece of content is image
    	// 3rd piece of content is audio (optional)
    	// (can make it more robust later)
    	
    	console.log( this.html);
    	if (this.object.contents[1] != null)
       		 this.html.children[0].innerHTML = '<img class="note_media" style="width:500px;height:500px;" src="' + this.object.contents[1].media_url + '" />';
        if (this.object.contents[2] != null)
     	   this.html.children[1].children[0].innerHTML = 'Caption: ' + this.object.contents[0].text + '<br><br><br> Tags: ' + this.object.tagString + '<br><br><br>Audio:<br> <audio controls id="audio"><source src=' + this.object.contents[2].media_url + ' type="audio/mpeg"></audio>';
		this.html.children[1].children[1].innerHTML = 'Comments: ';
        this.html.children[1].children[2].innerHTML = '<br><br><textarea id="commentInput" rows="4" placeholder="add comment"></textarea><br><button id="commentSubmit" class="button" onclick="submitComment()">Submit</button><br><br><br>'; 
        this.html.children[1].children[2].innerHTML += this.object.likes + controller.getLikeIcon() + '    ' + this.object.comments.length + controller.getCommentIcon();   
    	this.loadComments();
    }
	
	this.loadComments = function() {
		console.log("loading comments");
	 	for(var i = 0; i < this.object.comments.length; i++)
            this.html.children[1].children[1].innerHTML += this.constructCommentHTML(this.object.comments[i]);
	}
	
	
	this.submitComment = function() {
	
		if (typeof model === "undefined") return;
		
		console.log("model.playerId : " + model.playerId );
		if (model.playerId > 0) {  
			console.log("noteId: " + model.currentNote.noteId);
			console.log("commentInput" + document.getElementById("commentInput").value);
	 		controller.addCommentToNote(model.currentNote.noteId, document.getElementById("commentInput").value, loadComments);
		} else {
			//controller.showLoginView(this.object);
		}
	}


    this.constructContentHTML = function(content)
    {
        var contentHTML = document.getElementById('note_content_cell_construct').cloneNode(true);
        contentHTML.setAttribute('id','');
        switch(content.type)
        {
            case 'TEXT':
                contentHTML.innerHTML = content.text;
                break;
            case 'PHOTO':
                contentHTML.innerHTML = '<img class="note_media" src="'+content.media_url+'" />';
                break;
            case 'AUDIO':
                //contentHTML.innerHTML = '<audio class="note_media" controls="controls"><source src="'+content.media_url+'" type="audio/mpeg"><a href="'+content.media_url+'">audio</a></audio>';
                contentHTML.innerHTML = '<a href="'+content.media_url+'">audio</a>';
                break;
            case 'VIDEO':
                contentHTML.innerHTML = '<video class="note_media" controls="controls"><source src="'+content.media_url+'"><a href="'+content.media_url+'">video</a></video>';
                break;
        }
        return contentHTML;
    };
    

    this.constructCommentHTML = function(comment)
    {
        var commentHTML = document.getElementById('note_comment_cell_construct').cloneNode(true);
        commentHTML.setAttribute('id','');
		var splitDateCreated = comment.created.split(/[- :]/);
		var dateCreated = new Date(splitDateCreated[0], splitDateCreated[1]-1, splitDateCreated[2], splitDateCreated[3], splitDateCreated[4], splitDateCreated[5]);
        commentHTML.children[0].innerHTML = '<br>' + comment.username + ' (' + dateCreated.toLocaleString() + '):';
        commentHTML.appendChild(this.constructContentHTML({"type":"TEXT","text":comment.title}));
        for(var i = 0; i < comment.contents.length; i++)
            commentHTML.appendChild(this.constructContentHTML(comment.contents[i]));
        return commentHTML;
    }

    this.constructHTML();
    if (document.getElementById("commentSubmit") != null) {
    	console.log("add event listener submit comment");
    	document.getElementById("commentSubmit").addEventListener("click", this.submitComment());
    }
}

  
function getLocation() {
	if (navigator.geolocation) {
		return navigator.geolocation.getCurrentPosition();
	} else {
		return "Geolocation is not supported by this browser.";
	}
}


function submitNote() 
{
	
	// check for required stuff
	

	// add location to note
	controller.updateNoteLocation(model.currentNote.noteId, model.currentNote.lat, model.currentNote.lon);
		
	// add text to note
	model.currentNote.text = document.getElementById("caption").value;
	if (model.currentNote.text != '')
		controller.addContentToNote(model.currentNote.noteId, 0, "TEXT", model.currentNote.text, '');
	
	// add image content
	if (model.currentNote.imageFile != null) {
		
		console.log ("Image file: " + model.currentNote.imageFile);
		
		var oMyForm = new FormData();
		oMyForm.append("file", model.currentNote.imageFile);
		oMyForm.append("path", model.gameId); // number 123456 is immediately converted to string "123456"
 		console.log("gameID: " + model.gameId);
 
		var oReq = new XMLHttpRequest();
		oReq.open("POST", "http://dev.arisgames.org/server/services/v1/uploadHandler.php");   // gws to do: make this link relative
		oReq.onreadystatechange = function ClientSideUpdate() {
            if (oReq.readyState == 4) 
             	model.currentNote.arisImageFileName = oReq.responseText;
             	console.log("arisImageFilename: " + model.currentNote.arisImageFileName);
             	console.log("model.currentNote.noteId: " + model.currentNote.noteId);
             	controller.addContentToNote(model.currentNote.noteId, model.currentNote.arisImageFileName, "PHOTO", '', '');
           };
		oReq.send(oMyForm);

	}
			
	
	// add tags
	if (document.getElementById("tag1").checked)
		controller.addTagToNote(model.currentNote.noteId, document.getElementById("tag1").value);
	if (document.getElementById("tag2").checked)
		controller.addTagToNote(model.currentNote.noteId, document.getElementById("tag2").value);
	if (document.getElementById("tag3").checked)
		controller.addTagToNote(model.currentNote.noteId, document.getElementById("tag3").value);
	if (document.getElementById("tag4").checked)
		controller.addTagToNote(model.currentNote.noteId, document.getElementById("tag4").value);
	if (document.getElementById("tag5").checked)
		controller.addTagToNote(model.currentNote.noteId, document.getElementById("tag5").value);
	if (document.getElementById("tag6").checked)
		controller.addTagToNote(model.currentNote.noteId, document.getElementById("tag6").value);
	if (document.getElementById("tag7").checked)
		controller.addTagToNote(model.currentNote.noteId, document.getElementById("tag7").value);

	// add audio content (optional)
	if (model.currentNote.audioFile != null) {
		
		
		var oMyForm = new FormData();
		console.log(model.currentNote.audioFile);
		oMyForm.append("file", model.currentNote.audioFile);
		oMyForm.append("path", model.gameId); // number 123456 is immediately converted to string "123456"
 
		var oReq = new XMLHttpRequest();
		oReq.open("POST", "http://dev.arisgames.org/server/services/v1/uploadHandler.php");  // gws to do: make this link relative
		oReq.onreadystatechange = function ClientSideUpdate() {
            if (oReq.readyState == 4) 
             	model.currentNote.arisAudioFileName = oReq.responseText;
             	controller.addContentToNote(model.currentNote.noteId, model.currentNote.arisAudioFileName, "AUDIO", '', '');
           };
		oReq.send(oMyForm);

	}
	
	// hide create note view
	controller.hideCreateNoteView();
	
}



function MapMarker(callback, object)
{
    var self = this; // <- I hate javascript.
    this.callback = callback;
    this.object = object;
	//this.marker = new google.maps.Marker({ position:this.object.geoloc, map:model.views.gmap, });  // won't need this eventually
	
	if (this.object.contents[0] == null)
		return;
			
	var imageMarker = new RichMarker({
          position: this.object.geoloc,
          map: model.views.gmap,
          draggable: false,
      	  content: constructMarker(this.object)
          });
		
	// setting shadow for square markers
	//imageMarker.setShadow('0px -3px 4px rgba(88,88,88,0.2)');
	
	// old way of doing it without using richmarker library
	/*var imageIcon = new google.maps.MarkerImage(
		this.object.contents[0].media_url,
		null, // size is determined at runtime 
		null, // origin is 0,0 
		null, // anchor is bottom center of the scaled image 
		new google.maps.Size(56, 75)
		);
	this.marker.setIcon(imageIcon);*/
   
   this.marker = imageMarker;
   model.views.markerclusterer.addMarker(this.marker);
   
   google.maps.event.addListener(this.marker, 'click', function(e) { self.callback(self); });
   
}

function constructMarker(note) {
	var html;
	var mediaURL = getMediaToUse(note);
	mediaType = mediaToUseType(note);
	var clip;
	var size;
	var height;
	var width;
	var left;
	var top;
	
	if (mediaType == "PHOTO") {
		clip = "rect(2px 30px 32px 2px)";
		size = "height='40' width='40'";
		position = "top:0;left:0;";
		height = 40;
		width = 30;
		top = 0;
		left = 0;
		
	} else
	{
		clip = "";
		size = "height = '25' width = '30'";
		position = "top:4;left:6;";
		height = 25;
		width = 20;
		top = 4;
		left = 6;
	}
	
	
	var image = new Image();
	var imageSource = getMediaToUse(note); //"./images/defaultImageIcon.png";
	image.onload = function() {
		//replaceMarkerImage(imageSource);	
	}
	image.src = imageSource;
	image.style.top = top;
	image.style.left = left;
	image.style.position = "absolute";
	image.style.clip = clip;
	image.height = height;
	image.width = width;
	
	var outerDiv = document.createElement('div'); 
	outerDiv.style.cursor = "pointer";
	/*var innerDiv = document.createElement('div'); 
	innerDiv.style.top = 1;
	innerDiv.style.left = 33;
	innerDiv.style.position = "absolute";
	innerDiv.innerHTML = getIconsForNoteContents(note);*/
	
	var speechBubble = new Image();
	speechBubble.src = './images/speechBubble2.png';
	speechBubble.height = 51;
	speechBubble.width = 32;
	
	outerDiv.appendChild(speechBubble);
	outerDiv.appendChild(image);
	//outerDiv.appendChild(innerDiv);
	
	html = outerDiv.outerHTML;
	
	//html  = "<div style=><img src='./images/speechBubble.png' height='51' width='43'/> " + image + " </div><div style='top:1;left:33; position:absolute' >" +   getIconsForNoteContents(note) +"</div>"	;
	
	return html;
}


function getMediaToUse(note) {
	var mediaURL = "";
	
	for (i = 0; i < note.contents.length; i++) {
		if (note.contents[i].type == "PHOTO")
			return note.contents[i].media_url;
	}

	if (note.contents[0].type == "TEXT")
		mediaURL = "./images/defaultTextIcon.png";
	else if (note.contents[0].type == "AUDIO")
		mediaURL = "./images/defaultAudioIcon.png";
	else if (note.contents[0].type == "VIDEO")
		mediaURL = "./images/defaultVideoIcon.png";
	
	return mediaURL;
}

function getImageToUse(note) {
	var mediaURL = "";
	
	for (i = 0; i < note.contents.length; i++) {
		if (note.contents[i].type == "PHOTO")
			mediaURL = note.contents[i].media_url;
	}
	
	return mediaURL;
}

function mediaToUseType(note) {
	
	for (i = 0; i < note.contents.length; i++) {
		if (note.contents[i].type == "PHOTO")
			return "PHOTO";
	}
	
	return note.contents[0].type;
}

function getIconsForNoteContents(note)
	{
		if (note.contents[0] == null)
			return "";
			
		var textCount = 0;
		var audioCount = 0;
		var videoCount = 0;
		var photoCount = 0;
		
		for (i = 0; i < note.contents.length; i++) {
	
			if (note.contents[i].type == "AUDIO")
				audioCount++;
			else if (note.contents[i].type == "VIDEO")
				videoCount++;
			else if (note.contents[i].type == "PHOTO")
				photoCount++;
			else  if (note.contents[i].type == "TEXT")
				textCount++;
		}
		
		var iconHTML = "";
		if (textCount > 0)
			iconHTML += '<img src="./images/defaultTextIcon.png" height=8px;><br>';
		if (audioCount > 0)
			iconHTML += '<img src="./images/defaultAudioIcon.png" height=8px;><br>';
		if (photoCount > 0)
			iconHTML += '<img src="./images/defaultImageIcon.png" height=8px;><br> ';
		if (videoCount > 0)
			iconHTML += '<img src="./images/defaultVideoIcon.png" height=8px;>';

		return iconHTML;
	};


function changeCheckBox(innerHTML, checked)
{
	
	var checkboxCheckedFilename = "checkbox.png";
	var checkboxUncheckedFilename = "checkboxUnchecked.png";
	var htmlCheckboxChecked = '<img src="./images/' + checkboxCheckedFilename + '" height="14px";>  ';
	var htmlCheckboxUnchecked = '<img src="./images/' + checkboxUncheckedFilename + '" height="14px";>  ';
	
	// clear out previous check box
	var checkBoxLoc = innerHTML.indexOf(checkboxCheckedFilename);
	if (checkBoxLoc >= 0) 
		innerHTML = innerHTML.substr(htmlCheckboxChecked.length+4, innerHTML.length);
	checkBoxLoc = innerHTML.indexOf(checkboxUncheckedFilename);
	if (checkBoxLoc >= 0) 
		innerHTML = innerHTML.substr(htmlCheckboxUnchecked.length+4, innerHTML.length);
	
	// insert new check box
	if (checked == true) 
		innerHTML = htmlCheckboxChecked + innerHTML;
	else
		innerHTML = htmlCheckboxUnchecked + innerHTML;
		
	return innerHTML;
}


this.playerPicForNote = function(username) 
{
	var picHTML = '  <img src="' + model.getProfilePicForContributor(username) + '"vertical-align:middle; height=40px;> ';
	return picHTML;
};


function handleImageFileSelect(files) {
		
	for (var i = 0; i < files.length; i++) {
		var file = files[i];
		var imageType = /image.*/;
		 
		if (!file.type.match(imageType)) {
		  continue;
		}
		 
		var img = document.getElementById("imageThumbnail");
		img.classList.add("obj");
		img.file = file;
		model.currentNote.imageFile = file;
		 
		var reader = new FileReader();
		reader.onload = (function(aImg) { return function(e) { 
			aImg.src = e.target.result; 
			model.currentNote.imageFileURL = e.target.result;
			}; 
		})(img);
		
		reader.readAsDataURL(file);	
		
		console.log
	}
}


function handleAudioFileSelect(files) {
		
	for (var i = 0; i < files.length; i++) {
		var file = files[i];
		var audioType = /audio.*/;

		if (!file.type.match(audioType)) {
		  continue;
		}
		
		// preview audio control
		var audioPreview = document.getElementById("audioPreview");
		audioPreview.src = URL.createObjectURL(file);
		model.currentNote.audioFile = file;
		
	}
}

function showVideo() {

	 var canvas = document.getElementById("canvas"),
		context = canvas.getContext("2d"),
		video = document.getElementById("video"),
		videoObj = { "video": true },
		errBack = function(error) {
			console.log("Video capture error: ", error.code); 
		};

 
 // Put video listeners into place
	if(navigator.getUserMedia) { // Standard
		navigator.getUserMedia(videoObj, function(stream) {
			video.src = stream;
			video.play();
		}, errBack);
	} else if(navigator.webkitGetUserMedia) { // WebKit-prefixed
		navigator.webkitGetUserMedia(videoObj, function(stream){
			video.src = window.webkitURL.createObjectURL(stream);
			video.play();
		}, errBack);
	}
	
	console.log("showing video");
	unhide("video");
	unhide("snap");
};

function recordAudio() {
	
	try {
      // webkit shim
      window.AudioContext = window.AudioContext || window.webkitAudioContext;
      navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia;
      window.URL = window.URL || window.webkitURL;
      
      model.audio_context = new AudioContext;
      console.log('Audio context set up.');
      console.log('navigator.getUserMedia ' + (navigator.getUserMedia ? 'available.' : 'not present!'));
    } catch (e) {
      alert('No web audio support in this browser!');
    }
    
    navigator.getUserMedia({audio: true}, startUserMedia, function(e) {
      console.log('No live audio input: ' + e);
    });
	
	unhide("startRecording");
	unhide("stopRecording");
	
};



function cancelNote() 
{
	console.log("cancel note called");
	// add location to note
	controller.deleteNote(model.currentNote.noteId);
	
	// hide create note view
	controller.hideCreateNoteView();
	
}

function markerMoved(marker, map){

        var point = marker.getPosition();
        map.panTo(point);
		//document.getElementById("latitude").innerHTML = "Latitude: " + point.lat();
		//document.getElementById("longitude").innerHTML = "Longitude: " + point.lng();
		document.getElementById("latitude").innerHTML = "";
		document.getElementById("longitude").innerHTML = "";
		
		console.log("lat:" + point.lat());
		console.log("lon:" + point.lng());

		var geocoder = new google.maps.Geocoder();

		geocoder.geocode({latLng: point}, function(results, status) {
			if (status == google.maps.GeocoderStatus.OK) {
				if (results[0]) {
					document.getElementById("address").innerHTML = "Approximate Address:<br> " + results[0].formatted_address;
					console.log("formatted_address:" + results[0].formatted_address);
				}
			}
		});
        model.currentNote.lat = point.lat();
		model.currentNote.lon = point.lng();

}

function handleNoGeolocation(errorFlag) {
	if (errorFlag) {
	  var content = 'Error: The Geolocation service failed.';
	} else {
	  var content = 'Error: Your browser doesn\'t support geolocation.';
	}
}


function dataURItoBlob(dataURI) {
    var binary = atob(dataURI.split(',')[1]);
    var array = [];
    for(var i = 0; i < binary.length; i++) {
        array.push(binary.charCodeAt(i));
    }
    return new Blob([new Uint8Array(array)], {type: 'image/jpeg'});
}

function unhide(div) {

	var item = document.getElementById(div);

    if (item) 
    {       
    	if (item.classList.contains('hidden'))
    		 item.classList.remove('hidden');
    	else
    		item.classList.add('hidden');
    }
 }

  // audio functionality currently doesn't work, but should based on HTML5 spec.
  // keep an eye on https://github.com/mattdiamond/Recorderjs for updates
  function startUserMedia(stream) {
    var input = model.audio_context.createMediaStreamSource(stream);
    console.log('Media stream created.');
    
    input.connect(model.audio_context.destination);
    console.log('Input connected to audio context destination.');
    
    model.recorder = new Recorder(input);
    console.log('Recorder initialised.');
  }

  function startRecording(button) {
    model.recorder && model.recorder.record();
    button.disabled = true;
    button.nextElementSibling.disabled = false;
    console.log('Recording...');
  }

  function stopRecording(button) {
    model.recorder && model.recorder.stop();
    button.disabled = true;
    button.previousElementSibling.disabled = false;
    console.log('Stopped recording.');
    
    // create WAV download link using audio data blob
    createDownloadLink();
    
    //model.recorder.clear();
  }

  function createDownloadLink() {
    model.recorder && model.recorder.exportWAV(function(blob) {
      var url = URL.createObjectURL(blob);
      var li = document.createElement('li');
      var au = document.createElement('audio');
      var hf = document.createElement('a');
      
      au.controls = true;
      au.src = url;
      hf.href = url;
      hf.download = new Date().toISOString() + '.wav';
      hf.innerHTML = hf.download;
      li.appendChild(au);
      li.appendChild(hf);
      recordingslist.appendChild(li);
    });
  }

function clickBrowseImage() {

	document.getElementById('imageFileInput').click();
}

function clickBrowseAudio() {
	document.getElementById('audioFileInput').click();
}


function clickLogin() {

	console.log("login clicked");
	var email = document.getElementById('usermail').value;
	var password = document.getElementById('password').value;
	console.log("email: " + email);
	console.log("password: " + password);
	
	controller.login(email, password);
}

function clickNoAccount() {
	controller.showJoinView();

}

function clickViewLoginPage() {
	controller.showLoginView();
}

function clickSignUp() {
	var email = document.getElementById('usermail').value;
	var password = document.getElementById('password').value;
	console.log("email: " + email);
	console.log("password: " + password);
	
	controller.createAccount(email, password);
}

function clickForgotPassword() {
	var email = document.getElementById('usermail').value;

	if (email != "") {
		controller.resetAndEmailPassword(email);
		alert("An email has been sent to you with instructions on how to reset your password.");
	} else {
		alert("Enter your e-mail above and click this link again for instructions on changing your password.");
	}
}

function LoginView(html)
{
	this.html = html;
	
	
	this.constructHTML = function()
    {
		console.log("LoginView html:" + html);
	
		/*<div id='login_view_construct' class='login_view'>
			<div id='login_view_top_construct' class='login_view_top'>Login</div>
			<div id='login_view_bottom_construct' class='login_view_bottom'></div>
		</div>*/

		this.html.children[0].innerHTML = '<br>To upload content, you must login.<br><br><button id="loginFacebook" class="button" onclick="clickLoginFacebook()">Login with Facebook</button><button id="loginGoogle" onclick="clickLoginGoogle()" class="button">Login with Google+</button><br><hr style="background:#F87431; border:0; height:7px" /><br><br>';
		this.html.children[1].innerHTML = '<ul><li><label for="usermail">Email</label> <input type="email" id="usermail" placeholder="yourname@email.com" required></li>  <li><label for="password">Password</label>  <input type="password" id="password" placeholder="password" required></li>  <li>  <button id="login" class="button" onclick="clickLogin()">Login</button></li>  </ul> <br> <span id="noAccount" onClick="clickNoAccount()" class="internalLink">Don\'t have an account?</span><br><span id="forgotPassword" onClick="clickForgotPassword()" class="internalLink">Forgot Password?</span>';
	}
	
	this.constructHTML();
}


function JoinView(html)
{
	this.html = html;
	
	this.constructHTML = function()
    {
		/*<div id='login_view_construct' class='login_view'>
			<div id='login_view_top_construct' class='login_view_top'>Login</div>
			<div id='login_view_bottom_construct' class='login_view_bottom'></div>
		</div>*/

		this.html.children[0].innerHTML = 'Join to contribute<br><br>connect with<br><button id="joinFacebook" class="button" onclick="clickLoginFacebook()">Facebook</button><button id="joinGoogle" onclick="clickJoinGoogle()" class="button">Google+</button><br><hr/><hr style="background:#F87431; border:0; height:7px" /><br>';
		this.html.children[1].innerHTML = 'OR sign up with your email address<br><ul><li><label for="usermail">Email</label> <input type="email" id="usermail" placeholder="yourname@email.com" required></li>  <li><label for="password">Password</label>  <input type="password" id="password" placeholder="password" required></li>  <li> <button id="signUp" class="button" onclick="clickSignUp()">Sign Up</button></li>  </ul> <br> Already have an account?<span id="viewLoginPage" onClick="clickViewLoginPage()" class="internalLink">Log in</a>';
	}		
	
	this.constructHTML();
}


function NoteCreateView(html)
{
    this.html = html;
    
    console.log("NoteCreateView");
    controller.createNewNote();
	
    this.constructHTML = function()
    {

        //Ok. This next bit of codes is going to look ridiculous... but since the DOM has no easy way of heirarchical access, its the best I can think of.
        //I recommend opening 'index.html' and finding the xml defining 'note_view_construct' (the DOM node cloned to be this.html) as reference (vim command ':sp index.html')
		
		// Apply each element to the Date function
		/*<div id='note_create_view_construct' class='note_create_view'>
			<div id='note_create_view_left_construct' class='note_create_view_left'>
				<div id='note_create_view_image_construct' class='note_create_view_image'>Image:</div>
				<div id='note_create_view_location_construct' class='note_create_view_location'>Location:</div>
			</div>
			<div id='note_create_view_right_construct' class='note_create_view_right'>
				<div id='note_create_view_caption_construct' class='note_create_view_caption'>Caption:</div>
				<div id='note_create_view_tagsaudio_construct' class='note_create_view_tagsaudio'>
					<div id='note_create_view_tags_construct' class='note_create_view_tags'>Tags:</div>
					<div id='note_create_view_audio_construct' class='note_create_view_audio'>Audio:</div>
				</div>
				<div id='note_create_view_submit_construct' class='note_create_view_submit'>Submit:</div>
			</div>
		</div>*/
		
        this.html.children[0].children[0].innerHTML = '<br>Image:<br><img width=300 height=300 id="imageThumbnail"><input type="file" id="imageFileInput" onchange="handleImageFileSelect(this.files)" style="visibility:hidden;position:absolute;top:-50;left:-50"/><button id="browseImage" class="button" onclick="clickBrowseImage()">Browse</button><button id="showCamera" onclick="showVideo()" class="button">Camera</button><video id="video" width="200" height="200" autoplay class="hidden"></video><button id="snap" class="button hidden">Snap Photo</button><div hidden><canvas id="canvas" width="200" height="200"></canvas></div>';
        this.html.children[0].children[1].innerHTML = '<br>Location:<br><div id="mapCanvas" style="width:300px;height:300px;border:1px solid black;"></div><br><input type="text" name="location" id="searchTextField" style="width:300px"><br><div id="latitude"></div><div id="longitude"></div><div id="address"></div><br><br>';
		this.html.children[1].children[0].innerHTML = '<br>Caption:<br><textarea id="caption" rows="8"></textarea><br><br>';
		this.html.children[1].children[1].children[0].innerHTML = 'Tags:<br><input id="tag1" value="Innovation" type="checkbox">Innovation</input><br><input id="tag2" value="Civil Disobedience" type="checkbox">Civil Disobedience</input><br><input id="tag3" value="Stories of the Past" type="checkbox">Stories of the Past</input><br><input id="tag4" value="Gratitudes" type="checkbox">Gratitudes</input><br><input id="tag5" value="Culture" type="checkbox">Culture</input><br><input id="tag6" value="Buckys List" type="checkbox">Bucky\'s List</input><br><input id="tag7" value="Envisioning the Future" type="checkbox">Envisioning the Future</input><br><br>';
        //this.html.children[1].children[1].children[1].innerHTML = 'Audio:<br><input type="file" id="audioFileInput" onchange="handleAudioFileSelect(this.files)" style="visibility:hidden;position:absolute;top:-50;left:-50"/><button id="browseAudio" class="button" onclick="clickBrowseAudio()">Browse</button><br><button id="recordAudio" onclick="recordAudio()" class="button">Record</button> <button class="hidden button" id="startRecording" onclick="startRecording(this);">start</button><button id="stopRecording" onclick="stopRecording(this);" class="hidden button" disabled>stop</button><div id="audioPreview"><br>Preview:<br><audio controls id="audioPreview"><source src="test.ogg" type="audio/ogg"><source type="audio/mpeg"></audio></div><br><br>';
		this.html.children[1].children[1].children[1].innerHTML = 'Audio:<br><button id="browseAudio" class="button" onclick="clickBrowseAudio()">Browse</button><br><input type="file" id="audioFileInput" onchange="handleAudioFileSelect(this.files)" class="hidden"><button id="recordAudio" onclick="recordAudio()" class="button">Record</button> <button class="hidden button" id="startRecording" onclick="startRecording(this);">start</button><button id="stopRecording" onclick="stopRecording(this);" class="hidden button" disabled>stop</button><br>Preview:<br><audio controls id="audioPreview"><source type="audio/ogg"><source type="audio/mpeg">Your browser does not support the audio element.</audio><br><br>';
		
		this.html.children[1].children[2].innerHTML = '<br><button id="submitNote" onclick="submitNote()" class="button">Submit</button><button id="cancelNote" onclick="cancelNote()" class="button">Cancel</button>';
		
		var refreshIntervalId;
		refreshIntervalId = setInterval(function () { updateTimer() }, 300);


	function updateTimer() 
	{
		clearInterval(refreshIntervalId);
 

		var map;
		var mapOptions = {
			  zoom: 12,
			  mapTypeId: google.maps.MapTypeId.ROADMAP
			};
   
		map = new google.maps.Map(document.getElementById('mapCanvas'), mapOptions);

			var marker = null;
			// Try HTML5 geolocation
			if(navigator.geolocation) {
			  navigator.geolocation.getCurrentPosition(function(position) {
				var pos = new google.maps.LatLng(position.coords.latitude,
												 position.coords.longitude);

				marker = new google.maps.Marker({ 
				  map: map,
				  position: pos,
				  draggable: true
				  });
			  
				 google.maps.event.addListener(marker, 'dragend', function() { markerMoved(marker, map); } );

				map.setCenter(pos);
				markerMoved(marker, map);
			  }, function() {
				handleNoGeolocation(true);
			  });
			} else {
			  // Browser doesn't support Geolocation
			  handleNoGeolocation(false);
			}
		
	  
		 var input = document.getElementById('searchTextField');
		 var autocomplete = new google.maps.places.Autocomplete(input);
 
		  autocomplete.bindTo('bounds', map);
 
 
		  google.maps.event.addListener(autocomplete, 'place_changed', function() {
	  
			var place = autocomplete.getPlace();
			if (place.geometry.viewport) {
			  map.fitBounds(place.geometry.viewport);
			} else {
			  map.setCenter(place.geometry.location);
			  map.setZoom(17);  // Why 17? Because it looks good.
			}
		
		
			marker.setPosition(place.geometry.location);
			markerMoved(marker, map);
		
 
			var address = '';
			if (place.address_components) {
			  address = [
				(place.address_components[0] &&
				 place.address_components[0].short_name || ''),
				(place.address_components[1] &&
				 place.address_components[1].short_name || ''),
				(place.address_components[2] &&
				 place.address_components[2].short_name || '')].join(' ');
			}
		});
    
    
		document.getElementById("snap").addEventListener("click", function() {
		
			console.log("snapPhoto");
			var canvas = document.getElementById("canvas");
			var	context = canvas.getContext("2d");
	
			video = document.getElementById("video");
			context.drawImage(video, 0, 0, 200, 200);
			var image = canvas.toDataURL('image/jpeg');
	
			var img = document.getElementById("imageThumbnail");
			img.src = image;
			console.log("image: " + image);
			model.currentNote.imageFile = dataURItoBlob(image); // it looks like there will eventually be a method canvas.toBlob() method for HTML5 but it is not implemented yet in most browsers as of April 2013
			console.log("imageFile: " + model.currentNote.imageFile);
			}, false );
	  
		}
   
        
    };
	

    this.constructContentHTML = function(content)
    {
        var contentHTML = document.getElementById('note_content_cell_construct').cloneNode(true);
        contentHTML.setAttribute('id','');
        switch(content.type)
        {
            case 'TEXT':
                contentHTML.innerHTML = content.text;
                break;
            case 'PHOTO':
                contentHTML.innerHTML = '<img class="note_media" src="'+content.media_url+'" />';
                break;
            case 'AUDIO':
                //contentHTML.innerHTML = '<audio class="note_media" controls="controls"><source src="'+content.media_url+'" type="audio/mpeg"><a href="'+content.media_url+'">audio</a></audio>';
                contentHTML.innerHTML = '<a href="'+content.media_url+'">audio</a>';
                break;
            case 'VIDEO':
                contentHTML.innerHTML = '<video class="note_media" controls="controls"><source src="'+content.media_url+'"><a href="'+content.media_url+'">video</a></video>';
                break;
        }
        return contentHTML;
    };

    this.constructCommentHTML = function(comment)
    {
        var commentHTML = document.getElementById('note_comment_cell_construct').cloneNode(true);
        commentHTML.setAttribute('id','');
		var splitDateCreated = comment.created.split(/[- :]/);
		var dateCreated = new Date(splitDateCreated[0], splitDateCreated[1]-1, splitDateCreated[2], splitDateCreated[3], splitDateCreated[4], splitDateCreated[5]);
        commentHTML.children[0].innerHTML = '<br>' + comment.username + ' (' + dateCreated.toLocaleString() + '):';
        commentHTML.appendChild(this.constructContentHTML({"type":"TEXT","text":comment.title}));
        for(var i = 0; i < comment.contents.length; i++)
            commentHTML.appendChild(this.constructContentHTML(comment.contents[i]));
        return commentHTML;
    }


    this.constructHTML();

}


