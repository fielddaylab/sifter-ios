<?php

include_once "RESTLoginLib.php";

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_Developer
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */

class Framework_Module_RESTDeveloper extends Framework_Auth_User
{
    /**
     * __default
     *
     * Shows Developer tools
     *
     * @access      public
     * @return      mixed
     */
    public function __default() {
    	$this->pageTemplateFile = 'empty.tpl';
		
		$user = loginUser();
    	
    	if(!$user) {
    		header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		die;
    	}
    	
    	$site = Framework::$site;
    	$this->chromeless = true;
		
	}

	//Clear out all events for this player
	protected function deleteAllEvents() {
		$user = loginUser();
		
		$this->title = Framework::$site->config->aris->developer->title;
		$player_id = $user['player_id'];
		$sql = $this->db->prefix("DELETE FROM _P_player_events WHERE player_id = '$player_id'");
		$this->db->exec($sql);
		
		$this->__default();
		$this->tplFile = 'RESTDeveloper.tpl';
		$this->message = 'Deleted all events.';
	}
	
	//Clear out all items for this player
	protected function deleteAllItems() {
		$user = loginUser();
		
		$this->title = Framework::$site->config->aris->developer->title;
		$player_id = $user['player_id'];
		$sql = $this->db->prefix("DELETE FROM _P_player_items WHERE player_id = '$player_id'");
		$this->db->exec($sql);
		
		$this->__default();
		$this->tplFile = 'RESTDeveloper.tpl';
		$this->message = 'Deleted all items.';
	}
	
}
?>
