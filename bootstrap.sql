
CREATE DATABASE IF NOT EXISTS iptv;
USE iptv;

--
-- Table structure for table `blacklist`
--

CREATE TABLE IF NOT EXISTS  `blacklist` (
  `channelName` varchar(255) DEFAULT NULL,
  `id` varchar(1000) DEFAULT NULL,
  `user_id` varchar(255) NOT NULL,
  `country` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Table structure for table `dstv`
--

CREATE TABLE IF NOT EXISTS  `dstv` (
  `channel` varchar(255) DEFAULT NULL,
  `url` varchar(1000) DEFAULT NULL,
  `country` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Table structure for table `favorite`
--

CREATE TABLE IF NOT EXISTS  `favorite` (
  `channelName` varchar(255) DEFAULT NULL,
  `id` varchar(1000) DEFAULT NULL,
  `user_id` varchar(255) NOT NULL,
  `country` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

--
-- Table structure for table `master`
--

CREATE TABLE IF NOT EXISTS  `master` (
  `ID` varchar(255) NOT NULL,
  `FNAME` varchar(255) DEFAULT NULL,
  `LNAME` varchar(255) DEFAULT NULL,
  `MNAME` varchar(255) DEFAULT NULL,
  `DOB` date DEFAULT NULL,
  `AUTH` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_swedish_ci DEFAULT NULL,
  `GENDER` varchar(255) DEFAULT NULL,
  `EMAIL` varchar(255) DEFAULT NULL,
  `PHONE` varchar(255) DEFAULT NULL,
  `CATEGORY` varchar(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `master`
--

DELETE FROM `master`;
INSERT INTO `master` (`ID`, `FNAME`, `LNAME`, `MNAME`, `DOB`, `AUTH`, `GENDER`, `EMAIL`, `PHONE`, `CATEGORY`) VALUES
('AKINBOLU', 'KAYODE', 'AKINPELU', 'AKINBOLU', '1986-05-24', '827ccb0eea8a706c4c34a16891f84e7b', 'M', 'KAYODE.AKINPELU@GMAIL.COM', '+2348036105931', 'H'),
('BUNMI', 'BUNMI', 'AKINPELU', 'OLUWASEUN', NULL, '827ccb0eea8a706c4c34a16891f84e7b', 'F', '', '', 'H'),
('SYSADMIN', 'SYSTEM', 'ADMINISTRATOR', 'SYS', '2017-03-07', '827ccb0eea8a706c4c34a16891f84e7b', 'M', '', '', 'H');

--
-- Table structure for table `sessions`
--

CREATE TABLE IF NOT EXISTS  `sessions` (
  `user_id` varchar(100) NOT NULL,
  `session_id` varchar(500) NOT NULL,
  `valid_till` datetime NOT NULL,
  `user_type` varchar(1) NOT NULL DEFAULT 'U',
  `owner_id` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Indexes for table `favorite`
--
ALTER TABLE `favorite`
  ADD UNIQUE KEY `id` (`id`);

--
-- Indexes for table `master`
--
ALTER TABLE `master`
  ADD PRIMARY KEY (`ID`) USING BTREE;


CREATE TABLE `permissions` (
  `owner_id` varchar(50) NOT NULL,
  `viewer_id` varchar(50) NOT NULL,
  `objects` varchar(5000) NOT NULL,
  `actions` varchar(500) NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `auth` varchar(500) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'P@ssw0rd';