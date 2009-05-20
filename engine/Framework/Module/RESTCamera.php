<?php

include_once "RESTLoginLib.php";

	
/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */

/**
 * Framework_Module_RESTCamera
 *
 * The RESTCamera interfaces with the Camera app on the client to upload player photos 
 *
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @copyright   Joe Stump <joe@joestump.net>
 * @package     Framework
 * @subpackage  Module
 * @filesource
 */


/**
 * Framework_Module_QRCodeScanner
 *
 * @author		David Gagnon <djgagnon@wisc.edu>
 * @package     Framework
 * @subpackage  Module
 */
class Framework_Module_RESTCamera extends Framework_Auth_User
{
    public $controllers = array('JSON', 'Web');
	
    /**
     * __default
     *
     * @access      public
     * @return      mixed
     */
    public function __default() {
    	$this->pageTemplateFile = 'empty.tpl';
    	$user = loginUser();
    	
    	if(!$user) {
    		//header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
    		//die;
    	}
    	
		$this->chromeless = true;

		
		//Move uplaoded image to the site's UserFiles directory using a unique name
		$targetPath = Framework::$site->getPath() . '/Templates/Default/templates/';
		$fileExtension = substr(strrchr($_FILES['image']['name'], "."), 1); 
		$randomName = md5(rand() * time());
		$newName = $randomName . '.' . $fileExtension;
		$fullPath = $targetPath . $newName;
					if (!move_uploaded_file($_FILES['image']['tmp_name'], $fullPath)) {
						//Throw an exception
		}
			
		//Create an item for the file
		if (isset ($_REQUEST['name']) && strlen($_REQUEST['name']) > 0) $name = $_REQUEST['name']; else $name = "Camera Image";
		if (isset ($_REQUEST['name']) && strlen($_REQUEST['description']) > 0) $description = $_REQUEST['description']; else $description = "Taken " . date("l F d, Y");
		$newItemID = $this->createItem($name, $description, "Image", $newName);
		
		//Give the player this item
		$this->giveItemToPlayer($newItemID, $_SESSION['player_id']);
		
		$this->message = "Image Upload Sucessfull";

		
	}//default

}//class
	
?>
