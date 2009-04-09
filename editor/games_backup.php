<?php	
	
	include_once('common.inc.php');
	print_header('Download an ARIS Game');
	//Navigation
	echo "<div class = 'nav'>
	<a href = 'index.php'>Back to Game Selection</a>
	<a href = 'logout.php'>Logout</a>
	</div>";

	if (!isSet($_REQUEST['prefix'])) die ("<h3>You did not arrive at this page correctly</h3>");
	$prefix = substr($_REQUEST['prefix'],0,strlen($_REQUEST['prefix'])-1);
	
	//Set up a tmp directory
	$tmpDir = "{$prefix}_backup_" . date('Y_m_d');
	exec("mkdir {$engine_sites_path}/Backups/{$tmpDir}", $output, $return);
	if ($return) die ("<h3>There was an error creating the directory {$engine_sites_path}/Backups/{$tmpDir}</h3>
					  <p>Check your config file and your permissions on {$engine_sites_path}<p>");
	
	//Create SQL File
	$sqlFile = 'database.sql';
	$tables = "{$prefix}_applications {$prefix}_events {$prefix}_items {$prefix}_locations {$prefix}_log {$prefix}_nodes {$prefix}_npcs {$prefix}_npc_conversations {$prefix}_player_applications {$prefix}_player_events {$prefix}_player_items";
	$createSQLCommand = "{$mysql_bin_path}/mysqldump -u {$opts['un']} --password={$opts['pw']} {$opts['db']} $tables > {$engine_sites_path}/Backups/{$tmpDir}/{$sqlFile}";
	//echo $createSQLCommand;
	exec($createSQLCommand, $output, $return);
	if ($return) die ("<h3>There was an error exporting the SQL file</h3>
					  <p>Check your config file for the mysql bin path and username / password<p>");
	else echo "<p>SQL Data Dumped</p>";
	
	//Copy the site into the tmp directory
	$copyCommand = "cp /{$engine_sites_path}/{$prefix}.php {$engine_sites_path}/Backups/{$tmpDir}";
	exec($copyCommand, $output, $return);
	if ($return) die ("<h3>There was an error copying your files to the temp directory</h3>
					  <p>Check your config file and file permissions<p>");
	else echo "<p>Game Files Dumped</p>";	
	$copyCommand = "cp -R /{$engine_sites_path}/{$prefix} {$engine_sites_path}/Backups/{$tmpDir}/{$prefix}";
	exec($copyCommand, $output, $return);
	if ($return) die ("<h3>There was an error copying your files to the temp directory</h3>
					  <p>Check your config file and file permissions<p>");
	else echo "<p>Game PHP file dumped</p>";
	
	//Create a version file
	$versionCommand = "{$svn_bin_path}/svnversion {$engine_path} > {$engine_sites_path}/Backups/{$tmpDir}/version";
	exec($versionCommand, $output, $return);
	if ($return) echo ("<h3>There was an error creating a version file</h3>
					  <p>Check your svn_bin_path in the config file<p>");
	else echo "<p>Version Recorded</p>";
	
	//Zip up the whole directory
	$zipFile = "{$prefix}_backup_" . date('Y_m_d') . ".tar";
	chdir("/{$engine_sites_path}/Backups");
	$createZipCommand = "tar -cf {$engine_sites_path}/Backups/{$zipFile} {$tmpDir}/";
	exec($createZipCommand, $output, $return);
	if ($return) die ("<h3>There was an error compressing your files</h3>
					   <p>Check that tar is installed an in path<p>");
	else echo "<p>Compressed Files</p>";
	
	$rmCommand = "rm -rf /{$engine_sites_path}/Backups/{$tmpDir}";
	exec($rmCommand, $output, $return);
	if ($return) die ("<h3>There was an error cleaning up</h3>
					   <p>Check your file permissions<p>");
	else echo "<p>Cleaned up</p>";
	
	echo "<h3>Done!</h3>";
	echo "<a href = '{$engine_sites_www_path}/Backups/{$zipFile}'>Download Zip Game Package</a></h3>";

?>