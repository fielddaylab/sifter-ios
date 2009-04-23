<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * RESTNodeManager
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */

/**
 * RESTNodeManager
 *
 * Encapsulates all node loading, requirements, etc.
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @author 		David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */
class RESTNodeManager
{
	/** 
	 * $node
     * 
     * @access public
     * @var object $module The fully-processed node object
     * @static
	 */
	static public $node = null;
	static public $npc = null;
	static public $conversations = null;
	static public $messages = array();

	static public function loadNode($nodeID, $npcID = 0) {
		
		$user = loginUser();
		$userID = $user['player_id'];
		
		//Load the NPC
		$sql = Framework::$db->prefix("SELECT * FROM _P_npcs WHERE npc_id = '$npcID'");
    	self::$npc = Framework::$db->getRow($sql);

		
		//echo 'Manager: Begin loading node: ' . $nodeID . '<br/>';
		//echo 'User Data:<br/>';
		//var_dump ($user);
		
		if (!empty($_REQUEST['answer_string'])) {
			$nodeID = self::checkQuestionNode($nodeID);
		}
	
		$sql = Framework::$db->prefix("SELECT * FROM _P_nodes 
			WHERE node_id = '$nodeID'");
    	
		//echo '<p>Manager: DB Call to fetch row begin:</p>';
		
		$row = Framework::$db->getRow($sql);
		
    	if (!$row) {
    		// TODO: Change this to an appropriate exception.
			throw new Framework_Exception('Communication disrupted.', 
	    		FRAMEWORK_ERROR_AUTH);
    	}


    	self::$node = $row;
		
		//echo '<p>Manager: self::$node set. Here is the data:</p>';
		//var_dump(self::$node);

		
		if (self::$node['require_item_id'] > 0) {
	    	self::checkRequiredItem($userID, self::$node['require_item_id'],
	    		self::$node['required_condition_not_met_node_id'], $npcID);
		}
		
		if (self::$node['require_event_id'] > 0) {
	    	self::checkRequiredEvent($userID, self::$node['require_event_id'],
				self::$node['required_condition_not_met_node_id'], $npcID);
		}

    	if (self::$node['add_item_id']) {
    		self::addItem($userID, self::$node['add_item_id']);
    	}

    	if (self::$node['remove_item_id']) {
    		self::removeItem($userID, self::$node['remove_item_id']);
    	}

    	if (self::$node['add_event_id']) {
			Framework_Module::addEvent($userID, self::$node['add_event_id']);
    	}
		
		if (self::$node['remove_event_id']) {
			Framework_Module::removePlayerEvent($userID, self::$node['remove_event_id']);
    	}

       	// TODO: Check for a remove event_id

		//echo '<p>Manager: Checking for empty req answer and options</p>';

		// NOTE: calling methods should check for 'require_answer_string' 
		// to handle input
    	
		if (empty(self::$node['require_answer_string'])) {
    		if ((!empty(self::$node['opt1_text']) && !empty(self::$node['opt1_node_id']))
    			|| (!empty(self::$node['opt2_text']) && !empty(self::$node['opt2_node_id']))
    			|| (!empty(self::$node['opt3_text']) && !empty(self::$node['opt3_node_id']))) { 
					self::loadOptions($npcID); 
			}
    		
    		if ($npcID > 0 && is_null(self::$conversations)) {
    			//echo '<p>Manager: loadNodeConversations for NPC: '. $npcID . '</p>';
				self::loadNodeConversations($npcID);
				
    		}
    	}
		
		//echo 'Maager: Ending LoadNode(). Self Node Data:<br/>';
		//var_dump(self::$node);
	}
	
	/**
     * Returns the correct question-result node or the REQUEST node
     * if not a question.
     *
     * @returns int
     */
    static protected function checkQuestionNode($nodeID) {
   		$sql = Framework::$db->prefix("SELECT * FROM _P_nodes 
   			WHERE node_id='$nodeID'");
    	$row = Framework::$db->getRow($sql);
    		
		if (!$row) {
			// TODO: Change this to an appropriate exception.
			throw new Framework_Exception('Communication terminated.', 
    			FRAMEWORK_ERROR_AUTH);
    	}
    		
    	if (strtolower(trim($_REQUEST['answer_string']))
    		== strtolower($row['require_answer_string']))
    	{
    		// Correct answer
    		$nodeID = $row['require_answer_correct_node_id'];
    	}
		else { 
			// Incorrect answer
			$nodeID = $row['required_condition_not_met_node_id'];
   		}
    	
    	return $nodeID;
    }
    
    /**
     * Checks if the player owns this item.
     */
    static protected function checkRequiredItem($userID, $itemID, $notFoundNodeID, $npcID) {
		//echo 'Manager: begin req item test<br/>';
		
		$sql = Framework::$db->prefix("SELECT * FROM _P_player_items 
			WHERE player_id = '$userID' 
				AND item_id = '$itemID'");
		$row = Framework::$db->getRow($sql);
		
		if (!$row) {
			//echo 'Manager: req item test failed, load node:' . $notFoundNodeID . '<br/>';
			// Item not found, load the required_item_not_found_node_id
			self::loadNode($notFoundNodeID, $npcID);
		}
    }
    
	/**
     * Checks if the player has this event.
     */
    static protected function checkRequiredEvent($userID, $eventID, $notFoundNodeID, $npcID) {
		//echo '<p>Manager: begin req event test<br/>';
		
		$sql = Framework::$db->prefix("SELECT * FROM _P_player_events 
									  WHERE player_id = '$userID' 
									  AND event_id = '$eventID'");
		
		//echo '<p>Manager: ' . $sql. '</p>';
		
		$row = Framework::$db->getRow($sql);
		
		if (!$row) {
			//echo 'Manager: req item test failed, load node:' . $notFoundNodeID . '<br/>';
			// Item not found, load the required_item_not_found_node_id
			self::loadNode($notFoundNodeID, $npcID);
		}
    }
	
	
	
    /**
     * Adds the specified item to the specified player.
     */
    static public function addItem($userID, $itemID) {
    	$sql = Framework::$db->prefix("SELECT * FROM _P_items 
    		WHERE item_id = $itemID");
    	$row = Framework::$db->getRow($sql);
    	
    	if ($row) {    	
    		$sql = Framework::$db->prefix("INSERT INTO _P_player_items 
    			(player_id, item_id) VALUES ($userID, $itemID)
    			ON duplicate KEY UPDATE item_id = $itemID");
    		Framework::$db->exec($sql);
    		self::$messages[] = 'Received ' . $row['name'] . '.';
    	}
    	else {
    		self::$messages[] = "** addItem: $itemID not defined **";
    	}
    	
    	return $row;
    }
    
    /**
     * Removes the specified item from the user.
     */ 
    static protected function removeItem($userID, $itemID) {
    	$sql = Framework::$db->prefix("SELECT * FROM _P_items
    		WHERE item_id = $itemID");
    	$row = Framework::$db->getRow($sql);
    	
    	if ($row) {
    		$sql = Framework::$db->prefix("DELETE FROM _P_player_items 
    			WHERE player_id = $userID AND item_id = $itemID");
    		Framework::$db->exec($sql);
    		self::$messages[] = 'Lost ' . $row['name'] . '.';
		}
		else self::$messages[] =  "** removeItem: Item $itemID not defined **";
    }

    static public function loadNodeConversations($npcID) {
    	
		//echo '<p>Manager: loadNodeConversations begining for NPC: ' . $npcID . '</p>';
		
		// Ensure that we have an id
    	// TODO: Change to an appropriate exception
    	if (empty($npcID)) throw new Framework_Exception('Unauthorized link.',
    		FRAMEWORK_ERROR_AUTH);
    	
		$session = Framework_Session::singleton();
		//var_dump($session);
		
    	$sql = Framework::$db->prefix("SELECT * FROM _P_npcs WHERE npc_id = $npcID");
    	self::$npc = Framework::$db->getRow($sql);

    	$sql = Framework::$db->prefix(
    	"SELECT * FROM _P_npc_conversations 
			WHERE  
				(require_event_id IS NULL OR require_event_id IN 
					(SELECT event_id FROM _P_player_events WHERE player_id = {$session->player_id})) 
			AND
				(require_location_id IS NULL OR require_location_id IN 
					(SELECT last_location_id FROM players WHERE player_id = {$session->player_id})) 
			AND
				(_P_npc_conversations.remove_if_event_id IS NULL 
					OR _P_npc_conversations.remove_if_event_id NOT IN 
						(SELECT event_id FROM _P_player_events WHERE player_id = {$session->player_id}))
			AND	npc_id = $npcID
			ORDER BY node_id DESC"
    	);
    	
    	self::$conversations = Framework::$db->getAll($sql);    
    }
    
    static public function loadOptions($npcID) {
    	if (!empty($npcID) && $npcID > 0) {
	    	$sql = Framework::$db->prefix("SELECT * FROM _P_npcs WHERE npc_id = $npcID");
    		self::$npc = Framework::$db->getRow($sql);
    	}
    	else {
    		self::$npc = array('name' => self::$node['title'], 'npc_id' => -1,
    		'media' => self::$node['media']);
    	}
    
    
    	$results = array();
    	$r = self::loadOption($results, 'opt1_text', 'opt1_node_id');
    	$r = self::loadOption($results, 'opt2_text', 'opt2_node_id');
    	$r = self::loadOption($results, 'opt3_text', 'opt3_node_id');
    	
    	self::$conversations = $results;
    }
    
    static public function loadOption(&$target, $text, $id) {
	    if ((!empty(self::$node[$text]) && !empty(self::$node[$id]))) {
    		array_push($target, array('text' => self::$node[$text],
    			'node_id' => self::$node[$id], 'npc_id' => -1));
    	}
    }
}
?>
