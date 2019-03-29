DROP TABLE IF EXISTS `dsip_lcr`;
CREATE TABLE `dsip_lcr` (
	    `pattern` varchar(64) NOT NULL DEFAULT '',
	    `key_type` varchar(64) NOT NULL DEFAULT '0',
	    `dr_groupid` varchar(64) NOT NULL DEFAULT '',
	    `value_type` varchar(64) NOT NULL DEFAULT '0',
	    `cost` decimal(3,2) NOT NULL DEFAULT '0.0',
	    `from_prefix` varchar(64) NOT NULL DEFAULT '',
	    `expires` int(11) NOT NULL DEFAULT '0',
	    PRIMARY KEY (`pattern`)
);
