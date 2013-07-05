-- phpMyAdmin SQL Dump
-- version 3.5.8.1deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jul 05, 2013 at 02:09 AM
-- Server version: 5.5.31-0ubuntu0.13.04.1
-- PHP Version: 5.4.9-4ubuntu2.1

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `dastal`
--

-- --------------------------------------------------------

--
-- Stand-in structure for view `player_ot`
--
DROP VIEW IF EXISTS `player_ot`;
CREATE TABLE IF NOT EXISTS `player_ot` (
`session` int(10) unsigned
,`time` int(10) unsigned
,`event` varchar(255)
,`clientid` varchar(255)
,`oid` varchar(255)
,`name` varchar(255)
,`level` bigint(21)
,`xp` bigint(21)
,`death` bigint(21)
,`kills_player` bigint(21)
,`xp_combat` bigint(21)
,`xp_creeps` bigint(21)
,`xp_resources` bigint(21)
,`barrier_dmg` bigint(21)
,`resources_dmg` bigint(21)
);
-- --------------------------------------------------------

--
-- Table structure for table `raw`
--

DROP TABLE IF EXISTS `raw`;
CREATE TABLE IF NOT EXISTS `raw` (
  `session` int(10) unsigned NOT NULL,
  `time` int(10) unsigned NOT NULL,
  `event` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `p1` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `p2` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `p3` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `p4` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `p5` varchar(255) DEFAULT NULL,
  `p6` varchar(255) DEFAULT NULL,
  `p7` varchar(255) DEFAULT NULL,
  `p8` varchar(255) DEFAULT NULL,
  `p9` varchar(255) DEFAULT NULL,
  `p10` varchar(255) DEFAULT NULL,
  `p11` varchar(255) DEFAULT NULL,
  `p12` varchar(255) DEFAULT NULL,
  `p13` varchar(255) DEFAULT NULL,
  `p14` varchar(255) DEFAULT NULL,
  `p15` varchar(255) DEFAULT NULL,
  `p16` varchar(255) DEFAULT NULL,
  `p17` varchar(255) DEFAULT NULL,
  `p18` varchar(255) DEFAULT NULL,
  `p19` varchar(255) DEFAULT NULL,
  `p20` varchar(255) DEFAULT NULL,
  `p21` varchar(255) DEFAULT NULL,
  `p22` varchar(255) DEFAULT NULL,
  `p23` varchar(255) DEFAULT NULL,
  `p24` varchar(255) DEFAULT NULL,
  `p25` varchar(255) DEFAULT NULL,
  KEY `session` (`session`),
  KEY `time` (`time`),
  KEY `event` (`event`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Stand-in structure for view `t`
--
DROP VIEW IF EXISTS `t`;
CREATE TABLE IF NOT EXISTS `t` (
`time` int(10) unsigned
);
-- --------------------------------------------------------

--
-- Structure for view `player_ot`
--
DROP TABLE IF EXISTS `player_ot`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `player_ot` AS select `raw`.`session` AS `session`,`raw`.`time` AS `time`,`raw`.`event` AS `event`,`raw`.`p1` AS `clientid`,`raw`.`p2` AS `oid`,`raw`.`p3` AS `name`,cast(`raw`.`p4` as signed) AS `level`,cast(`raw`.`p5` as signed) AS `xp`,cast(`raw`.`p6` as signed) AS `death`,cast(`raw`.`p7` as signed) AS `kills_player`,cast(`raw`.`p8` as signed) AS `xp_combat`,cast(`raw`.`p9` as signed) AS `xp_creeps`,cast(`raw`.`p10` as signed) AS `xp_resources`,cast(`raw`.`p11` as signed) AS `barrier_dmg`,cast(`raw`.`p12` as signed) AS `resources_dmg` from `raw` where (`raw`.`event` = 'player_ot');

-- --------------------------------------------------------

--
-- Structure for view `t`
--
DROP TABLE IF EXISTS `t`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `t` AS select distinct `raw`.`time` AS `time` from `raw`;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
