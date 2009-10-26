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
 * Purpose:  automate creating application links<br>
 * Input:<br>
 *         - module = the (name, directory[, event]) tuple to use
 *
 * Examples:
 * <pre>
 * {application module=$app}
 * </pre>
 * @version  1.0
 * @author   Kevin Harris <klharris2 at wisc dot edu>
 * @param    array
 * @param    Smarty
 * @return   string
 */
function smarty_function_application($params, &$smarty)
{
	if (!isset($params['module'])) {
		$smarty->trigger_error('{application} requires a valid module (e.g., {application module=\'\$app\'}.', E_USER_ERROR);
		return; // Do we need this?
	}

	$module = $params['module']['directory'];
	$site = $smarty->get_template_vars('site');
	$sitePath = 'Framework/Site/' . $site . '/Framework/Module/';
	$frameworkPath = 'Framework/Module/';
	
	if (file_exists($sitePath . $module)) $root = $sitePath . $module;
	else if (file_exists($frameworkPath . $module)) $root = $frameworkPath . $module;
	else {
		$smarty->trigger_error("Neither {$sitePath}{$module} nor {$frameworkPath}{$module} exists for {application}.");
		return; // Do we need this?
	}
	
	$eventImg = isset($params['module']['event']) ? '_'. $params['module']['event']
		: '';
	$img = $root . '/Templates/Default/' . $module . $eventImg . '.png';
	// Default image if needed
	if (!file_exists($img)) {
		$img = $smarty->get_template_vars('frameworkTplPath') . '/defaultButton.png';
	}

	$text = $params['module']['name'];
	$event = isset($params['module']['event']) ? '&event='. $params['module']['event']
		: '';
	
	echo <<<APP
	
	<div class="application">
		<a href="index.php?module=$module&controller=Web&site={$site}{$event}" target="_self"><img src="$img" /><div><p>$text</p></div></a>
	</div>
	
APP;
}

/* vim: set expandtab: */

?>
