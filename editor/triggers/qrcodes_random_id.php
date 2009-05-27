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
	
	
	$newID = createKey(4);
	$newvals['qrcode_id'] = $newID;
	
	echo "<h1>RANDOM ID: {$newID} </h1>";
	
	function createKey($amount){
		$keyset = "1234567890";
		$randkey = "";
		for ($i=0; $i<$amount; $i++)
			$randkey .= substr($keyset, rand(0,strlen($keyset)-1), 1);
		return $randkey;	
	}
	
?>