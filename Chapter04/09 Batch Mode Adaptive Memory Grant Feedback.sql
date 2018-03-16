--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 04 - Transact-SQL Enhancements
--------  Adaptive Query Processing in SQL Server 2017
--------	Batch Mode Adaptive Memory Grant Feedback
--------------------------------------------------------------------

USE WideWorldImporters;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 130;
GO
--create a simple stored procedure
CREATE OR ALTER PROCEDURE dbo.GetOrders
@OrderDate DATETIME
AS
BEGIN
    DECLARE @now DATETIME = @OrderDate;
    SELECT * FROM dbo.Orders
    WHERE orderdate >= @now
    ORDER BY amount DESC;
END
GO
--call the stored procedure with a parameter representing a date in the future 
--and with the Include Actual Execution Plan option:
EXEC dbo.GetOrders '20180101';
--You can see that this query has the memory grant of 263 MB although no rows are returned

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 140;
GO
EXEC dbo.GetOrders '20180101';
GO 20

--execute with the Include Actual Execution Plan option:
EXEC dbo.GetOrders '20180101';
--The execution plan looks the same, as well as memory grants!!!

-- Batch mode adaptive memory grant feedback feature? This feature is available only if affected table has a columnstore index; without an index it won't work. So, you need to create a columnstore index:
CREATE NONCLUSTERED COLUMNSTORE INDEX ixc ON dbo.Orders(id, orderdate,custid, amount) WHERE id  = -4;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.GetOrders '20180101';
--You can see the same execution plan (with a bit different percents near to the plan operators) and slightly higher memory grant - 278 MB.

--Now, turn off the Include Actual Execution Plan option (to allow SSMS to display results faster) and execute the same query 20 times as in the above code:

EXEC dbo.GetOrders '20180101';
GO 20


--execute with the Include Actual Execution Plan option:
EXEC dbo.GetOrders '20180101';
--You can see that after 20 executions of the stored procedure the memory grant has been reduced to 1,7 MB only!!!

EXEC dbo.GetOrders '20000101';
GO 2
--You can see that after additional two executions of the stored procedure, but with a non-selective paramaters, the memory grant has been corrected again; this time it is increased to 596 MB.

--Cleanup
DROP PROCEDURE IF EXISTS dbo.GetOrders;
GO