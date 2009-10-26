<?php	
	
	include_once('common.inc.php');
	print_header('Delete an ARIS Game');
	
	//Navigation
	echo "<div class = 'nav'>
	<a href = 'index.php'>Back to Game Selection</a>
	<a href = 'logout.php'>Logout</a>
	</div>";
	
	if (isset($_REQUEST['prefix']) and isset($_REQUEST['confirmed'])) {
		//Go ahead and delete the data
		delete($opts['db'],$_REQUEST['prefix'],$engine_sites_path, $_REQUEST['game_id']);
		//echo $_REQUEST['prefix'];
		
	}

	else if (isset($_REQUEST['game_id'])){
		$query = "SELECT * FROM games WHERE game_id = {$_REQUEST['game_id']}";
		$result = mysql_query($query);
		$row = mysql_fetch_array($result);
		$prefix = substr($row['prefix'],0,strlen($row['prefix'])-1);

		echo "<h3>Are you sure you want to delete {$row['name']}?</h3><h3>This cannot be undone!</h3>";
		echo "<a href = 'index.php'>Cancel</a> / <a href = '{$_SERVER['PHP_SELF']}?prefix={$prefix}&game_id={$_REQUEST['game_id']}&confirmed=true'>Continue Delete</a>";
	}
	
	

	function delete($schema,$prefix,$path,$game_id) {		
	
		echo '<h3>Start Delete...</h3>';
	
		//Delete the files
		echo exec("rm -rf {$path}/{$prefix}", $output, $return);
		if ($return) echo ("<h3>There was an error deleting your files</h3>
						  <p>Check the paths in your config file and ensure that the Sites directory is writable by the web server<p>");
		else echo "<p>Deleted game directory</p>";		
		

		echo exec("rm {$path}/{$prefix}.php", $output, $return);
		if ($return) echo ("<h3>There was an error deleting your files</h3>
						  <p>Check the paths in your config file and ensure that the Sites directory is writable by the web server<p>");
		else echo "<p>Deleted game php file</p>";		
		
		
		//Delete the editor_games record
		$query = "DELETE FROM game_editors WHERE game_id IN (SELECT game_id FROM games WHERE prefix = '{$prefix}_')";
		mysql_query($query);
		echo '<p>' . $query . '</p>';
		echo mysql_error();
		
		//Delete the game record
		$query = "DELETE FROM games WHERE prefix = '{$prefix}_'";
		mysql_query($query);
		echo '<p>' . $query . '</p>';
		echo mysql_error();
		
		//Delete the player registrations
		$query = "DELETE FROM game_players WHERE game_id = $game_id";
		mysql_query($query);
		echo '<p>' . $query . '</p>';
		echo mysql_error();		
		
		//Delete the test players
		$query = "DELETE FROM players WHERE first_name = '{$prefix}' and last_name = 'Tester' and user_name = '{$prefix}'";
		mysql_query($query);
		echo '<p>' . $query . '</p>';
		echo mysql_error();
		
		
		//Fetch the table names for this game
		$query = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='{$schema}' AND TABLE_NAME LIKE '{$prefix}_%'";
		$result = mysql_query($query);
		echo '<p>Finding a list of tables for this game using the command:' . $query . '</p>';
		echo mysql_error();
		while ($table = mysql_fetch_array($result)) {
			 $query = "DROP TABLE {$table['TABLE_NAME']}";
			 mysql_query($query);
			 echo '<p>' . $query . '</p>';
			 echo mysql_error();
		}
		

		
		echo '<h3>Done! Review the messages above for errors.</h3>';
	}