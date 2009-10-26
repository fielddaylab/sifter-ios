<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_Main
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @copyright   Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */


class Framework_Module_Map extends Framework_Auth_User
{
    /**
     * __default
     * Displays a map, we didn't come here with a location to display
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
    	$site = Framework::$site;
    	$user = Framework_User::singleton();
		
		// Set up a marker for each location in the locations table
		$pointsString = '';
		$sql = Framework::$db->prefix("SELECT * FROM _P_locations 
									  LEFT OUTER JOIN _P_player_events ON 
									  _P_locations.require_event_id = _P_player_events.event_id
									  WHERE latitude != '' AND longitude != ''
									  AND (require_event_id IS NULL OR player_id = {$user->player_id})
									  AND (_P_locations.remove_if_event_id IS NULL 
									  OR _P_locations.remove_if_event_id NOT IN (SELECT event_id FROM _P_player_events WHERE player_id = {$user->player_id}))
									  AND hidden != '1'");
		$rows = Framework::$db->getAll($sql);
		$this->allLocations = $rows;
		
		//Set up all the markers
		foreach ($rows as $row) {
			if (isset($row['icon']) and strlen($row['icon'])>0) $icon = $site->getUriPath() . '/templates/' . $row['icon'];
			else  $icon = $site->getUriPath() . '/templates/' . $site->config->aris->map->defaultLocationIcon;
			
			$pointsString  .= "createMarker({$row['latitude']}, {$row['longitude']}, '{$row['name']}', '{$icon}');\n";
		}
		
		// Set up a player marker
		if (!$user->latitude or !$user->longitude) {
			$user->latitude = 1;
			$user->longitude = 1;
		}
			$playerIcon = $site->getUriPath() . '/templates/' . $site->config->aris->map->defaultPlayerIcon;
			$pointsString  .= "	// Create our player marker icon
								var playerIcon = new GIcon(G_DEFAULT_ICON);
								playerIcon.image = '{$playerIcon}';
								
								// Set up our GMarkerOptions object
								var playerMarkerOptions = { icon:playerIcon };
								var latlng = new GLatLng($user->latitude, $user->longitude);
								playerMarker = new GMarker(latlng, playerMarkerOptions);
								map.addOverlay(playerMarker);
								bounds.extend(playerMarker.getPoint());
								
								//Make the Callout
								GEvent.addListener(playerMarker,'click', function() {
									var myHtml = '<p>$user->user_name</p>';
									map.openInfoWindowHtml(latlng, myHtml);
								});";		
		
		
		
	
		
		$this->rawHead = '<script src="http://www.google.com/jsapi?key=' . $site->config->aris->map->googleKey . '"></script>
		<script type="text/javascript">
		google.load("maps", "2");
		var map;
		var bounds;
		var playerMarker;
							
		function createMarker(lat, lng, html, iconPath) {
			// Create our player marker icon
			var icon = new GIcon(G_DEFAULT_ICON);
			icon.image = iconPath;
		
			// Set up our GMarkerOptions object
			var markerOptions = { icon:icon };
			var latlng = new GLatLng(lat, lng);
			var marker = new GMarker(latlng,markerOptions);
		
			// Add it to the map
			map.addOverlay(marker);
		
			//Add it to the bounds (for auto scaling and centering)
			bounds.extend(marker.getPoint());
		
			//Make the Callout
			GEvent.addListener(marker,"click", function() {
						   map.openInfoWindowHtml(latlng, html);});	
		}
		
		function initialize() {
			map = new GMap2(document.getElementById("map_canvas"));
			map.addControl(new GSmallZoomControl());
			map.addControl(new GMapTypeControl());
			bounds = new GLatLngBounds();
			map.setCenter(new GLatLng(0,0),0);
			bounds = new GLatLngBounds();
									
			' . $pointsString . '
			map.setZoom(map.getBoundsZoomLevel(bounds) -1);
			map.setCenter(bounds.getCenter());
			return true;
		}
		</script>';
		
		$this->mapWidth = $site->config->aris->map->width;
		$this->mapHeight = $site->config->aris->map->height;
		$this->title = 'Current Location';
		$this->onLoad = 'initialize()';
		$this->loadLocationAdmin($user);
    }
    
    
    /**
     * Loads the administration apps for the default view.
     */
    protected function loadLocationAdmin($user) {
    	if ($user->authorization > 0) {
    		$applications = array();
    		$applications[] = array('directory' => 'Map',
    			'name' => 'New', 'event' => 'addLocation');
    			
    		$this->adminApplications = $applications;
    	}
    }
	
	
    public function addLocation() {
    	$site = Framework::$site;
		
    	$this->title = 'Add New Location';
    	$this->mediaFiles = $this->getSiteMediaFiles();
		
    	$this->requireEvents = $this->getEvents();
    	$this->removeEvents = $this->requireEvents;
    }
	
	
}//class
?>
