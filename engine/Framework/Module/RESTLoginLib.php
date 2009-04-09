<?php

/**
 * simple login functionality to re-use in modules
 *
 * @return True if login was successful
 */
function loginUser() {
	$loggedIn = false;
	
	if(!empty($_REQUEST['user_name'])) {
		
		$userField = Framework::$site->config->user->userField;
		$session = Framework_Session::singleton();
		
		// Query the database
		$sql = sprintf("SELECT * FROM %s 
			WHERE user_name='%s' AND password='%s'", 
			Framework::$site->config->user->userTable,
			$_REQUEST['user_name'], $_REQUEST['password']);
		
		$row = Framework::$db->getRow($sql);
		
		if($_REQUEST['user_name'] == $row['user_name'] && $_REQUEST['password'] == $row['password']) {
				$session->authorization = array('user_name' => $_REQUEST['user_name'], "$userField" => $row["$userField"]);
			
			$session->{$userField} = $row["$userField"];
			
			$loggedIn = $row;
		}
	}
	
	return $loggedIn;
}

?>