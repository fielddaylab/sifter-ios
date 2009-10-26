<?php	
	
	include_once('common.inc.php');
	print_header($_SESSION['current_game_name'] . ' ARIS Page Layout');
	print_general_navigation();
	
	$file = "{$engine_sites_path}/{$_SESSION['current_game_short_name']}/Templates/Default/templates/page.tpl";
	
	if (isset($_POST['data'])) save($file);
	print_form($file);
	
	
	
	function print_form($file_path) {
		
		$contents = file_get_contents($file_path);	
		echo "<form action = '{$_SERVER['PHP_SELF']}' method = 'post'>
		<p><textarea name = 'data' cols='130' rows='100'>{$contents}</textarea></p>
		<p><input type = 'submit' value = 'Save File'/></p>
		</form>";
	}
	
	function save ($file_path) {
		
		$file_handle = fopen($file_path, 'w') or die("Can't open file for Writing. Could your permissions be set wrong?");
		fwrite($file_handle, stripslashes($_POST['data']));
		fclose($file_handle);
	}