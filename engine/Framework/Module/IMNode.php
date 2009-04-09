<?php

require_once('NodeManager.php');

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_IMNode
 *
 * @author      Joe Stump <joe@joestump.net>
 * @copyright   Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */

/**
 * Framework_Module_IMNode
 *
 * @author      Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_IMNode extends Framework_Auth_No
{
	public $controllers = array('JSON');

    /**
     * __default
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
    	// Need a node ID
    	if (!$_REQUEST['nodeID']) return "No node ID specified.";

    	$nodeID = $_REQUEST['nodeID'];
    	$npcID = $_REQUEST['npcID'];
		NodeManager::loadNode($nodeID, $npcID);
    
    	$this->data = $this->formatNode(NodeManager::$node, $npcID);
    }
    
    protected function formatNode($node, $npcID) {
    	$session = Framework_Session::singleton();
    	$user = Framework_User::singleton();
    
    	$messages = new stdClass;
    	$messages->id = $node['node_id'];
    	$messages->player_icon = $this->findMedia($user->photo, 'defaultUser.png');
    	
    	$messages->phrases = $this->makePhrases($node);
    	$messages->requiresInput = !empty($node['require_answer_string'])
    		? true : false;
    	$messages->options = $this->makeOptions($node, $npcID);
    	$messages->optionDelay = 1000;
    	
    	$sql = Framework::$db->prefix("SELECT * FROM _P_npcs WHERE npc_id = $npcID");
    	$row = Framework::$db->getRow($sql);
    	$messages->npc_name = $row['name'];
    	$messages->npc_icon = $this->findMedia($row['media'], 'defaultUser.png');
    	
    	return $messages;
    }
    
    /**
     * Generates phrases from the node.
     */
    protected function &makePhrases($dbRow) {
    	// We have <p>a</p><p>b</p>
    	$lines = explode('</p>', $dbRow['text']);
    	$isNPC = false;
    	$phrases = array();
    	foreach ($lines as $line) {
    		$line = trim($line);
    		if (empty($line)) continue;
    		
    		if (stristr($line, 'PC')) {
    			$isNPC = false;
    		}
    		else $isNPC = true;
    		$phrases[] = $this->makePhrase($isNPC, $line . "</p>", strlen($line) * 	
    			mt_rand(40, 45));
    	}
    	return $phrases;
    }
    
    /**
     * Generates all of the options.
     */
    protected function &makeOptions($dbRow, $npcID) {
    	$options = array();
    
    	for ($i = 1; $i < 4; ++$i) {
    		if ($dbRow["opt{$i}_text"] && $dbRow["opt{$i}_node_id"]) {
    			$options[] = $this->makeOption($dbRow["opt{$i}_text"], 	
    				$dbRow["opt{$i}_node_id"]);
    		}
    	}
    	
    	if (count($options) == 0) $options = &$this->getConversations($npcID);
    	
    	return $options;
    }
    
    /**
     * Formats conversations as options.
     */
    protected function getConversations($npcID) {
    	$rows = NodeManager::$conversations;
    	$options = Array();
    	
    	if (count($rows) < 1) return $options;
    	
    	foreach ($rows as $row) {
   			$options[] = $this->makeOption($row['text'], $row['node_id']);
   		}
   		return $options;
    }

	/**
	 * Generates phrases.
	 */
	protected function makePhrase($isNPC, $phrase, $delay) {
    	$utterance = new stdClass;
	    $utterance->isNPC = $isNPC;
    	$utterance->phrase = trim($phrase);
	    $utterance->delay = $delay;
    	return $utterance;
	}

	/**
	 * Returns the option list from the node.
	 */
	protected function makeOption($phrase, $queueId) {
    	$option = new stdClass;
	    $option->phrase = trim($phrase);
    	$option->queueId = $queueId;
	    return $option;
	}
}

?>
