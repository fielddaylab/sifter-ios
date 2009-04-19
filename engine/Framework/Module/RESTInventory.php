<?php
	
	include_once "RESTLoginLib.php";
	
	/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4: */
	
	require_once('NodeManager.php');
	
	/**
	 * Framework_Module_Main
	 *
	 * @author      Kevin Harris <klharris2@wisc.edu>
	 * @author		David Gagnon <djgagnon@wisc.edu>
	 * @copyright   Joe Stump <joe@joestump.net>
	 * @package     Framework
	 * @subpackage  Module
	 * @filesource
	 */
	
	define('DEFAULT_IMAGE', 'defaultInventory.png');
	
	/**
	 * Framework_Module_Inventory
	 *
	 * @author      Kevin Harris <klharris2@wisc.edu>
	 * @author		David Gagnon <djgagnon@wisc.edu>
	 * @package     Framework
	 * @subpackage  Module
	 */
	class Framework_Module_RESTInventory extends Framework_Auth_User
	{
		/**
		 * __default
		 *
		 * Shows the list of items for a player
		 *
		 * @access      public
		 * @return      mixed
		 */
		public function __default() {
			$user = loginUser();
			
			if(!$user) {
				header("Location: {$_SERVER['PHP_SELF']}?module=RESTError&controller=Web&event=loginError&site=" . Framework::$site->name);
				die;
			}
			
			$site = Framework::$site;
			
			$this->chromeless = true;
			$this->pageTemplateFile = 'empty.tpl';
			$this->loadInventory($user["player_id"]);
		}
		
		protected function loadInventory($userID) {
			//Set the title
			$this->title = Framework::$site->config->aris->inventory->title;
			
			$sql = $this->db->prefix("SELECT * FROM _P_items
									 JOIN _P_player_items 
									 ON _P_items.item_id = _P_player_items.item_id
									 WHERE player_id = $userID");
			$inventory = $this->db->getAll($sql);
			
			//groom media
			foreach ($inventory as &$item) {
				//Use defaults if specified media cannot be found
				$media = empty($item['media']) ? DEFAULT_IMAGE : $item['media'];
				$item['mediaURL'] = 'http://' . $_SERVER['SERVER_NAME'] . $this->findMedia($media, DEFAULT_IMAGE);
				$item['icon'] = 'http://' . $_SERVER['SERVER_NAME'] . $this->findMedia(Framework::$site->config->aris->inventory->imageIcon, NULL);
			}
			unset($item);
			
			$this->inventory = $inventory;
		}
		
		public function displayItem(){
			$this->chromeless = true;
			
			if (empty($_REQUEST['item_id'])) {
				$this->title = "Error";
				$this->errorMessage = "Item cannot be viewed at this time.";
				return;
			}
			$itemID = $_REQUEST['item_id'];
			
			// Load the item data
			$sql = Framework::$db->prefix("SELECT * FROM _P_items WHERE item_id = $itemID");
			$this->item = Framework::$db->getRow($sql);
			
			//Set the title
			$this->title = $this->item['name'];
			
			//Check if an image was specified and can be found, if not, load the default
			$this->media = $this->findMedia($this->item['media'], DEFAULT_IMAGE);			
		}
		
		public function addItem() {
			$this->chromeless = true;
			
			if (empty($_REQUEST['item_id'])) {
				$this->title = "Detection Error";
				$this->message = "No objects detected.";
				return;
			}
			
			if (isset($_REQUEST['event_id']) && $_REQUEST['event_id'] > 0) {
				$this->addEvent($this->user->player_id, $_REQUEST['event_id']);
			}
			
			$item = NodeManager::addItem($_SESSION['player_id'], 
				$_REQUEST['item_id']);
			
			if (isset($_REQUEST['location_id'])) $this->decrementItemQtyAtLocation($_REQUEST['location_id'], 1);

			$this->tplFile = "RESTInventory_displayItem.tpl";
			$this->title = $item['name'];
			$this->item = $item;
			$this->message = implode('<br />', NodeManager::$messages);

			//Check if an image was specified and can be found, if not, load the default
			$this->media = $this->findMedia($this->item['media'], DEFAULT_IMAGE);
		}
		
		public function dropItemHere(){
			$this->chromeless = true;
			$this->pageTemplateFile = 'empty.tpl';
			
			if (empty($_REQUEST['item_id'])) {
				$this->title = "Error";
				$this->message = "No item selected.";
				return;
			}
			
			//Place this item in the world inventory
			$this->giveItemToWorld($_REQUEST['item_id'], $this->user->latitude, $this->user->longitude);
			
			//Remove from the player's inventory
			$this->takeItemFromPlayer($_REQUEST['item_id'], $this->user->player_id);

		}
		
		public function destroyPlayerItem(){
			$this->chromeless = true;
			$this->pageTemplateFile = 'empty.tpl';
			
			if (empty($_REQUEST['item_id'])) {
				$this->title = "Error";
				$this->message = "No item selected.";
				return;
			}
			
			//Remove from the player's inventory
			$this->takeItemFromPlayer($_REQUEST['item_id'], $this->user->player_id);

		}		
		
		public function pickupItem() {
			$this->chromeless = true;
			$this->pageTemplateFile = 'empty.tpl';
			
			$item = NodeManager::addItem($_SESSION['player_id'], 
										 $_REQUEST['item_id']);
			
			if (isset($_REQUEST['location_id'])) $this->decrementItemQtyAtLocation($_REQUEST['location_id'], 1);
		}		
		
		
		
	}
?>
