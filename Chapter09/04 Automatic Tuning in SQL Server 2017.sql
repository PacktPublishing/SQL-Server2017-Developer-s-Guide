--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 09 - Query Store
--------- Automatic Tuning in SQL Server 2017
--------------------------------------------------------------------

--------------------------------------------------------------------
-- Offline recommendations - sys.dm_db_tuning_recommendations 
--------------------------------------------------------------------

USE WideWorldImporters;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
ALTER DATABASE WideWorldImporters SET QUERY_STORE = OFF;
GO
ALTER DATABASE WideWorldImporters 
SET QUERY_STORE = ON 
( 
OPERATION_MODE = READ_WRITE, 
INTERVAL_LENGTH_MINUTES = 1 
); 
GO
ALTER DATABASE current SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = Off); 
GO
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 110;
GO
--Ensure that the Discard results after execution option is turned on
--run query with CL 110
SET NOCOUNT ON;
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0,897);
GO 1000

--change CL to the latest one
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 140;
GO

--Ensure that the Discard results after execution option is turned on
--run query with CL 140
SET NOCOUNT ON;
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0,897);
GO 1000

-- check recommendations
SELECT * FROM sys.dm_db_tuning_recommendations;
GO
/*
name            type                    reason                                                valid_since                 last_refresh                state                                                                    is_executable_action is_revertable_action execute_action_start_time   execute_action_duration execute_action_initiated_by                                                                                                                                                                                                                                      execute_action_initiated_time revert_action_start_time    revert_action_duration revert_action_initiated_by                                                                                                                                                                                                                                       revert_action_initiated_time score       details
--------------- ----------------------- ----------------------------------------------------- --------------------------- --------------------------- ------------------------------------------------------------------------ -------------------- -------------------- --------------------------- ----------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------- --------------------------- ---------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------- ----------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PR_1            FORCE_LAST_GOOD_PLAN    Average query CPU time changed from 0.03ms to 8.41ms  2018-02-13 23:39:54.4566667 2018-02-13 23:39:54.4566667 {"currentValue":"Active","reason":"AutomaticTuningOptionNotEnabled"}     1                    0                    NULL                        NULL                    NULL                                                                                                                                                                                                                                                             NULL                          NULL                        NULL                   NULL                                                                                                                                                                                                                                                             NULL                         100         {"planForceDetails":{"queryId":1,"regressedPlanId":2,"regressedPlanExecutionCount":18,"regressedPlanErrorCount":0,"regressedPlanCpuTimeAverage":8.406666666666666e+003,"regressedPlanCpuTimeStddev":9.912169848782452e+002,"recommendedPlanId":1,"recommendedPla
*/

SELECT 
    reason, 
    score,
    details.[query_id],
    details.[regressed_plan_id],
    details.[recommended_plan_id],
    JSON_VALUE(details, '$.implementationDetails.script') AS command
 FROM sys.dm_db_tuning_recommendations
    CROSS APPLY OPENJSON (details, '$.planForceDetails')
        WITH ( 
                query_id INT '$.queryId',
                regressed_plan_id INT '$.regressedPlanId',
                recommended_plan_id INT '$.recommendedPlanId'
              ) AS details;
 GO
/*
reason                                                       score       query_id    regressed_plan_id recommended_plan_id command
------------------------------------------------------------ ----------- ----------- ----------------- ------------------- ------------------------------------------------------------
Average query CPU time changed from 0.03ms to 8.41ms         100         1           2                 1                   exec sp_query_store_force_plan @query_id = 1, @plan_id = 1
*/

--follow recommendation and execute the query from the command column
EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 1;
GO

--execute the query and check the execution plan
SET NOCOUNT ON;
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0,897);
GO
/*
UsePlan="true"
...
<QueryPlan DegreeOfParallelism="1" CachedPlanSize="96" CompileTime="36" CompileCPU="36" CompileMemory="1952" UsePlan="true">
 */
SELECT plan_id, query_id, is_forced_plan FROM sys.query_store_plan;
/*
plan_id              query_id             is_forced_plan
-------------------- -------------------- --------------
1                    1                    1
2                    1                    0
3                    2                    0
4                    1                    0
*/

--------------------------------------------------------------------
-- Automatic Tuning
--------------------------------------------------------------------

USE WideWorldImporters;
GO
ALTER DATABASE current SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON); 
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE = OFF;
GO
ALTER DATABASE WideWorldImporters 
SET QUERY_STORE = ON 
( 
OPERATION_MODE = READ_WRITE, 
INTERVAL_LENGTH_MINUTES = 1 
); 
GO
ALTER DATABASE current SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON); 
GO
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 110;
GO
--Ensure that the Discard results after execution option is turned on
--run query with CL 110
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0,897);
GO 10000

--change CL to the latest one
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 140;
GO

--Ensure that the Discard results after execution option is turned on
--run query with CL 140
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0,897);
GO 10000

--check forced plans
SELECT plan_id, query_id, is_forced_plan FROM sys.query_store_plan;
/*
plan_id              query_id             is_forced_plan
-------------------- -------------------- --------------
1                    1                    1
2                    1                    0
3                    2                    0
*/
--The old plan is automatically forced