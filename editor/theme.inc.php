<?php

	function print_header($title){
		
		echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
		"http://www.w3.org/TR/html4/loose.dtd">
		<html>
		<head>

		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">';
		
		echo '<title>' . $title . '</title>';
		
		echo '
		<style type="text/css"> @import url("theme.css"); </style> 
		<script type="text/javascript" src="js/popwindow.js"></script>
		<script type="text/javascript" src="js/fileupload.js"></script>
		</head>
		<body>';
		
		echo '<h1>' . $title . '</h1>';
		
	}
	
	function print_general_navigation(){
		echo "<div class = 'nav'>
		<a href = 'games.php'>Game Home</a>
		<a href = 'index.php'>Select a Different Game</a>
		<a href = 'locations.php'>Locations</a>
		<a href = 'qrcodes.php'>QR Codes</a>
		<a href = 'nodes.php'>Nodes</a>
		<a href = 'npcs.php'>NPCs</a>
		<a href = 'items.php'>Items</a>
		<a href = 'events.php'>Events</a>
		<a href = 'quests.php'>Quests</a>
		<a href = 'game_players.php'>Registered Players</a>
		<a href = 'http://arisdocumentation.pbwiki.com' target = '_blank'>Help</a>
		<a href = 'logout.php'>Logout</a>
		</div>";	
	}
	
	function print_footer(){
		echo'</body>
			</html>';
	}
	
	
?>

