<?php
	include_once('../common.inc.php');
	
	if ($_REQUEST['req'] == 'update_location') {
		$query = "UPDATE {$_SESSION['current_game_prefix']}locations SET latitude = '{$_REQUEST['latitude']}', longitude = '{$_REQUEST['longitude']}' WHERE location_id = {$_REQUEST['location_id']}";
		mysql_query($query);
		//echo $query;
		if (!mysql_error()) echo "<p>Location {$_REQUEST['location_id']} updated</p>";
		else echo mysql_error();
	}


?>