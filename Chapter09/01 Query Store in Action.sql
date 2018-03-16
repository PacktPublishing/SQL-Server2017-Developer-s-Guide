--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 09 - Query Store
--------		Query Store in Action
--------------------------------------------------------------------

----------------------------------------------------
-- Getting troubeshooting data form server cache
----------------------------------------------------

USE WideWorldImporters;
--create some workload
EXEC Website.SearchForPeople @SearchText = N'Peter', @MaximumRowsToReturn = 20;
GO 10

--Getting exec plan for a given stored procedure
SELECT 
	c.usecounts, c.cacheobjtype, c.objtype, q.text AS query_text, p.query_plan
FROM 
	sys.dm_exec_cached_plans c
	CROSS APPLY sys.dm_exec_sql_text(c.plan_handle) q
	CROSS APPLY sys.dm_exec_query_plan(c.plan_handle) p
WHERE
	c.objtype = 'Proc' AND q.text LIKE '%SearchForPeople%';


/*Result:
usecounts   cacheobjtype    objtype    query_text                                       query_plan                                                                                                                                                                                                                
----------- -------------   ---------- --------------------------- -------------------- -----------------------------------
10	Compiled Plan			Proc	   CREATE PROCEDURE Website.SearchForPeople.... <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.5" Build="13.0.4001.0"><BatchSequence><Batch><Statements><StmtSimple StatementText="&#xD;&#xA;CREATE PROCEDURE Website.SearchForPeople&#xD;&#xA;@SearchText nvarchar(100
*/

--Getting exec statistics for a given stored procedure
SELECT 
p.name,
s.execution_count,
ISNULL(s.execution_count*60/(DATEDIFF(second, s.cached_time, GETDATE())), 0) AS calls_per_minute,
(s.total_elapsed_time/(1000*s.execution_count)) AS avg_elapsed_time_ms,
s.total_logical_reads/s.execution_count AS avg_logical_reads,
s.last_execution_time,
s.last_elapsed_time/1000 AS last_elapsed_time_ms,
s.last_logical_reads
FROM sys.procedures p
INNER JOIN sys.dm_exec_procedure_stats AS s ON p.object_id = s.object_id AND s.database_id = DB_ID()
WHERE p.name LIKE '%SearchForPeople%';
GO
/*Result:
name               execution_count      calls_per_minute     avg_elapsed_time_ms  avg_logical_reads    last_execution_time     last_elapsed_time_ms last_logical_reads
------------------ -------------------- -------------------- -------------------- -------------------- ----------------------- -------------------- --------------------
SearchForPeople    10                   30                    3                    91                   2017-11-22 22:09:50.677 6                    90
*/


----------------------------------------------------
-- Enable and configure Query Store
----------------------------------------------------
ALTER DATABASE WideWorldImporters
SET QUERY_STORE = ON;
--This is equivalent to
ALTER DATABASE WideWorldImporters
SET QUERY_STORE = ON   
(
	OPERATION_MODE = READ_WRITE,   
	MAX_STORAGE_SIZE_MB = 100,
	DATA_FLUSH_INTERVAL_SECONDS = 900,
	INTERVAL_LENGTH_MINUTES = 60,
	CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 367),
	QUERY_CAPTURE_MODE = ALL,
	SIZE_BASED_CLEANUP_MODE = OFF,
	MAX_PLANS_PER_QUERY = 200
);  

--check Query Store configuration
SELECT * FROM sys.database_query_store_options;

/*Result:
desired_state desired_state_desc                                           actual_state actual_state_desc                                            readonly_reason current_storage_size_mb flush_interval_seconds interval_length_minutes max_storage_size_mb  stale_query_threshold_days max_plans_per_query  query_capture_mode query_capture_mode_desc                                      size_based_cleanup_mode size_based_cleanup_mode_desc                                 actual_state_additional_info
------------- ------------------------------------------------------------ ------------ ------------------------------------------------------------ --------------- ----------------------- ---------------------- ----------------------- -------------------- -------------------------- -------------------- ------------------ ------------------------------------------------------------ ----------------------- ------------------------------------------------------------ ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2             READ_WRITE                                                   2            READ_WRITE                                                   0               11                      3000                   15                      500                  30                         1000                 2                  AUTO                                                         1                       AUTO                                                         
*/

--clearing Query Store
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR; 
--disabling Query Store
ALTER DATABASE WideWorldImporters SET QUERY_STORE = OFF; 
GO

---------------------------------------
--- Query Store Demo
---------------------------------------
ALTER DATABASE WideWorldImporters 
SET QUERY_store = ON    
  ( 
    OPERATION_MODE = READ_WRITE,    
    MAX_STORAGE_SIZE_MB = 100, 
    DATA_FLUSH_INTERVAL_SECONDS = 900, 
    INTERVAL_LENGTH_MINUTES = 60, 
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 367), 
    QUERY_CAPTURE_MODE = ALL, 
    SIZE_BASED_CLEANUP_MODE = OFF, 
    MAX_PLANS_PER_QUERY = 200 
  );  
--check Query Store configuration
SELECT * FROM sys.database_query_store_options;
/*Result:
desired_state desired_state_desc                                           actual_state actual_state_desc                                            readonly_reason current_storage_size_mb flush_interval_seconds interval_length_minutes max_storage_size_mb  stale_query_threshold_days max_plans_per_query  query_capture_mode query_capture_mode_desc                                      size_based_cleanup_mode size_based_cleanup_mode_desc                                 actual_state_additional_info
------------- ------------------------------------------------------------ ------------ ------------------------------------------------------------ --------------- ----------------------- ---------------------- ----------------------- -------------------- -------------------------- -------------------- ------------------ ------------------------------------------------------------ ----------------------- ------------------------------------------------------------ ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2             READ_WRITE                                                   2            READ_WRITE                                                   0               0                       900                    1                       100                  367                        200                  1                  ALL                                                          1                       AUTO                                                         
*/

ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 110;
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR; 
ALTER DATABASE WideWorldImporters
SET QUERY_STORE = ON   
    (  
      OPERATION_MODE = READ_WRITE,   
      INTERVAL_LENGTH_MINUTES = 1   
    );  
--Run this code to execute one statement 100 times 
USE WideWorldImporters;
GO
SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE SalespersonPersonID IN (0, 897);
GO 100 

 --check query store (your results might be different)
SELECT * FROM sys.query_store_query;
/*Result:
query_id             query_text_id        context_settings_id  object_id            batch_sql_handle                                                                           query_hash         is_internal_query query_parameterization_type query_parameterization_type_desc                             initial_compile_start_time         last_compile_start_time            last_execution_time                last_compile_batch_sql_handle                                                              last_compile_batch_offset_start last_compile_batch_offset_end count_compiles       avg_compile_duration   last_compile_duration avg_bind_duration      last_bind_duration   avg_bind_cpu_time      last_bind_cpu_time   avg_optimize_duration  last_optimize_duration avg_optimize_cpu_time  last_optimize_cpu_time avg_compile_memory_kb  last_compile_memory_kb max_compile_memory_kb is_clouddb_internal_query
-------------------- -------------------- -------------------- -------------------- ------------------------------------------------------------------------------------------ ------------------ ----------------- --------------------------- ------------------------------------------------------------ ---------------------------------- ---------------------------------- ---------------------------------- ------------------------------------------------------------------------------------------ ------------------------------- ----------------------------- -------------------- ---------------------- --------------------- ---------------------- -------------------- ---------------------- -------------------- ---------------------- ---------------------- ---------------------- ---------------------- ---------------------- ---------------------- --------------------- -------------------------
1                    1                    1                    0                    NULL                                                                                       0x9048192B43764AA6 0                 0                           None                                                         2018-02-14 00:02:01.4630000 +00:00 2018-02-14 00:02:37.5130000 +00:00 2018-02-14 00:02:06.3670000 +00:00 0x020000009F91EF30E984EF409F05AC93975F3DA1306A836A0000000000000000000000000000000000000000 0                               68                            2                    15203                  14789                 5215                   5509                 5214,5                 5508                 9988                   9280                   9988                   9280                   1488                   1496                   1496                  0
2                    2                    1                    0                    NULL                                                                                       0xA27993CCD0936E0B 0                 0                           None                                                         2018-02-14 00:02:14.4330000 +00:00 2018-02-14 00:02:14.4330000 +00:00 2018-02-14 00:02:14.4370000 +00:00 0x020000009E203F124F62D809CC05C066A95534021684874E0000000000000000000000000000000000000000 0                               296                           1                    4921                   4921                  1648                   1648                 1648                   1648                 3273                   3273                   3273                   3273                   1256                   1256                   1256                  0

 */

SELECT q.query_id, qt.query_sql_text FROM sys.query_store_query q 
INNER JOIN sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id; 
/*
query_id             query_sql_text
-------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1                    SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE SalespersonPersonID IN (0, 897)
2                    SELECT * FROM sys.query_store_query
*/


--get captured execution plans (your results might be different)
SELECT * FROM sys.query_store_plan;
/*Result:
plan_id              query_id             plan_group_id        engine_version                   compatibility_level query_plan_hash    query_plan                                                                                                                                                                                                                                                       is_online_index_plan is_trivial_plan is_parallel_plan is_forced_plan is_natively_compiled force_failure_count  last_force_failure_reason last_force_failure_reason_desc                                                                                                   count_compiles       initial_compile_start_time         last_compile_start_time            last_execution_time                avg_compile_duration   last_compile_duration plan_forcing_type plan_forcing_type_desc
-------------------- -------------------- -------------------- -------------------------------- ------------------- ------------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------------------- --------------- ---------------- -------------- -------------------- -------------------- ------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------- ---------------------------------- ---------------------------------- ---------------------------------- ---------------------- --------------------- ----------------- ------------------------------------------------------------
1                    1                    0                    14.0.1000.169                    110                 0x01184EAB5749F258 <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM Sales.Orders o&#xd;&#xa;INNER JOIN Sales.OrderLines ol ON o.OrderID  0                    0               0                0              0                    0                    0                         NONE                                                                                                                             1                    2018-02-14 00:03:44.7870000 +00:00 2018-02-14 00:03:44.7870000 +00:00 2018-02-14 00:03:44.7930000 +00:00 3939                   3939                  0                 NONE
2                    2                    0                    14.0.1000.169                    110                 0xC63CA0FA9CC60C73 <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM sys.query_store_query" StatementId="1" StatementCompId="1" Statement 0                    0               0                0              0                    0                    0                         NONE                                                                                                                             1                    2018-02-14 00:03:52.5130000 +00:00 2018-02-14 00:03:52.5130000 +00:00 2018-02-14 00:03:58.3100000 +00:00 14101                  14101                 0                 NONE
3                    3                    0                    14.0.1000.169                    110                 0xE2E1199F3FE566C6 <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT q.query_id, qt.query_sql_text FROM sys.query_store_query q &#xd;&#xa;INNER  0                    0               0                0              0                    0                    0                         NONE                                                                                                                             1                    2018-02-14 00:04:03.0630000 +00:00 2018-02-14 00:04:03.0630000 +00:00 2018-02-14 00:04:03.0670000 +00:00 4755                   4755                  0                 NONE
4                    4                    0                    14.0.1000.169                    110                 0xFCB248AB150F795F <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT StatMan([SC0]) FROM (SELECT TOP 100 PERCENT [plan_id] AS [SC0] FROM [sys].[ 0                    1               0                0              0                    0                    0                         NONE                                                                                                                             1                    2018-02-14 00:04:24.9100000 +00:00 2018-02-14 00:04:24.9100000 +00:00 2018-02-14 00:04:24.9100000 +00:00 942                    942                   0                 NONE
5                    5                    0                    14.0.1000.169                    110                 0x400A854E99973BF6 <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM sys.query_store_plan" StatementId="1" StatementCompId="1" StatementT 0                    0               0                0              0                    0                    0                         NONE                                                                                                                             2                    2018-02-14 00:04:24.9030000 +00:00 2018-02-14 00:04:24.9170000 +00:00 NULL                               12126                  12753                 0                 NONE
*/

--get queries and plans with text (your results might be different)
SELECT qs.query_id, q.query_sql_text, CAST(p.query_plan AS XML) AS qplan
FROM sys.query_store_query AS qs 
INNER JOIN sys.query_store_plan AS p ON p.query_id = qs.query_id 
INNER JOIN sys.query_store_query_text AS q ON qs.query_text_id = q.query_text_id
ORDER BY qs.query_id; 
/*Result:
query_id             query_sql_text                                                                                                                                                                                                                                                   query_plan
-------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
query_id             query_sql_text                                                                                                                                                                                                                                                   qplan
-------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1                    SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE SalespersonPersonID IN (0, 897)                                                                                                                                    <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM Sales.Orders o&#xD;&#xA;INNER JOIN Sales.OrderLines ol ON o.OrderID 
2                    SELECT * FROM sys.query_store_query                                                                                                                                                                                                                              <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM sys.query_store_query" StatementId="1" StatementCompId="1" Statement
3                    SELECT q.query_id, qt.query_sql_text FROM sys.query_store_query q 
INNER JOIN sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id                                                                                                            <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT q.query_id, qt.query_sql_text FROM sys.query_store_query q &#xD;&#xA;INNER 
4                    SELECT StatMan([SC0]) FROM (SELECT TOP 100 PERCENT [plan_id] AS [SC0] FROM [sys].[plan_persist_plan] WITH (READUNCOMMITTED)  ORDER BY [SC0] ) AS _MS_UPDSTATS_TBL  OPTION (MAXDOP 16)                                                                            <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT StatMan([SC0]) FROM (SELECT TOP 100 PERCENT [plan_id] AS [SC0] FROM [sys].[
5                    SELECT * FROM sys.query_store_plan                                                                                                                                                                                                                               <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM sys.query_store_plan" StatementId="1" StatementCompId="1" StatementT
6                    SELECT StatMan([SC0]) FROM (SELECT TOP 100 PERCENT [plan_flags] AS [SC0] FROM [sys].[plan_persist_plan] WITH (READUNCOMMITTED)  ORDER BY [SC0] ) AS _MS_UPDSTATS_TBL  OPTION (MAXDOP 16)                                                                         <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT StatMan([SC0]) FROM (SELECT TOP 100 PERCENT [plan_flags] AS [SC0] FROM [sys
7                    SELECT StatMan([SC0]) FROM (SELECT TOP 100 PERCENT [is_forced_plan] AS [SC0] FROM [sys].[plan_persist_plan] WITH (READUNCOMMITTED)  ORDER BY [SC0] ) AS _MS_UPDSTATS_TBL  OPTION (MAXDOP 16)                                                                     <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT StatMan([SC0]) FROM (SELECT TOP 100 PERCENT [is_forced_plan] AS [SC0] FROM 
8                    SELECT StatMan([SC0], [SC1]) FROM (SELECT TOP 100 PERCENT [query_id] AS [SC0], [plan_id] AS [SC1] FROM [sys].[plan_persist_plan] WITH (READUNCOMMITTED)  ORDER BY [SC0], [SC1] ) AS _MS_UPDSTATS_TBL  OPTION (MAXDOP 16)                                         <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT StatMan([SC0], [SC1]) FROM (SELECT TOP 100 PERCENT [query_id] AS [SC0], [pl
9                    SELECT qs.query_id, q.query_sql_text, CAST(p.query_plan AS XML) AS qplan
FROM sys.query_store_query AS qs 
INNER JOIN sys.query_store_plan AS p ON p.query_id = qs.query_id 
INNER JOIN sys.query_store_query_text AS q ON qs.query_text_id = q.query_text_id <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT qs.query_id, q.query_sql_text, CAST(p.query_plan AS XML) AS qplan&#xD;&#xA;
9                    SELECT qs.query_id, q.query_sql_text, CAST(p.query_plan AS XML) AS qplan
FROM sys.query_store_query AS qs 
INNER JOIN sys.query_store_plan AS p ON p.query_id = qs.query_id 
INNER JOIN sys.query_store_query_text AS q ON qs.query_text_id = q.query_text_id <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT qs.query_id, q.query_sql_text, CAST(p.query_plan AS XML) AS qplan&#xD;&#xA;
                                                                                                                                                                                                                              <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.5" Build="13.0.4001.0"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM sys.query_store_plan" StatementId="1" StatementCompId="1" StatementTyp
*/

--Identify queries with multiple execution plans
SELECT query_id, COUNT(*) AS cnt 
FROM sys.query_store_plan p
GROUP BY query_id 
HAVING COUNT(*) > 1 ORDER BY cnt DESC;
/*Result:
no rows, but very useful - you can identify all queries that are executed with more than one execution plan. 
*/

--get runtime stats
SELECT * FROM sys.query_store_runtime_stats;
/*Result:
runtime_stats_id     plan_id              runtime_stats_interval_id execution_type execution_type_desc                                          first_execution_time               last_execution_time                count_executions     avg_duration           last_duration        min_duration         max_duration         stdev_duration         avg_cpu_time           last_cpu_time        min_cpu_time         max_cpu_time         stdev_cpu_time         avg_logical_io_reads   last_logical_io_reads min_logical_io_reads max_logical_io_reads stdev_logical_io_reads avg_logical_io_writes  last_logical_io_writes min_logical_io_writes max_logical_io_writes stdev_logical_io_writes avg_physical_io_reads  last_physical_io_reads min_physical_io_reads max_physical_io_reads stdev_physical_io_reads avg_clr_time           last_clr_time        min_clr_time         max_clr_time         stdev_clr_time         avg_dop                last_dop             min_dop              max_dop              stdev_dop              avg_query_max_used_memory last_query_max_used_memory min_query_max_used_memory max_query_max_used_memory stdev_query_max_used_memory avg_rowcount           last_rowcount        min_rowcount         max_rowcount         stdev_rowcount         avg_num_physical_io_reads last_num_physical_io_reads min_num_physical_io_reads max_num_physical_io_reads stdev_num_physical_io_reads avg_log_bytes_used     last_log_bytes_used  min_log_bytes_used   max_log_bytes_used   stdev_log_bytes_used   avg_tempdb_space_used  last_tempdb_space_used min_tempdb_space_used max_tempdb_space_used stdev_tempdb_space_used
-------------------- -------------------- ------------------------- -------------- ------------------------------------------------------------ ---------------------------------- ---------------------------------- -------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- --------------------- -------------------- -------------------- ---------------------- ---------------------- ---------------------- --------------------- --------------------- ----------------------- ---------------------- ---------------------- --------------------- --------------------- ----------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ------------------------- -------------------------- ------------------------- ------------------------- --------------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ------------------------- -------------------------- ------------------------- ------------------------- --------------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- ---------------------- --------------------- --------------------- -----------------------
4                    4                    2                         0              Regular                                                      2018-02-14 00:04:24.9100000 +00:00 2018-02-14 00:04:24.9100000 +00:00 1                    153                    153                  153                  153                  0                      153                    153                  153                  153                  0                      3                      3                     3                    3                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
6                    6                    2                         0              Regular                                                      2018-02-14 00:04:26.7800000 +00:00 2018-02-14 00:04:26.7800000 +00:00 1                    589                    589                  589                  589                  0                      588                    588                  588                  588                  0                      3                      3                     3                    3                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      128                       128                        128                       128                       0                           1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
8                    8                    2                         0              Regular                                                      2018-02-14 00:04:35.9800000 +00:00 2018-02-14 00:04:35.9800000 +00:00 1                    294                    294                  294                  294                  0                      293                    293                  293                  293                  0                      2                      2                     2                    2                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      128                       128                        128                       128                       0                           1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
1                    1                    1                         0              Regular                                                      2018-02-14 00:03:44.7930000 +00:00 2018-02-14 00:03:44.9600000 +00:00 100                  67,46                  45                   42                   226                  32,8114309349653       67,1                   45                   42                   226                  32,765072867308        4                      4                     4                    4                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
2                    2                    1                         0              Regular                                                      2018-02-14 00:03:52.5300000 +00:00 2018-02-14 00:03:58.3100000 +00:00 2                    206                    141                  141                  271                  65                     206                    141                  141                  271                  65                     5                      6                     4                    6                    1                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           1,5                    2                    1                    2                    0,5                    0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
3                    3                    2                         0              Regular                                                      2018-02-14 00:04:03.0670000 +00:00 2018-02-14 00:04:03.0670000 +00:00 1                    210                    210                  210                  210                  0                      176                    176                  176                  176                  0                      6                      6                     6                    6                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           2                      2                    2                    2                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
5                    5                    2                         0              Regular                                                      2018-02-14 00:04:24.9470000 +00:00 2018-02-14 00:04:24.9470000 +00:00 1                    14754                  14754                14754                14754                0                      10031                  10031                10031                10031                0                      52                     52                    52                   52                   0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      146                       146                        146                       146                       0                           5                      5                    5                    5                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
7                    7                    2                         0              Regular                                                      2018-02-14 00:04:31.7800000 +00:00 2018-02-14 00:04:31.7800000 +00:00 1                    677                    677                  677                  677                  0                      677                    677                  677                  677                  0                      3                      3                     3                    3                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      128                       128                        128                       128                       0                           1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
9                    10                   2                         0              Regular                                                      2018-02-14 00:04:36.0630000 +00:00 2018-02-14 00:04:36.0630000 +00:00 1                    48525                  48525                48525                48525                0                      31839                  31839                31839                31839                0                      144                    144                   144                  144                  0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           10                     10                   10                   10                   0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
10                   11                   3                         0              Regular                                                      2018-02-14 00:05:04.5570000 +00:00 2018-02-14 00:05:04.5570000 +00:00 1                    371                    371                  371                  371                  0                      371                    371                  371                  371                  0                      2                      2                     2                    2                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      128                       128                        128                       128                       0                           1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
*/


--Migration simulation (set comp level to 140)
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 140;
GO
--execute execute sample query again
SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE SalespersonPersonID IN (0, 897);
GO 100 
 
--execution is slow and plan is Clustered Index Scan


--check the plans (you will find two plans for the same query => a new plan is generated under the comp level 130)
SELECT * FROM sys.query_store_plan WHERE query_id = 1;
/*Result:
plan_id              query_id             plan_group_id        engine_version                   compatibility_level query_plan_hash    query_plan                                                                                                                                                                                                                                                       is_online_index_plan is_trivial_plan is_parallel_plan is_forced_plan is_natively_compiled force_failure_count  last_force_failure_reason last_force_failure_reason_desc                                                                                                   count_compiles       initial_compile_start_time         last_compile_start_time            last_execution_time                avg_compile_duration   last_compile_duration plan_forcing_type plan_forcing_type_desc
-------------------- -------------------- -------------------- -------------------------------- ------------------- ------------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------------------- --------------- ---------------- -------------- -------------------- -------------------- ------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------- ---------------------------------- ---------------------------------- ---------------------------------- ---------------------- --------------------- ----------------- ------------------------------------------------------------
1                    1                    0                    14.0.1000.169                    110                 0x01184EAB5749F258 <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM Sales.Orders o&#xd;&#xa;INNER JOIN Sales.OrderLines ol ON o.OrderID  0                    0               0                0              0                    0                    0                         NONE                                                                                                                             1                    2018-02-14 00:03:44.7870000 +00:00 2018-02-14 00:03:44.7870000 +00:00 2018-02-14 00:03:44.7930000 +00:00 3939                   3939                  0                 NONE
16                   1                    0                    14.0.1000.169                    140                 0x2D2172993D117FE1 <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.6" Build="14.0.1000.169"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM Sales.Orders o&#xd;&#xa;INNER JOIN Sales.OrderLines ol ON o.OrderID  0                    0               0                0              0                    0                    0                         NONE                                                                                                                             1                    2018-02-14 00:06:41.0000000 +00:00 2018-02-14 00:06:41.0000000 +00:00 2018-02-14 00:06:47.0100000 +00:00 4716                   4716                  0                 NONE
*/

--force the old plan
EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 1;


--execute query and check the plan
SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE SalespersonPersonID IN (0, 897);
--execution is fast and plan is Index Seek + Key Lookup

--unforce the plan
EXEC sp_query_store_unforce_plan @query_id = 1, @plan_id = 1;
GO

--execute query and check the plan
SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE SalespersonPersonID IN (0, 897);
--execution is again slow and the plan is Clustered Index Scan


--Indetify ad-hoc queries
SELECT p.query_id
FROM sys.query_store_plan p
INNER JOIN sys.query_store_runtime_stats s ON p.plan_id = s.plan_id
GROUP BY p.query_id
HAVING SUM(s.count_executions) = 1;
/*Result:
 query_id
--------------------
9
6
7
1
10
4
5
8
*/
