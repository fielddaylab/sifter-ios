<?php	
	
	include_once('common.inc.php');
	
	print_header('Logout');

	session_destroy();

	echo '<h3>You are now logged out</h3>';
	
	echo '<script language="javascript">window.location = \'index.php\';</script>';

?>