<?php	
	
	include_once('common.inc.php');
	print_header($_SESSION['current_game_name'] . ' ARIS Game Config');
	print_general_navigation();

	$xml_file = "{$engine_sites_path}/{$_SESSION['current_game_short_name']}/config.xml";

	if (isset($_POST['data'])) save_xml($xml_file);
	print_form($xml_file);
	
	
	
	function print_form($file_path) {
		
		$xml_contents = file_get_contents($file_path);	
		echo "<form action = '{$_SERVER['PHP_SELF']}' method = 'post'>
		<textarea name = 'data' cols='130' rows='100'>{$xml_contents}</textarea>
		<input type = 'submit'/>
		</form>";
	}
	
	function save_xml ($file_path) {
	
		$file_handle = fopen($file_path, 'w') or die("Can't open file for Writing. Could your permissions be set wrong?");
		fwrite($file_handle, stripslashes($_POST['data']));
		fclose($file_handle);
	}