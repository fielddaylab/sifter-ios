function Model()
{
    this.gameJSONText = '';
    this.gameData = {};
    this.backpacks = [];
	this.playerId = 0;  
	this.currentNote = new Object();
	this.currentNote.noteId = 0;
	this.audio_context = '';
  	this.recorder = '';

    //All notes in order they were received 
    this.notes = [];
    this.addNote = function(note)
    {
        this.notes[this.notes.length] = note;
    }
    //All notes (no order)
    this.mapNotes = [];
    this.mapMarkers = [];
	
    this.addMapNote = function(mapNote)
    {
    	console.log("adding map note");
        mapNote.geoloc = new google.maps.LatLng(mapNote.lat, mapNote.lon);
        this.mapNotes[this.mapNotes.length] = mapNote;
    }
    // GWS: some of the next couple of functions aren't currently used, but I left them in there in case we want them later
    //All notes ordered alphabetically by owner name
    this.contributorNotes = [];
    this.addContributorNote = function(contributorNote)
    {
        for(var i = 0; i < this.contributorNotes.length; i++)
        {
            if(this.contributorNotes[i].username.toLowerCase() >= contributorNote.username.toLowerCase())
            {
                this.contributorNotes.splice(i, 0, contributorNote);
                return;
            }
        }
        this.contributorNotes[this.contributorNotes.length] = contributorNote;
    }

    //All notes ordered alphabetically by first alphabetical tag
    this.tagNotes = [];
    this.addTagNote = function(tagNote)
    {
        for(var i = 0; i < this.tagNotes.length; i++)
        {
            if(this.tagNotes[i].tagString.toLowerCase() >= tagNote.tagString.toLowerCase())
            {
                this.tagNotes.splice(i, 0, tagNote);
                return;
            }
        }
        this.tagNotes[this.tagNotes.length] = tagNote;
    }

    //All notes ordered by total amount of likes on self/comments
    this.popularNotes = [];
    this.addPopularNote = function(popularNote)
    {
        for(var i = 0; i < this.popularNotes.length; i++)
        {
            if(this.popularNotes[i].popularity <= popularNote.popularity)
            {
                this.popularNotes.splice(i, 0, popularNote);
                return;
            }
        }
        this.popularNotes[this.popularNotes.length] = popularNote;
    }

    //List of all contributors to any note in game (whether owner of note or just comment) ordered alphabetically
    this.contributors = [];
    this.contributorMapCells = [];
    this.contributorListCells = [];
    this.addContributor = function(contributor)
    {
        for(var i = 0; i < this.contributors.length; i++)
        {
            if(this.contributors[i] == contributor) return;
            if(this.contributors[i].toLowerCase() > contributor.toLowerCase())
            {
                this.contributors.splice(i, 0, contributor);
                return;
            }
        }
        this.contributors[this.contributors.length] = contributor;
    }
    this.mapContributorSelected = function(contributor)
    {
        for(var i = 0; i < this.contributorMapCells.length; i++)
        {
            if(this.contributorMapCells[i].object == contributor)
                return this.contributorMapCells[i].selected;
        }
        return false;
    }
    this.listContributorSelected = function(contributor)
    {
        for(var i = 0; i < this.contributorListCells.length; i++)
        {
            if(this.contributorListCells[i].object == contributor)
                return this.contributorListCells[i].selected;
        }
        return false;
    }

    //List of all tags in any note in game ordered alphabetically 
    this.tags = [];
    this.tagMapCells = [];
    this.tagListCells = [];
    this.addTag = function(tag)
    {
        for(var i = 0; i < this.tags.length; i++)
        {
            if(this.tags[i] == tag) return;
            if(this.tags[i].toLowerCase() > tag.toLowerCase())
            {
                this.tags.splice(i, 0, tag);
                return;
            }
        }
        this.tags[this.tags.length] = tag;
    }
    this.mapTagsSelected = function(tags)
    {
        //n^2! oh noes!
        for(var i = 0; i < this.tagMapCells.length; i++)
        {
            for(var j = 0; j < tags.length; j++)
            {
                if(this.tagMapCells[i].object == tags[j].tag && this.tagMapCells[i].selected)
                    return true;
            }
        }
        return false;
    }
    this.listTagsSelected = function(tags)
    {
        //n^2! oh noes!
        for(var i = 0; i < this.tagListCells.length; i++)
        {
            for(var j = 0; j < tags.length; j++)
            {
                if(this.tagListCells[i].object == tags[j].tag && this.tagListCells[i].selected)
                    return true;
            }
        }
        return false;
    }

	this.numberOfNotesForTag = function(tag)
    {
		var notesForTag = 0;
		for(var i = 0; i < this.notes.length; i++)
        {
			if(!controller.filter(this.notes[i], document.getElementById("filterbox").value)) continue;
			for (var j = 0; j < this.notes[i].tags.length; j++) 
			{		
				if (this.notes[i].tags[j].tag.toLowerCase() == tag.toLowerCase()) {
					console.log("matching tag: " + tag.toLowerCase());
					notesForTag ++;
					
				}
				
			}
		}
        return notesForTag;
    }
	
	this.numberOfTotalNotes = function()
    {
		var notes = 0;
		for(var i = 0; i < this.notes.length; i++)
        {
			if(!controller.filter(this.notes[i], document.getElementById("filterbox").value)) continue;
			
			notes ++;		
		}
		
        return notes;
    }
	
	
	this.numberOfNotesForContributor = function(contributor)
    {
		var notesForContributor = 0;
		for(var i = 0; i < this.notes.length; i++)
        {
			
			if (this.notes[i].username.toLowerCase() == contributor.toLowerCase()) {
				if(controller.filter(this.notes[i], document.getElementById("filterbox").value))	
					notesForContributor ++;
			}
		}
        return notesForContributor;
    }
	
	this.getProfilePicForContributor = function(contributor)
    {
		var picURL = "";
		for(var i = 0; i < this.backpacks.length; i++)
        {
        	if(!this.backpacks[i].owner) console.log("PHIL BLAH" + this.backpacks[i]);
			if (contributor == null || this.backpacks[i].owner.user_name == null) {
				picURL = "./images/DefaultPCImage.png";
			}
			else if (this.backpacks[i].owner.user_name.toLowerCase() == contributor.toLowerCase())
				picURL = this.backpacks[i].owner.player_pic_url;
		}
		
		if (picURL == null)
			picURL = "./images/DefaultPCImage.png";
			
        return picURL;
    }


    this.views = new function Views()
    { 
        //Layouts
        //this.mapLayout = document.getElementById('map_layout');
        //this.listLayout = document.getElementById('list_layout');
                
		console.log("creating views");
          //Content
        this.mainView = document.getElementById('main_view');
        this.mainView.addEventListener('click', function(e) { e.stopPropagation(); });
        this.mainViewContainer = document.getElementById('main_view_container');
        this.mainViewLeft = document.getElementById('main_view_left');
        this.createNoteViewContainer = document.getElementById('create_note_view_container');
        this.noteViewContainer = document.getElementById('note_view_container');
        this.noteViewCloseButton = new ActionButton(document.getElementById('note_view_close_button'), controller.hideNoteView);
        this.createNoteViewCloseButton = new ActionButton(document.getElementById('create_note_view_close_button'), controller.hideCreateNoteView);
        this.loginViewCloseButton = new ActionButton(document.getElementById('login_view_close_button'), controller.hideLoginView);
        this.joinViewCloseButton = new ActionButton(document.getElementById('join_view_close_button'), controller.hideJoinView);
        this.loginViewContainer = document.getElementById('login_view_container');
        this.joinViewContainer = document.getElementById('join_view_container');
        this.constructNoteView = document.getElementById('note_view_construct');
		this.constructNoteCreateView = document.getElementById('note_create_view_construct');
		this.constructLoginView = document.getElementById('login_view_construct');
		this.constructJoinView = document.getElementById('join_view_construct');
        this.defaultNoteView = document.getElementById('note_view_default');
		this.defaultNoteCreateView = document.getElementById('note_create_view_default');
        this.noteView = new NoteView(this.defaultNoteView, null);
        console.log("done with content views");

        //Map
        this.map = document.getElementById('main_view_map');
        var centerLoc = new google.maps.LatLng(0, 0);
        var myOptions = { zoom:5, center:centerLoc, mapTypeId:google.maps.MapTypeId.ROADMAP };
        this.gmap = new google.maps.Map(this.map, myOptions);
        
        // setup info area
        document.getElementById('main_view_info').innerHTML = 'Tags:<br><input id="tag1" value="Innovation" type="checkbox" checked="checked" onchange="controller.repopulateAll()">Innovation</input><br><input id="tag2" value="Civil Disobedience" type="checkbox" checked="checked" onchange="controller.repopulateAll()">Civil Disobedience</input><br><input id="tag3" value="Stories of the Past" type="checkbox" checked="checked" onchange="controller.repopulateAll()">Stories of the Past</input><br><input id="tag4" value="Gratitudes" type="checkbox" checked="checked" onchange="controller.repopulateAll()">Gratitudes</input><br><input id="tag5" value="Culture" type="checkbox" checked="checked" onchange="controller.repopulateAll()">Culture</input><br><input id="tag6" value="Buckys List" type="checkbox" checked="checked" onchange="controller.repopulateAll()">Bucky\'s List</input><br><input id="tag7" value="Envisioning the Future" type="checkbox" checked="checked" onchange="controller.repopulateAll()">Envisioning the Future</input><br><br><span> Search: <input id="filterbox" type="text" onchange="controller.repopulateAll()"/></span><br><br><br><button onClick="JavaScript:controller.noteCreate()" class="button">Upload</button>';
		
		// marker clusterer
		var mcOptions = {styles: [{
			height: 53,
			url: "./images/speechBubble_cluster_large.png",
			width: 41,
			anchor:[15,17],
			fontFamily:"Helvetica, Arial"
			},
			{
			height: 53,
			url: "./images/speechBubble_cluster_large.png",
			width: 41,
			anchor:[15,13],
			fontFamily: "Helvetica, Arial"
			},
			{
			height: 53, 
			url: "./images/speechBubble_cluster_large.png",
			width: 41,
			anchor:[15,13],
			fontFamily: "Helvetica, Arial"
			},
			{
			height: 53,
			url: "./images/speechBubble_cluster_large.png",
			width: 41,
			anchor:[15,13],
			fontFamily: "Helvetica, Arial"
			},
			{
			height: 53,
			url: "./images/speechBubble_cluster_large.png",
			width: 41,
			anchor:[15,13],
			fontFamily: "Helvetica, Arial"
			}]};
		this.markerclusterer = new MarkerClusterer(this.gmap,[],mcOptions);
		this.markerclusterer.setMinimumClusterSize(3)
		
		console.log("done with creating views");
		
    };

    document.addEventListener('keydown', function(e) { if(e.keyIdentifier == 'Up' || e.keyIdentifier == 'Down') { controller.displayNextNote(e.keyIdentifier); e.stopPropagation(); e.preventDefault(); } }, false);
}
