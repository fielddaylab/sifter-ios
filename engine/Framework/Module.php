<?php

/**
 * Framework_Module
 *
 * @author Joe Stump <joe@joestump.net>
 * @copyright Joe Stump <joe@joestump.net>
 * @license http://www.opensource.org/licenses/bsd-license.php
 * @package Framework
 * @filesource
 */

define('FRAMEWORK_MODULE_ERROR_INVALID_MODULE_FILE',        2);
define('FRAMEWORK_MODULE_ERROR_INVALID_MODULE_CLASS',       4);
define('FRAMEWORK_MODULE_ERROR_INVALID_EVENT',              8);
define('FRAMEWORK_MODULE_ERROR_INVALID_CONTROLLER',        16);

/**
 * Framework_Module
 *
 * The base module class. All applications will extends from this class. This
 * means each module will, by default, have an open DB connection and an
 * open log file to write to. Also, it's a good place to put functions,
 * variables, etc. that all modules need.
 *
 * @author Joe Stump <joe@joestump.net>
 * @package Framework
 */
abstract class Framework_Module extends Framework_Object_Web
{
    /**
     * $presenter
     *
     * Used in Framework_Presenter::factory() to determine which presentation
     * (view) class should be used for the module.
     *
     * @author      Joe Stump <joe@joestump.net>
     * @access      public
     * @var         string      $presenter
     * @see         Framework_Presenter, Framework_Presenter_common
     * @see         Framework_Presenter_Smarty
     */
    public $presenter = 'Smarty';

    /**
     * $contollers
     *
     * This is an array of acceptable controllers. Not all modules will want
     * to enable all controllers.
     *
     * @author      Joe Stump <joe@joestump.net>
     * @access      public
     * @var         array       $controllers     Array of acceptable controllers
     * @see         Framework_Controller
     */
    public $controllers = array('Web', 'REST', 'SimpleREST');

    /**
     * $data
     *
     * Data set by the module that will eventually be passed to the view.
     *
     * @author Joe Stump <joe@joestump.net>
     * @var mixed $data Module data
     * @see Framework_Module::set(), Framework_Module::getData()
     */
    protected $data = array();

    /**
     * $name
     *
     * @author Joe Stump <joe@joestump.net>
     * @var string $name Name of module class
     */
    public $name = '';

    /**
     * $tplFile
     *
     * @author Joe Stump <joe@joestump.net>
     * @var string $tplFile Name of template file
     * @see Framework_Presenter_Smarty
     */
    public $tplFile = '';

    /**
     * $moduleName
     *
     * @author Joe Stump <joe@joestump.net>
     * @var string $moduleName Name of requested module
     * @see Framework_Presenter_Smarty
     */
    public $moduleName = null;

    /**
     * $pageTemplateFile
     *
     * @author Joe Stump <joe@joestump.net>
     * @var string $pageTemplateFile Name of outer page template
     */
    public $pageTemplateFile = null;

    /**
     * Constructor
     *
     * @access      public
     * @return      void
     */
    public function __construct()
    {
        parent::__construct();
        $parts = explode('_',$this->me->getName());
        $this->name = array_pop($parts);
    }

    /**
     * Default event handler
     *
     * This function is ran by the controller if an event is not specified
     * in the user's request.
     *
     * @abstract
     * @access      public
     * @return      mixed
     */
    abstract public function __default();

    /**
     * __shutdown
     *
     * Used to tear down a Framework_Module class. This merely disconnects from
     * the database and closes the log file. This should be ran from any child
     * classes that use this function as well.
     *
     * @access      public
     * @return      boolean
     */
    public function __shutdown()
    {
        return true;
    }

    /**
     * setData
     *
     * Set data for your module. This will eventually be passed toe the
     * presenter class via Framework_Module::getData().
     *
     * @access      public
     * @param       string      $var        Name of variable
     * @param       mixed       $val        Value of variable
     * @return      void
     * @see         Framework_Module::getData()
     */
    public function setData($var,$val) {
        $this->data[$var] = $val;
    }

    /**
     * getData
     *
     * Returns module's data.
     *
     * @return      mixed
     * @see         Framework_Presenter_common
     */
    public function getData()
    {
        return $this->data;
    }

    /**
     * __set
     *
     * @access      public
     * @return      void
     * @see         Framework_Module::setData()
     */
    public function __set($var,$val)
    {
        $this->setData($var,$val);
    }

    /**
     * __get
     *
     * @access      public
     * @return      mixed
     * @see         Framework_Module::$data
     */
    public function __get($var)
    {
        if (!isset($this->data[$var])) {
            $this->data[$var] = null;
        }

        return $this->data[$var];
    }

    /**
     * Adds the specified item to the specified player.
	 *
	 * @access protected
     * @return void
     */
     protected function giveItemToPlayer($itemID, $userID) {
    	$sql = Framework::$db->prefix("SELECT * FROM _P_items 
									  WHERE item_id = $itemID");
    	$row = Framework::$db->getRow($sql);
    	
    	if ($row) {    	
    		$sql = Framework::$db->prefix("INSERT INTO _P_player_items 
										  (player_id, item_id) VALUES ($userID, $itemID)
										  ON duplicate KEY UPDATE item_id = $itemID");
    		Framework::$db->exec($sql);
    	}
	else {
    		//Throw exception
    	}
    }
	
	
	/**
     * Removes the specified item from the user.
     */ 
    static protected function takeItemFromPlayer($itemID, $userID) {
		$sql = Framework::$db->prefix("SELECT * FROM _P_items
									  WHERE item_id = $itemID");
    	$row = Framework::$db->getRow($sql);
    	
    	if ($row) {
    		$sql = Framework::$db->prefix("DELETE FROM _P_player_items 
										  WHERE player_id = $userID AND item_id = $itemID");
    		Framework::$db->exec($sql);
    		return TRUE;
		}
		else return FALSE;
    }
	
	/**
     * Decrement the item_qty at the specified location by the specified amount, default of 1
     */ 
    static protected function decrementItemQtyAtLocation($locationID, $qty = 1) {
   		//If this location has a null item_qty, decrementing it will still be a null
		$sql = Framework::$db->prefix("UPDATE _P_locations 
									  SET item_qty=item_qty-1
									  WHERE location_id = '{$locationID}'");
    	Framework::$db->exec($sql);
	}
	
	/**
     * Adds an item to Locations at the specified latitude, longitude
     */ 
    static protected function giveItemToWorld($itemID, $lat, $long, $qty = 1) {
    	
		//Check that the items exists and lookup the name
		$sql = Framework::$db->prefix("SELECT * FROM _P_items
									  WHERE item_id = $itemID");
    	$itemRow = Framework::$db->getRow($sql);
    	
    	if ($itemRow) {
			//Create a location that points to this item
    		$sql = Framework::$db->prefix("INSERT INTO _P_locations (name,type,type_id,latitude,longitude, item_qty)
										  VALUES ('{$itemRow['name']}','Item','{$itemID}','{$lat}','{$long}','{$qty}')");
    		Framework::$db->exec($sql);
    		return TRUE;
		}
		else return FALSE;
    }
	
    
    /**
     * Creates a new Item for the game and returns its itemID
	 *
	 * name and description are strings, image is the name of an image file, assumed to be in the Site Template or UserFiles
	 *
	 * @access protected
     * @return int
     */
	protected function createItem($name, $description, $type, $media = null) {
   		$sql = Framework::$db->prefix("INSERT INTO _P_items 
										  (name, description, type, media) 
										VALUES ('{$name}', '{$description}', '{$type}' , '{$media}')");
    	Framework::$db->exec($sql);
		return mysql_insert_id();
	}	

	/**
     * Marks the item as viewed by the player
     */ 
    static protected function itemViewedByPlayer($itemID, $userID) {
		//Load the item
		$sql = Framework::$db->prefix("SELECT * FROM _P_items
									  WHERE item_id = '$itemID'");
		//echo $sql;
		$row = Framework::$db->getRow($sql);
		
		//If it has an event to set, give it to the player
		if ($row['event_id_when_viewed']) self::addEvent($userID, $row['event_id_when_viewed']);
    }
	
    /**
     * loadApplications
     *
     * @access protected
     * @return void
     */
    protected function loadApplications($userID) {
    	$sql = $this->db->prefix("SELECT name, directory 
    		FROM _P_applications, _P_player_applications
    		WHERE _P_applications.application_id = 	
    			_P_player_applications.application_id 
    		AND _P_player_applications.player_id = $userID");
    	$rows = $this->db->getAll($sql);

		Framework_Session::singleton()->applications = $rows;
    }
    
    /**
     * listSiteMediaFiles
     *
     * We currently support png, jp[e]g, and gif
     *
     * @access protected
     * @return array
     */
    protected function getSiteMediaFiles() {
    	$sitePath = Framework::$site->getPath() . '/Templates/'
    		. Framework::$site->template . '/templates';
    	$files = array();
    	$pattern = '/\.([pP][nN][gG]|[jJ][pP][eE]?[gG]|[gG][iI][fF])$/';
    	 
    	if ($handle = opendir($sitePath)) {
    		while (false !== ($file = readdir($handle))) {
    			if (preg_match($pattern, $file) > 0) $files[] = $file;
    		}
    	}
    	
    	return $files;
    }
    
    /**
     * getItems
     *
     * Returns all items for a user organized by rows.
     *
     * @param	int		$forUserId
     * @access protected
     * @return array
     */
    protected function getItems($forUserId) {
    	$sql = $this->db->prefix("SELECT * FROM _P_player_items 
    		WHERE player_id = $forUserId");
    	return $this->db->getAll($sql);
    }
    
    /**
     * getItemsByIds
     *
     * Returns all items for a user indexed by item id.
     *
     * @param	int		$forUserId
     * @access protected
     * @return array
     */
    protected function getItemsByIds($forUserId) {
    	$rows = $this->getItems($forUserId);
    	$result = array();
    	foreach($rows as $ignore => $data) {
    		$result[$data['item_id']] = $data;
    	}
    	return $result;
    }
    
    /**
     * getEvents
     *
     * Returns all events.
     *
     * @access protected
     * @return array
     */
    protected function getEvents() {
    	$sql = $this->db->prefix("SELECT * FROM _P_events ORDER BY event_id");
    	return $this->db->getAll($sql);
    }
    
    /** 
     * getEventsByIds
     *
     * Returns an array of events, indexed by event_id.
     *
     * @access protected
     * @return array
     */
    protected function getEventsByIds() {
    	$rows = $this->getEvents();
    	$result = array();
    	
    	foreach($rows as $ignore => $data) {
			$result[$data['event_id']] = $data['description'];
		}
		return $result;
    }
    
    /**
     * getPlayerEvents
     *
     * Returns all events.
     *
     * @access protected
     * @return array
     */
    protected function getPlayerEvents($forPlayerId) {
    	$sql = $this->db->prefix("SELECT * FROM _P_player_events 
    		WHERE player_id = {$forPlayerId} ORDER BY event_id");
    	return $this->db->getAll($sql);
    }
    
    /** 
     * getPlayerEventsByIds
     *
     * Returns an array of events, indexed by event_id.
     *
     * @access protected
     * @return array
     */
    protected function getPlayerEventsByIds($forPlayerId) {
    	$rows = $this->getPlayerEvents($forPlayerId);
    	$result = array();
    	
    	foreach($rows as $ignore => $data) {
			$result[$data['event_id']] = $data;
		}
		return $result;
    }
    
	/** 
	 * addEvent
	 *
     * Adds the specified event to the user.
	 *
	 * @param		string	$userID
     * @param		string	$eventID
	 * @access public
     * @return void
     */
    public function addEvent($userID, $eventID) {
	   	if (!self::checkForEvent($userID, $eventID)) {
			$sql = Framework::$db->prefix("INSERT INTO _P_player_events 
									  (player_id, event_id) VALUES ('$userID','$eventID')
									  ON duplicate KEY UPDATE event_id = '$eventID'");
			Framework::$db->exec($sql);
		}
    }
	
	/** 
	 * removePlayerEvent
	 *
     * Removes the specified event from the Specified player.
	 *
	 * @param		string	$userID
     * @param		string	$eventID
	 * @access public
     * @return void
     */
    public function removePlayerEvent($userID, $eventID) {
		$sql = Framework::$db->prefix("DELETE FROM _P_player_events 
									  WHERE player_id = '{$userID}' AND event_id = '{$eventID}'");
			Framework::$db->exec($sql);

    }
	
	
	/** 
	 * checkForEvent
	 *
     * Checks if the specified user has the specified event.
	 *
	 * @param		string	$userID
     * @param		string	$eventID
	 * @access public
     * @return boolean
     */
    public function checkForEvent($userID, $eventID) {
		$sql = Framework::$db->prefix("SELECT * FROM _P_player_events 
									  WHERE player_id = '$userID' 
									  AND event_id = '$eventID'");
		//echo $sql;
		$row = Framework::$db->getRow($sql);
		
		if ($row) return true;
		else return false;
    }
	
	
	/** 
	 * addPlayerApplication
	 *
     * Adds the specified application to the user.
	 *
	 * @param		string	$userID
     * @param		string	$applicationID
	 * @access public
     * @return void
     */
    public function addPlayerApplication($userID, $applicationID) {
		//The ON duplicaite KEY has a performace benefit
	   	$sql = Framework::$db->prefix("INSERT INTO _P_player_applications 
									  (player_id, application_id) VALUES ('$userID','$applicationID')
									  ON duplicate KEY UPDATE application_id = '$applicationID'");
   		Framework::$db->exec($sql);
		
		$this->loadApplications(Framework_User::singleton()->player_id);
    }	

	/** 
	 * removePlayerApplication
	 *
     * Adds the specified application to the user.
	 *
	 * @param		string	$userID
     * @param		string	$applicationID
	 * @access public
     * @return void
     */
    public function removePlayerApplication($userID, $applicationID) {
		//The ON duplicaite KEY has a performace benefit
	   	$sql = Framework::$db->prefix("DELETE FROM _P_player_applications 
									  WHERE player_id = '$userID' and application_id = '$applicationID'");
   		Framework::$db->exec($sql);
		
		$this->loadApplications(Framework_User::singleton()->player_id);
    }		
	
    /**
     * findMedia
     *
     * Returns a URI path to the media, if available, or to the
     * default media located in the Framewrok template path.
     *
     * @param		string	$filename
     * @param		string	$default
     * @return		string
     */
    public function findMedia($filename, $default, $defaultPath = null) {
    	$basePath = !is_null($defaultPath) 
    		? $defaultPath : dirname($_SERVER['PHP_SELF']) . ltrim($this->frameworkTplPath, '.') . '/';
    	if (!empty($filename)) {
    		$sitePath = Framework::$site->getPath() . '/Templates/' . 	
    			Framework::$site->template . '/templates';
	
    		if (file_exists("$sitePath/$filename")) {
				//echo 'File found at sitepath/filename:' . "$sitePath/$filename" . '</br>';
	    		return Framework::$site->getUriPath() . "/templates/$filename";
    		}
    
    		if (file_exists("{$basePath}{$filename}")) {
    			//echo 'File found at basepath/filename:' . "{$basePath}{$filename}" . '</br>';
				return "{$basePath}{$filename}";
    		}
    	}
    	return "{$basePath}{$default}";
    }

    /**
     * isValid
     *
     * Determines if $module is a valid framework module. This is used by
     * the controller to determine if the module fits into our framework's
     * mold. If it extends from both Framework_Module and Framework_Auth then
     * it should be good to run.
     *
     * @param       object      $module
     * @return      bool
     * @static
     */
    public static function isValid($module)
    {
        return (is_object($module) &&
                $module instanceof Framework_Module &&
                method_exists($module, 'authenticate'));
    }

    /**
     * Instantiate a Framework module
     *
     * @access      public
     * @param       object  $request
     * @return      object  Framework module on success
     * @static
     */
    public static function &factory(Framework_Request_Common $request)
    {
        $file = 'Framework/Module/'.$request->module;
        $class = 'Framework_Module_'.$request->module;
        if (strlen($request->class)) {
            $file   .= '/'.$request->class;
            $class .= '_'.$request->class;
        }
        $file   .= '.php';

        $module = self::tryModule($request->module, $file, $class);
        $module->frameworkTplPath = 
        	'./Framework/Module/Framework/Templates/Default';
        $module->isIphone = stristr($_SERVER['HTTP_USER_AGENT'], "iPhone") !== false;
        if (isset($_REQUEST['notification'])) $module->notification = $_REQUEST['notification'];
        
        return $module;
    }

    /**
     * Try loading a module at a given location
     *
     * @param   string  $module  Module name
     * @param   string  $file    File the class is in
     * @param   string  $class   Class name of the module
     * @return  mixed   Framework_Module instance on success,
     *                  PEAR_Error otherwise.
     */
    public static function tryModule($module, $file, $class)
    {
        if (!include_once($file)) {
            throw new Framework_Exception('Module file not found: ' . $file, FRAMEWORK_MODULE_ERROR_INVALID_MODULE_FILE);
        }

        if (!class_exists($class)) {
            throw new Framework_Exception('Module class not found: '. $module, FRAMEWORK_MODULE_ERROR_INVALID_MODULE_CLASS);
        }

        $instance = new $class();
        if (!Framework_Module::isValid($instance)) {
            throw new Framework_Exception('Invalid module class loaded', FRAMEWORK_MODULE_ERROR_INVALID_MODULE_CLASS);
        }

        $instance->moduleName = $module;
        return $instance;
    }

    /**
     * start
     *
     * Accepts the module and the request in which the module should be ran
     * and runs the appropriate event. Additionally, if the request specifies
     * a different presenter and the presenter is listed in the list of
     * acceptable presenters then it switches the presenter to be used.
     *
     * @access      public
     * @param       object      $module         Module to load
     * @param       object      $request        Request to load
     * @return      mixed       Framework module on success,
     *                          PEAR_Error on failure
     * @static
     */
    static public function start(Framework_Module &$module, $request)
    {
        if (!method_exists($module, $request->event) &&
            !method_exists($module, '__call')) {
            throw new Framework_Exception('Invalid event: ' . get_class($module) . '::' . $request->event. '()', FRAMEWORK_MODULE_ERROR_INVALID_EVENT);
        }

        $tplFile = $request->module;
        if (isset($request->class) && strlen($request->class)) {
            $tplFile .= '_' . $request->class; 
        }

        if ($request->event != '__default') {
            $tplFile .= '_' . $request->event; 
        }

        $tplFile .= '.tpl';
        $module->tplFile = $tplFile;

        $result = $module->{$request->event}();
        
        //if (!$result) throw new Framework_Exception("Module failure");
        /*
        if (PEAR::isError($result)) {
            throw new Framwork_Exception($result->getMessage(), $result);
        }
        */

        if (!is_null($request->presenter) &&
            $request->presenter != $module->presenter) {
            if (is_array($module->presenter) &&
                in_array($request->presenter, $module->presenter)) {
                $module->presenter = $request->presenter;
            }
        }

        return true;
    }

    /**
     * stop
     *
     * @access public
     * @param object $module
     * @return mixed True on success, PEAR_Error on failure
     * @static
     */
    static public function stop(&$module)
    {
        if (method_exists($module,'__shutdown')) {
            $module->__shutdown();
        }

        return true;
    }
}

?>
