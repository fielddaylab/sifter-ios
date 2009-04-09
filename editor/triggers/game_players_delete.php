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
	$query = "SELECT prefix FROM games WHERE game_id = '{$oldvals['game_id']}'";
	$row = mysql_fetch_array(mysql_query($query));
	$prefix = $row['prefix'];
	
	//Remove Apps	
	$query = "DELETE FROM 
		{$prefix}player_applications 
		WHERE
		player_id = '{$oldvals['player_id']}'";
	mysql_query($query);
	if (mysql_error()) echo 'Error Deleting Player Applications' . mysql_error();
	
	
	//Remove Items
		$query = "DELETE FROM 
		{$prefix}player_items 
		WHERE
		player_id = '{$oldvals['player_id']}'";
		mysql_query($query);
	if (mysql_error()) echo 'Error Deleting Player Items' . mysql_error();

	
	//Remove Events
		$query = "DELETE FROM 
		{$prefix}player_events 
		WHERE
		player_id = '{$oldvals['player_id']}'";
		mysql_query($query);
	if (mysql_error()) echo 'Error Deleting Player Events' . mysql_error();
