<?php

include_once "RESTLoginLib.php";

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

require_once('NodeManager.php');

/**
 * Framework_Module_Main
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @copyright   Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */

/**
 * Framework_Module_NodeViewer
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @author 		David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_RESTNodeViewer extends Framework_Auth_User
{
    /**
     * __default
     *
     * This sets up the contact list.
     *
     * @access      public
     * @return      void
     */
    public function __default() {
    	
    	$user = loginUser();
    	
    	if(!$user) {
    		header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		die;
    	}
    	
    	$this->restUser = $user;
    	$this->chromeless = true;
    	
    	$this->title = sprintf(Framework::$site->config->aris->nodeViewer->title, 
    		$user['user_name']);
    	$this->company = Framework::$site->config->aris->company;
    	
    	$sql = Framework::$db->prefix("SELECT * FROM _P_npcs
			WHERE location_id = '0' 
				AND (require_event_id IS NULL or require_event_id IN 
					(SELECT event_id FROM _P_player_events 
						WHERE player_id = {$user['player_id']}))");
		$npcs = Framework::$db->getAll($sql);
		
		foreach ($npcs as &$npc) {
			if (!empty($npc['media'])) {
				$npc['media'] = $this->findMedia($npc['media'], 'defaultUser.png');
			}
		}
		unset($npc);
		
		$this->npcs = $npcs;
		$this->event = 'conversation';
		$this->username = $user['user_name'];
		$this->password = $user['password'];
    }
    
    /**
     * conversations
     *
     * List all of the conversations available for the given 
     * NPC and player.
     * 
     * @access		public
     * @return		void
     */
    public function conversation()
    {
		$user = loginUser();
    	
    	if(!$user) {
    		header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		die;
    	}
		
		$this->chromeless = true;
    	$session = Framework_Session::singleton();
		$user = $this->restUser;

    	$photo = $this->findMedia($user['photo'], 'defaultUser.png');
    	$site = Framework::$site->name;
    	
		NodeManager::loadNodeConversations($_REQUEST['npc_id']);
		$this->setVariables();
		$this->time = date('g:i a');
				
		$this->rawHead = <<<SCRIPT
   <script type="application/x-javascript">
   <!--
    var site = "$site";
    var wwwBase = "{$this->wwwBase}";
   	npcID = {$this->npc['npc_id']};
   	messageQueue['player_icon'] = "$photo";
   	messageQueue['options'] = new Array();
   //-->
   </script>
   
SCRIPT;
    	$this->scripts = array('im.js');
    }
    
    /**
     * Face to Face Initial Conversation
     */
    public function faceConversation() {
		$user = loginUser();
    	
    	if(!$user) {
    		header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		die;
    	}
		
		$this->chromeless = true;
    	$session = Framework_Session::singleton();
		//$user = $this->restUser;
		
		NodeManager::loadNodeConversations($_REQUEST['npc_id']);
		$this->setVariables();
		$this->username = $user['user_name'];
		$this->password = $user['password'];
    }
    
    /**
     * F2F Ongoing Conversation
     */
    public function faceTalk() {
		$user = loginUser();
    	
    	if(!$user) {
    		header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		die;
    	}
		
    	if (!isset($_REQUEST['node_id']) 
    		&& !isset($_REQUEST['question_node_id']))
    	{
    		// TODO: Change this to an appropriate exception.
    		throw new Framework_Exception('Communication terminated.', 
    			FRAMEWORK_ERROR_AUTH);
    	}
    	
		$this->chromeless = true;
		//$user = $this->restUser;
    	$session = Framework_Session::singleton();
    	$this->messages = array();
		
		NodeManager::loadNode($_REQUEST['node_id'], $_REQUEST['npc_id']);
		
		$this->setVariables();
		$npc = $this->npc;
		$this->username = $user['user_name'];
		$this->password = $user['password'];
		
		if (!empty($this->node['media'])) {
			$npc['media'] = $this->findMedia($this->node['media'], 
			$npc['media']);
			$this->npc = $npc;
		}
    }
    
    protected function setVariables() {
    	$this->conversations = NodeManager::$conversations;
    	// TODO: Is this needed?
		$this->wwwBase = FRAMEWORK_WWW_BASE_PATH;
		
    	$this->node = NodeManager::$node;
    	$npc = NodeManager::$npc;
    	if ($npc['npc_id'] > 0) $this->title = 'Chat with ' . $npc['name'];
    	else $this->title = $this->node['title'];

		if (!empty($npc['media'])) {
			$npc['media'] = $this->findMedia($npc['media'], 
				'defaultUser.png');
		}
		$this->npc = $npc;
    }
}

?>
