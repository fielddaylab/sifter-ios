<?php
include_once('../common.inc.php');
	
	$query = "SELECT * FROM {$_SESSION['current_game_prefix']}locations WHERE location_id = {$_REQUEST['location_id']}";
	$result = mysql_query($query);
	$row = mysql_fetch_array($result);
	
	echo "<h2>{$row['name']}</h2>";
	echo "<table>
			<tr><td><a  href='locations.php?PME_sys_fl=0&amp;PME_sys_fm=0&amp;PME_sys_sfn[0]=0&amp;PME_sys_operation=PME_op_Change&amp;PME_sys_rec={$_REQUEST['location_id']}'>Edit this Location</a></td></tr>
			<tr><td><a  href='locations.php?PME_sys_fl=0&amp;PME_sys_fm=0&amp;PME_sys_sfn[0]=0&amp;PME_sys_operation=PME_op_Delete&amp;PME_sys_rec={$_REQUEST['location_id']}'>Delete this Location</a></td></tr>

			<tr><td><a href = 'locations_infowindow/add_node.inc.php?location_id={$_REQUEST['location_id']}&location_name={$row['name']}' target = '_blank'>Create new Node here</a></td></tr>
			<tr><td><a href = 'locations_infowindow/add_npc.inc.php?location_id={$_REQUEST['location_id']}&location_name={$row['name']}' target = '_blank'>Create new NPC here</a></td></tr>
			<tr><td><a href = 'locations_infowindow/add_item.inc.php?location_id={$_REQUEST['location_id']}&location_name={$row['name']}' target = '_blank'>Create new Item here</a></td></tr>
		</table>";
	
?>