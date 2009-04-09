<?php	
	
	include_once('common.inc.php');
	print_header('Upload an ARIS Game');
	
	//Navigation
	echo "<div class = 'nav'>
	<a href = 'index.php'>Back to Game Selection</a>
	<a href = 'logout.php'>Logout</a>
	</div>";

	if (!isset($_REQUEST['MAX_FILE_SIZE'])) {
		//Form
		echo "<h3>Use this form to select and upload an ARIS .tgz or .tar game package. 
				The file must have the same filename as the original download.</h3>"; 
		
		echo "<form enctype='multipart/form-data' action='{$_SERVER['PHP_SELF']}' method='POST'>
		<input type='hidden' name='MAX_FILE_SIZE' value='1000000000' />
		Choose a file to upload: <input name='uploadedfile' type='file' /><br />
		<input type='submit' value='Upload File' />
		</form>";
	}	
	
	
	else {
		//Handler
		$target_path = "/tmp";
		
		$target_path = $target_path . '/' . basename( $_FILES['uploadedfile']['name']); 
		
		$file_name = basename( $_FILES['uploadedfile']['name']);
		
		//Check that the file is a .tar or .tgz and get the location of the extension
		$extension_index = strpos($file_name,'.tar');
		if ($extension_index < 1) {
			$extension_index = strpos($file_name,'.tgz');
			if ($extension_index < 1) die ("Wrong File Type.");
		}
		
		//Strip the exension off the file, which should give the directory name when unzipped
		$unzipped_folder_name = substr($file_name,0,$extension_index);
		
		//Move the file to the target_path
		if(move_uploaded_file($_FILES['uploadedfile']['tmp_name'], $target_path)) {
			echo "<p>The file ".  basename( $_FILES['uploadedfile']['name']). 
			" has been uploaded</p>";
		} else{
			die ("<p>There was an error uploading the file, please try again!</p>");
		}
		
		//unzip the file
		chdir("/tmp");
		$unzipCommand = "tar xvf $file_name";
		exec($unzipCommand, $output, $return);
		if ($return) die ("<h3>There was an error unzipping you file</h3>
						   <p>Check you Config file for the tar command binary path. Check that the web user can read and write in /tmp. It could also be a corrupt file<p>");
		else echo "<p>File Unzipped</p>";	
		
		
		//Find the game prefix by finding the prefix.php file
		$temp_unzipped_folder = "/tmp/$unzipped_folder_name";
		if (!is_dir($temp_unzipped_folder)) die ("<h3>There was an error accessing your unzipped files</h3>
												 <p>Is the filename exactly the same as the one created by ARIS?<p>");
		chdir($temp_unzipped_folder);
		$glob = glob("*.php");
		$prefix = substr($glob[0],0,strlen($glob[0])-4);

		
		//Check if a game with this prefix has already been created
		$query = "SELECT * FROM games WHERE prefix = '{$prefix}_'";
		if( mysql_num_rows(mysql_query($query)) > 0) die ("<h3>The game '{$prefix}' Already exists.</h3>
														  <p>The existing game must be deleted or this package must be modified<p>");
		
		
		
		//If it wasn't found, this is not an ARIS file
		if (strlen($prefix) == 0) die ("<p>Your file was not a valid ARIS game package: No [game].php file found</p>");
		echo ("<p>Resoring: $prefix</p>");
		
		//move the files
		$moveCommand = "mv $prefix {$engine_sites_path}/";
		exec($moveCommand, $output, $return);
		if ($return) die ("<h3>There was an error moving files to the Sites directory</h3>
						  <p>Check your config file paths and that the Framework/Site directoy is writrable by the web server<p>");
		else echo "<p>Files Moved</p>";	
		
		$moveCommand = "mv {$prefix}.php {$engine_sites_path}/";
		exec($moveCommand, $output, $return);
		if ($return) die ("<h3>There was an error moving a file to the Sites directory</h3>
						  <p>Check your config file paths and that the Framework/Site directoy is writrable by the web server<p>");
		else echo "<p>Game PHP File Moved</p>";			

		
		//check for, then run the sql
		$SQLglob = glob("database.sql");
		if (empty($SQLglob)) die ("<p>Your file was not a valid ARIS game package: No SQL file found</p>");

		$SQLCommand = "{$mysql_bin_path}/mysql -u {$opts['un']} --password={$opts['pw']} aris < database.sql";
		//echo $SQLCommand;
		exec($SQLCommand);
		echo ('<p>SQL upload attempted</p>');
		
		//Add a game record
		$query = "INSERT INTO games (prefix, name) VALUES ('{$prefix}_','{$prefix}')";
		mysql_query($query);
		$new_game_id = mysql_insert_id();
		echo ("<p>New Game record created for {$prefix}, using id:{$new_game_id}</p>");
		
		//Make this editor an editor for the game
		$query = "INSERT INTO game_editors (game_id, editor_id) VALUES ('{$new_game_id}','{$_SESSION[user_id]}')";
		mysql_query($query);
		echo ("<p>You have been made an editor for {$prefix}</p>");
		
		
		
		//Delete all records from the stored player_applications table
		echo "<p>Clearning original player_applications</p>";
		$query = "DELETE FROM {$prefix}_player_applications";
		mysql_query($query);
		echo mysql_error();
		
		
		
		
		//Create a test player for this game and give them all applications
		echo "<p>Creating a test player for this game and give them default applicaitons</p>";
		$query = "INSERT INTO players (first_name,last_name,user_name,password,site) 
		VALUES 	('{$prefix}', 'Tester', '{$prefix}', '{$prefix}','{$prefix}')";
		mysql_query($query);
		echo mysql_error();
		$test_player_id = mysql_insert_id();
		
		$query = "SELECT * FROM {$prefix}_applications";
		$result = mysql_query($query);
		echo mysql_error();
		while ($application = mysql_fetch_array($result)) {
			$new_player_application_query = "INSERT INTO {$prefix}_player_applications (player_id,application_id)
			VALUES ('{$test_player_id}','{$application['application_id']}')";
			mysql_query($new_player_application_query);
			echo mysql_error();
		}
		
		
		
		echo ("<h3>Upload Complete! {$prefix} restored.</h3>");
		
	}
	
	
?>