<?php
	echo '<h1>Trigger!</h1>';
	
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
	
	
	//If add_event_id
	if ($newvals["event_id_when_viewed"] == 'ADD') {	
		//insert a new item
		$new_id = new_event("Player viewed Item: " .  $newvals['name']);
		
		//store new id here, replacing 'add'
		$query = "UPDATE $this->tb SET event_id_when_viewed = '{$new_id}' WHERE item_id = '{$this->rec}'";
		mysql_query($query); //for add
		$newvals["event_id_when_viewed"] = $new_id; //for update
	}			
	
	function new_event($desc) {
		//Insert a new event
		$table = $_SESSION['current_game_prefix'].'events';
		$query = "INSERT INTO $table (description) VALUES ('{$desc}')";
		mysql_query($query);
		return mysql_insert_id();	
	}
	
	
	?>