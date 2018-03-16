--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 04 - Transact-SQL Enhancements
--------  Adaptive Query Processing in SQL Server 2017
--------		Adaptive Batch Mode JOIN
--------------------------------------------------------------------

USE WideWorldImporters;
GO
--create a sample stored procedure
CREATE OR ALTER PROCEDURE dbo.GetSomeOrderDeatils
@UnitPrice DECIMAL(18,2)
AS
SELECT o.OrderID, o.OrderDate, ol.OrderLineID, ol.Quantity, ol.UnitPrice
FROM Sales.OrderLines ol
INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
WHERE ol.UnitPrice = @UnitPrice;
GO
--execute with the Include Actual Execution Plan option:
EXEC dbo.GetSomeOrderDeatils 112;
--You can see new Adaptive Join operator in the execution plan. 
--Adaptive Threshold Rows = 97,3, number of rows is 1004 and it exceeds the threshold, 
--therefore the Hash Mach Join operator is implemented. 

--execute with the Include Actual Execution Plan option:
EXEC dbo.GetSomeOrderDeatils 1;
--This time, the actual number of rows is 32 and since this is under the threshold, 
--the branch 3 is executed and the property Actual Join Type has value NestedLoops.


--To see what's going on under the hood, when Adaptive Join is used, 
--you need to enable the trace flag 9415 
DBCC TRACEON (9415);
EXEC dbo.GetSomeOrderDeatils 112;
--As you can see, the Adaptive Join uses the extended Concatenation and Table Spool operators.
GO

--Disable adaptive batch mode joins
ALTER DATABASE SCOPED CONFIGURATION SET DISABLE_BATCH_MODE_ADAPTIVE_JOINS = ON;
GO

--You can also use the query hint DISABLE_BATCH_MODE_ADAPTIVE_JOINS to disable this feature. 
CREATE OR ALTER PROCEDURE dbo.GetSomeOrderDeatils
@UnitPrice DECIMAL(18,2)
AS
SELECT o.OrderID, o.OrderDate, ol.OrderLineID, ol.Quantity, ol.UnitPrice
FROM Sales.OrderLines ol
INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
WHERE ol.UnitPrice = @UnitPrice 
OPTION (USE HINT ('DISABLE_BATCH_MODE_ADAPTIVE_JOINS'));

--Now, invoke the procedure
EXEC dbo.GetSomeOrderDeatils 112;
--As you expected, no Adaptive Join operator is shown. 
--Cleanup
DROP PROCEDURE IF EXISTS dbo.GetSomeOrderDeatils;
GO