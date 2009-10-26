<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_Developer
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */

class Framework_Module_Developer extends Framework_Auth_User
{
    /**
     * __default
     *
     * Shows Developer tools
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
    	$site = Framework::$site;
    	$user = Framework_User::singleton();
    	
    	$this->title = $site->config->aris->developer->title;
    	$this->loadLocations();

	}
	
	protected function loadLocations() {
		$sql = $this->db->prefix("SELECT * FROM _P_locations");
		$locations = $this->db->getAll($sql);
		
		foreach ($locations as &$location) {
			$name = $location['name'];
			$latitude = $location['latitude'];
			$longitude = $location['longitude'];
		}
		unset($location);
		
		$this->locations = $locations;
	}

	//Clear out all events for this player
	protected function deleteAllEvents() {
		$this->title = Framework::$site->config->aris->developer->title;
		$player_id = $this->user->player_id;
		$sql = $this->db->prefix("DELETE FROM _P_player_events WHERE player_id = '$player_id'");
		$this->db->exec($sql);
		
		$this->__default();
		$this->tplFile = 'Developer.tpl';
		$this->message = 'Deleted all events.';
	}
	
	//Clear out all items for this player
	protected function deleteAllItems() {
		$this->title = Framework::$site->config->aris->developer->title;
		$player_id = $this->user->player_id;
		$sql = $this->db->prefix("DELETE FROM _P_player_items WHERE player_id = '$player_id'");
		$this->db->exec($sql);
		
		$this->__default();
		$this->tplFile = 'Developer.tpl';
		$this->message = 'Deleted all items.';
	}
	
}
?>
