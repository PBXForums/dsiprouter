// Script generated by Aqua Data Studio Schema Synchronization for MariaDB 10.x 10.5 on Thu Mar 30 06:59:55 CST 2023
// Execute this script on:
// 		kamailio/<All Schemas> - This database/schema will be modified
// to synchronize it with MariaDB 10.x 10.5:
// 		kamailio/<All Schemas>

// This deployment will run without transactions. This could leave your database in an inconsistent state if it fails.
// We recommend backing up the database prior to executing the script.
// We also recommend turning on File > Options > Results > Script Execution > Stop on error.

SET @ORIGINAL_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS = 0
;
SET @ORIGINAL_UNIQUE_CHECKS = @@UNIQUE_CHECKS, UNIQUE_CHECKS = 0
;
SET @ORIGINAL_SQL_MODE = @@SQL_MODE, SQL_MODE = 'ALLOW_INVALID_DATES,NO_AUTO_VALUE_ON_ZERO,NO_AUTO_CREATE_USER,NO_UNSIGNED_SUBTRACTION'
;

// Drop index kamailio.acc_callid
DROP INDEX acc_callid ON acc
;

// Drop check constraint kamailio.CONSTRAINT_1
ALTER TABLE dsip_settings
	DROP CONSTRAINT CONSTRAINT_1
;

// Drop procedure kamailio.update_dsip_settings
DROP PROCEDURE update_dsip_settings
;

// Rebuild table kamailio.cdrs
CREATE TABLE ADS_SSDATA_1680181064695  (
	call_start_time	datetime NOT NULL DEFAULT current_timestamp(),
	calltype       	varchar(20) NULL,
	cdr_id         	bigint(20) UNSIGNED AUTO_INCREMENT NOT NULL,
	cost           	int(11) NOT NULL DEFAULT '0',
	created        	datetime NOT NULL DEFAULT current_timestamp(),
	dst_domain     	varchar(255) NOT NULL DEFAULT '''''',
	dst_gwgroupid  	varchar(10) NOT NULL DEFAULT '''''',
	dst_ousername  	varchar(128) NOT NULL DEFAULT '''''',
	dst_username   	varchar(128) NOT NULL DEFAULT '''''',
	duration       	int(10) UNSIGNED NOT NULL DEFAULT '0',
	fraud          	tinyint(1) NOT NULL DEFAULT '0',
	rated          	int(11) NOT NULL DEFAULT '0',
	sip_call_id    	varchar(255) NOT NULL DEFAULT '''''',
	sip_from_tag   	varchar(128) NOT NULL DEFAULT '''''',
	sip_to_tag     	varchar(128) NOT NULL DEFAULT '''''',
	src_domain     	varchar(255) NOT NULL DEFAULT '''''',
	src_gwgroupid  	varchar(10) NOT NULL DEFAULT '''''',
	src_ip         	varchar(64) NOT NULL DEFAULT '''''',
	src_username   	varchar(128) NOT NULL DEFAULT '''''',
	PRIMARY KEY(cdr_id) USING BTREE
)
;
INSERT INTO ADS_SSDATA_1680181064695(call_start_time, calltype, cdr_id, cost, created, dst_domain, dst_gwgroupid, dst_ousername, dst_username, duration, fraud, rated, sip_call_id, sip_from_tag, sip_to_tag, src_domain, src_gwgroupid, src_ip, src_username)
	SELECT call_start_time, calltype, cdr_id, cost, created, dst_domain, dst_gwgroupid, dst_ousername, dst_username, duration, fraud, rated, sip_call_id, sip_from_tag, sip_to_tag, src_domain, src_gwgroupid, src_ip, src_username
	FROM cdrs
;
DROP TABLE cdrs
;
RENAME TABLE ADS_SSDATA_1680181064695 TO cdrs
;

// Create procedure kamailio.update_dsip_settings
CREATE PROCEDURE update_dsip_settings (IN `NEW_DSIP_ID` varbinary(128), IN `NEW_DSIP_CLUSTER_ID` int(10) unsigned, IN `NEW_DSIP_CLUSTER_SYNC` tinyint(1), IN `NEW_DSIP_PROTO` varchar(16), IN `NEW_DSIP_PORT` int(11), IN `NEW_DSIP_USERNAME` varchar(255), IN `NEW_DSIP_PASSWORD` varbinary(128), IN `NEW_DSIP_IPC_PASS` varbinary(160), IN `NEW_DSIP_API_PROTO` varchar(16), IN `NEW_DSIP_API_PORT` int(11), IN `NEW_DSIP_PRIV_KEY` varchar(255), IN `NEW_DSIP_PID_FILE` varchar(255), IN `NEW_DSIP_UNIX_SOCK` varchar(255), IN `NEW_DSIP_IPC_SOCK` varchar(255), IN `NEW_DSIP_API_TOKEN` varbinary(160), IN `NEW_DSIP_LOG_LEVEL` int(11), IN `NEW_DSIP_LOG_FACILITY` int(11), IN `NEW_DSIP_SSL_KEY` varchar(255), IN `NEW_DSIP_SSL_CERT` varchar(255), IN `NEW_DSIP_SSL_CA` varchar(255), IN `NEW_DSIP_SSL_EMAIL` varchar(255), IN `NEW_DSIP_CERTS_DIR` varchar(255), IN `NEW_VERSION` varchar(32), IN `NEW_DEBUG` tinyint(1), IN `NEW_ROLE` varchar(32), IN `NEW_GUI_INACTIVE_TIMEOUT` int(10) unsigned, IN `NEW_KAM_DB_HOST` varchar(255), IN `NEW_KAM_DB_DRIVER` varchar(255), IN `NEW_KAM_DB_TYPE` varchar(255), IN `NEW_KAM_DB_PORT` varchar(255), IN `NEW_KAM_DB_NAME` varchar(255), IN `NEW_KAM_DB_USER` varchar(255), IN `NEW_KAM_DB_PASS` varbinary(160), IN `NEW_KAM_KAMCMD_PATH` varchar(255), IN `NEW_KAM_CFG_PATH` varchar(255), IN `NEW_KAM_TLSCFG_PATH` varchar(255), IN `NEW_RTP_CFG_PATH` varchar(255), IN `NEW_FLT_CARRIER` int(11), IN `NEW_FLT_PBX` int(11), IN `NEW_FLT_MSTEAMS` int(11), IN `NEW_FLT_OUTBOUND` int(11), IN `NEW_FLT_INBOUND` int(11), IN `NEW_FLT_LCR_MIN` int(11), IN `NEW_FLT_FWD_MIN` int(11), IN `NEW_DEFAULT_AUTH_DOMAIN` varchar(255), IN `NEW_TELEBLOCK_GW_ENABLED` tinyint(1), IN `NEW_TELEBLOCK_GW_IP` varchar(255), IN `NEW_TELEBLOCK_GW_PORT` varchar(255), IN `NEW_TELEBLOCK_MEDIA_IP` varchar(255), IN `NEW_TELEBLOCK_MEDIA_PORT` varchar(255), IN `NEW_FLOWROUTE_ACCESS_KEY` varchar(255), IN `NEW_FLOWROUTE_SECRET_KEY` varchar(255), IN `NEW_FLOWROUTE_API_ROOT_URL` varchar(255), IN `NEW_HOMER_ID` int(11), IN `NEW_HOMER_HEP_HOST` varchar(255), IN `NEW_HOMER_HEP_PORT` int(11), IN `NEW_NETWORK_MODE` int(11), IN `NEW_IPV6_ENABLED` tinyint(1), IN `NEW_INTERNAL_IP_ADDR` varchar(255), IN `NEW_INTERNAL_IP_NET` varchar(255), IN `NEW_INTERNAL_IP6_ADDR` varchar(255), IN `NEW_INTERNAL_IP6_NET` varchar(255), IN `NEW_INTERNAL_FQDN` varchar(255), IN `NEW_EXTERNAL_IP_ADDR` varchar(255), IN `NEW_EXTERNAL_IP6_ADDR` varchar(255), IN `NEW_EXTERNAL_FQDN` varchar(255), IN `NEW_PUBLIC_IFACE` varchar(255), IN `NEW_PRIVATE_IFACE` varchar(255), IN `NEW_UPLOAD_FOLDER` varchar(255), IN `NEW_MAIL_SERVER` varchar(255), IN `NEW_MAIL_PORT` int(11), IN `NEW_MAIL_USE_TLS` tinyint(1), IN `NEW_MAIL_USERNAME` varchar(255), IN `NEW_MAIL_PASSWORD` varbinary(160), IN `NEW_MAIL_ASCII_ATTACHMENTS` tinyint(1), IN `NEW_MAIL_DEFAULT_SENDER` varchar(255), IN `NEW_MAIL_DEFAULT_SUBJECT` varchar(255), IN `NEW_DSIP_CORE_LICENSE` varbinary(128), IN `NEW_DSIP_STIRSHAKEN_LICENSE` varbinary(128), IN `NEW_DSIP_TRANSNEXUS_LICENSE` varbinary(128), IN `NEW_DSIP_MSTEAMS_LICENSE` varbinary(128))
	SQL SECURITY DEFINER
	NOT DETERMINISTIC
	CONTAINS SQL
<Body>
;

// Alter table kamailio.dsip_cdrinfo
ALTER TABLE dsip_cdrinfo MODIFY COLUMN email varchar(255) NOT NULL DEFAULT ''''''
;

// Rebuild table kamailio.dsip_settings
CREATE TABLE ADS_SSDATA_1680181064696  (
	DEBUG                  	tinyint(1) NOT NULL DEFAULT '0',
	DEFAULT_AUTH_DOMAIN    	varchar(255) NOT NULL DEFAULT '''sip.dsiprouter.org''',
	DSIP_API_PORT          	int(11) NOT NULL DEFAULT '5000',
	DSIP_API_PROTO         	varchar(16) NOT NULL DEFAULT '''http''',
	DSIP_API_TOKEN         	varbinary(160) NOT NULL,
	DSIP_CERTS_DIR         	varchar(255) NOT NULL DEFAULT '''/etc/dsiprouter/certs''',
	DSIP_CLUSTER_ID        	int(10) UNSIGNED NOT NULL DEFAULT '1',
	DSIP_CLUSTER_SYNC      	tinyint(1) NOT NULL DEFAULT '1',
	DSIP_CORE_LICENSE      	varbinary(160) NOT NULL DEFAULT '''',
	DSIP_ID                	varbinary(128) NOT NULL DEFAULT '''',
	DSIP_IPC_PASS          	varbinary(160) NOT NULL,
	DSIP_IPC_SOCK          	varchar(255) NOT NULL DEFAULT '''/run/dsiprouter/ipc.sock''',
	DSIP_LOG_FACILITY      	int(11) NOT NULL DEFAULT '18',
	DSIP_LOG_LEVEL         	int(11) NOT NULL DEFAULT '3',
	DSIP_MSTEAMS_LICENSE   	varbinary(160) NOT NULL DEFAULT '''',
	DSIP_PASSWORD          	varbinary(128) NOT NULL DEFAULT '''',
	DSIP_PID_FILE          	varchar(255) NOT NULL DEFAULT '''/run/dsiprouter/dsiprouter.pid''',
	DSIP_PORT              	int(11) NOT NULL DEFAULT '5000',
	DSIP_PRIV_KEY          	varchar(255) NOT NULL DEFAULT '''/etc/dsiprouter/privkey''',
	DSIP_PROTO             	varchar(16) NOT NULL DEFAULT '''http''',
	DSIP_SSL_CA            	varchar(255) NOT NULL DEFAULT '''/etc/dsiprouter/certs/ca-list.pem''',
	DSIP_SSL_CERT          	varchar(255) NOT NULL DEFAULT '''''',
	DSIP_SSL_EMAIL         	varchar(255) NOT NULL DEFAULT '''''',
	DSIP_SSL_KEY           	varchar(255) NOT NULL DEFAULT '''''',
	DSIP_STIRSHAKEN_LICENSE	varbinary(160) NOT NULL DEFAULT '''',
	DSIP_TRANSNEXUS_LICENSE	varbinary(160) NOT NULL DEFAULT '''',
	DSIP_UNIX_SOCK         	varchar(255) NOT NULL DEFAULT '''/run/dsiprouter/dsiprouter.sock''',
	DSIP_USERNAME          	varchar(255) NOT NULL DEFAULT '''admin''',
	EXTERNAL_FQDN          	varchar(255) NOT NULL DEFAULT '''''',
	EXTERNAL_IP_ADDR       	varchar(255) NOT NULL DEFAULT '''''',
	EXTERNAL_IP6_ADDR      	varchar(255) NOT NULL DEFAULT '''''',
	FLOWROUTE_ACCESS_KEY   	varchar(255) NOT NULL DEFAULT '''''',
	FLOWROUTE_API_ROOT_URL 	varchar(255) NOT NULL DEFAULT '''https://api.flowroute.com/v2''',
	FLOWROUTE_SECRET_KEY   	varchar(255) NOT NULL DEFAULT '''''',
	FLT_CARRIER            	int(11) NOT NULL DEFAULT '8',
	FLT_FWD_MIN            	int(11) NOT NULL DEFAULT '20000',
	FLT_INBOUND            	int(11) NOT NULL DEFAULT '9000',
	FLT_LCR_MIN            	int(11) NOT NULL DEFAULT '10000',
	FLT_MSTEAMS            	int(11) NOT NULL DEFAULT '17',
	FLT_OUTBOUND           	int(11) NOT NULL DEFAULT '8000',
	FLT_PBX                	int(11) NOT NULL DEFAULT '9',
	GUI_INACTIVE_TIMEOUT   	int(10) UNSIGNED NOT NULL DEFAULT '20',
	HOMER_HEP_HOST         	varchar(255) NOT NULL DEFAULT '''''',
	HOMER_HEP_PORT         	int(11) NOT NULL DEFAULT '9060',
	HOMER_ID               	int(11) NOT NULL DEFAULT '''',
	INTERNAL_FQDN          	varchar(255) NOT NULL DEFAULT '''''',
	INTERNAL_IP_ADDR       	varchar(255) NOT NULL DEFAULT '''''',
	INTERNAL_IP_NET        	varchar(255) NOT NULL DEFAULT '''''',
	INTERNAL_IP6_ADDR      	varchar(255) NOT NULL DEFAULT '''''',
	INTERNAL_IP6_NET       	varchar(255) NOT NULL DEFAULT '''''',
	IPV6_ENABLED           	tinyint(1) NOT NULL DEFAULT '0',
	KAM_CFG_PATH           	varchar(255) NOT NULL DEFAULT '''/etc/kamailio/kamailio.cfg''',
	KAM_DB_DRIVER          	varchar(255) NOT NULL DEFAULT '''''',
	KAM_DB_HOST            	varchar(255) NOT NULL DEFAULT '''localhost''',
	KAM_DB_NAME            	varchar(255) NOT NULL DEFAULT '''kamailio''',
	KAM_DB_PASS            	varbinary(160) NOT NULL,
	KAM_DB_PORT            	varchar(255) NOT NULL DEFAULT '''3306''',
	KAM_DB_TYPE            	varchar(255) NOT NULL DEFAULT '''mysql''',
	KAM_DB_USER            	varchar(255) NOT NULL DEFAULT '''kamailio''',
	KAM_KAMCMD_PATH        	varchar(255) NOT NULL DEFAULT '''/usr/sbin/kamcmd''',
	KAM_TLSCFG_PATH        	varchar(255) NOT NULL DEFAULT '''/etc/kamailio/tls.cfg''',
	MAIL_ASCII_ATTACHMENTS 	tinyint(1) NOT NULL DEFAULT '0',
	MAIL_DEFAULT_SENDER    	varchar(255) NOT NULL DEFAULT '''DoNotReply@smtp.gmail.com''',
	MAIL_DEFAULT_SUBJECT   	varchar(255) NOT NULL DEFAULT '''dSIPRouter System Notification''',
	MAIL_PASSWORD          	varbinary(160) NOT NULL,
	MAIL_PORT              	int(11) NOT NULL DEFAULT '587',
	MAIL_SERVER            	varchar(255) NOT NULL DEFAULT '''smtp.gmail.com''',
	MAIL_USE_TLS           	tinyint(1) NOT NULL DEFAULT '1',
	MAIL_USERNAME          	varchar(255) NOT NULL DEFAULT '''''',
	NETWORK_MODE           	int(11) NOT NULL DEFAULT '0',
	PRIVATE_IFACE          	varchar(255) NOT NULL DEFAULT '''''',
	PUBLIC_IFACE           	varchar(255) NOT NULL DEFAULT '''''',
	ROLE                   	varchar(32) NOT NULL DEFAULT '''''',
	RTP_CFG_PATH           	varchar(255) NOT NULL DEFAULT '''/etc/kamailio/kamailio.cfg''',
	TELEBLOCK_GW_ENABLED   	tinyint(1) NOT NULL DEFAULT '0',
	TELEBLOCK_GW_IP        	varchar(255) NOT NULL DEFAULT '''62.34.24.22''',
	TELEBLOCK_GW_PORT      	varchar(255) NOT NULL DEFAULT '''5066''',
	TELEBLOCK_MEDIA_IP     	varchar(255) NOT NULL DEFAULT '''''',
	TELEBLOCK_MEDIA_PORT   	varchar(255) NOT NULL DEFAULT '''''',
	UPLOAD_FOLDER          	varchar(255) NOT NULL DEFAULT '''/tmp''',
	VERSION                	varchar(32) NOT NULL DEFAULT '''0.61''',
	PRIMARY KEY(DSIP_ID) USING BTREE
)
;
INSERT INTO ADS_SSDATA_1680181064696(DEBUG, DEFAULT_AUTH_DOMAIN, DSIP_API_PORT, DSIP_API_PROTO, DSIP_API_TOKEN, DSIP_CERTS_DIR, DSIP_CLUSTER_ID, DSIP_CLUSTER_SYNC, DSIP_ID, DSIP_IPC_PASS, DSIP_IPC_SOCK, DSIP_LOG_FACILITY, DSIP_LOG_LEVEL, DSIP_PASSWORD, DSIP_PID_FILE, DSIP_PORT, DSIP_PRIV_KEY, DSIP_PROTO, DSIP_SSL_CA, DSIP_SSL_CERT, DSIP_SSL_EMAIL, DSIP_SSL_KEY, DSIP_UNIX_SOCK, DSIP_USERNAME, EXTERNAL_FQDN, EXTERNAL_IP_ADDR, EXTERNAL_IP6_ADDR, FLOWROUTE_ACCESS_KEY, FLOWROUTE_API_ROOT_URL, FLOWROUTE_SECRET_KEY, FLT_CARRIER, FLT_FWD_MIN, FLT_INBOUND, FLT_LCR_MIN, FLT_MSTEAMS, FLT_OUTBOUND, FLT_PBX, GUI_INACTIVE_TIMEOUT, HOMER_HEP_HOST, HOMER_HEP_PORT, HOMER_ID, INTERNAL_IP_ADDR, INTERNAL_IP_NET, INTERNAL_IP6_ADDR, INTERNAL_IP6_NET, IPV6_ENABLED, KAM_CFG_PATH, KAM_DB_DRIVER, KAM_DB_HOST, KAM_DB_NAME, KAM_DB_PASS, KAM_DB_PORT, KAM_DB_TYPE, KAM_DB_USER, KAM_KAMCMD_PATH, KAM_TLSCFG_PATH, MAIL_ASCII_ATTACHMENTS, MAIL_DEFAULT_SENDER, MAIL_DEFAULT_SUBJECT, MAIL_PASSWORD, MAIL_PORT, MAIL_SERVER, MAIL_USE_TLS, MAIL_USERNAME, NETWORK_MODE, ROLE, RTP_CFG_PATH, TELEBLOCK_GW_ENABLED, TELEBLOCK_GW_IP, TELEBLOCK_GW_PORT, TELEBLOCK_MEDIA_IP, TELEBLOCK_MEDIA_PORT, UPLOAD_FOLDER, VERSION)
	SELECT DEBUG, DEFAULT_AUTH_DOMAIN, DSIP_API_PORT, DSIP_API_PROTO, DSIP_API_TOKEN, DSIP_CERTS_DIR, DSIP_CLUSTER_ID, DSIP_CLUSTER_SYNC, DSIP_ID, DSIP_IPC_PASS, DSIP_IPC_SOCK, DSIP_LOG_FACILITY, DSIP_LOG_LEVEL, DSIP_PASSWORD, DSIP_PID_FILE, DSIP_PORT, DSIP_PRIV_KEY, DSIP_PROTO, DSIP_SSL_CA, DSIP_SSL_CERT, DSIP_SSL_EMAIL, DSIP_SSL_KEY, DSIP_UNIX_SOCK, DSIP_USERNAME, EXTERNAL_FQDN, EXTERNAL_IP_ADDR, EXTERNAL_IP6_ADDR, FLOWROUTE_ACCESS_KEY, FLOWROUTE_API_ROOT_URL, FLOWROUTE_SECRET_KEY, FLT_CARRIER, FLT_FWD_MIN, FLT_INBOUND, FLT_LCR_MIN, FLT_MSTEAMS, FLT_OUTBOUND, FLT_PBX, GUI_INACTIVE_TIMEOUT, HOMER_HEP_HOST, HOMER_HEP_PORT, SQLALCHEMY_SQL_DEBUG, INTERNAL_IP_ADDR, INTERNAL_IP_NET, INTERNAL_IP6_ADDR, INTERNAL_IP6_NET, IPV6_ENABLED, KAM_CFG_PATH, KAM_DB_DRIVER, KAM_DB_HOST, KAM_DB_NAME, KAM_DB_PASS, KAM_DB_PORT, KAM_DB_TYPE, KAM_DB_USER, KAM_KAMCMD_PATH, KAM_TLSCFG_PATH, MAIL_ASCII_ATTACHMENTS, MAIL_DEFAULT_SENDER, MAIL_DEFAULT_SUBJECT, MAIL_PASSWORD, MAIL_PORT, MAIL_SERVER, MAIL_USE_TLS, MAIL_USERNAME, SQLALCHEMY_TRACK_MODIFICATIONS, ROLE, RTP_CFG_PATH, TELEBLOCK_GW_ENABLED, TELEBLOCK_GW_IP, TELEBLOCK_GW_PORT, TELEBLOCK_MEDIA_IP, TELEBLOCK_MEDIA_PORT, UPLOAD_FOLDER, VERSION
	FROM dsip_settings
;
DROP TABLE dsip_settings
;
RENAME TABLE ADS_SSDATA_1680181064696 TO dsip_settings
;

// Create check constraint kamailio.CONSTRAINT_1
ALTER TABLE dsip_settings
	ADD CONSTRAINT CONSTRAINT_1
	CHECK (`ROLE` in ('','outbound','inout'))
;

// Rebuild table kamailio.acc
CREATE TABLE ADS_SSDATA_1680181064697  (
	callid       	varchar(255) NOT NULL DEFAULT '''''',
	calltype     	varchar(20) NULL,
	cdr_id       	int(10) UNSIGNED NOT NULL DEFAULT '0',
	dst_domain   	varchar(255) NOT NULL DEFAULT '''''',
	dst_gwgroupid	varchar(10) NOT NULL DEFAULT '''''',
	dst_ouser    	varchar(128) NOT NULL DEFAULT '''''',
	dst_user     	varchar(128) NOT NULL DEFAULT '''''',
	from_tag     	varchar(128) NOT NULL DEFAULT '''''',
	id           	int(10) UNSIGNED AUTO_INCREMENT NOT NULL,
	method       	varchar(16) NOT NULL DEFAULT '''''',
	sip_code     	char(3) NOT NULL DEFAULT '''''',
	sip_reason   	varchar(255) NOT NULL DEFAULT '''''',
	src_domain   	varchar(255) NOT NULL DEFAULT '''''',
	src_gwgroupid	varchar(10) NOT NULL DEFAULT '''''',
	src_ip       	varchar(64) NOT NULL DEFAULT '''''',
	src_user     	varchar(128) NOT NULL DEFAULT '''''',
	time         	datetime NOT NULL DEFAULT current_timestamp(),
	to_tag       	varchar(128) NOT NULL DEFAULT '''''',
	PRIMARY KEY(id) USING BTREE
)
;
INSERT INTO ADS_SSDATA_1680181064697(callid, calltype, cdr_id, dst_domain, dst_gwgroupid, dst_ouser, dst_user, from_tag, id, method, sip_code, sip_reason, src_domain, src_gwgroupid, src_ip, src_user, time, to_tag)
	SELECT callid, calltype, cdr_id, dst_domain, dst_gwgroupid, dst_ouser, dst_user, from_tag, id, method, sip_code, sip_reason, src_domain, src_gwgroupid, src_ip, src_user, time, to_tag
	FROM acc
;
DROP TABLE acc
;
RENAME TABLE ADS_SSDATA_1680181064697 TO acc
;

// Create index kamailio.acc_callid
CREATE INDEX acc_callid USING BTREE
	ON acc(callid)
;

SET FOREIGN_KEY_CHECKS = @ORIGINAL_FOREIGN_KEY_CHECKS
;
SET UNIQUE_CHECKS = @ORIGINAL_UNIQUE_CHECKS
;
SET SQL_MODE = @ORIGINAL_SQL_MODE
;
