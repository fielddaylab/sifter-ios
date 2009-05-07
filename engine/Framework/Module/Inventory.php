<?php
	
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
	class Framework_Module_Inventory extends Framework_Auth_User
	{
		/**
		 * __default
		 *
		 * Shows the list of items for a player
		 *
		 * @access      public
		 * @return      mixed
		 */
		public function __default()
		{
			$site = Framework::$site;
			$user = Framework_User::singleton();
			
			$this->loadInventory($user->player_id);
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
				$item['media'] = $this->findMedia($media, DEFAULT_IMAGE);
				
				//Support multiple media types by changing the link and the icon
				$extension = substr(strrchr($item['media'], "."), 1);
				
				//Is it an image?
				if (array_search($extension,array("png", "jpg", "gif")) !== FALSE) {
					$item['isImage'] = TRUE;
					$item['icon'] = $this->findMedia(Framework::$site->config->aris->inventory->imageIcon, NULL);

				}
			
				//Is it a movie?
				if (array_search($extension,array("mp4", "mov", "m4v", "3gp")) !== FALSE) {
					$item['isImage'] = FALSE;
					$item['icon'] = $this->findMedia(Framework::$site->config->aris->inventory->videoIcon, NULL);
					$item['link'] = 'http://' . $_SERVER["SERVER_NAME"] . $item['media'];
				}
				
				//Is it audio?
				if (array_search($extension,array("mp3", "m4a")) !== FALSE) {
					$item['isImage'] = FALSE;
					$item['icon'] = $this->findMedia(Framework::$site->config->aris->inventory->audioIcon, NULL);
					$item['link'] = 'http://' . $_SERVER["SERVER_NAME"] . $item['media'];
				}
				
				//Is it a PDF?
				if (array_search($extension,array("pdf")) !== FALSE) {
					$item['isImage'] = FALSE;
					$item['icon'] = $this->findMedia(Framework::$site->config->aris->inventory->pdfIcon, NULL);
					$item['link'] = 'http://' . $_SERVER["SERVER_NAME"] . $item['media'];
				}
				
			}
			unset($item);
			
			$this->inventory = $inventory;
		}
		
		public function displayItem(){
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
			if (empty($_REQUEST['item_id'])) {
				$this->title = "Detection Error";
				$this->message = "No objects detected.";
				return;
			}
			
			if (isset($_REQUEST['event_id']) && $_REQUEST['event_id'] > 0) {
				$this->addEvent($_SESSION['player_id'], $_REQUEST['event_id']);
			}
			
			$item = NodeManager::addItem($_SESSION['player_id'], 
				$_REQUEST['item_id']);

			$this->tplFile = "Inventory_displayItem.tpl";
			$this->title = $item['name'];
			$this->item = $item;
			$this->message = implode('<br />', NodeManager::$messages);

			//Check if an image was specified and can be found, if not, load the default
			$this->media = $this->findMedia($this->item['media'], DEFAULT_IMAGE);
		}
		
		public function dropItemHere(){
						
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
					
			if (empty($_REQUEST['item_id'])) {
				$this->title = "Error";
				$this->message = "No item selected.";
				return;
			}
			
			//Remove from the player's inventory
			$this->takeItemFromPlayer($_REQUEST['item_id'], $this->user->player_id);
			
		}		
		
		public function pickupItem() {
						
			$item = NodeManager::addItem($_SESSION['player_id'], 
										 $_REQUEST['item_id']);
			
			if (isset($_REQUEST['location_id'])) $this->decrementItemQtyAtLocation($_REQUEST['location_id'], 1);
		}		
		
	}
	?>
