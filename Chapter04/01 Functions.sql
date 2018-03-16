--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 04 - Transact-SQL Enhancements
--------				Functions
--------------------------------------------------------------------

----------------------------------------------------
-- Functions (STRING_SPLIT)
----------------------------------------------------
--split the input string and return a table
SELECT value 
FROM STRING_SPLIT(N'Rapid Wien,Benfica Lisbon,Seattle Seahawks',',');
/*Result:
value
------
Rapid Wien
Benfica Lisbon
Seattle Seahawks
*/

--get stock items having the tag "16GB"
USE WideWorldImporters;
SELECT StockItemID, StockItemName, Tags 
FROM Warehouse.StockItems 
WHERE '"16GB' IN (SELECT value FROM STRING_SPLIT(REPLACE(REPLACE(Tags,'[',''), ']',''), ','));  
/*
StockItemID StockItemName                                         Tags
----------- ----------------------------------------              ----------------
5            USB food flash drive - hamburger                     ["16GB","USB Powered"]
7            USB food flash drive - pizza slice                   ["16GB","USB Powered"]
9            USB food flash drive - banana                        ["16GB","USB Powered"]
11           USB food flash drive - cookie                        ["16GB","USB Powered"]
13           USB food flash drive - shrimp cocktail               ["16GB","USB Powered"]
15           USB food flash drive - dessert 10 drive variety pack ["16GB","USB Powered"]
*/

--Get order details for comma separated list of order IDs (using STRING_SPLIT)
USE WideWorldImporters;
DECLARE @orderIds AS VARCHAR(100) = '1,3,7,8,9,11';
SELECT o.OrderID, o.CustomerID, o.OrderDate 
FROM Sales.Orders o
INNER JOIN STRING_SPLIT(@orderIds,',') x ON x.value= o.OrderID;
GO
/*Result:
OrderID     CustomerID  OrderDate
----------- ----------- ----------
1           832         2013-01-01
3           105         2013-01-01
7           575         2013-01-01
8           964         2013-01-01
9           77          2013-01-01
11          586         2013-01-01
*/
--Get order details for comma separated list of order IDs (using OPENJSON)
DECLARE @orderIds AS VARCHAR(100) = '1,3,7,8,9,11';
SELECT o.OrderID, o.CustomerID, o.OrderDate 
FROM Sales.Orders o
INNER JOIN (SELECT value FROM OPENJSON( CHAR(91) + @orderIds + CHAR(93) )) x ON x.value= o.OrderID;
GO
/*Result:
OrderID     CustomerID  OrderDate
----------- ----------- ----------
1           832         2013-01-01
3           105         2013-01-01
7           575         2013-01-01
8           964         2013-01-01
9           77          2013-01-01
11          586         2013-01-01
*/

--NULL input produces an empty resultset
DECLARE @input AS NVARCHAR(20) = NULL;
SELECT * FROM STRING_SPLIT(@input,',')
/*Result:
value
--------------------
*/

--The database must be at least in the compatibility level 130, otherwise you'll get exception
USE WideWorldImporters;
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 120;
GO
SELECT value FROM STRING_SPLIT('1,2,3',',');
/*Result:
Msg 208, Level 16, State 1, Line 65
Invalid object name 'STRING_SPLIT'.
*/
--back to the original compatibility level
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 140;
GO

----------------------------------------------------
-- Functions (STRING_ESCAPE)
----------------------------------------------------

--Data type for the input must be string
SELECT STRING_ESCAPE(1, 'JSON') AS escaped_input;
/*Result:

Msg 8116, Level 16, State 1, Line 13
Argument data type int is invalid for argument 1 of string_escape function.
*/

--Deprecated string types TEXT and NTEXT cannot be used, too
DECLARE @input AS TEXT = 'test';
SELECT STRING_ESCAPE(@input, 'JSON') AS escaped_input;

/*Result:

Msg 2739, Level 16, State 1, Line 20
The text, ntext, and image data types are invalid for local variables.
*/

--Escaping string input
SELECT STRING_ESCAPE('a\bc/de"f','JSON') AS escaped_input;
/*Result:

escaped_input
--------------
a\\bc\/de\"f
*/

--Escaping string input
SELECT STRING_ESCAPE(N'one
	"two"
	three/four\', 'JSON')  AS escaped_input;  

/*Result:

escaped_input
------------------------------------
one\r\n\t\"two\"\r\n\tthree\/four\\
*/

--Both keys and values are escaped
SELECT STRING_ESCAPE(N'key:1, i\d:4', 'JSON') AS escaped_input;; 
/*Result:

key:1, i\\d:4
*/

--Escaping control characters
SELECT STRING_ESCAPE(CHAR(0), 'JSON') AS escaped_char0, STRING_ESCAPE(CHAR(4), 'JSON') AS escaped_char4, STRING_ESCAPE(CHAR(31), 'JSON') AS escaped_char31;
/*Result:

escaped_char0	escaped_char4	escaped_char31
--------------	---------------	----------
\u0000			\u0004			\u001f
*/

--Escaping horizontal tab with multiple representations (both end up with the same escaping sequence)
SELECT STRING_ESCAPE(CHAR(9), 'JSON') AS escaped_tab1, STRING_ESCAPE('	', 'JSON') AS escaped_tab2; 
/*Result:

escaped_tab1		escaped_tab2
--------------	--------------
\t				\t 
*/
GO
--NULL as input produces NULL as output
DECLARE @input AS NVARCHAR(20) = NULL;
SELECT STRING_ESCAPE(@input, 'JSON') AS escaped_input;
/*Result:

escaped_input
--------------
NULL
*/

--Do not use it for an already formatted JSON string - all double quotas will be escaped
DECLARE @json AS NVARCHAR(200) = '{
    "id": 1,
    "name": "Milos Radivojevic",
    "country": "Austria",
    "favorite teams": ["Seattle Seahawks", "Benfica Lisbon", "Rapid Wien"]
}';
SELECT STRING_ESCAPE(@json, 'JSON') AS escaped_json; 
/*Result:

{\r\n    \"id\": 1,\r\n    \"name\": \"Milos Radivojevic\",\r\n    \"country\": \"Austria\",\r\n    \"favorite teams\": [\"Seattle Seahawks\", \"Benfica Lisbon\", \"Rapid Wien\"]\r\n}
*/


----------------------------------------------------
-- Functions (STRING_AGG)
----------------------------------------------------

SELECT name FROM sys.databases; 
/*
Result:

name
------------------
master
tempdb
model
msdb
WideWorldImporters
WideWorldImportersDW
*/

--To get a comma separated list of database names
SELECT STRING_AGG (name, ',') AS dbs_as_csv FROM sys.databases;
/*
Result:

dbs_as_csv
------------------
master,tempdb,model,msdb,WideWorldImporters,WideWorldImportersDW
*/

--Column does not need to be of string type. 
--You can use non-string column; data is automatically converted to string
SELECT STRING_AGG (database_id, ',') AS dbiss_as_csv FROM sys.databases;
/*
Result:

dbids_as_csv
-----------------
1,2,3,4,5,6
*/

USE WideWorldImporters;
SELECT STRING_AGG (name, ',') AS cols FROM sys.syscolumns; 
/*
Msg 9829, Level 16, State 1, Line 224
STRING_AGG aggregation result exceeded the limit of 8000 bytes. Use LOB types to avoid result truncation.
*/

--To show a comma separated list of all database columnst, you need to convert the data type of the name column
SELECT STRING_AGG (CAST(name AS NVARCHAR(MAX)), ',') AS cols FROM sys.syscolumns;
/*
cols
----------------------------------
bitpos,cid,colguid,hbcolid,maxinrowlen,nullbit,offset,ordkey,rcmodified,rscolid,rsid...
*/

--handling NULLs
SELECT STRING_AGG(c,',') AS fav_city FROM (VALUES('Vienna'),('Lisbon')) AS T(c)
UNION ALL
SELECT STRING_AGG(c,',') AS fav_city FROM (VALUES('Vienna'),(NULL),('Lisbon')) AS T(c);
/*
fav_city
---------------------------------
Vienna,Lisbon
Vienna,Lisbon
*/

SELECT STRING_AGG(c,',') AS fav_city FROM (VALUES('Vienna'),('Lisbon')) AS T(c)
UNION ALL
SELECT STRING_AGG(COALESCE(c,'N/A'),',') AS fav_city FROM (VALUES('Vienna'),(NULL),('Lisbon')) AS T(c);
/*
dfav_city
---------------------------------
Vienna,Lisbon
Vienna,N/A,Lisbon
*/

--WITHIN GROUP clause
-----------------------
--By using the WITHIN GROUP clause, you can define the ordering for concatenated values
GO
DECLARE @input VARCHAR(20) = '1059,1060,1061';
SELECT CustomerID, STRING_AGG(OrderID, ',') AS OrderIDs
FROM Sales.Orders o
INNER JOIN STRING_SPLIT(@input,',') x ON x.value = o.CustomerID
GROUP BY CustomerID
ORDER BY CustomerID;
/*
CustomerID  OrderIDs
----------- ------------------------------------------------------
1059        68716,69684,70534,71100,71720,71888,73260,73453
1060        72646,72738,72916,73081
1061        72637,72669,72671,72713,72770,72787,73340,73350,7335
*/

GO
--In this example order ids are stored descending:
DECLARE @input VARCHAR(20) = '1059,1060,1061';
SELECT CustomerID, STRING_AGG(OrderID, ',') WITHIN GROUP(ORDER BY OrderID DESC) AS orderids
FROM Sales.Orders o
INNER JOIN STRING_SPLIT(@input,',') x ON x.value = o.CustomerID
GROUP BY CustomerID
ORDER BY CustomerID;
/*
CustomerID  OrderIDs
----------- ------------------------------------------------------
1059        73453,73260,71888,71720,71100,70534,69684,68716
1060        73081,72916,72738,72646
1061        73356,73350,73340,72787,72770,72713,72671,72669,72637
*/

---------------------------------------------------------------------
--Compare SQL_AGG with solutions prior to SQL Server 2017
---------------------------------------------------------------------
--Prior to SQL Server 2017:
GO
CREATE OR ALTER FUNCTION dbo.SplitStrings 
( 
    @input NVARCHAR(MAX), 
    @delimiter CHAR(1) 
) 
RETURNS @output TABLE(item NVARCHAR(MAX) 
) 
BEGIN 
    DECLARE @start INT, @end INT; 
    SELECT @start = 1, @end = CHARINDEX(@delimiter, @input);
    WHILE @start < LEN(@input) + 1 BEGIN 
        IF @end = 0  
            SET @end = LEN(@input) + 1;
       
        INSERT INTO @output (item)  
        VALUES(SUBSTRING(@input, @start, @end - @start)); 
        SET @start = @end + 1;
        SET @end = CHARINDEX(@delimiter, @input, @start);
    END 
    RETURN 
END
GO
DECLARE @input VARCHAR(20) = '1059,1060,1061';
SELECT C.CustomerID,
    STUFF( (SELECT ',' + CAST(OrderId AS VARCHAR(10)) AS [text()]
    FROM Sales.Orders AS O
    WHERE O.CustomerID = C.CustomerID
    ORDER BY OrderID ASC
    FOR XML PATH('')), 1, 1, NULL) AS OrderIDs
FROM Sales.Customers AS C
    INNER JOIN dbo.SplitStrings(@input,',') AS F ON F.item = C.CustomerID
ORDER BY CustomerID;
GO
--SQL Server 2017:
DECLARE @input VARCHAR(20) = '1059,1060,1061';
SELECT CustomerID, STRING_AGG(OrderID, ',') WITHIN GROUP(ORDER BY OrderID ASC) AS OrderIDs
FROM Sales.Orders o
INNER JOIN STRING_SPLIT(@input,',') x ON x.value = o.CustomerID
GROUP BY CustomerID
ORDER BY CustomerID;
/*
CustomerID  OrderIDs
----------- -----------------------------------------------------
1059        68716,69684,70534,71100,71720,71888,73260,73453
1060        72646,72738,72916,73081
1061        72637,72669,72671,72713,72770,72787,73340,73350,73356
*/
----------------------------------------------------
-- Functions (CONCAT_WS)
----------------------------------------------------

SELECT CONCAT_WS(' / ',name, compatibility_level, collation_name) FROM sys.databases WHERE database_id < 5;
/*
 db
-----------------------------------------
master / 140 / SQL_Latin1_General_CP1_CI_AS
tempdb / 140 / SQL_Latin1_General_CP1_CI_AS
model / 140 / SQL_Latin1_General_CP1_CI_AS
msdb / 130 / SQL_Latin1_General_CP1_CI_AS
*/
--For the same output with the CONCAT function, you would need to put the separator after each input string
SELECT CONCAT(name, ' / ', compatibility_level, ' / ', collation_name) AS db FROM sys.databases WHERE database_id < 5;

----------------------------------------------------
-- Functions (TRIM)
----------------------------------------------------

SELECT TRIM('     Patasa  ');
/*
-------------
Patasa
*/
--equivalent to 
SELECT LTRIM(RTRIM('     Patasa  '));
/*
-------------
Patasa
*/
----------------------------------------------------
-- Functions (TRANSLATE)
----------------------------------------------------

--replace square brackets with parenthesis parentheses.
SELECT TRANSLATE('[Sales].[SalesOrderHeader]','[]','()');
/*
---------------------------
(Sales).(SalesOrderHeader)
*/
--equivalent to
SELECT REPLACE(REPLACE('[Sales].[SalesOrderHeader]','[','('),']',')');

--You cannot use TRANSLATE function to replace characters with an empty string (i.e. to remove characters). 
SELECT TRANSLATE('[Sales].[SalesOrderHeader]','[]','');
/*
Msg 9828, Level 16, State 1, Line 390
The second and third arguments of the TRANSLATE built-in function must contain an equal number of characters.
*/

----------------------------------------------------
-- Functions (COMPRESS)
----------------------------------------------------

--Use data collected by the XE session system_health to check potential compression rate for the column target_data
SELECT 
	xet.target_name,
	DATALENGTH(xet.target_data) AS original_size,
	DATALENGTH(COMPRESS(xet.target_data)) AS compressed_size,
	CAST((DATALENGTH(xet.target_data) - DATALENGTH(COMPRESS(xet.target_data)))*100.0/DATALENGTH(xet.target_data) AS DECIMAL(5,2)) AS compression_rate_in_percent
FROM sys.dm_xe_session_targets xet  
INNER JOIN sys.dm_xe_sessions xe ON xe.address = xet.event_session_address  
WHERE xe.name = 'system_health'; 
GO
/*Result (in abbreviated form, you might get different, but similar results)

target_name  original_size   compressed_size  compression_rate_in_pct
------------ --------------  ---------------- -----------------------
ring_buffer  8386188         349846           95.83
event_file   410             235              42.68
You can see that compression rate is about 95%
*/
 
 --Compressed value can be also longer than the original one
DECLARE @input AS NVARCHAR(15) = N'SQL Server 2017'; 
SELECT @input AS input, DATALENGTH(@input) AS input_size, COMPRESS(@input) AS compressed, DATALENGTH(COMPRESS(@input)) AS comp_size;
GO
/*Result

input           input_size  compressed                                                                                                                                                                                                                                                       comp_size
--------------- ----------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------
SQL Server 2017 30          0x1F8B08000000000004000B660864F06150600866486528622803930A0C460C060C860CE60C0000C8F8941E000000                                                                                                                                                                   46

*/

--Compare compression rate between ROW and PAGE compression and the COMPRESS function
--Let's create four sample tables:
USE WideWorldImporters;

--No compression
DROP TABLE IF EXISTS dbo.messages;
SELECT message_id, language_id, severity, is_event_logged, text 
INTO dbo.messages 
FROM sys.messages;
CREATE UNIQUE CLUSTERED INDEX PK_messages ON dbo.messages(message_id, language_id);
GO

--ROW Compression
DROP TABLE IF EXISTS dbo.messages_row;
SELECT message_id, language_id, severity, is_event_logged, text 
INTO dbo.messages_row 
FROM sys.messages;
CREATE UNIQUE CLUSTERED INDEX PK_messages_row ON dbo.messages_row(message_id, language_id) WITH(DATA_COMPRESSION = ROW);
GO

--PAGE Compression
DROP TABLE IF EXISTS dbo.messages_page;
SELECT message_id, language_id, severity, is_event_logged, text 
INTO dbo.messages_page 
FROM sys.messages;
CREATE UNIQUE CLUSTERED INDEX PK_messages_page ON dbo.messages_page(message_id, language_id) WITH(DATA_COMPRESSION = PAGE);
GO

--COMPRESS Function
DROP TABLE IF EXISTS dbo.messages_compress;
SELECT message_id, language_id, severity, is_event_logged, COMPRESS(text) AS text 
INTO dbo.messages_compress 
FROM sys.messages;
CREATE UNIQUE CLUSTERED INDEX PK_messages_compress ON dbo.messages_compress(message_id, language_id);
GO

--Check the size of all tables:
EXEC sp_spaceused 'dbo.messages';
/*Result
name           rows    reserved      data          index_size    unused
-------------- ------- ------------- ------------- ------------- -------
dbo.messages   278718  70216 KB      70000 KB      152 KB        64 KB
*/
EXEC sp_spaceused 'dbo.messages_row';
/*Result
name				rows    reserved      data          index_size    unused
--------------		------- ------------- ------------- ------------- -------
dbo.messages_row	278718  39304 KB      39128 KB      96 KB        80 KB
*/

EXEC sp_spaceused 'dbo.messages_page';
/*Result
name				rows    reserved      data          index_size    unused
--------------		------- ------------- ------------- ------------- -------
dbo.messages_page	278718  39112 KB      38936 KB      96 KB        80 KB
*/
EXEC sp_spaceused 'dbo.messages_compress';
/*Result
name					rows    reserved      data          index_size    unused
--------------			------- ------------- ------------- ------------- -------
dbo.messages_compress	278718  46536 KB      46344 KB      104 KB        88 KB
*/

--Cleanup
DROP TABLE IF EXISTS dbo.messages;
DROP TABLE IF EXISTS dbo.messages_row;
DROP TABLE IF EXISTS dbo.messages_page;
DROP TABLE IF EXISTS dbo.messages_compress;

----------------------------------------------------
-- Functions (DECOMPRESS)
----------------------------------------------------

--the function returns VARBINARY
DECLARE @input AS NVARCHAR(100) = N'SQL Server 2017 Developer''s Guide';
SELECT DECOMPRESS(COMPRESS(@input)) AS input;
GO
/*Result
input
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
0x530051004C00200053006500720076006500720020003200300031003700200044006500760065006C006F0070006500720027007300200047007500690064006500
*/
--to get correct result you need to CAST to original data type 
DECLARE @input AS NVARCHAR(100) = N'SQL Server 2017 Developer''s Guide';
SELECT CAST(DECOMPRESS(COMPRESS(@input)) AS NVARCHAR(100)) AS input;
GO
/*Result

input
-------------------------------------
SQL Server 2017 Developer's Guide
*/

--if you choose non-unicode CAST you will end up with unexpected results 
DECLARE @input AS NVARCHAR(100) = N'SQL Server 2017 Developer''s Guide';
SELECT CAST(DECOMPRESS(COMPRESS(@input)) AS VARCHAR(100)) AS input;
GO
/*Result if you has chosen the option Results to Text to display query results

input
--------------------------------------------------------------------
S Q L   S e r v e r   2 0 1 7   D e v e l o p e r ' s   G u i d e 
*/

/*Result if you has chosen the option Results to Grid to display query results

input
-------
S
*/

--in opposite direction is even more funny
DECLARE @input AS VARCHAR(100) = N'SQL Server 2017 Developer''s Guide';
SELECT CAST(DECOMPRESS(COMPRESS(@input)) AS NVARCHAR(100));
GO
/*Result
兓⁌敓癲牥㈠㄰‷敄敶潬数❲⁳畇摩e
Bing translation to English: 兓 ⁌ 敓 Epilepsy 牥 ㈠㄰‷ 敄 the 敶 潬 number ❲⁳ mo E
*/

----------------------------------------------------
-- Functions (CURRENT_TRANSACTION_ID)
----------------------------------------------------

--Multiple calls of this function will result with different transaction numbers if there is no an explicit transaction
SELECT CURRENT_TRANSACTION_ID();
SELECT CURRENT_TRANSACTION_ID();
BEGIN TRAN
SELECT CURRENT_TRANSACTION_ID();
SELECT CURRENT_TRANSACTION_ID();
COMMIT
GO
/*Result (on my machine, you will definitely get different numbers, but with the same pattern)

921406054
921406055
921406056
921406056
*/

--You could use the function CURRENT_TRANSACTION_ID to check if your transaction in the active transactions:
SELECT * FROM sys.dm_tran_active_transactions WHERE transaction_id = CURRENT_TRANSACTION_ID();

--The function SESSION_ID() works only in Azure Datawarehouse
SELECT SESSION_ID();
/*Result 

Msg 195, Level 15, State 10, Line 133
'SESSION_ID' is not a recognized built-in function name.
*/

----------------------------------------------------
-- Functions (SESSION_CONTEXT)
----------------------------------------------------
--Set session context variable 
EXEC sys.sp_set_session_context @key = N'language', @value = N'German';
--Read the variable
SELECT SESSION_CONTEXT(N'language') AS lng;
GO
/*Result 

lng
------
German
*/

--The input type must be a nvarchar
SELECT SESSION_CONTEXT('language') AS lng;
 /*Result 

Msg 8116, Level 16, State 1, Line 194
Argument data type varchar is invalid for argument 1 of session_context function.
*/

--Even an NCHAR data type cannot be used!
DECLARE @varname NCHAR(10) = N'language';
SELECT SESSION_CONTEXT(@varname) AS lng;
GO
 /*Result 

Msg 8116, Level 16, State 1, Line 203
Argument data type nchar is invalid for argument 1 of session_context function.
*/

--It must be an NVARCHAR data type
DECLARE @varname NVARCHAR(10) = N'language';
SELECT SESSION_CONTEXT(@varname) AS lng;
GO
 /*Result 

lng
--------
German
*/


----------------------------------------------------
-- Functions (DATEDIFF_BIG)
----------------------------------------------------

--Get difference between 1st January 1948 and 1st January 2016 in seconds
SELECT DATEDIFF(SECOND,'19480101','20160101') AS diff;
/*Result 

diff
-----------
2145916800
*/

--Get difference between 1st January 1947 and 1st January 2016 in seconds
SELECT DATEDIFF(SECOND,'19470101','20160101') AS diff;
/*Result 

Msg 535, Level 16, State 0, Line 233
The datediff function resulted in an overflow. The number of dateparts separating two date/time instances is too large. Try to use datediff with a less precise datepart.
*/

--Get difference between 1st January 1947 and 1st January 2016 with the function DATEDIFF_BIG
SELECT DATEDIFF_BIG(SECOND,'19470101','20160101') AS diff;
/*Result 

diff
--------------------
2177452800

*/

--Get difference between min and max date supported by the data type DATETIME2 in microseconds
SELECT DATEDIFF_BIG(MICROSECOND,'010101','99991231 23:59:59.999999999') AS diff;
/*Result 

diff
--------------------
252423993599999999
*/

--Get difference between min and max date supported by the data type DATETIME2 in nanoseconds
SELECT DATEDIFF_BIG(NANOSECOND,'010101','99991231 23:59:59.999999999') AS diff;
/*Result 

Msg 535, Level 16, State 0, Line 255
The datediff_big function resulted in an overflow. The number of dateparts separating two date/time instances is too large. Try to use datediff_big with a less precise datepart.
Even with DATEDIFF_BIG an overflow is possible, but the query is anyway a non-sense
*/

----------------------------------------------------
-- Functions (AT TIME ZONE)
----------------------------------------------------
SELECT  
  CONVERT(DATETIME, SYSDATETIMEOFFSET()) AS UTCTime, 
  CONVERT(DATETIME, SYSDATETIMEOFFSET() AT TIME ZONE 'Eastern Standard Time') AS NewYork_Local, 
  CONVERT(DATETIME, SYSDATETIMEOFFSET() AT TIME ZONE 'Central European Standard Time') AS Vienna_Local; 
  GO
/*Result 
UTCTime                 NewYork_Local           Vienna_Local
----------------------- ----------------------- -----------------------
2018-02-04 22:58:57.440 2018-02-04 16:58:57.440 2018-02-04 22:58:57.440
*/

 
--The following code displays time in four different time zones
SELECT name, CONVERT(DATETIME, SYSDATETIMEOFFSET() AT TIME ZONE name) AS local_time  
FROM sys.time_zone_info 
WHERE name IN (SELECT value FROM STRING_SPLIT('UTC,Eastern Standard Time,Central European Standard Time,Russian Standard Time',',')); 

/*Result 

name                              local_time
--------------------------------- -----------------------
Eastern Standard Time             2018-02-04 11:27:50.193
UTC                               2018-02-04 15:27:50.193
Central European Standard Time    2018-02-04 17:27:50.193
Russian Standard Time             2018-02-04 18:27:50.193
*/

--The values supported for time zone can be found in a new system catalog sys.time_zone_info 
SELECT * FROM sys.time_zone_info;
/*Result (136 entries on my machine and in abbreviated form, you might get slightly different results)
name                                                                                                                             current_utc_offset is_currently_dst
-------------------------------------------------------------------------------------------------------------------------------- ------------------ ----------------
Dateline Standard Time                                                                                                           -12:00             0
UTC-11                                                                                                                           -11:00             0
Aleutian Standard Time                                                                                                           -10:00             0
Hawaiian Standard Time                                                                                                           -10:00             0
Marquesas Standard Time                                                                                                          -09:30             0
Alaskan Standard Time                                                                                                            -09:00             0
UTC-09                                                                                                                           -09:00             0
Pacific Standard Time (Mexico)                                                                                                   -08:00             0

...
Greenwich Standard Time                +00:00             0
W. Europe Standard Time                +02:00             1
Central Europe Standard Time           +02:00             1
Romance Standard Time                  +02:00             1
Central European Standard Time         +02:00             1
W. Central Africa Standard Time        +01:00             0
...
Central Pacific Standard Time                                                                                                    +11:00             0
Russia Time Zone 11                                                                                                              +12:00             0
New Zealand Standard Time                                                                                                        +13:00             1
UTC+12                                                                                                                           +12:00             0
Fiji Standard Time                                                                                                               +12:00             0
Kamchatka Standard Time                                                                                                          +12:00             0
Chatham Islands Standard Time                                                                                                    +13:45             1
UTC+13                                                                                                                           +13:00             0
Tonga Standard Time                                                                                                              +13:00             0
Samoa Standard Time                                                                                                              +14:00             1
Line Islands Standard Time                                                                                                       +14:00             0
*/

--What time is it in Seattle, when a clock in Vienna shows 22:33 today, on Super Bowl Sunday (4th February 2018)?
SELECT CAST('20180204 22:33' AS DATETIME)  
AT TIME ZONE 'Central European Standard Time'  
AT TIME ZONE 'Pacific Standard Time' AS Seattle_Time; 
/*Result
Seattle_Time
---------------------------------
2018-02-04 14:33:00.000 -07:00
*/

----------------------------------------------------
-- Functions (HASHBYTES)
----------------------------------------------------

--You should run this query on SQL Server 2014 or an earlier version
USE AdventureWorks2014;
SELECT HASHBYTES('SHA2_256',(SELECT TOP (6) * FROM Sales.SalesOrderHeader FOR XML AUTO)) AS hashed_value;
/*Result 

hashed_value
------------------------------------------------------------------
0x26C8A739DB7BE2B27BCE757105E159647F70E02F45E56C563BBC3669BEF49AAF
*/

SELECT HASHBYTES('SHA2_256',(SELECT TOP (7) * FROM Sales.SalesOrderHeader FOR XML AUTO)) AS hashed_value;
/*Result 

Msg 8152, Level 16, State 10, Line 19
String or binary data would be truncated
*/


--the same query in SQL Server 2016 (even in the old compatibilty mode)
USE AdventureWorks2016CTP3;
SELECT HASHBYTES('SHA2_256',(SELECT TOP (7) * FROM Sales.SalesOrderHeader FOR XML AUTO)) AS hashed_value;
/*Result 

hashed_value
------------------------------------------------------------------
0x864E9FE792E0E99165B46F43DB43E659CDAD56F80369FD6D2C58AD2E8386CBF3
*/

--In SQL Server 2016 you can hash the whole table
SELECT HASHBYTES('SHA2_256',(SELECT * FROM Sales.SalesOrderHeader FOR XML AUTO)) AS hashed_value;
/*Result 

hashed_value
------------------------------------------------------------------
0x2930C226E613EC838F88D821203221344BA93701D39A72813ABC7C936A8BEACA
*/

--Check hash value for product data mart in the AdventureWorks2016CTP3 database
--You can calculate hash value for the whole data mart and compare it with the value on another instance
--Useful for relativ static tables to check if something related to them has been changed
USE AdventureWorks2016CTP3;
SELECT HASHBYTES('SHA2_256',(SELECT * 
 FROM 
	Production.Product p
	INNER JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
	INNER JOIN Production.ProductCategory c ON sc.ProductCategoryID = c.ProductCategoryID
	INNER JOIN Production.ProductListPriceHistory ph ON ph.ProductID = p.ProductID
	FOR XML AUTO)) AS hashed_value;
/*Result 

hashed_value
------------------------------------------------------------------
0xAFC05E912DC6742B085AFCC2619F158B823B4FE53ED1ABD500B017D7A899D99D
*/

