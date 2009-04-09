<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

include_once "RESTLoginLib.php";

/**
 * Framework_Module_SelectGame
 *
 * @author      David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */


class Framework_Module_RESTSelectGame extends Framework_Auth_No
{
    /**
     * __default
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
    	$this->pageTemplateFile = 'empty.tpl';
    	
    	$user = loginUser();
    	
    	$session = Framework_Session::singleton();
    	
    	if(!$user) {
    		header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		die;
    	}
    	
		error_log("user id: " . $user['player_id']);
		//Determine Games Available to this user		
		$sql = sprintf("SELECT * FROM games
					   LEFT JOIN game_players
					   ON games.game_id = game_players.game_id
					   WHERE game_players.player_id = '%s'", 
					   $user['player_id']);
		$available_games = Framework::$db->getAll($sql);
		
		$this->available_games = $available_games;
				
    }
	/*
	public function loadGame()
	{
		$site = substr($_REQUEST['prefix'], 0, strlen ($_REQUEST['prefix']) - 1);
		$user = Framework_User::singleton();
		
		//Set player site to current game
		$sql = "UPDATE players
		SET site = '$site' 
		WHERE player_id = '{$_SESSION['player_id']}'";
		$this->db->exec($sql);
		
		// Prepare the next site
		Framework::$site = Framework_Site::factory($site);
		Framework::$site->prepare();
		$this->site = Framework::$site->name;
		
		// Load Applications
		$this->loadApplications($user->player_id);
		//$this->defaultModule = Framework::$site->config->aris->main->defaultModule;
		header("Location: {$_SERVER['PHP_SELF']}?module=RESTQuest&chromeless=true&controller=Web&site="
			   . $this->site);
		die;
	}
	*/
}

?>
