<?php
	$HTTP_GET_VARS = $_GET;
	$HTTP_POST_VARS = $_POST;
	session_name('aris_editor');
	session_start();
	include_once('config.inc.php');
	include_once('theme.inc.php');

	//Connect to the db
	$db = mysql_connect($opts['hn'], $opts['un'], $opts['pw']);
	echo mysql_error();
	mysql_select_db($opts['db'], $db);
	
	
	//See if we have requested a new account
	if (isset($_REQUEST['req']) and $_REQUEST['req'] == 'register' or $_REQUEST['req'] == 'register2') {
		print_header('Register for ARIS Editor');
		include_once('register.inc.php');
		die();
	}
	
	//Check that a user is logged on
	if (!isset($_SESSION['user_name'])) {
		print_header('Login to ARIS Editor');
		include_once('login.inc.php');
		die();
	}
	
	function new_player_setup($game_short, $game_id, $player_id) {
		echo "Setup New Player. Game Short: $game_short Game ID: $game_id Player ID: $player_id";
		
		//Find the game name from its id
		$query = "SELECT name FROM games WHERE game_id = '$game_id'";
		$row = mysql_fetch_array(mysql_query($query));
		$game_name = $row['name'];
		$xml_path = "{$GLOBALS['engine_sites_path']}/{$game_short}/config.xml";	
	
		$xml = simplexml_load_file($xml_path);
		
		//Process Starting Apps	
		foreach ($xml->aris->applications->startingIDs->id as $id) {	
			$query = "INSERT INTO 
			{$game_short}_player_applications 
			(player_id , application_id) 
			VALUES 
			('$player_id','$id')";
			//echo $query;
			mysql_query($query);
		}
	
		//Process Starting Items	
		foreach ($xml->aris->inventory->startingIDs->id as $id) {	
			$query = "INSERT INTO 
			{$game_short}_player_items 
			(player_id , item_id) 
			VALUES 
			('$player_id','$id')";
			mysql_query($query);
		}
	
		//Process Starting Events
		foreach ($xml->aris->events->startingIDs->id as $id) {	
			$query = "INSERT INTO 
			{$game_short}_player_events
			(player_id , event_id) 
			VALUES 
			('$player_id','$id')";
			mysql_query($query);
		}
	}
	


?>