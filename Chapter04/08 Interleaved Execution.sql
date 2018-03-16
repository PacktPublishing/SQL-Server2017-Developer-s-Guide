--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 04 - Transact-SQL Enhancements
--------  Adaptive Query Processing in SQL Server 2017
--------			Interleaved Execution
--------------------------------------------------------------------

USE WideWorldImporters;
GO
CREATE OR ALTER FUNCTION dbo.SignificantOrders()
RETURNS @T TABLE
(ID INT NOT NULL)
AS
BEGIN
    INSERT INTO @T
    SELECT OrderId FROM Sales.Orders
    RETURN
END
GO

-----------------------------------
----Compatibility Level 130
-----------------------------------
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 130;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT ol.OrderID,  ol.UnitPrice, ol.StockItemID 
FROM Sales.Orderlines ol
INNER JOIN dbo.SignificantOrders() f1 ON f1.Id = ol.OrderID
WHERE PackageTypeID = 7;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
--You can see the Query Optimizer decided to use Nested Loop Operator, since only 100 outputed rows are expected. You can also see that 
--the Actual Number of Rows is 73.595 and due this fixed estimation, the execution plan is not optimal. 

/*
Table 'OrderLines'. Scan count 73595, logical reads 866031, physical reads 47,... 
Table '#AFCC5499'. Scan count 1, logical reads 119, physical reads 0, read-ahead...
SQL Server Execution Times:
   CPU time = 1093 ms,  elapsed time = 2189 ms.
*/
 

-----------------------------------
----Compatibility Level 140
-----------------------------------
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 140;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT ol.OrderID,  ol.UnitPrice, ol.StockItemID 
FROM Sales.Orderlines ol
INNER JOIN dbo.SignificantOrders() f1 ON f1.Id = ol.OrderID
WHERE PackageTypeID = 7;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
--The plan with Hash Match Join is more appopriate for this cardinality.  The execution parameter look better:

/*
Table 'OrderLines'. Scan count 4, logical reads 391, physical reads 0, read-ahead reads 0, lob logical reads 163...
Table 'OrderLines'. Segment reads 1, segment skipped 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0...
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0...
Table '#B2A8C144'. Scan count 1, logical reads 119, physical reads 0, read-ahead reads 0...

 SQL Server Execution Times:
   CPU time = 406 ms,  elapsed time = 1458 ms.
*/

--As you can see, CPU time is reduced more than 50%, and the query executed 33% faster