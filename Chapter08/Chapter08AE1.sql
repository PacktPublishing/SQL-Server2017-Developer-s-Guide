------------------------------------------------------
-------   SQL Server 2017 Developer’s Guide    -------
------   Chapter 08 - Tightening the Security  -------
------------------------------------------------------

----------------------------------------------------
-- Section 2: Data Encryption
-- Always Encrypted Session 1
----------------------------------------------------

USE master;
IF DB_ID(N'AEDemo') IS NULL
   CREATE DATABASE AEDemo;
GO
USE AEDemo;
GO

-- Create the column master key
-- NOTE: USE SSMS GUI!!!
-- Don't execute the following commented code; again, use SSMS GUI.
-- You get different KEY_PATH and AEDEMO.EXE later does not work 
/*
USE AEDemo;
CREATE COLUMN MASTER KEY AE_ColumnMasterKey WITH
(
	KEY_STORE_PROVIDER_NAME = N'MSSQL_CERTIFICATE_STORE',
	KEY_PATH = N'LocalMachine/My/3288264FEFA40F3D188715F96BC2AF9ED211F439';
)
GO
*/
-- Check the column master keys
SELECT * 
FROM sys.column_master_keys;
GO

-- Create the column encryption key
-- Again, use SSMS GUI
-- Don't execute the commented code, it is for an example only
/*
CREATE COLUMN ENCRYPTION KEY AE_ColumnEncryptionKey
WITH VALUES
(
	COLUMN_MASTER_KEY = AE_ColumnMasterKey,
	ALGORITHM = 'RSA_OAEP',
	ENCRYPTED_VALUE = 0x01700000016C006F00630061006C006D0061006300680069006E0065002F006D0079002F00330032003800380032003600340066006500660061003400300066003300640031003800380037003100350066003900360062006300320061006600390065006400320031003100660034003300390035730C0606ED126B052F759D73FE634B745A53343687905ABCCD2FABD823FC4CE0FD86C79C17BEBB04217FD8D08A061F391116AFD831D9C76C05EC35391F37756DC60E9AB43289D44A107F77A691C76FAB49CF3FE6F5D088095A579021D16E0E5EBDA74F5C6A1BF07FC1AA0EBEB3B31E0FDA83367C1EBE3FFC0625B27E07FA4FBACB3ED259AEFF2736884CFA27555DD3016D2F41D3A9E0E38365D8E5259A6783C08CF46B583B953640A6F1D0B05DB45CE5121CF7306E87C16E0675BB30A84611501895B7E63EA373DB65EFB093B2D2AE78DDEFA76DB7CAD1D367D0C2609B5E1A0F5A53F5F9908280AC6F9D24B767FE6031BD47F3BC6AAF0CE74AE3163F0F7F27CC9A25E9E20C7F40638C986344516DC4AA8F2310C222A60C56676A57FC30DC1181EEED1EAD1620A9EB922B2DFBF5737DF587AD887807892639E2E700C3263F53B3A8CDFE2F4715507B01B302EB432EBFF0F9BF1E3456D66580880472D9590538CC5D0CB359F6834762954BAF6612B6DB5D9DE672D99852B46B89D7AF837E20F96A33752FEC2077E77C27BBD1467C71261714AD5A6577859883E78715FE76D8BE3E5AAC621F5D37B2C56F3C475EFDC2E9B0C3BA5D17145BA9D40960B9BA0CD3BE0BD87DF28CD6085B90BEBC10827B4CE35A32ABDC75A1EAFA2DF114461745A7D25902525ED450784D380B9B982D6D68FC6C93350E585F86538EB8060266A77542
);
*/
-- Check the column encryption keys
SELECT * 
FROM sys.column_encryption_keys;
GO

-- A table with one deterministic encryption
-- and one random encryption (salted) columns
-- Try with
CREATE TABLE dbo.T1
(id INT,
 SecretDeterministic NVARCHAR(10) 
  ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = AE_ColumnEncryptionKey,
   ENCRYPTION_TYPE = DETERMINISTIC,
   ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL,
 SecretRandomized NVARCHAR(10) 
  ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = AE_ColumnEncryptionKey,
   ENCRYPTION_TYPE = RANDOMIZED,
   ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
);
GO
/* Error
Msg 33289, Level 16, State 38, Line 59
Cannot create encrypted column 'SecretDeterministic',
 character strings that do not use a *_BIN2 collation cannot be encrypted.
*/

-- Correct
CREATE TABLE dbo.T1
(id INT,
 SecretDeterministic NVARCHAR(10) COLLATE Latin1_General_BIN2 
  ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = AE_ColumnEncryptionKey,
   ENCRYPTION_TYPE = DETERMINISTIC,
   ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL,
 SecretRandomized NVARCHAR(10) COLLATE Latin1_General_BIN2
  ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = AE_ColumnEncryptionKey,
   ENCRYPTION_TYPE = RANDOMIZED,
   ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
);
GO

-- Try to insert data
INSERT INTO dbo.T1
 (id, SecretDeterministic, SecretRandomized)
VALUES (1, N'DeterSec01', N'RandomSec1');
GO
/* Error
Msg 206, Level 16, State 2, Line 93
Operand type clash: nvarchar is incompatible with nvarchar(4000) 
 encrypted with (encryption_type = 'DETERMINISTIC', 
 encryption_algorithm_name = 'AEAD_AES_256_CBC_HMAC_SHA_256', 
 column_encryption_key_name = 'AE_ColumnEncryptionKey', 
 column_encryption_key_database_name = 'AEDemo')
*/

-- Can truncate the table
TRUNCATE TABLE dbo.T1;
GO

-- Run the AEDemo client application to insert two rows
-- Use SQLCMD mode
!!C:\SQL2017DevGuide\AEDemo 1 DeterSec01 RandomSec1
!!C:\SQL2017DevGuide\AEDemo 2 DeterSec02 RandomSec2
GO

-- Try to read the data wihtout the Column Encryption Setting=enabled
SELECT *
FROM dbo.T1;
GO
-- Data is encrypted

-- Use a new query window Always Encrypted Session 2
-- to show how to read the data with the Column Encryption Setting=enabled

-- Index on the deterministic encription
CREATE NONCLUSTERED INDEX NCI_Table1_SecretDeterministic
 ON dbo.T1(SecretDeterministic);
GO
-- Works

-- Index on the random encription
CREATE NONCLUSTERED INDEX NCI_Table1_SecretRandomized
 ON dbo.T1(SecretRandomized);
GO
/* Error
Msg 33282, Level 16, State 2, Line 127
Column 'dbo.Table1.SecretRandomized' is encrypted using
 a randomized encryption type and is therefore not valid for use 
 as a key column in a constraint, index, or statistics.
*/

-- Clean up 
USE master;
IF DB_ID(N'AEDemo') IS NOT NULL
   DROP DATABASE AEDemo;
GO
