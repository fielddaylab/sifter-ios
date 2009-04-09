<?php

/**
 * PHP PDO driver for Framework_DB
 *
 * @author      Joe Stump <joe@joestump.net>
 * @author      Kevin Harris <klharris2@wisc.edu>
 * @package     Framework
 * @subpackage  DB
 * @filesource
 */

require_once 'Framework/DB/Common.php';

/**
 * PHP PDO driver for Framework_DB
 *
 * The generator driver that handles building up a connection to the DB using
 * PHP's PDO package.
 *
 * @author      Joe Stump <joe@joestump.net>
 * @author      Kevin Harris
 * @package     Framework
 * @subpackage  DB
 * @link        http://us.php.net/manual/en/book.pdo.php
 */
class Framework_DB_PDO extends Framework_DB_Common
{
    /**
     * Fetchmode map
     *
     * @access      private
     * @var         array       $fetchModes     Map of names to values
     * @static
     */
    static private $fetchModes = array(
        'DB_FETCHMODE_DEFAULT' => PDO::FETCH_BOTH,
        'DB_FETCHMODE_ORDERED' => PDO::FETCH_NUM,
        'DB_FETCHMODE_ASSOC'   => PDO::FETCH_ASSOC,
        'DB_FETCHMODE_OBJECT'  => PDO::FETCH_OBJ,
//        'DB_FETCHMODE_FLIPPED' => DB_FETCHMODE_FLIPPED,
        'DB_GETMODE_ORDERED'   => PDO::FETCH_NUM,
        'DB_GETMODE_ASSOC'     => PDO::FETCH_ASSOC
//        'DB_GETMODE_FLIPPED'   => DB_GETMODE_FLIPPED
    );

    /**
     * Create a singleton of PDO's DB 
     *
     * @access      public
     * @return      object      Instance of PEAR DB connected to the DB
     * @throws      Framework_DB_Exception
     */
    public function singleton()
    {
        if (!is_null(parent::$db) && parent::$db instanceof PDOWrapper) {
            return parent::$db;
        }

		try {
        	parent::$db = new PDOWrapper($this->dsn);
        }
        catch (PDOException $obj) {
        	throw new Framework_DB_Exception($obj->getMessage());
        }

        $fetchMode = PDO::FETCH_ASSOC;
        if (isset($this->options->fetchMode) && 
            isset(self::$fetchModes[(string)$this->options->fetchMode])) {
            $fetchMode = self::$fetchModes[(string)$this->options->fetchMode];
        }

        parent::$db->setFetchMode($fetchMode);
        return parent::$db;
    }
}

class PDOWrapper extends Framework_DB_Common
{
    protected $fetchMode;
    protected $pdoDb;
    
    public function __construct($dsn) {
    	$this->pdoDb = new PDO($dsn, "root", "root");
    }
    
    public function singleton() { return this; }
    
    public function setFetchMode($newMode) {
    	$this->fetchMode = $newMode;
    }
    
    public function exec($sql) {
    	return $this->pdoDb->exec($sql);
    }
    
    public function getRow($sql) {
    	$result = $this->pdoDb->prepare($sql);
    	$result->execute();
  	
    	if ($result instanceof PDOStatement) {
    		$result->setFetchMode($this->fetchMode);
    		return $result->fetch();
    	}
		throw new Framework_DB_Exception("Query failed: ".$sql);
    }
    
    public function &getAll($sql) {
    	$result = $this->pdoDb->prepare($sql);
    	$result->execute();
  	
    	if ($result instanceof PDOStatement) {
    		$result->setFetchMode($this->fetchMode);
    		
    		$allRows = array();
    		while ($row = $result->fetch()) {
    			$allRows[] = $row;
    		}
    		
    		return $allRows;
    	}
		throw new Framework_DB_Exception("Query failed: ".$sql);
    }
    
    public function disconnect() {
    	Framework::$db = null;
    }
}

?>
