--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 04 - Transact-SQL Enhancements
--------		Enhanced DML and DDL Statements
--------	    Resumable online index rebuild
--------------------------------------------------------------------


USE WideWorldImporters;
CREATE INDEX IX1 ON Sales.Orderlines (OrderId, StockItemId, UnitPrice);
GO

--You need two connections:
--CONNECTION 1:
ALTER INDEX IX ON Sales.Orderlines
REBUILD WITH (RESUMABLE = ON, ONLINE = ON)
GO
--CONNECTION 2:
USE WideWorldImporters;
ALTER INDEX IX1 ON Sales.OrderLines PAUSE;
GO
-- After you have executed the commands from both windows as described above, in the first window, you will see the following message:
/*
Msg 1219, Level 16, State 1, Line 4
Your session has been disconnected because of a high priority DDL operation.
Msg 1219, Level 16, State 1, Line 4
Your session has been disconnected because of a high priority DDL operation.
Msg 596, Level 21, State 1, Line 3
Cannot continue the execution because the session is in the kill state.
Msg 0, Level 20, State 0, Line 3
A severe error occurred on the current command.  The results, if any, should be discarded.
*/

--Check the status of the rebuild:
SELECT name, sql_text, state_desc, percent_complete, start_time, last_pause_time
FROM sys.index_resumable_operations;
/*
name    state_desc           percent_complete       start_time              last_pause_time
------- -------------------- ---------------------- ----------------------- -----------------------
IX1      PAUSED              23,4927315783105       2017-12-11 13:08:14.223 2017-12-11 13:08:16.203
*/

--CONNECTION 2:
USE WideWorldImporters;
ALTER INDEX IX1 ON Sales.OrderLines RESUME;
GO
--Check the status of the rebuild:
SELECT name, sql_text, state_desc, percent_complete, start_time, last_pause_time
FROM sys.index_resumable_operations;
/*
name    state_desc           percent_complete       start_time              last_pause_time
------- -------------------- ---------------------- ----------------------- -----------------------
 */
 --After the rebuild operation is done, when you query the sys.index_resumable_operations view, there will be no entry for the index that you rebuilt.


ALTER INDEX IX1 ON Sales.Orderlines
REBUILD WITH (RESUMABLE = ON )
GO
/*
Msg 11438, Level 15, State 1, Line 58
The RESUMABLE option cannot be set to 'ON' when the ONLINE option is set to 'OFF'.
*/
ALTER INDEX IX1 ON Sales.OrderLines
REBUILD WITH (RESUMABLE = ON, ONLINE = ON )
GO
/*
Commands completed successfully.
*/

