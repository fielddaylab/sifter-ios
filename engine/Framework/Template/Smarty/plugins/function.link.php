<?php
/**
 * Smarty plugin
 * @package Smarty
 * @subpackage plugins
 */


/**
 * Smarty {link} function plugin
 *
 * Type:     function<br>
 * Name:     link<br>
 * Date:     August 13, 2008
 * Purpose:  automate creating links<br>
 * Input:<br>
 *         - controller = the controller to use; defaults to Web
 *         - module = the module to use
 *         - site = the site to use; defaults to the current site
 *		   - event = the event to fire, if any
 *         - text = the text to display
 *         - class = the link's class
 *
 * Examples:
 * <pre>
 * {link controller="Web" module="Login" site="Nac1" text="Log in"}
 * </pre>
 * @version  1.0
 * @author   Kevin Harris <klharris2 at wisc dot edu>
 * @param    array
 * @param    Smarty
 * @return   string
 */
function smarty_function_link($params, &$smarty)
{
	if (!isset($params['module'])) {
		$smarty->trigger_error('{link} requires a module (e.g., {link module=\'gps\'}.', E_USER_ERROR);
		return; // Do we need this?
	}
	if (!isset($params['text'])) {
		$smarty->trigger_error('{link} requires text (e.g., {application text=\'GPS App\'}.', E_USER_ERROR);
		return; // Do we need this?
	}
	
	$controller = isset($params['controller']) ? $params['controller'] : 'Web';
	$site = isset($params['site']) 
		? $params['site'] : $smarty->get_template_vars('site');
	$event = isset($params['event']) ? "&event=" . $params['event'] : '';
	$class = isset($params['class']) ? 'class="' . $params['class'] .'"' : '';

	echo <<<LINK
	<a $class href="index.php?module={$params['module']}&controller=$controller&site=$site$event" target="_self">{$params['text']}</a>
	
LINK;
}

/* vim: set expandtab: */

?>
