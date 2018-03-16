--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 16 - Graph Databases
--------	  SQL Graph System Functions
--------------------------------------------------------------------


------------------------------------------------------------
-- SQL Graph System Functions
------------------------------------------------------------

--The following code returns the object_id for the dbo.TwitterUser node table:
SELECT OBJECT_ID_FROM_NODE_ID('{"type":"node","schema":"dbo","table":"TwitterUser","id":0}');
/*

-----------
902294274
*/

--The following code will still return the correct object_id although there is no an entry in the node table with the value 567890 for the graph_id column:

SELECT OBJECT_ID_FROM_NODE_ID('{"type":"node","schema":"dbo","table":"TwitterUser","id":567890}');
/*

-----------
902294274
*/

SELECT OBJECT_ID_FROM_NODE_ID('abc');
SELECT OBJECT_ID_FROM_NODE_ID('');
SELECT OBJECT_ID_FROM_NODE_ID(NULL);
/*
-----------
NULL

-----------
NULL

-----------
NULL
*/
--if you provide a non-string input function returns an exception
SELECT OBJECT_ID_FROM_NODE_ID(1);
/*
Msg 8116, Level 16, State 1, Line 269
Argument data type int is invalid for argument 1 of object_id_from_node_id function.
*/


--------------------------------
--GRAPH_ID_FROM_NODE_ID
--------------------------------

--it returns a graph_id for a given node_id. The following code returns the graph_id for the dbo.TwitterUser node table:
SELECT GRAPH_ID_FROM_NODE_ID('{"type":"node","schema":"dbo","table":"TwitterUser","id":0}');
/*
--------------------
0
*/
-- code will return a value although there is no an entry with the value of 567890 for the graph_id in the node table:
SELECT GRAPH_ID_FROM_NODE_ID('{"type":"node","schema":"dbo","table":"TwitterUser","id":567890}');
/*
--------------------
567890
*/

--------------------------------
--NODE_ID_FROM_PARTS 
--------------------------------
-- generates a JSON conforming string for a given node_id from an object_id, with the help of the following code:
SELECT NODE_ID_FROM_PARTS(OBJECT_ID('dbo.TwitterUser'), 0);
/*
-----------------------------------------------------------
{"type":"node","schema":"dbo","table":"TwitterUser","id":0}
*/
--The function return NULL, if a given object_id does not belong to a node tabl 
SELECT NODE_ID_FROM_PARTS(58, 0);
/*
---------------
NULL
*/


--------------------------------
--OBJECT_ID_FROM_EDGE_ID
--------------------------------
 

-- returns the object_id from a given edge_id rather than from a node_id. The following code returns the object_id for the dbo.Followsedge table:
SELECT OBJECT_ID_FROM_EDGE_ID('{"type":"edge","schema":"dbo","table":"Follows","id":1}');
/*
-----------
1014294673
*/

--------------------------------
--GRAPH_ID_FROM_EDGE_ID
--------------------------------

SELECT GRAPH_ID_FROM_EDGE_ID('{"type":"edge","schema":"dbo","table":"Follows","id":1}');
/*
-----------
1
*/

--------------------------------
--EDGE_ID_FROM_PARTS
--------------------------------
 
--It returns the JSON value that corresponds to the value for the in the first row in the dbo.Follows edge table
SELECT EDGE_ID_FROM_PARTS(OBJECT_ID('dbo.Follows'), 1);
/*
-----------------------------------------------------------------------
{"type":"edge","schema":"dbo","table":"Follows","id":1}
*/

