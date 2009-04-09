<?php

/**
 * index.php
 *
 * An example controller to use with Framework. Copy this file into your
 * website's document root to use.
 *
 * @author Joe Stump <joe@joestump.net>
 * @filesource
 */

/**
 * FRAMEWORK_BASE_PATH
 *
 * Dynamically figure out where in the filesystem we are located.
 *
 * @author Joe Stump <joe@joestump.net>
 * @author Kevin Harris <klharris2@wisc.edu>
 * @global string FRAMEWORK_BASE_PATH Absolute path to our framework
 */
define('FRAMEWORK_BASE_PATH', dirname(__FILE__));
define('FRAMEWORK_WWW_BASE_PATH', dirname($_SERVER['PHP_SELF']));

$pathSep = strstr(ini_get('include_path'), ';') ? ';' : ':';

ini_set("include_path", ini_get('include_path') . $pathSep  
	. FRAMEWORK_BASE_PATH . "/Framework{$pathSep}" 
	. FRAMEWORK_BASE_PATH . '/Framework/Template/Smarty');
ini_set('display_errors', 1);

$site = null;
try {
    require_once 'Framework.php';

    // Load the Framework_Site_Example class and initialize modules, run
    // events, etc. You could create an array based on $_SERVER['SERVER_NAME']
    // that loads up different site drivers depending on the server name. For
    // instance, www.foo.com and foo.com load up Framework_Site_Foo, while
    // www.bar.com, www.baz.com, baz.com, and bar.com load up Bar
    // (Framework_Site_Bar).
    $site = isset($_REQUEST['site']) ? $_REQUEST['site'] : "Default";
    
    // The second argument is the controller. Not all modules will support all
    // controllers. If that's the case an appropriate error will be output. We
    // default to using the web controller.
    $controller = isset($_REQUEST['controller']) ? $_REQUEST['controller'] : 'Web';
	
    Framework::start($site, $controller);

    // Run shutdown functions and stop the Framework
    Framework::stop();
} 
catch (Framework_Exception $error) {
    switch ($error->getCode()) {
    
    case FRAMEWORK_ERROR_AUTH:
        
		//Check for a cookie
		if (isset($_COOKIE["ARISUserField"]) && !isset($_REQUEST["user_name"])) {	
			//log them in and redirect
			$session = Framework_Session::singleton();
			$userField = Framework::$site->config->user->userField;
			
			$session->authorization = array('user_name' => $_COOKIE["ARISUserField"],
											"$userField" => $_COOKIE["ARISUserField"]);
			
			$session->{$userField} = $_COOKIE["ARISUserField"];
			
			header("Location: {$_SERVER['PHP_SELF']}?module=SelectGame&controller=Web&site="
				   . Framework::$site->name);
			die;
		}
		
		if(!isset($_REQUEST["user_name"])) {
			// Redirect to your login page here?
        	$pg = urlencode($_SERVER['REQUEST_URI']);
        	header("Location: index.php?module=Welcome&controller=Web&site=$site&event=error");
		} else {
			header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
		}
		
        break;
    default:
        // If a PEAR error is returned usually something catastrophic
        // happend like an event returning a PEAR_Error or throwing an
        // exception of some sort.
        echo $error->getMessage();
    }

} 
catch (Exception $error) {
    echo $error->getMessage();
}

?>
