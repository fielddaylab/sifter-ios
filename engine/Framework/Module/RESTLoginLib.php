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
			WHERE UPPER(user_name) LIKE UPPER('%s') AND password='%s'", 
			Framework::$site->config->user->userTable,
			$_REQUEST['user_name'], $_REQUEST['password']);
		
		$row = Framework::$db->getRow($sql);
		
		if(strtoupper($_REQUEST['user_name']) == strtoupper($row['user_name']) && $_REQUEST['password'] == $row['password']) {
				$session->authorization = array('user_name' => $_REQUEST['user_name'], "$userField" => $row["$userField"]);
			
			$session->{$userField} = $row["$userField"];
			
			$loggedIn = $row;
		}
	}
	
	return $loggedIn;
}

?>