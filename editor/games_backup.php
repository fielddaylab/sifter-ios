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

	$tmpDir = "{$prefix}_backup_" . date('Y_m_d');
	
	
	//Delete a previous backup with the same name
	$rmCommand = "rm -rf {$engine_sites_path}/Backups/{$tmpDir}";
	//echo "<p>Running: $rmCommand </p>";
	exec($rmCommand, $output, $return);
	if ($return) die ("<h3>There was an error cleaning up: $return </h3>
					  <p>Check your file permissions<p>");
	else echo "<p>Cleaned up</p>";
	
	//Set up a tmp directory
	$mkdirCommand = "mkdir {$engine_sites_path}/Backups/{$tmpDir}";
	//echo "<p>Running: $mkdirCommand </p>";
	exec($mkdirCommand, $output, $return);
	if ($return) die ("<h3>There was an error creating the directory {$engine_sites_path}/Backups/{$tmpDir}: $return </h3>
					  <p>Check your config file and your permissions on {$engine_sites_path}<p>");
	else echo "<p>Created Temp Directory</p>";

	//Create SQL File
	$sqlFile = 'database.sql';
	
	$getTablesCommand = "{$mysql_bin_path}/mysql --user={$opts['un']} --password={$opts['pw']} -B --skip-column-names INFORMATION_SCHEMA -e \"SELECT TABLE_NAME FROM TABLES WHERE TABLE_SCHEMA='{$opts['db']}' AND TABLE_NAME LIKE '{$prefix}_%'\"";
	//echo "<p>Running: $getTablesCommand </p>";
	
	exec($getTablesCommand, $output, $return);
	
	if ($output == 127) die ("<h3>There was an error fetching the table names for this game.</h3>
							 <p>Check your config file for the mysql bin path and username / password<p>");
	
	
	$tables = '';
	foreach ($output as $table) {
		$tables .= $table;
		$tables .= ' ';
	}
	//echo "<p>Tables to backup: $tables </p>";

	
	$createSQLCommand = "{$mysql_bin_path}/mysqldump -u {$opts['un']} --password={$opts['pw']} {$opts['db']} $tables > {$engine_sites_path}/Backups/{$tmpDir}/{$sqlFile}";
	//echo "<p>Running: $createSQLCommand </p>";
	exec($createSQLCommand, $output, $return);
	if ($return) die ("<h3>There was an error exporting the SQL file: $return </h3>
					  <p>Check your config file for the mysql bin path and username / password<p>");
	else echo "<p>SQL Data Dumped</p>";
	
	
	//Copy the site into the tmp directory
	$copyCommand = "cp {$engine_sites_path}/{$prefix}.php {$engine_sites_path}/Backups/{$tmpDir}";
	//echo "Running: $copyCommand </p>";
	exec($copyCommand, $output, $return);
	if ($return) die ("<h3>There was an error copying your files to the temp directory: $return </h3>
					  <p>Check your config file and file permissions<p>");
	else echo "<p>Game Files Dumped</p>";	
	
	$copyCommand = "cp -R {$engine_sites_path}/{$prefix} {$engine_sites_path}/Backups/{$tmpDir}/{$prefix}";
	//echo "<p>Running: $copyCommand </p>";
	exec($copyCommand, $output, $return);
	if ($return) die ("<h3>There was an error copying your files to the temp directory: $return </h3>
					  <p>Check your config file and file permissions<p>");
	else echo "<p>Game PHP file dumped</p>";
	
	
	//Create a version file
	$versionCommand = "{$svn_bin_path}/svnversion {$engine_path} > {$engine_sites_path}/Backups/{$tmpDir}/version";
	echo "<p>Running: $versionCommand </p>";
	exec($versionCommand, $output, $return);
	if ($return) echo ("<h3>There was an error creating a version file: $return </h3>
					  <p>Check your svn_bin_path in the config file<p>");
	else echo "<p>Version Recorded</p>";
	
	
	//Zip up the whole directory
	$zipFile = "{$prefix}_backup_" . date('Y_m_d') . ".tar";
	$newWd = "{$engine_sites_path}/Backups";
	//echo "<p>Changing Directory to $newWd </p>";
	chdir($newWd);
	$createZipCommand = "tar -cf {$engine_sites_path}/Backups/{$zipFile} {$tmpDir}/";
	//echo "<p>Running: $createZipCommand </p>";
	exec($createZipCommand, $output, $return);
	if ($return) die ("<h3>There was an error compressing your files: $return </h3>
					   <p>Check that tar is installed an in path<p>");
	else echo "<p>Compressed Files</p>";
	
	//Delete the Temp
	$rmCommand = "rm -rf {$engine_sites_path}/Backups/{$tmpDir}";
	//echo "<p>Running: $rmCommand </p>";
	exec($rmCommand, $output, $return);
	if ($return) die ("<h3>There was an error cleaning up: $return </h3>
					   <p>Check your file permissions<p>");
	else echo "<p>Cleaned up</p>";
	
	echo "<h3>Done!</h3>";
	echo "<a href = '{$engine_sites_www_path}/Backups/{$zipFile}'>Download Zip Game Package</a></h3>";

?>