<?php

include_once "RESTLoginLib.php";
require_once('NodeManager.php');
	
/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_RESTQRCodeScanner
 *
 * The RESTQRScanner is much like the Async Module for GPS except it will be taking a QRID as an input and returning only one result 
 *
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @copyright   Joe Stump <joe@joestump.net>
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
 * Framework_Module_QRCodeScanner
 *
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_RESTQRScanner extends Framework_Auth_User
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
    	
		if (isset($_REQUEST['qrcode_id']))
		{
			$session = Framework_Session::singleton();
			$session->qrcode_id = $_REQUEST['qrcode_id'];
			
			$sql = $this->db->prefix("SELECT * FROM _P_qrcodes 
									 WHERE qrcode_id = {$session->qrcode_id}"); 
			$qrcode = $this->db->getRow($sql);
			
			$this->object = $this->processQRCode($qrcode);
		}
		else $this->object = '';
		
	}
	
    
	protected function makeLink($type, $url, $name, $icon = null) {
		$object = array('QRType' => $type, 'url' => $url, 'name' => $name);
		$object['icon'] = (is_null($icon)) ? $this->findMedia("async{$type}.png",
															'defaultAsync.png') : $icon;
	
		return $object;
	}	
    
    protected function processQRCode($qrcode) {		
		//Throw it out if it was not set in the qrcode table
		if ($qrcode['type_id'] < 1) return;
		
		//Process based on type
    	switch($qrcode['type']) {
    		case TYPE_NODE:
    			return $this->processNode($qrcode);
    			break;
    		case TYPE_EVENT:
    			return $this->processEvent($qrcode);
    			break;
    		case TYPE_ITEM:
				return $this->processItem($qrcode);
    			break;
    		case TYPE_NPC:
    			return $this->processNpc($qrcode);
    			break;
    		default:
    			throw new Framework_Exception("Unknown location type: " . $qrcode['type']);
    	}
    }
    
    protected function processNode($qrcode) {
		
		NodeManager::loadNode($qrcode['type_id'], -1);
    	if (!is_null(NodeManager::$node)) {
    		$media = (array_key_exists('media', NodeManager::$node) 
					  && !empty(NodeManager::$node['media']))
			? $this->findMedia(NodeManager::$node['media'], 'defaultAsync.png') : null;
    		return $this->makeLink(TYPE_NODE, "&amp;event=faceTalk&amp;npc_id=-1&amp;node_id=" 
									   . NodeManager::$node['node_id'], NodeManager::$node['title'], $media);
    	}
    }
    
    protected function processEvent($qrcode) {
    	if (!array_key_exists($qrcode['type_id'], $this->events)) {
			$this->addEvent($_SESSION['player_id'], $qrcode['type_id']);
    		return '';
    	}
    }
    
    protected function processItem($qrcode) {
		$sql = $this->db->prefix("SELECT * FROM _P_items 
								 WHERE item_id={$qrcode['type_id']}");
    	$item = $this->db->getRow($sql);
		$item['mediaURL'] = $this->findMedia($item['media'], 'defaultInventory.png');
		$item['icon'] = $this->findMedia(Framework::$site->config->aris->inventory->imageIcon, NULL);	
		$item['QRType'] = "Item";
    	
		return $item;
    }
    
    protected function processNpc($qrcode) {
    	$sql = $this->db->prefix("SELECT * FROM _P_npcs 
								 WHERE npc_id={$qrcode['type_id']}");
    	$npc = $this->db->getRow($sql);
		
    	$npcName = (array_key_exists('name', $npc) && !empty($npc['name']))
		? $npc['name'] : 'undefined';
    	$npcMedia = (array_key_exists('media', $npc) && !empty($npc['media']))
		? $this->findMedia($npc['media'], 'defaultUser.png') : null;
		
    	return $this->makeLink(TYPE_NPC,"&amp;event=faceConversation&amp;npc_id=" . $qrcode['type_id'],
										   $npcName, $npcMedia);
    }
	
}
	
?>
