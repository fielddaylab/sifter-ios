<?php
	
	include_once('common.inc.php');
	
	print_header( $_SESSION['current_game_name'] . ' Items');
	print_general_navigation();
	
	echo "<div class = 'nav'>
	<a href = 'player_items.php'>Player Items</a>
	</div>";		
	
	/**********************
	 PHP My Edit Config
	 *********************/
	
	// Select the Table Name
	$opts['tb'] = $_SESSION['current_game_prefix'] . 'items';
	
	//Triggers
	$opts['triggers']['insert']['after'] = 'triggers/uploader.php';
	$opts['triggers']['update']['before'] = 'triggers/uploader.php';	
	
	// Name of field which is the unique key
	$opts['key'] = 'item_id';
	
	// Type of key field (int/real/string/date etc.)
	$opts['key_type'] = 'int';
	
	// Sorting field(s)
	$opts['sort_field'] = array($opts['key']);
	
	// Number of records to display on the screen
	// Value of -1 lists all records in a table
	$opts['inc'] = -1;
	
	// Options you wish to give the users
	// A - add,  C - change, P - copy, V - view, D - delete,
	// F - filter, I - initial sort suppressed
	$opts['options'] = 'ACPDF';
	
	// Number of lines to display on multiple selection filters
	$opts['multiple'] = '4';
	
	// Navigation style: B - buttons (default), T - text links, G - graphic links
	// Buttons position: U - up, D - down (default)
	$opts['navigation'] = 'GU';
	
	// Display special page elements
	$opts['display'] = array(
							 'form'  => true,
							 'query' => true,
							 'sort'  => false,
							 'time'  => false,
							 'tabs'  => true
							 );
	
	// Set default prefixes for variables
	$opts['js']['prefix']               = 'PME_js_';
	$opts['dhtml']['prefix']            = 'PME_dhtml_';
	$opts['cgi']['prefix']['operation'] = 'PME_op_';
	$opts['cgi']['prefix']['sys']       = 'PME_sys_';
	$opts['cgi']['prefix']['data']      = 'PME_data_';
	
	/* Get the user's default language and use it if possible or you can
	 specify particular one you want to use. Refer to official documentation
	 for list of available languages. */
	$opts['language'] = $_SERVER['HTTP_ACCEPT_LANGUAGE'] . '-UTF8';
	
	/* Table-level filter capability. If set, it is included in the WHERE clause
	 of any generated SELECT statement in SQL query. This gives you ability to
	 work only with subset of data from table.
	 
	 $opts['filters'] = "column1 like '%11%' AND column2<17";
	 $opts['filters'] = "section_id = 9";
	 $opts['filters'] = "PMEtable0.sessions_count > 200";
	 */
	
	/* Field definitions
	 
	 Fields will be displayed left to right on the screen in the order in which they
	 appear in generated list. Here are some most used field options documented.
	 
	 ['name'] is the title used for column headings, etc.;
	 ['maxlen'] maximum length to display add/edit/search input boxes
	 ['trimlen'] maximum length of string content to display in row listing
	 ['width'] is an optional display width specification for the column
	 e.g.  ['width'] = '100px';
	 ['mask'] a string that is used by sprintf() to format field output
	 ['sort'] true or false; means the users may sort the display on this column
	 ['strip_tags'] true or false; whether to strip tags from content
	 ['nowrap'] true or false; whether this field should get a NOWRAP
	 ['select'] T - text, N - numeric, D - drop-down, M - multiple selection
	 ['options'] optional parameter to control whether a field is displayed
	 L - list, F - filter, A - add, C - change, P - copy, D - delete, V - view
	 Another flags are:
	 R - indicates that a field is read only
	 W - indicates that a field is a password field
	 H - indicates that a field is to be hidden and marked as hidden
	 ['URL'] is used to make a field 'clickable' in the display
	 e.g.: 'mailto:$value', 'http://$value' or '$page?stuff';
	 ['URLtarget']  HTML target link specification (for example: _blank)
	 ['textarea']['rows'] and/or ['textarea']['cols']
	 specifies a textarea is to be used to give multi-line input
	 e.g. ['textarea']['rows'] = 5; ['textarea']['cols'] = 10
	 ['values'] restricts user input to the specified constants,
	 e.g. ['values'] = array('A','B','C') or ['values'] = range(1,99)
	 ['values']['table'] and ['values']['column'] restricts user input
	 to the values found in the specified column of another table
	 ['values']['description'] = 'desc_column'
	 The optional ['values']['description'] field allows the value(s) displayed
	 to the user to be different to those in the ['values']['column'] field.
	 This is useful for giving more meaning to column values. Multiple
	 descriptions fields are also possible. Check documentation for this.
	 */
	
	$opts['fdd']['item_id'] = array(
									'name'     => 'Item ID',
									'select'   => 'T',
									'options'  => 'LAVCPDR', // auto increment
									'maxlen'   => 11,
									'default'  => '0',
									'sort'     => true
	);
	$opts['fdd']['name'] = array(
								 'name'     => 'Name',
								 'select'   => 'T',
								 'maxlen'   => 25,
								 'sort'     => true,
								 'help'		=> 'Do NOT use double quotes!'
	);
	$opts['fdd']['description'] = array(
										'name'     => 'Description',
										'select'   => 'T',
										'maxlen'   => 65535,
										'textarea' => array(
															'rows' => 5,
															'cols' => 50),
										'sort'     => true,
										'help'		=> 'Do NOT use double quotes!'
	);
	
	$opts['fdd']['type'] = array(
								 'name'     => 'Item Type',
								 'select'   => 'T',
								 'maxlen'   => 5,
								 'values'   => array(
													 "Image",
													 "AV"),
								 'sort'     => true
								 );
	
	$opts['fdd']['media'] = array(
								  //  'colattrs|LF'   => '',
								  //  'escape'     => false,
								  
								  'input'      => 'F',
								  'imagepath'  =>  $image_path,
								  'URL'        => $image_www_path .'$value',
								  'URLtarget'  => '_blank',
								  'maxlen'     => 128,
								  'name'       => 'Image',
								  'options'    => 'ACPVDFL',
								  'required'   => false,
								  'select'     => 'T',
								  'size|ACP'   => 60,
								  'sqlw'       => 'TRIM("$val_as")',
								  //  'tab'        => 'File',
								  'sort'       => true,
								  'help'		=> 'Use images (.gif .png .jpg), audio (.mp3 .aac) or video (.mp4 h.264) files'
	);
	
	// Now important call to phpMyEdit
	require_once('phpMyEdit.class.php');
	new phpMyEdit($opts);
	
	print_footer();
	?>
