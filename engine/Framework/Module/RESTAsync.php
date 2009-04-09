<?php

include_once "RESTLoginLib.php";

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

require_once('NodeManager.php');

/**
 * Framework_Module_Async
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @copyright   ARIS
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */

define('TYPE_NODE', 'Node');
define('TYPE_EVENT', 'Event');
define('TYPE_ITEM', 'Item');
define('TYPE_NPC', 'Npc');
define('TYPE_JS', 'JS');

/**
 * Framework_Module_Async
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_RESTAsync extends Framework_Auth_User
{
	public $controllers = array('JSON', 'Web');

	protected $events;
	protected $items;

    /**
     * __default
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
    	
    	$this->chromeless = true;
    	
		$this->links = $this->processLocationRequest();
	}
    
	
    public function displayList() {
    	$this->title = 'Things of Interest';
    	$this->things = $this->process();
    	$this->defaultModule = Framework::$site->config->aris->main->defaultModule;
    	$this->notificationText = 
    		Framework::$site->config->aris->async->notification;
    }
    
	protected function makeLink($type, $url, $label, $icon = null) {
		$item = array('type' => $type, 'url' => $url, 'label' => $label);
		$item['icon'] = (is_null($icon)) ? $this->findMedia("async{$type}.png",
			'defaultAsync.png') : $icon;
		return $item;
	}
    
    protected function processLocationRequest() {
	    if (isset($_REQUEST['latitude']) 
			&& isset($_REQUEST['longitude']) 
			&& isset($_SESSION['player_id']))
		{
			$session = Framework_Session::singleton();
			$session->latitude = $_REQUEST['latitude'];
			$session->longitude =$_REQUEST['longitude'];
			$session->last_location_timestamp = time();
			
			$sql = "UPDATE players
				SET latitude = '{$_REQUEST['latitude']}', longitude = '{$_REQUEST['longitude']}' 
				WHERE player_id = '{$_SESSION['player_id']}'";
			$this->db->exec($sql);

			$sql = $this->db->prefix("SELECT * FROM _P_locations 
				WHERE latitude < ({$_REQUEST['latitude']} + error) 
					AND latitude > ({$_REQUEST['latitude']} - error)
					AND longitude < ({$_REQUEST['longitude']} + error)
					AND longitude > ({$_REQUEST['longitude']} - error)"); 
			$locations = $this->db->getAll($sql);
			
			$sql = $this->db->prefix("SELECT event_id FROM _P_player_events WHERE player_id = 
				{$_SESSION['player_id']}");
			$this->events = $this->getPlayerEventsByIds($_SESSION['player_id']);
			$this->items = $this->getItemsByIds($_SESSION['player_id']);

			$links = array();
			foreach ($locations as $location) {
				$this->processLocation($location, $links);
			}
			return $links;
		}
		
		//return a blank array, not enough information to process
		return array();
    }
    
    protected function processLocation($location, &$links) {		
		//Check for required events
		if (array_key_exists('require_event_id', $location) 
			&& $location['require_event_id'] > 0)
		{
			if (!array_key_exists($location['require_event_id'], $this->events)) return;
		}
		if (array_key_exists('remove_if_event_id', $location)
			&& $location['remove_if_event_id'] > 0)
		{
			if (array_key_exists($location['remove_if_event_id'], $this->events)) return;
		}
		
		//Check if an event should be added
		if (array_key_exists($location['add_event_id'], $location)
			&& $location['add_event_id'] > 0
			&& !array_key_exists($location['add_event_id'], $this->events)) 
		{
			$this->addEvent($_SESSION['player_id'], $location['add_event_id']);
		}
		
		if ($location['type_id'] < 1) return;
    
		//Process based on type
    	switch($location['type']) {
    		case TYPE_NODE:
    			$this->processNode($location, $links);
    			break;
    		case TYPE_EVENT:
    			$this->processEvent($location);
    			break;
    		case TYPE_ITEM:
				$this->processItem($location, $links);
    			break;
    		case TYPE_NPC:
    			$this->processNpc($location, $links);
    			break;
    		default:
    			throw new Framework_Exception("Unknown location type: " . $location['type']);
    	}
    }
    
    protected function processNode($location, &$links) {
    	NodeManager::loadNode($location['type_id'], -1);

    	if (!is_null(NodeManager::$node)) {
    		$media = (array_key_exists('media', NodeManager::$node) 
    			&& !empty(NodeManager::$node['media']))
    				? $this->findMedia(NodeManager::$node['media'], 'defaultAsync.png') : null;
    		array_push($links, 
    			$this->makeLink(TYPE_NODE, "&amp;event=faceTalk&amp;npc_id=-1&amp;node_id=" 
    				. NodeManager::$node['node_id'], NodeManager::$node['title'], $media));
    	}
    }
    
    protected function processEvent($location) {
    	if (!array_key_exists($location['type_id'], $this->events)) {
			$this->addEvent($_SESSION['player_id'], $location['type_id']);
    		array_push($this->events, $location['type_id']);
    	}
    }
    
    protected function processItem($location, &$links) {
    	$sql = $this->db->prefix("SELECT * FROM _P_items 
    		WHERE item_id={$location['type_id']}");
    	$item = $this->db->getRow($sql);
    
    	$itemName = (array_key_exists('name', $item) && !empty($item['name']))
    		? $item['name'] : 'undefined';
    	$media = (array_key_exists('media', $item) 
    			&& !empty($item['media']))
    				? $this->findMedia($item['media'], 'defaultInventory.png') : null;
    
    	array_push($links, 
    		$this->makeLink(TYPE_ITEM, "&amp;event=addItem&amp;item_id={$location['type_id']}", 
    			$itemName, $media));
    }
    
    protected function processNpc($location, &$links) {
    	$sql = $this->db->prefix("SELECT * FROM _P_npcs 
    		WHERE npc_id={$location['type_id']}");
    	$npc = $this->db->getRow($sql);
    
    	$npcName = (array_key_exists('name', $npc) && !empty($npc['name']))
    		? $npc['name'] : 'undefined';
    	$npcMedia = (array_key_exists('media', $npc) && !empty($npc['media']))
    		? $this->findMedia($npc['media'], 'defaultUser.png') : null;
    
    	array_push($links, $this->makeLink(TYPE_NPC,
    		"&amp;event=faceConversation&amp;npc_id=" . $location['type_id'],
    		$npcName, $npcMedia));
    }

}

?>
