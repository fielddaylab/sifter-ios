<?php
	
	include_once('common.inc.php');
	
	print_header( $_SESSION['current_game_name'] . ' Conversations');
	print_general_navigation();
	
	
	/**********************
	 PHP My Edit Config
	 *********************/
	$opts['triggers']['insert']['after'][0] = 'triggers/conversations.php';
	$opts['triggers']['update']['before'][0] = 'triggers/conversations.php';	
	
	
	// Select the Table Name
	$opts['tb'] = $_SESSION['current_game_prefix'] . 'npc_conversations';
	
	// Name of field which is the unique key
	$opts['key'] = 'conversation_id';
	
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
	$opts['fdd']['conversation_id'] = array(
											'name'     => 'Conversation ID',
											'select'   => 'T',
											'options'  => 'AVCPDR', // auto increment
											'maxlen'   => 11,
											'default'  => '0',
											'sort'     => true
											);
	
	
	
	$opts['fdd']['npc_id'] = array(						'maxlen'     => 20,
														   'name'       => 'NPC',
														   'options'    => 'LAVCPD',
														   'required'   => true,
														   'select'     => 'T',
														   'size|ACP'   => 20,
														   'sqlw'		=>'IF($val_qas = "", NULL, $val_qas)',	 
														   'sort'       => true,
														   'values'     => array(
																				 'db'          	=> $opts['db'],
																				 'table'       	=> $_SESSION['current_game_prefix'] . 'npcs',
																				 'column'      	=> 'npc_id',
																				 'description'	=> array('columns' => array('0' => 'name')),
																				 'orderby'     => 'npc_id')
														   );	
		$opts['fdd']['npc_id']['values2'] = array('ADD' => '-Add a new NPC-');	
	
	

	
	
	$opts['fdd']['node_id'] = array(
										'maxlen'     => 20,
										 'name'       => 'Starting Node',
										 'options'    => 'AVCPD',
										 'required'   => true,
										 'select'     => 'T',
										 'size|ACP'   => 20,
										 'sqlw'		=>'IF($val_qas = "", NULL, $val_qas)',	 
										 'sort'       => true,
										 'values'     => array(
															   'db'          	=> $opts['db'],
															   'table'       	=> $_SESSION['current_game_prefix'] . 'nodes',
															   'column'      	=> 'node_id',
															   'description'	=> array(
																						 'columns' => array('0' => 'title', '1' => 'text'),
																						 'divs' => array('0' => ' : ')
																						 ),
															   'orderby'     => 'node_id')
										 );	
	
	$opts['fdd']['node_id']['values2'] = array('ADD' => '-Add a new Node-');
	
	
	
	$opts['fdd']['text'] = array(
								 'name'     => 'Text',
								 'select'   => 'T',
								 'maxlen'   => 255,
								 'textarea' => array(
													 'rows' => 5,
													 'cols' => 50),
								 'sort'     => true
	);
	
	
	$opts['fdd']['require_item_id'] = array(
											'tab'		=> 'Requirements',
											'default'    => '',
											'maxlen'     => 20,
											'name'       => 'Hide unless player has item',
											'options'    => 'AVCPD',
											'required'   => false,
											'select'     => 'T',
											'size|ACP'   => 20,
											'sqlw'		=>'IF($val_qas = "", NULL, $val_qas)',	 
											'sort'       => true,
											'values'     => array(
																  'db'          	=> $opts['db'],
																  'table'       	=> $_SESSION['current_game_prefix'] . 'items',
																  'column'      	=> 'item_id',
																  'description'	=> array('columns' => array('0' => 'name')),
																  'orderby'     => 'item_id')
											);	
	$opts['fdd']['require_item_id']['values2'] = array(
													   null => '-Not Used-',
													   'ADD' => '-Add a new Item-'
													   );	
	
	
	$opts['fdd']['require_event_id'] = array(
											 'default'    => '',
											 'maxlen'     => 20,
											 'name'       => 'Hide unless player has event',
											 'options'    => 'AVCPD',
											 'required'   => false,
											 'select'     => 'T',
											 'size|ACP'   => 20,
											 'sqlw'		=>'IF($val_qas = "", NULL, $val_qas)',	 
											 'sort'       => true,
											 'values'     => array(
																   'db'          	=> $opts['db'],
																   'table'       	=> $_SESSION['current_game_prefix'] . 'events',
																   'column'      	=> 'event_id',
																   'description'	=> array('columns' => array('0' => 'description')),
																   'orderby'     => 'event_id')
											 );	
	$opts['fdd']['require_event_id']['values2'] = array(
														null => '-Not Used-',
														'ADD' => '-Add a new Event-'
														);		
	
	
	
	$opts['fdd']['remove_if_event_id'] = array(
											 'default'    => '',
											 'maxlen'     => 20,
											 'name'       => 'Hide if player has event',
											 'options'    => 'AVCPD',
											 'required'   => false,
											 'select'     => 'T',
											 'size|ACP'   => 20,
											 'sqlw'		=>'IF($val_qas = "", NULL, $val_qas)',	 
											 'sort'       => true,
											 'values'     => array(
																   'db'          	=> $opts['db'],
																   'table'       	=> $_SESSION['current_game_prefix'] . 'events',
																   'column'      	=> 'event_id',
																   'description'	=> array('columns' => array('0' => 'description')),
																   'orderby'     => 'event_id')
											 );	
	$opts['fdd']['remove_if_event_id']['values2'] = array(
														null => '-Not Used-',
														'ADD' => '-Add a new Event-'
														);			
	
	

	
	
	// Now important call to phpMyEdit
	require_once('phpMyEdit.class.php');
	new phpMyEdit($opts);

	
	print_footer();
	?>
