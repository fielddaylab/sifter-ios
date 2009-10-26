<?php
	/*
	 Variables available within a trigger include:
	 $this - object reference
	 $this->dbh - nitialized MySQL database handle
	 $this->key - primary key name
	 $this->key_type - primary key type
	 $this->key_delim - primary key deliminator
	 $this->rec - primary key value (update and delete only)
	 $newvals  - associative array of new values (update and insert only)
	 $oldvals - associative array of old values (update and delete only)
	 $changed - array of keys with changed values
	 */
	$query = "SELECT prefix FROM games WHERE game_id = '{$newvals['game_id']}'";
	$row = mysql_fetch_array(mysql_query($query));
	$prefix = $row['prefix'];
	$game_name_short = substr($prefix,0,strlen($prefix)-1);
	
	new_player_setup($game_name_short,$newvals['game_id'], $newvals['player_id']);
	