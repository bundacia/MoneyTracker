-- MySQL dump 10.10
--
-- Host: localhost    Database: money_tracker_00
-- ------------------------------------------------------
-- Server version	5.0.18

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `budget`
--

DROP TABLE IF EXISTS `budget`;
CREATE TABLE `budget` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(30) default NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `budget`
--


/*!40000 ALTER TABLE `budget` DISABLE KEYS */;
LOCK TABLES `budget` WRITE;
INSERT INTO `budget` VALUES (1,'Test Budget 00'),(2,'Test Budget 01'),(3,'Test Budget 02'),(4,'My Test Budget'),(5,'Little Family Budget'),(7,'Little Family Budget 01'),(8,'Little Family Budget 02'),(9,'Little Family Budget 03');
UNLOCK TABLES;
/*!40000 ALTER TABLE `budget` ENABLE KEYS */;

--
-- Table structure for table `budget_user_assoc`
--

DROP TABLE IF EXISTS `budget_user_assoc`;
CREATE TABLE `budget_user_assoc` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `user_id` int(10) unsigned NOT NULL,
  `budget_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `budget_user_assoc`
--


/*!40000 ALTER TABLE `budget_user_assoc` DISABLE KEYS */;
LOCK TABLES `budget_user_assoc` WRITE;
INSERT INTO `budget_user_assoc` VALUES (1,1,1),(2,15,1),(3,16,2),(4,1,2),(5,1,3),(6,1,4);
UNLOCK TABLES;
/*!40000 ALTER TABLE `budget_user_assoc` ENABLE KEYS */;

--
-- Table structure for table `entity`
--

DROP TABLE IF EXISTS `entity`;
CREATE TABLE `entity` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `budget_id` int(10) unsigned default NULL,
  `name` varchar(30) default NULL,
  `description` varchar(150) default NULL,
  `address1` varchar(100) default NULL,
  `address2` varchar(100) default NULL,
  `city` varchar(30) default NULL,
  `state` varchar(30) default NULL,
  `zipcode` int(11) default NULL,
  `country` varchar(30) default NULL,
  `phone` varchar(20) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `entity`
--


/*!40000 ALTER TABLE `entity` DISABLE KEYS */;
LOCK TABLES `entity` WRITE;
INSERT INTO `entity` VALUES (1,1,'Harris Teeter',NULL,NULL,NULL,'Morrisville',NULL,NULL,NULL,NULL),(2,1,'Wal-Mart',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(3,2,'Target',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(4,2,'Target',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `entity` ENABLE KEYS */;

--
-- Table structure for table `entry`
--

DROP TABLE IF EXISTS `entry`;
CREATE TABLE `entry` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `fund_id` int(10) unsigned default NULL,
  `user_id` int(10) unsigned default NULL,
  `date` datetime default NULL,
  `amount` decimal(10,2) default NULL,
  `entity` varchar(25) default NULL,
  `description` varchar(150) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `entry`
--


/*!40000 ALTER TABLE `entry` DISABLE KEYS */;
LOCK TABLES `entry` WRITE;
INSERT INTO `entry` VALUES (1,4,15,NULL,'-100.00','Teeters','Got some Food.'),(159,6,1,'2006-11-11 00:00:00','-1.00','',''),(68,2,17,'2006-11-09 10:30:01','359.79','ROLLOVER','AUTO ROLLOVER: Food Rollover'),(66,2,17,'2006-11-04 10:30:01','-234.96','ROLLOVER','AUTO ROLLOVER: Food Rollover'),(17,NULL,15,'2006-09-25 20:00:00','-100.00','Loan Shark','This months Car Payment'),(67,2,15,'2006-11-02 10:30:01','-100.00','Loan Shark','This months Car Payment'),(65,2,15,'2006-11-10 10:30:01','-69.04','Loan Shark','This months Car Payment'),(64,2,17,'2006-11-05 10:30:01','-22.48','ROLLOVER','AUTO ROLLOVER: Food Rollover'),(37,4,15,'2006-10-01 00:00:00','-100.00','Shell','snack'),(134,13,1,'2006-11-11 11:11:11','-99.99','test','test desc'),(35,4,15,'2006-11-10 10:30:01','-26.52','Shell','more_gas'),(34,4,15,'2006-11-10 10:30:01','-40.00','Shell','more gas'),(32,4,15,'2006-10-16 18:08:15','-100.00','Loan Shark','This months Car Payment'),(33,4,15,'2006-10-01 00:00:01','-100.00','Shell','gas'),(31,4,15,'2006-10-15 17:59:22','-100.00','Loan Shark','This months Car Payment'),(30,4,15,'2006-10-15 17:15:00','-275.00','Loan Shark','This months Car Payment'),(169,3,1,'2006-11-14 12:00:00','-100.00','wal-mart','foo'),(45,2,15,'2006-09-01 08:30:00','-10.00','McDonalds','breakfast'),(61,2,15,'2006-10-16 19:41:37','-100.00','Loan Shark','This months Car Payment'),(62,2,17,'2006-10-16 19:41:37','-121.34','Wal-Mart','AUTO ROLLOVER: Food Rollover'),(59,2,15,'2006-10-16 19:40:32','-100.00','Loan Shark','This months Car Payment'),(60,2,17,'2006-10-16 19:40:32','-180.62','ROLLOVER','AUTO ROLLOVER: Food Rollover'),(58,2,17,'2006-10-16 19:39:04','-40.31','ROLLOVER','AUTO ROLLOVER: Food Rollover'),(57,2,15,'2006-10-16 19:39:04','-100.00','Car Guys','This months Car Payment'),(133,13,1,'2006-11-11 11:11:11','-99.99','test','test desc'),(132,13,1,'2006-11-11 11:11:11','-99.99','test','test desc'),(73,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(74,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(75,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(76,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(77,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(78,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(79,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(80,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(81,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(82,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(83,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(84,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(85,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(86,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(87,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(161,6,1,'2006-11-14 12:00:00','-1.00','Joe','bribe'),(89,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(90,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(91,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(93,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(94,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(95,8,15,'2006-11-10 10:30:01','-11.99','a different guy','another_entry'),(96,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(97,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(136,13,1,'2006-11-11 11:11:11','-99.99','test','test desc'),(99,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(100,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(165,3,1,'2006-11-14 12:00:00','-1.00','joe','bribe'),(127,13,1,'2006-11-11 11:11:11','-99.99','test','test desc'),(103,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(104,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(213,44,1,'2006-11-16 12:00:00','-55.44','papa','later'),(163,3,1,'2006-11-14 12:00:00','-1.00','Joe','bribe'),(107,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(108,8,15,'2006-11-10 10:30:01','-11.99','some guy','another_entry'),(135,13,1,'2006-11-11 11:11:11','-99.99','test','test desc'),(170,3,1,'2006-11-14 12:00:00','-199.00','wal-mart','foo'),(110,NULL,NULL,'2006-11-09 12:00:00','-14.99','Target','T-Shirt'),(111,NULL,NULL,'2006-11-11 12:00:00','-4.00','Caribu Coffe','Mocha'),(112,NULL,NULL,'2006-11-04 12:00:00','-4.00','Caribu','Mocha'),(113,NULL,NULL,'2006-11-03 12:00:00','-100.00','dd','ff'),(120,13,1,'2006-11-02 12:00:00','1.00','Wafel House','bad java'),(119,13,1,'2006-11-11 12:00:00','-3.76','Starbucks','Frappucino'),(118,13,1,'2006-11-11 12:00:00','-4.00','Caribu','Mocha'),(147,6,1,'2006-11-11 00:00:00','-1.00','',''),(142,5,1,'2006-11-14 12:00:00','-4.00','coffe man','coffe'),(212,5,1,'2006-11-15 12:00:00','-4.00','Caribu','Coffe'),(210,36,1,'2006-11-15 12:00:00','-4.66','Baskin Robins','Chocolate'),(176,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(177,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(178,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(179,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(180,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(181,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(182,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(183,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(184,6,1,'2006-11-11 11:11:11','-100.00','test_entity','test_description'),(185,5,1,'2006-11-13 12:00:00','-3.33','Starbucks','5'),(208,13,1,'2006-11-11 11:11:11','-99.99','test','test desc'),(188,6,1,'2006-11-14 12:00:00','4444.00','44','44'),(189,6,1,'2006-11-14 12:00:00','44444.00','44','44'),(192,4,1,'2006-11-18 12:00:00','-33.00','Exon','33'),(209,35,1,'2006-11-15 12:00:00','-100.00','Trevor','for being so cool'),(216,2,1,'2006-12-16 12:00:00','-100.00','testing','food buy'),(211,13,1,'2006-11-11 11:11:11','-99.99','test','test desc');
UNLOCK TABLES;
/*!40000 ALTER TABLE `entry` ENABLE KEYS */;

--
-- Table structure for table `entry_event`
--

DROP TABLE IF EXISTS `entry_event`;
CREATE TABLE `entry_event` (
  `ID` int(10) NOT NULL auto_increment,
  `budget_id` int(10) default NULL,
  `fund_id` int(10) default NULL,
  `type` enum('entry','rollover') default NULL,
  `event_time` datetime default NULL,
  `name` varchar(30) default NULL,
  `recurrence` enum('year','month','day') default NULL,
  `frequency` int(5) default NULL,
  `active` int(1) default NULL,
  `amount` decimal(10,2) default NULL,
  `description` varchar(150) default NULL,
  `user_id` int(10) default NULL,
  `entity` varchar(25) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `entry_event`
--


/*!40000 ALTER TABLE `entry_event` DISABLE KEYS */;
LOCK TABLES `entry_event` WRITE;
INSERT INTO `entry_event` VALUES (6,1,4,'entry','2009-01-25 21:36:03','Lancer Payment','month',2,1,'-11.32','blah blah blah blah blah blah',1,'teeters'),(7,1,2,'entry','2006-12-16 00:00:00','Grocery Bill','month',7,1,'-88.82','yummy!',1,'Harris Teeters'),(8,1,2,'entry','2006-09-26 00:00:00','2nd car Payment','month',1,1,'-11.32','blah blah blah blah blah blah',1,'teeters'),(9,1,2,'entry','2006-09-26 00:00:00','food rent','month',1,1,'-11.32','blah blah blah blah blah blah',1,'teeters'),(53,1,52,'rollover','2006-12-01 00:00:01','Rollover from November','month',1,1,NULL,NULL,NULL,NULL),(52,1,3,'entry','2006-12-09 00:00:00','d','month',1,NULL,'-98.00','gfkjhgf',1,'d');
UNLOCK TABLES;
/*!40000 ALTER TABLE `entry_event` ENABLE KEYS */;

--
-- Table structure for table `fund`
--

DROP TABLE IF EXISTS `fund`;
CREATE TABLE `fund` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(30) default NULL,
  `value` decimal(10,2) default NULL,
  `budget_id` int(10) unsigned default NULL,
  `rollover` int(2) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `fund`
--


/*!40000 ALTER TABLE `fund` DISABLE KEYS */;
LOCK TABLES `fund` WRITE;
INSERT INTO `fund` VALUES (3,'Medicine','100.00',1,1),(2,'Food','69.69',1,0),(4,'Car','1000.00',1,NULL),(5,'Anna Fund','60.00',1,NULL),(6,'Trevor','30.00',1,NULL),(7,'Hosting','40.50',2,NULL),(8,'House 2','50.00',1,NULL),(10,'Gas','200.00',1,NULL),(12,'Personal Maintenance','40.00',1,NULL),(13,'Coffe For Anna','15.00',1,NULL),(42,'Date','60.00',1,NULL),(52,'dodo','100.00',1,1),(44,'bye-bye','100.00',1,NULL),(45,'bye-bye','100.00',1,NULL),(46,'bye-bye','100.00',1,NULL),(47,'bye-bye','100.00',1,NULL),(48,'bye-bye','100.00',1,NULL),(49,'bye-bye','100.00',1,NULL),(50,'bye-bye','100.00',1,NULL),(51,'foo','300.00',1,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `fund` ENABLE KEYS */;

--
-- Table structure for table `period`
--

DROP TABLE IF EXISTS `period`;
CREATE TABLE `period` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(25) default NULL,
  `monthly` char(1) default NULL,
  `length` int(10) unsigned default NULL,
  `start_time` datetime default NULL,
  `end_time` datetime default NULL,
  `budget_id` int(10) unsigned default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `period`
--


/*!40000 ALTER TABLE `period` DISABLE KEYS */;
LOCK TABLES `period` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `period` ENABLE KEYS */;

--
-- Table structure for table `tag`
--

DROP TABLE IF EXISTS `tag`;
CREATE TABLE `tag` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `budget_id` int(11) unsigned NOT NULL,
  `name` varchar(25) default NULL,
  `description` varchar(150) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tag`
--


/*!40000 ALTER TABLE `tag` DISABLE KEYS */;
LOCK TABLES `tag` WRITE;
INSERT INTO `tag` VALUES (3,1,'Trip',NULL),(2,1,'Trip',NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `tag` ENABLE KEYS */;

--
-- Table structure for table `tag_entry_assoc`
--

DROP TABLE IF EXISTS `tag_entry_assoc`;
CREATE TABLE `tag_entry_assoc` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `tag_id` int(10) unsigned default NULL,
  `entry_id` int(10) unsigned default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tag_entry_assoc`
--


/*!40000 ALTER TABLE `tag_entry_assoc` DISABLE KEYS */;
LOCK TABLES `tag_entry_assoc` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `tag_entry_assoc` ENABLE KEYS */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `user_name` varchar(25) default NULL,
  `password` varchar(20) NOT NULL,
  `first_name` varchar(25) default NULL,
  `last_name` varchar(25) default NULL,
  `address1` varchar(100) default NULL,
  `address2` varchar(100) default NULL,
  `city` varchar(30) default NULL,
  `state` varchar(30) default NULL,
  `zipcode` int(11) default NULL,
  `country` varchar(30) default NULL,
  `phone` char(20) default NULL,
  `gender` enum('M','F') default NULL,
  `email` varchar(50) default NULL,
  `type` int(1) default NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `user_name` (`user_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `user`
--


/*!40000 ALTER TABLE `user` DISABLE KEYS */;
LOCK TABLES `user` WRITE;
INSERT INTO `user` VALUES (1,'tlittle','6500kHzNYfWPw',NULL,NULL,NULL,NULL,NULL,'TX',NULL,NULL,NULL,NULL,NULL,1),(15,'test','109qlJe/bF3vE','Steven','Little','123 Spring Garden Drive','','Morrisville','AL',35209,NULL,'(919) 622-9952','M','test@example.com',1),(17,'app_user','397FvGHdWdJnY',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

