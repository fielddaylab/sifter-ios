-- phpMyAdmin SQL Dump
-- version 2.11.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Oct 25, 2008 at 11:15 PM
-- Server version: 5.0.51
-- PHP Version: 5.2.6

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `aris`
--

-- --------------------------------------------------------

--
-- Table structure for table `editors`
--


CREATE TABLE IF NOT EXISTS `editors` (
  `editor_id` int(11) NOT NULL auto_increment,
  `name` varchar(25) default NULL,
  `password` varchar(32) default NULL,
  `super_admin` enum('0','1') NOT NULL default '0',
  `comments` tinytext,
  PRIMARY KEY  (`editor_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=10 ;

--
-- Dumping data for table `editors`
--

INSERT INTO `editors` (`editor_id`, `name`, `password`,   `super_admin`,  `comments`) VALUES
(1, 'editor', md5('aris'), '1', 'Default Administrator');

-- --------------------------------------------------------

--
-- Table structure for table `games`
--

CREATE TABLE IF NOT EXISTS `games` (
  `game_id` int(11) NOT NULL auto_increment,
  `prefix` varchar(50) default NULL,
  `name` varchar(100) default NULL,
  PRIMARY KEY  (`game_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=43 ;

--
-- Dumping data for table `games`
--


-- --------------------------------------------------------

--
-- Table structure for table `game_editors`
--

CREATE TABLE IF NOT EXISTS `game_editors` (
  `game_id` int(11) default NULL,
  `editor_id` int(11) default NULL,
  UNIQUE KEY `unique` (`game_id`,`editor_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `game_editors`
--

-- --------------------------------------------------------

--
-- Table structure for table `game_players`
--

CREATE TABLE `game_players` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `game_id` int(10) unsigned NOT NULL,
  `player_id` int(10) unsigned NOT NULL,
  `registered` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `unique` (`game_id`,`player_id`),
  KEY `game_id` (`game_id`),
  KEY `player_id` (`player_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;
