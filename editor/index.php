<?php	

	include_once('common.inc.php');

	//Clear Session variables for current game
	unset($_SESSION['current_game_prefix']);
	unset($_SESSION['current_game_short_name']);
	unset($_SESSION['current_game_name']);
	unset($_SESSION['current_game_id']);
	
	print_header('Your ARIS Games');
	
	echo '<!--Editor revision: ';
	include ('version');
	echo '-->';
	
	//Navigation
	echo "<div class = 'nav'>
		<a href = 'games_add.php'>Add a Game</a>
		<a href = 'games_restore.php'>Restore a Game</a>
		<a href = 'http://arisdocumentation.pbwiki.com' target = '_blank'>Help</a>
		<a href = 'logout.php'>Logout</a>
	</div>";
	
	
	//Load Editor Info
	$query = "SELECT * FROM editors WHERE editor_id = {$_SESSION['user_id']}";
	$result = mysql_query($query);
	$row = mysql_fetch_array($result);
	
	//Superuser Navigation
	if (isset($row['super_admin']) and $row['super_admin']) {
		echo "<div class = 'nav'>
		<a href = 'players.php'>Global Players</a>
		</div>";
	}
	
	//Display Games they can admin
	if (isset($row['super_admin']) and $row['super_admin']) $query = "SELECT * FROM games JOIN game_editors WHERE games.game_id = game_editors.game_id GROUP BY games.game_id";
	else $query = "SELECT * FROM games JOIN game_editors ON (games.game_id = game_editors.game_id) 
		WHERE game_editors.editor_id = {$_SESSION['user_id']}";
	
	$result = mysql_query($query);
	
	if (mysql_num_rows($result) == 0) echo 'No games are currently set up for your user. Add or restore a game to get started';
	else {
		echo '<table class = "games">
		<tr><th>Game Name</th><th>Prefix</th><th>Editors</th></tr>';

		while ($row=mysql_fetch_array($result)) {
			
			$editors = '';
			$first = TRUE;
			$editor_query = "SELECT * FROM editors JOIN game_editors ON editors.editor_id = game_editors.editor_id 
				WHERE game_editors.game_id = {$row['game_id']}";
			$editor_result = mysql_query($editor_query);
			while ($editor_row = mysql_fetch_array($editor_result)) {
				if ($first) {
					$editors.= $editor_row['name'];
					$first = FALSE;
				}
				else $editors.= ', ' . $editor_row['name'];
			}
			 
			echo "<tr>
					<td><a href = 'games.php?game_id={$row['game_id']}'>{$row['name']}</a></td>
					<td>{$row['prefix']}</td>
					<td>{$editors}</td>
					<td><a href = 'games_delete.php?game_id={$row['game_id']}'>Delete</a></td>
					<td><a href = 'games_backup.php?prefix={$row['prefix']}'>Backup</a></td>
					<td><a href = 'games.php?game_id={$row['game_id']}'>Edit</a></td>
				</tr>";
		
		}
		echo '</table>';
	}
	
	
?>