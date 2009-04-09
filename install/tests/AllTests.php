<?php


if ( defined( 'PHPUnit_MAIN_METHOD' ) === false )
{
    define( 'PHPUnit_MAIN_METHOD', 'TestAllTests::main' );
}

require_once 'PHPUnit/Framework/TestSuite.php';
require_once 'PHPUnit/TextUI/TestRunner.php';

require_once 'ArrayTest.php';


class TestAllTests {
    /**
     * Test suite main method.
     *
     * @return void
     */
    public static function main() {
        PHPUnit_TextUI_TestRunner::run( self::suite() );
    }
    
    /**
     * Creates the phpunit test suite for this package.
     *
     * @return PHPUnit_Framework_TestSuite
     */
    public static function suite() {
        $suite = new PHPUnit_Framework_TestSuite( 'phpUnderControl - AllTests' );
        $suite->addTestSuite('ArrayTest');

        return $suite;
    }
}

if ( PHPUnit_MAIN_METHOD === 'TestAllTests::main' ) {
    TestAllTests::main();
}