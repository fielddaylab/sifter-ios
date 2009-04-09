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

define('DEFAULT_IMAGE', 'defaultQuest.png');

/**
 * Framework_Module_Quest
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_Quest extends Framework_Auth_User
{
    /**
     * __default
     *
     * Displays a map, we didn't come here with a location to display
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
    	$site = Framework::$site;
    	$user = Framework_User::singleton();
    	
    	$this->title = $site->config->aris->quest->title;
    	$this->loadActiveQuests($user->player_id);
    	$this->loadCompletedQuests($user->player_id);
	}
	
	protected function loadActiveQuests($userID) {
		$sql = $this->db->prefix("SELECT * FROM _P_log
			LEFT OUTER JOIN _P_player_events 
				ON _P_log.require_event_id = _P_player_events.event_id
			WHERE (require_event_id IS NULL OR player_id = $userID) 
				AND (_P_log.complete_if_event_id IS NULL 
				OR _P_log.complete_if_event_id 
					NOT IN (SELECT event_id FROM _P_player_events 
						WHERE player_id = $userID))");
		$quests = $this->db->getAll($sql);
		
		foreach ($quests as &$quest) {
			$media = empty($quest['media']) ? DEFAULT_IMAGE : $quest['media'];
			$quest['media'] = $this->findMedia($media, DEFAULT_IMAGE);
		}
		unset($quest);
		
		$this->activeQuests = $quests;
	}
	
	protected function loadCompletedQuests($userID) {
		$sql = $this->db->prefix("SELECT * FROM _P_log
			WHERE _P_log.complete_if_event_id IN 
				(SELECT event_id FROM _P_player_events 
					WHERE player_id = $userID)");
		$quests = $this->db->getAll($sql);
		
		foreach ($quests as &$quest) {
			$media = empty($quest['media']) ? DEFAULT_IMAGE : $quest['media'];
			$quest['media'] = $this->findMedia($media, DEFAULT_IMAGE);
		}
		unset($quest);
		
		$this->completedQuests = $quests;
	}
}
?>
