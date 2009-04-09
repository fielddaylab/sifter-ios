<?php

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
class Framework_Module_RESTError extends Framework_Auth_No
{
    /**
     * __default
     *
     * @access      public
     * @return      mixed
     */
    public function __default()
    {
    	$this->pageTemplateFile = 'empty.tpl';
    	
    	// Destroy the session so apps/etc. don't appear.
    	$_SESSION = array();
    	session_destroy();
    }
    
    public function error() {
		$this->__default();
    	$this->error = "Unauthorized access attempt. Please log in.";
    	$this->tplFile = 'RESTError.tpl';
    }
    
    public function loginError() {
    	$this->__default();
    	$this->error = "Invalid credentials. Please try again.";
    	$this->tplFile = 'RESTError.tpl';
    }
}

?>
