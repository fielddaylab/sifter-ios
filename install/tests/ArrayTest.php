<?php

require_once "PHPUnit/Framework.php";

class ArrayTest extends PHPUnit_Framework_TestCase {

	public function testNewArrayIsEmpty() {
		$fixture = array();
		 
		$this->assertEquals(0, sizeof($fixture));
	}
	
	public function testArrayContainsAnElement() {
		$fixture = array();
		
		$fixture[] = "element";
		
		$this->assertEquals(1, sizeof($fixture));
	}

}

?>
