------------------------------------------------------
-------   SQL Server 2017 Developer’s Guide    -------
------   Chapter 08 - Tightening the Security  -------
------------------------------------------------------

----------------------------------------------------
-- Section 2: Data Encryption
-- Always Encrypted Session 2
----------------------------------------------------

-- Right-click in this window and choose Connection, then Change Connection
-- In the connection dialog, click Options
-- Type AEDemo for the database name
-- Click on Additional Connection Parameters and enter
-- Column Encryption Setting=enabled
-- Click Connect


-- Try to insert data
INSERT INTO dbo.Table1
 (id, SecretDeterministic, SecretRandomized)
VALUES (3, N'DeterSec03', N'RandomSec3');
GO
/* Error
Msg 206, Level 16, State 2, Line 93
Operand type clash: nvarchar is incompatible with nvarchar(4000) 
 encrypted with (encryption_type = 'DETERMINISTIC', 
 encryption_algorithm_name = 'AEAD_AES_256_CBC_HMAC_SHA_256', 
 column_encryption_key_name = 'AE_ColumnEncryptionKey', 
 column_encryption_key_database_name = 'AEDemo')
*/
-- Still does not work -
-- insert must be parametrized and data encrypted by the client application
-- This works in SSMS 17.X

-- Try to insert data parameterized
DECLARE @p1 NVARCHAR(10)  = N'DeterSec03';
DECLARE @p2 NVARCHAR(10)  = N'RandomSec3';
INSERT INTO dbo.Table1
 (id, SecretDeterministic, SecretRandomized)
VALUES (3, @p1, @p2);
GO


-- Select works
SELECT * 
FROM dbo.Table1;
GO

-- Close window and continue in the first window
