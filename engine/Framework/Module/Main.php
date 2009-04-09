<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_Main
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @author      David Gagnon <djgagnon@wisc.edu>
 * @copyright   Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */

/**
 * Framework_Module_Main
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_Main extends Framework_Auth_User
{
    /**
     * __default
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
    	$user = Framework_User::singleton();
    
    	$this->title = sprintf(Framework::$site->config->aris->main->title, 
    		$user->user_name);
    	$this->company = Framework::$site->config->aris->company;
		$this->body = Framework::$site->config->aris->main->body;

    }
}

?>
