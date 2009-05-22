<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

define('SEED_XML', '<result></result>');

/**
 * Framework_Controller_SimpleREST
 *
 * @author      Kevin Harris (klharris2@wisc.edu)
 * @package     Framework
 * @subpackage  Controller
 * @filesource
 */


/**
 * Framework_Controller_SimpleREST
 *
 * @author      Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Controller
 */
class Framework_Controller_SimpleREST extends Framework_Controller_Web
{
    /**
     * $serializer
     *
     * An instance of SimpleXMLElement, which is used to 
     * serialize the module data and errors into XML.
     *
     * @access      protected
     * @var         object      $serlializer
     * @link        http://us.php.net/simplexml
     */
    protected $serializer = null;

    /**
     * __construct
     *
     * @access      public
     * @return      void
     */
    public function __construct()
    {
        parent::__construct();
        $this->serializer = new SimpleXMLElement(SEED_XML);
    }

    /**
     * module
     *
     * @access      public
     * @return      mixed
     */
    public function module()
    {
        try {
            return parent::module();
        } catch (Framework_Exception $e) {
            $this->output($result);
        }
    }

    /**
     * authenticate
     *
     * @access      public
     * @return      mixed
     */
    public function authenticate()
    {
        try {
            return parent::authenticate();
        } catch (Framework_Exception $e) {
            $this->output($result);
        }
    }

    /**
     * start
     *
     * @access      public
     * @return      mixed
     */
    public function start()
    {
        try {
            return parent::start();
        } catch (Framework_Exception $e) {
            $this->output($result);
        }
    }

    /**
     * stop
     *
     * @access      public
     * @return      mixed
     */
    public function stop()
    {
        try {
            return parent::stop();
        } catch (Framework_Exception $e) {
            $this->output($result);
        }
    }

    /**
     * display
     *
     * @access      public
     * @return      mixed
     */
    public function display()
    {
        try {
            $this->run();
            $result = Framework::$module->getData();
        } catch (Framework_Exception $result) {

        }

        $this->output($result);
    }

    /**
     * Outputs the given $data into XML using XML_Serializer
     *
     * @access      public
     * @param       mixed       $data       Data to serialize into XML
     * @return      mixed
     * @see         Framework_Controller_SimpleREST::$serializer
     */
    private function output($data)
    {
        header("Content-Type: text/plain");
        if ($data instanceof Framework_Exception) {
            $data = array('error' => $data->getMessage(),
                          'code'  => $data->getCode());
        }

        $this->serialize($this->serializer, $data);
        echo $this->serializer->asXML();
        exit;
    }

    /**
     * Builds the XML tree.
     *
     * @access      private
     * @param       SimpleXMLElement    $tree   The XML tree
     * @param       mixed               $data   The info to add
     */
    private function serialize($tree, $data)
    {
        //var_dump($data);
        foreach ($data as $key => $value) {
            if (is_array($value)) {
                // Add the thing & attributes
                $child = $tree->addChild(strval($key));
                $usesArray = false;
                foreach ($value as $childK => $childV) {
                    if (is_array($childV)) {
                        // Check if any of the children are arrays
                        $usesArray = false;
                        foreach ($childV as $testK => $testV) {
                            if (is_array($testV)) {
                                $usesArray = true;
                                break;
                            }
                        }
                        if ($usesArray) {
                            // Create a <row> containing the child info
                            $groupChild = $child->addChild('row');
                            $this->serialize($groupChild, $childV);
                        }
                        else {
                            // It's safe to add them as attributes
                            $groupChild = $child->addChild('row');
                            foreach ($childV as $testK => $testV) {
                                $groupChild->addAttribute($testK,
                                    $testV);
                            }
                        }
                    }
                    else {
                        // 
                        $child->addAttribute(strval($childK),
                            strval($childV));
                    }
                }
            }
            else {
                // Should record e.g., title -> "Inventory"
                $tree->addChild(strval($key), strval($value));
            }
        }
    }
}

?>
