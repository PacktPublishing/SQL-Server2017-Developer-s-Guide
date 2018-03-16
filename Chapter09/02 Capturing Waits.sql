--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 09 - Query Store
--------		Capturing Waits 
--------------------------------------------------------------------
 
USE WideWorldImporters;
GO
ALTER DATABASE WideWorldImporters SET QUERY_store CLEAR;
ALTER DATABASE WideWorldImporters SET QUERY_store = OFF;
GO
ALTER DATABASE WideWorldImporters 
SET QUERY_STORE = ON 
( 
OPERATION_MODE = READ_WRITE, 
INTERVAL_LENGTH_MINUTES = 1 
); 
GO

--Connection 1
USE WideWorldImporters;
SET NOCOUNT ON;
SELECT *
FROM Sales.Orders o
GO 5

--Connection 2
USE WideWorldImporters;
BEGIN TRAN
UPDATE Sales.Orders SET ContactPersonID = 3003 WHERE OrderID = 1;
--ROLLBACK

--Wait 20 seconds and then finish the transaction by removing the comment near to the ROLLBACK and executing it.

--check the Waits store:
SELECT * FROM sys.query_store_wait_stats;
/*
wait_stats_id        plan_id              runtime_stats_interval_id wait_category wait_category_desc                                           execution_type execution_type_desc                                          total_query_wait_time_ms avg_query_wait_time_ms last_query_wait_time_ms min_query_wait_time_ms max_query_wait_time_ms stdev_query_wait_time_ms
-------------------- -------------------- ------------------------- ------------- ------------------------------------------------------------ -------------- ------------------------------------------------------------ ------------------------ ---------------------- ----------------------- ---------------------- ---------------------- ------------------------
4                    1                    1                         3             Lock                                                         0              Regular                                                      11093                    3697,66666666667       0                       0                      11093                  5229,52864223918
16                   1                    1                         15            Network IO                                                   0              Regular                                                      3557                     1185,66666666667       1254                    1147                   1254                   51,8544115770298
*/

---Find exact wait types

--Connection 1
SELECT *
FROM Sales.Orders o
GO 5

--Connection 2
BEGIN TRAN
UPDATE Sales.Orders SET ContactPersonID = 3003 WHERE OrderID = 1;

--Connection 3
--use the session_id of the query in the first connection
SELECT * FROM sys.dm_os_waiting_tasks WHERE session_id = <Your_Session_Id>;
/*
waiting_task_address session_id exec_context_id wait_duration_ms     wait_type      resource_address   blocking_task_address blocking_session_id blocking_exec_context_id resource_description
-------------------- ---------- --------------- -------------------- -------------- ------------------ --------------------- ------------------- ------------------------ ----------------------------------------------------------------------------------------------------------------------
--0x00000222DF02FC28	54		0				5274				LCK_M_S			0x00000222DAD9B400	NULL				 59					 NULL					  pagelock fileid=3 pageid=1544 dbid=5 subresource=FULL id=lock22298715b80 mode=IX associatedObjectId=72057594047234048
*/

--Wait 20 seconds and then finish the transaction
--Connection 2
ROLLBACK

--Go to the Connection 3
SELECT * FROM sys.dm_os_waiting_tasks WHERE session_id = <Your_Session_Id>;
/*
waiting_task_address session_id exec_context_id wait_duration_ms     wait_type                                                    resource_address   blocking_task_address blocking_session_id blocking_exec_context_id resource_description
-------------------- ---------- --------------- -------------------- ------------------------------------------------------------ ------------------ --------------------- ------------------- ------------------------ ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
0x000002229C19D088   54         0               0                    ASYNC_NETWORK_IO                                             NULL               NULL                  NULL                NULL                     NULL
*/
 
 --Ensure that you have rolled back the transaction in the Connection 2