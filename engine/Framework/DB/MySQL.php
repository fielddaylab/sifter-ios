<?php

/**
 * MySQL driver for Framework_DB
 *
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @package     Framework
 * @subpackage  DB
 * @filesource
 */

require_once 'Framework/DB/Common.php';

/**
 * PHP MySQL driver for Framework_DB
 *
 * The generator driver that handles building up a connection to the DB using
 * PHP's MySQL functions
 *
 * @author      Kevin Harris
 * @package     Framework
 * @subpackage  DB
 * @link        http://us.php.net/manual/en/book.mysql.php
 */
class Framework_DB_MySQL extends Framework_DB_Common
{
    /**
     * Fetchmode map
     *
     * @access      private
     * @var         array       $fetchModes     Map of names to values
     * @static
     */
    static private $fetchModes = array(
//        'DB_FETCHMODE_DEFAULT' => PDO::FETCH_BOTH,
        'DB_FETCHMODE_ORDERED' => 'mysql_fetch_row',
        'DB_FETCHMODE_ASSOC'   => 'mysql_fetch_assoc',
        'DB_FETCHMODE_OBJECT'  => 'mysql_fetch_object',
//        'DB_FETCHMODE_FLIPPED' => DB_FETCHMODE_FLIPPED,
        'DB_GETMODE_ORDERED'   => 'mysql_fetch_row',
        'DB_GETMODE_ASSOC'     => 'mysql_fetch_assoc'
//        'DB_GETMODE_FLIPPED'   => DB_GETMODE_FLIPPED
    );

	/**
	 * How to return results.
	 */
    protected $fetchMode;

    /**
     * Create a singleton 
     *
     * @access      public
     * @return      object      Instance of PEAR DB connected to the DB
     * @throws      Framework_DB_Exception
     */
    public function singleton()
    {
        if (!is_null(parent::$db) && parent::$db instanceof Framework_DB_MySQL) {
            return parent::$db;
        }

      	parent::$db = new Framework_DB_MySQL($this->dsn);

        $fetchMode = 'mysql_fetch_assoc';
        if (isset($this->options->fetchMode) && 
            isset(self::$fetchModes[(string)$this->options->fetchMode])) {
            $fetchMode = self::$fetchModes[(string)$this->options->fetchMode];
        }

        parent::$db->setFetchMode($fetchMode);
        parent::$db->connect();
        return parent::$db;
    }
    
    public function connect() {    
	    if (substr($this->dsn, 0, strlen('mysql:')) == 'mysql:') {
	    	$tokens = explode(';', substr($this->dsn, strlen('mysql:')));
	    	$parameters = array();
	    	foreach ($tokens as $token) {
	    		$args = explode('=', $token);
	    		$parameters[$args[0]] = $args[1];
	    	}
	    	
	    	$this->db = mysql_connect(
	    		!empty($parameters['server']) ? $parameters['server'] : 'localhost',
	    		!empty($parameters['username']) ? $parameters['username'] : 'root',
	    		!empty($parameters['password']) ? $parameters['password'] : ''
	    	);
	    	if ($this->db) {
	    		if (!mysql_select_db(!empty($parameters['dbname']) 
	    			? $parameters['dbname'] : 'aris'))
	    		{
	    			throw new Framework_DB_Exception("Couldn't select database: " . mysql_error());
	    		}
	    	} else throw new Framework_DB_Exception("Couldn't connect to db: " . mysql_error());
	    } else throw new Framework_DB_Exception("Invalid DSN: should begin with 'mysql:'.");
    }
    
    public function setFetchMode($newMode) {
    	$this->fetchMode = $newMode;
    }
    
    public function exec($sql) {
    	if (mysql_query($sql)) {
    		return mysql_affected_rows();
    	}
    	throw new Framework_DB_Exception("Query failed: $sql\n" . mysql_error());
    }
    
    public function getRow($sql) {
    	$result = mysql_query($sql);
    	
    	if ($result) {
    		$func = $this->fetchMode;
    		return $func($result);
    	}
    
		throw new Framework_DB_Exception("Query failed: $sql\n" . mysql_error());
    }
    
    public function &getAll($sql) {
    	$result = mysql_query($sql);
    	
    	if ($result) {
    		$allRows = array();
    		$func = $this->fetchMode;
    		while ($row = $func($result)) {
    			$allRows[] = $row;
    		}
    		
    		return $allRows;
    	}
    
		throw new Framework_DB_Exception("Query failed: $sql\n" . mysql_error());
    }
    
    public function disconnect() {
    	mysql_close();
    	Framework::$db = null;
    }
}

?>
