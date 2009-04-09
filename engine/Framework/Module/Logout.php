<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_Logout
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @copyright   Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */

/**
 * Framework_Module_Logout
 *
 * @author		Kevin Harris <klharris2@wisc.edu>
 * @author      Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_Logout extends Framework_Auth_No
{
    /**
     * __default
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
	    $_SESSION = array();
    	session_destroy();
		setcookie("ARISUserField", "", time()-3600);
		header("Location: {$_SERVER['PHP_SELF']}?module=Welcome&controller=Web&site="
			. Framework::$site->name);
		die();
    }
}

?>
