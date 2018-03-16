--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 09 - Query Store
--------	Query Store Use Cases 
--------------------------------------------------------------------

--------------------------------
--Identifying ad hoc queries
--------------------------------
SELECT p.query_id 
FROM sys.query_store_plan p 
INNER JOIN sys.query_store_runtime_stats s ON p.plan_id = s.plan_id 
GROUP BY p.query_id 
HAVING SUM(s.count_executions) = 1;


--------------------------------
--Identifying unfinished queries
--------------------------------
ALTER DATABASE WideWorldImporters SET QUERY_store CLEAR ALL;
ALTER DATABASE WideWorldImporters SET QUERY_store = OFF;
ALTER DATABASE WideWorldImporters
SET QUERY_STORE = ON   
    (  
      OPERATION_MODE = READ_WRITE   
    , DATA_FLUSH_INTERVAL_SECONDS = 2000      
    , INTERVAL_LENGTH_MINUTES = 1   
    ); 
GO

--ensure that the latest compatibility mode is applied:
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 140; 
GO

--execute the query and click the Cancel Executing Query button
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID;
GO 

--execute the following query to simulate the Divide by zero error
SELECT TOP (1) OrderID/ (SELECT COUNT(*)
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0,897))
FROM Sales.Orders;
GO 10

--check the runtime statistics
SELECT * FROM sys.query_store_runtime_stats;
/*
runtime_stats_id     plan_id              runtime_stats_interval_id execution_type execution_type_desc                                          first_execution_time               last_execution_time                count_executions     avg_duration           last_duration        min_duration         max_duration         stdev_duration         avg_cpu_time           last_cpu_time        min_cpu_time         max_cpu_time         stdev_cpu_time         avg_logical_io_reads   last_logical_io_reads min_logical_io_reads max_logical_io_reads stdev_logical_io_reads avg_logical_io_writes  last_logical_io_writes min_logical_io_writes max_logical_io_writes stdev_logical_io_writes avg_physical_io_reads  last_physical_io_reads min_physical_io_reads max_physical_io_reads stdev_physical_io_reads avg_clr_time           last_clr_time        min_clr_time         max_clr_time         stdev_clr_time         avg_dop                last_dop             min_dop              max_dop              stdev_dop              avg_query_max_used_memory last_query_max_used_memory min_query_max_used_memory max_query_max_used_memory stdev_query_max_used_memory avg_rowcount           last_rowcount        min_rowcount         max_rowcount         stdev_rowcount         avg_num_physical_io_reads last_num_physical_io_reads min_num_physical_io_reads max_num_physical_io_reads stdev_num_physical_io_reads avg_log_bytes_used     last_log_bytes_used  min_log_bytes_used   max_log_bytes_used   stdev_log_bytes_used   avg_tempdb_space_used  last_tempdb_space_used min_tempdb_space_used max_tempdb_space_used stdev_tempdb_space_used
-------------------- -------------------- ------------------------- -------------- ------------------------------------------------------------ ---------------------------------- ---------------------------------- -------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- --------------------- -------------------- -------------------- ---------------------- ---------------------- ---------------------- --------------------- --------------------- ----------------------- ---------------------- ---------------------- --------------------- --------------------- ----------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ------------------------- -------------------------- ------------------------- ------------------------- --------------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ------------------------- -------------------------- ------------------------- ------------------------- --------------------------- ---------------------- -------------------- -------------------- -------------------- ---------------------- ---------------------- ---------------------- --------------------- --------------------- -----------------------
1                    1                    1                         3              Aborted                                                      2018-02-12 01:02:43.1000000 +00:00 2018-02-12 01:02:43.1000000 +00:00 1                    555722                 555722               555722               555722               0                      236538                 236538               236538               236538               0                      4664                   4664                  4664                 4664                 0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      8340                      8340                       8340                      8340                      0                           1                      1                    1                    1                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
2                    2                    1                         4              Exception                                                    2018-02-12 01:02:45.8770000 +00:00 2018-02-12 01:02:46.2170000 +00:00 8                    996,5                  913                  867                  1156                 106,133171063528       996,5                  913                  867                  1156                 106,133171063528       8                      8                     8                    8                    0                      0                      0                      0                     0                     0                       0                      0                      0                     0                     0                       0                      0                    0                    0                    0                      1                      1                    1                    1                    0                      274                       274                        274                       274                       0                           0                      0                    0                    0                    0                      0                         0                          0                         0                         0                           0                      0                    0                    0                    0                      0                      0                      0                     0                     0
*/