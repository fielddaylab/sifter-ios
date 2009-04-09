<?php	
	
	include_once('common.inc.php');
	
	//Check for correct input
	if(!isset($_REQUEST['game_id']) and !isset($_SESSION['current_game_id'])) echo '<script language="javascript">window.location = \'index.php\';</script>';
	if(isset($_REQUEST['game_id'])) $_SESSION['current_game_id'] = $_REQUEST['game_id'];
	
	//Load Game Info
	$query = "SELECT * FROM games WHERE game_id = {$_SESSION['current_game_id']}";
	$result = mysql_query($query);
	$row=mysql_fetch_array($result);
	print_header($row['name']);
	$_SESSION['current_game_prefix'] = $row['prefix'];
	$_SESSION['current_game_short_name'] = substr($row['prefix'],0,strlen($row['prefix']) -1);
	$_SESSION['current_game_name'] = $row['name'];
	
	//Navigation
	echo "<div class = 'nav'>
	<a href = 'index.php'>Select a Different Game</a>
	<a href = 'http://arisdocumentation.pbwiki.com' target = '_blank'>Help</a>
	<a href = 'logout.php'>Logout</a>
	</div>";
	
	
	echo "<h3>Basic Options</h3>
			<table class = 'gametasks' width = '600px'>
			<tr>
				<td width = '50px'><a href = 'locations.php'><img src = 'images/location_icon.png'/></a></td><td width = '250px'><a href = 'locations.php'>Locations</a></td>
				<td width = '50px'><a href = 'nodes.php'><img src = 'images/nodes.png'/></a></td><td width = '250px'><a href = 'nodes.php'>Nodes</a></td>
			</tr>
			<tr>
				<td width = '50px'><a href = 'qrcodes.php'><img src = 'images/qrcode_icon.png'/></a></td><td width = '250px'><a href = 'qrcodes.php'>QR Codes</a></td>
				<td><a href = '{$engine_www_path}' target='_blank'><img src = 'images/play.png'/></a></td><td><a href = '{$engine_www_path}' target='_blank'>Playtest your game<br/>Login: {$_SESSION['current_game_short_name']}<br/>Pass: {$_SESSION['current_game_short_name']}</a></td>
			</tr>
			
			</table>
	
			<h3>Intermediate Options</h3>
			<table class = 'gametasks' width = '600px'>
			<tr>
				<td width = '50px'><a href = 'npcs.php'><img src = 'images/npcs.png'/></a></td><td width = '250px'><a href = 'npcs.php'>NPCs</a></td>
				<td width = '50px'><a href = 'conversations.php'><img src = 'images/conversation_icon.png'/></a></td><td width = '250px'><a href = 'conversations.php'>NPC Conversations</a></td>
			</tr>
			<tr>
				<td><a href = 'quests.php'><img src = 'images/quests.png'/></a></td><td><a href = 'quests.php'>Quests</a></td>
				<td><a href = 'items.php'><img src = 'images/item_icon.png'/></a></td><td><a href = 'items.php'>Items</a></td>
			</tr>
			<tr>
				<td><a href = 'events.php'><img src = 'images/events.png'/></a></td><td><a href = 'events.php'>Events</a></td>
				<td>&nbsp;</td><td>&nbsp;</td>
			</tr>
			</table>

			<h3>Advanced Options</h3>
			<table class = 'gametasks' width = '600px'>
			<tr>
				<td width = '50px'><a href = 'applications.php'><img src = 'images/applications.png'/></a></td><td width = '250px'><a href = 'applications.php'>Applications</a></td>
				<td width = '50px'><a href = 'db_upgrades.php'><img src = 'images/gears.png'/></a></td><td width = '250px'><a href = 'db_upgrades.php'>DB Upgrades</a></td>
			</tr>
			<tr>
				<td><a href = 'game_players.php'><img src = 'images/players.png'/></a></td><td><a href = 'game_players.php'>Registered Players</a></td>
				<td><a href = 'games_edit_xml.php'><img src = 'images/gears.png'/></a></td><td><a href = 'games_edit_xml.php'>Edit XML Config</a></td>
			</tr>
			<tr>
				<td><a href = 'games_edit_page.php'><img src = 'images/gears.png'/></a></td><td><a href = 'games_edit_page.php'>Edit Visual Template</a></td>
			</tr>
			</table>";
	
	print_footer();
	

	
?>