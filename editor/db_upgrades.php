<?php
	
include_once('common.inc.php');
	
	print_header("{$_SESSION['current_game_name']} Database Upgrades");
	
	echo "<div class = 'nav'>
	<a href = 'games.php'>Back to {$_SESSION['current_game_name']}</a>
	<a href = 'logout.php'>Logout</a>
	</div>";	
	
	echo "<h3>Dropping dual primary key from npc_conversations</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}npc_conversations DROP PRIMARY KEY";
	mysql_query($query);
	if (mysql_error() == "Incorrect table definition; there can be only one auto column and it must be defined as a key") echo 'Not Needed';
		else echo mysql_error();	
	
	echo "<h3>Adding conversation_id primary key to npc_conversations</h3>";
	$query = "alter table {$_SESSION['current_game_prefix']}npc_conversations 
	add conversation_id int not null auto_increment primary key";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'conversation_id'") echo 'Not Needed';
	else echo mysql_error();	
	
	echo "<h3>Ensure Lat/Long are doubles in the Locations Table</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}locations 
			MODIFY COLUMN latitude DOUBLE ,
			MODIFY COLUMN longitude DOUBLE ";
	mysql_query($query);

	echo "<h3>Add support for locations refering to items,npcs,nodes</h3>";
	$query ="ALTER TABLE {$_SESSION['current_game_prefix']}locations 
		ADD COLUMN type enum('Node','Event','Item','Npc') AFTER longitude,
		ADD COLUMN type_id INT AFTER type;";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'type'") echo 'Not Needed';
	else echo mysql_error();	
	
	echo "<h3>Dropping dual primary key from player_applications</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}player_applications
				DROP PRIMARY KEY,
				ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'id'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Dropping dual primary key from player_items</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}player_items
	DROP PRIMARY KEY,
	ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'id'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Dropping dual primary key from player_events</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}player_events
	DROP PRIMARY KEY,
	ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'id'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Adding Error to Locaiton Table</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}locations
	ADD COLUMN error double default '0.0005'";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'error'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Set Location Table Defualts</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}locations 
	MODIFY COLUMN latitude DOUBLE default '43.0746561' ,
	MODIFY COLUMN longitude DOUBLE default '-89.384422'";
	mysql_query($query);
	echo mysql_error();
	
	echo "<h3>Unique game_editors</h3>";
	$query = "ALTER TABLE  game_editors ADD UNIQUE `unique` (game_id, editor_id)";
	mysql_query($query);
	if (mysql_error() == "Duplicate key name 'unique'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Unique player_events</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}player_events ADD UNIQUE `unique` (player_id, event_id)";
	mysql_query($query);
	if (mysql_error() == "Duplicate key name 'unique'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Unique player_items</h3>";
	$query = "ALTER TABLE  {$_SESSION['current_game_prefix']}player_items ADD UNIQUE `unique` (player_id,item_id)";
	mysql_query($query);
	if (mysql_error() == "Duplicate key name 'unique'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Extended name for items</h3>";
	$query = "ALTER TABLE  {$_SESSION['current_game_prefix']}items 
		CHANGE  name  name VARCHAR( 100 ) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL";
	mysql_query($query);
	echo mysql_error();
	
	echo "<h3>Hidden Locations Support</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}locations
					ADD COLUMN hidden enum('0','1') default '0'";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'hidden'") echo 'Not Needed';
	else echo mysql_error();

	echo "<h3>AJAX Map Support</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}locations
					CHANGE `media` `icon` VARCHAR( 30 ) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL";
	mysql_query($query);
	if (mysql_error() == "Unknown column 'media' in '{$_SESSION['current_game_prefix']}locations'") echo 'Not Needed';
	else echo mysql_error();
	
	echo "<h3>Item Type Support</h3>";
	$query = "ALTER TABLE {$_SESSION['current_game_prefix']}items
	ADD `type` ENUM(  'AV','Image' ) NOT NULL DEFAULT 'Image'";
	mysql_query($query);
	if (mysql_error() == "Duplicate column name 'type'") echo 'Not Needed';
	else echo mysql_error();	

	
	
	
?>