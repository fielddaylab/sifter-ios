<?php

//For testing - Cpmment Out in normal use	
//$_SESSION['player_id'] = $_REQUEST['player_id'];
	
session_start();
	

if (isset($_REQUEST['latitude']) 
	&& isset($_REQUEST['longitude']) 
	&& isset($_SESSION['player_id'])
	&& isset($_REQUEST['site'])) 
{	
	// Update Session
	$_SESSION['latitude']=$_REQUEST['latitude'];
	$_SESSION['longitude']=$_REQUEST['longitude'];
	$_SESSION['last_location_timestamp']=time();
	$_REQUEST['site'] = $_REQUEST['site'] . '_';
	
	/*************************************************************
	 Begin AWESOME GHETTO code now
	 ****************************************/
	
	$schema = 'aris';
	$user = 'arisuser';
	$pass = 'arispwd';
	$host = 'localhost';
	
	$db = mysql_connect($host, $user, $pass);
	echo mysql_error();
	mysql_select_db($schema);
	
	//Stire latitude and longitude in players table
	$query = "UPDATE players 
		SET latitude = '{$_REQUEST['latitude']}', longitude = '{$_REQUEST['longitude']}' 
		WHERE player_id = '{$_SESSION['player_id']}'";
	mysql_query($query);
	
	//Check for a matching location and add event if specified
	$gps_error_factor = .0005 ;

	$query = "SELECT * FROM {$_GET['site']}locations 
		WHERE 
		latitude < " .  ($_REQUEST['latitude'] + $gps_error_factor) . " AND latitude > " .  ($_REQUEST['latitude'] - $gps_error_factor) . 
		" AND longitude < " . ($_REQUEST['longitude'] + $gps_error_factor) . " AND longitude > " .  ($_REQUEST['longitude'] - $gps_error_factor);  

	$result = mysql_query($query);
}
else {
	echo 'Seriously? I need more vars than that.';
	
}

?>