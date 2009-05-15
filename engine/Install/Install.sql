-- phpMyAdmin SQL Dump
-- version 2.11.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Oct 26, 2008 at 10:41 AM
-- Server version: 5.0.51
-- PHP Version: 5.2.6

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `aris`
--

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

CREATE TABLE IF NOT EXISTS `players` (
  `player_id` int(11) unsigned NOT NULL auto_increment,
  `first_name` varchar(25) default NULL,
  `last_name` varchar(25) default NULL,
  `email` varchar(50) default NULL,
  `photo` varchar(25) default NULL,
  `password` varchar(32) default NULL,
  `user_name` varchar(30) default NULL,
  `last_location_id` int(11) default NULL,
  `latitude` double default NULL,
  `longitude` double default NULL,
  `authorization` smallint(6) NOT NULL default '0' COMMENT 'This is used to give the player editor rights',
  `site` varchar(64) NOT NULL default 'default',
  PRIMARY KEY  (`player_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

--
-- Dumping data for table `players`
--

INSERT INTO `players` (`player_id`, `first_name`, `last_name`, `photo`, `password`, `user_name`, `last_location_id`, `latitude`, `longitude`, `authorization`, `site`) VALUES
(0, '', '', NULL, '', 'Anonymous', NULL, NULL, NULL, 0, 'default');
