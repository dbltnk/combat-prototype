-- phpMyAdmin SQL Dump
-- version 3.5.8.1deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jul 05, 2013 at 01:43 PM
-- Server version: 5.5.31-0ubuntu0.13.04.1
-- PHP Version: 5.4.9-4ubuntu2.1

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

--
-- Database: `dastal`
--

-- --------------------------------------------------------

--
-- Stand-in structure for view `barrier_ot`
--
DROP VIEW IF EXISTS `barrier_ot`;
CREATE TABLE IF NOT EXISTS `barrier_ot` (
`session` int(10) unsigned
,`time` int(10) unsigned
,`event` varchar(255)
,`clientid` varchar(255)
,`currentPain` varchar(255)
);
-- --------------------------------------------------------

--
-- Stand-in structure for view `config`
--
DROP VIEW IF EXISTS `config`;
CREATE TABLE IF NOT EXISTS `config` (
`session` int(10) unsigned
,`time` int(10) unsigned
,`event` varchar(255)
,`clientid` varchar(255)
,`name` varchar(255)
,`team` varchar(255)
,`fullscreen` varchar(255)
,`screenWidth` varchar(255)
,`screenHeight` varchar(255)
,`max_chat_lines` varchar(255)
,`audioVolume` varchar(255)
,`skillOne` varchar(255)
,`skillTwo` varchar(255)
,`skillThree` varchar(255)
,`skillFour` varchar(255)
,`skillFive` varchar(255)
,`skillSix` varchar(255)
,`skillSeven` varchar(255)
,`skillEight` varchar(255)
,`targetSelf` varchar(255)
,`showHighscore` varchar(255)
,`toggleFullscreen` varchar(255)
,`quitGame` varchar(255)
);
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
,`xp_sum` bigint(21)
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
-- Stand-in structure for view `resource_ot`
--
DROP VIEW IF EXISTS `resource_ot`;
CREATE TABLE IF NOT EXISTS `resource_ot` (
`session` int(10) unsigned
,`time` int(10) unsigned
,`event` varchar(255)
,`clientid` varchar(255)
,`oid` varchar(255)
,`desc` varchar(255)
,`currentPain` varchar(255)
,`controller` varchar(255)
);
-- --------------------------------------------------------

--
-- Stand-in structure for view `skill_taken`
--
DROP VIEW IF EXISTS `skill_taken`;
CREATE TABLE IF NOT EXISTS `skill_taken` (
`session` int(10) unsigned
,`time` int(10) unsigned
,`event` varchar(255)
,`clientid` varchar(255)
,`name` varchar(255)
,`skill` varchar(255)
);
-- --------------------------------------------------------

--
-- Stand-in structure for view `skill_used`
--
DROP VIEW IF EXISTS `skill_used`;
CREATE TABLE IF NOT EXISTS `skill_used` (
`session` int(10) unsigned
,`time` int(10) unsigned
,`event` varchar(255)
,`clientid` varchar(255)
,`skill` varchar(255)
);
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
-- Structure for view `barrier_ot`
--
DROP TABLE IF EXISTS `barrier_ot`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `barrier_ot` AS select `raw`.`session` AS `session`,`raw`.`time` AS `time`,`raw`.`event` AS `event`,`raw`.`p1` AS `clientid`,`raw`.`p2` AS `currentPain` from `raw` where (`raw`.`event` = 'barrier_ot');

-- --------------------------------------------------------

--
-- Structure for view `config`
--
DROP TABLE IF EXISTS `config`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `config` AS select `raw`.`session` AS `session`,`raw`.`time` AS `time`,`raw`.`event` AS `event`,`raw`.`p1` AS `clientid`,`raw`.`p2` AS `name`,`raw`.`p3` AS `team`,`raw`.`p4` AS `fullscreen`,`raw`.`p5` AS `screenWidth`,`raw`.`p6` AS `screenHeight`,`raw`.`p7` AS `max_chat_lines`,`raw`.`p8` AS `audioVolume`,`raw`.`p9` AS `skillOne`,`raw`.`p10` AS `skillTwo`,`raw`.`p11` AS `skillThree`,`raw`.`p12` AS `skillFour`,`raw`.`p13` AS `skillFive`,`raw`.`p14` AS `skillSix`,`raw`.`p15` AS `skillSeven`,`raw`.`p16` AS `skillEight`,`raw`.`p17` AS `targetSelf`,`raw`.`p18` AS `showHighscore`,`raw`.`p19` AS `toggleFullscreen`,`raw`.`p19` AS `quitGame` from `raw` where (`raw`.`event` = 'config');

-- --------------------------------------------------------

--
-- Structure for view `player_ot`
--
DROP TABLE IF EXISTS `player_ot`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `player_ot` AS select `raw`.`session` AS `session`,`raw`.`time` AS `time`,`raw`.`event` AS `event`,`raw`.`p1` AS `clientid`,`raw`.`p2` AS `oid`,`raw`.`p3` AS `name`,cast(`raw`.`p4` as signed) AS `level`,cast(`raw`.`p5` as signed) AS `xp`,cast(`raw`.`p6` as signed) AS `death`,cast(`raw`.`p7` as signed) AS `kills_player`,cast(`raw`.`p8` as signed) AS `xp_combat`,cast(`raw`.`p9` as signed) AS `xp_creeps`,cast(`raw`.`p10` as signed) AS `xp_resources`,cast(`raw`.`p11` as signed) AS `barrier_dmg`,cast(`raw`.`p12` as signed) AS `resources_dmg`,cast(((`raw`.`p8` + `raw`.`p9`) + `raw`.`p10`) as signed) AS `xp_sum` from `raw` where (`raw`.`event` = 'player_ot');

-- --------------------------------------------------------

--
-- Structure for view `resource_ot`
--
DROP TABLE IF EXISTS `resource_ot`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `resource_ot` AS select `raw`.`session` AS `session`,`raw`.`time` AS `time`,`raw`.`event` AS `event`,`raw`.`p1` AS `clientid`,`raw`.`p2` AS `oid`,`raw`.`p3` AS `desc`,`raw`.`p4` AS `currentPain`,`raw`.`p5` AS `controller` from `raw` where (`raw`.`event` = 'resource_ot');

-- --------------------------------------------------------

--
-- Structure for view `skill_taken`
--
DROP TABLE IF EXISTS `skill_taken`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `skill_taken` AS select `raw`.`session` AS `session`,`raw`.`time` AS `time`,`raw`.`event` AS `event`,`raw`.`p1` AS `clientid`,`raw`.`p2` AS `name`,`raw`.`p3` AS `skill` from `raw` where (`raw`.`event` = 'skill_taken');

-- --------------------------------------------------------

--
-- Structure for view `skill_used`
--
DROP TABLE IF EXISTS `skill_used`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `skill_used` AS select `raw`.`session` AS `session`,`raw`.`time` AS `time`,`raw`.`event` AS `event`,`raw`.`p1` AS `clientid`,`raw`.`p2` AS `skill` from `raw` where (`raw`.`event` = 'skill_used');

-- --------------------------------------------------------

--
-- Structure for view `t`
--
DROP TABLE IF EXISTS `t`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `t` AS select distinct `raw`.`time` AS `time` from `raw`;
