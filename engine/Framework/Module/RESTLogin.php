<?php

include_once "RESTLoginLib.php";

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_Welcome
 *
 * @author      Joe Stump <joe@joestump.net>
 * @copyright   Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */

/**
 * Framework_Module_Welcome
 *
 * @author      Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_RESTLogin extends Framework_Auth_No
{
    /**
     * __default
     *
     * @access      public
     * @return      mixed
     */
    public function __default() {
    	$loginSuccess = loginUser();
    	
    	// Try to authenticate
    	$session = Framework_Session::singleton();
    	
    	if($loginSuccess) {
    		echo "1";
			die;
    	} else {
    		header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		die;
    	}
    }
	
	public function selfRegistration(){
		$this->pageTemplateFile = 'empty.tpl';
		$this->chromeless = true;
		$this->tplFile = 'RESTLogin.tpl';
		
		//Check if a user with the same name exists
		$userTable = Framework::$site->config->user->userTable;

		$sql = sprintf("SELECT * FROM %s WHERE UPPER(user_name) LIKE UPPER('%s')", 
					   $userTable, $_REQUEST['user_name']);
		//echo $sql;
		
		$row = Framework::$db->getRow($sql);
		
		//var_dump($row);
		
		if ($row or !isset($_REQUEST['user_name']) or !isset($_REQUEST['password']) or !isset($_REQUEST['first_name']) or !isset($_REQUEST['last_name']) or !isset($_REQUEST['email'])) {
			//There was a matching username
			die("0");
		}
		else {
			//Insert a record in the users table
			$sql = sprintf("INSERT INTO %s (user_name, password, first_name, last_name, email) VALUES ('%s','%s','%s','%s','%s')", 
						   $userTable, $_REQUEST['user_name'],$_REQUEST['password'],$_REQUEST['first_name'],$_REQUEST['last_name'],$_REQUEST['email']);
			//echo $sql;
			Framework::$db->exec($sql);
			die("1");
		}
	}
}

?>
