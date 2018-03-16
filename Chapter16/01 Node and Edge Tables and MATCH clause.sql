--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 16 - Graph Databases
--------  Node and Edge Tables and MATCH Clause
--------------------------------------------------------------------

----------------------------------------------------
-- Node and Edge Tables
----------------------------------------------------

CREATE TABLE dbo.TwitterUser(
UserId BIGINT NOT NULL,
UserName NVARCHAR(100) NOT NULL
) AS NODE
GO
INSERT INTO dbo.TwitterUser VALUES(1, '@MilosSQL'),(2, '@DejanSarka'),(3, '@sql_williamd'),(4, '@tomaz_tsql'),(5, '@WienerSportklub'),(6, '@nkolimpija');
GO

--check the content
SELECT * FROM dbo.TwitterUser;
/*
$node_id_9D6AC119070742D691F6296A8736E5D3                                  UserId               UserName
-------------------------------------------------------------------------- -------------------- ----------------
{"type":"node","schema":"dbo","table":"TwitterUser","id":0}                1                    @MilosSQL
{"type":"node","schema":"dbo","table":"TwitterUser","id":1}                2                    @DejanSarka
{"type":"node","schema":"dbo","table":"TwitterUser","id":2}                3                    @sql_williamd
{"type":"node","schema":"dbo","table":"TwitterUser","id":3}                4                    @tomaz_tsql
{"type":"node","schema":"dbo","table":"TwitterUser","id":4}                5                    @WienerSportklub
{"type":"node","schema":"dbo","table":"TwitterUser","id":5}                6                    @nkolimpija
*/

--you can referr to the first column by useing $node_id only
SELECT $node_id, UserId, UserName FROM dbo.TwitterUser;
/*
$node_id_9D6AC119070742D691F6296A8736E5D3                                  UserId               UserName
-------------------------------------------------------------------------- -------------------- ----------------
{"type":"node","schema":"dbo","table":"TwitterUser","id":0}                1                    @MilosSQL
{"type":"node","schema":"dbo","table":"TwitterUser","id":1}                2                    @DejanSarka
{"type":"node","schema":"dbo","table":"TwitterUser","id":2}                3                    @sql_williamd
{"type":"node","schema":"dbo","table":"TwitterUser","id":3}                4                    @tomaz_tsql
{"type":"node","schema":"dbo","table":"TwitterUser","id":4}                5                    @WienerSportklub
{"type":"node","schema":"dbo","table":"TwitterUser","id":5}                6                    @nkolimpija
*/

--check all columns
SELECT name, column_id, system_type_id, is_hidden, graph_type_desc 
FROM sys.columns WHERE object_id = OBJECT_ID('dbo.TwitterUser');
/*
name                                                                                                                             column_id   system_type_id is_hidden graph_type_desc
-------------------------------------------------------------------------------------------------------------------------------- ----------- -------------- --------- ------------------------------------------------------------
graph_id_3352B9203BBD4E569E0C0E0A3F677F5C                                                                                        1           127            1         GRAPH_ID
$node_id_9D6AC119070742D691F6296A8736E5D3                                                                                        2           231            0         GRAPH_ID_COMPUTED
UserId                                                                                                                           3           127            0         NULL
UserName                                                                                                                         4           231            0         NULL
*/

--you cannot refer to the first column  
SELECT graph_id_3352B9203BBD4E569E0C0E0A3F677F5C   , $node_id, UserId, UserName FROM dbo.TwitterUser;
/*
Msg 13908, Level 16, State 1, Line 58
Cannot access internal graph column 'graph_id_3352B9203BBD4E569E0C0E0A3F677F5C'.
*/

--It is recommended to create a unique constraint or index on the $node_id column at the time of creation of node table; 
--if one is not created, a default unique, non-clustered index is automatically created and cannot be removed
DROP TABLE IF EXISTS dbo.TwitterUser;
GO
CREATE TABLE dbo.TwitterUser(
UserId BIGINT NOT NULL,
UserName NVARCHAR(100) NOT NULL,
CONSTRAINT PK_TwitterUser PRIMARY KEY CLUSTERED(UserId),
CONSTRAINT UQ_TwitterUser UNIQUE($node_id)
) AS NODE
GO
INSERT INTO dbo.TwitterUser VALUES(1, '@MilosSQL'),(2, '@DejanSarka'),(3, '@sql_williamd'),(4, '@tomaz_tsql'),(5, '@WienerSportklub'),(6, '@nkolimpija');
GO

--create a normal (conjunction) table
CREATE TABLE dbo.UserFollows(
    UserId BIGINT NOT NULL,
    FollowingUserId BIGINT NOT NULL,
CONSTRAINT PK_UserFollows PRIMARY KEY CLUSTERED(
    UserId ASC,
    FollowingUserId ASC)
);
GO
--add foreign keys
ALTER TABLE dbo.UserFollows  WITH CHECK ADD CONSTRAINT FK_UserFollows_TwitterUser1 FOREIGN KEY(UserId) REFERENCES dbo.TwitterUser (UserId);
ALTER TABLE dbo.UserFollows CHECK CONSTRAINT FK_UserFollows_TwitterUser1;
GO
ALTER TABLE dbo.UserFollows  WITH CHECK ADD CONSTRAINT FK_UserFollows_TwitterUser2 FOREIGN KEY(FollowingUserId) REFERENCES dbo.TwitterUser (UserId);
ALTER TABLE dbo.UserFollows CHECK CONSTRAINT FK_UserFollows_TwitterUser2;
GO

--insert some following relations
INSERT INTO dbo.UserFollows VALUES (1,2),(1,3),(1,4),(1,5),(2,1),(2,3),(2,4),(2,6),(3,2),(3,4),(4,1),(4,2),(4,3),(5,1);
GO
/*
(14 rows affected)
*/

--create an edge table
CREATE TABLE dbo.Follows AS EDGE;
GO
--populate the edge table
INSERT INTO dbo.Follows  
SELECT u1.$node_id, u2.$node_id
FROM dbo.UserFollows t  
INNER JOIN dbo.TwitterUser u1 ON t.UserId = u1.UserId
INNER JOIN dbo.TwitterUser u2 ON t.FollowingUserId = u2.UserId;
GO
/*
(14 rows affected)
*/

--check the content
SELECT * FROM dbo.Follows;
/*
$edge_id_E57133E8FF3D48F3AAB1B25877573E56                                                                                                                                                                                                                        $from_id_E0B12D88F4774069A25AF54C31377E5B                                                                                                                                                                                                                        $to_id_5ECEBB0D409943C8A46ECBFAAF030E8F
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
{"type":"edge","schema":"dbo","table":"Follows","id":0}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":0}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":1}
{"type":"edge","schema":"dbo","table":"Follows","id":1}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":0}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":2}
{"type":"edge","schema":"dbo","table":"Follows","id":2}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":0}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":3}
{"type":"edge","schema":"dbo","table":"Follows","id":3}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":0}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":4}
{"type":"edge","schema":"dbo","table":"Follows","id":4}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":1}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":0}
{"type":"edge","schema":"dbo","table":"Follows","id":5}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":1}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":2}
{"type":"edge","schema":"dbo","table":"Follows","id":6}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":1}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":3}
{"type":"edge","schema":"dbo","table":"Follows","id":7}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":1}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":5}
{"type":"edge","schema":"dbo","table":"Follows","id":8}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":2}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":1}
{"type":"edge","schema":"dbo","table":"Follows","id":9}                                                                                                                                                                                                          {"type":"node","schema":"dbo","table":"TwitterUser","id":2}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":3}
{"type":"edge","schema":"dbo","table":"Follows","id":10}                                                                                                                                                                                                         {"type":"node","schema":"dbo","table":"TwitterUser","id":3}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":0}
{"type":"edge","schema":"dbo","table":"Follows","id":11}                                                                                                                                                                                                         {"type":"node","schema":"dbo","table":"TwitterUser","id":3}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":1}
{"type":"edge","schema":"dbo","table":"Follows","id":12}                                                                                                                                                                                                         {"type":"node","schema":"dbo","table":"TwitterUser","id":3}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":2}
{"type":"edge","schema":"dbo","table":"Follows","id":13}                                                                                                                                                                                                         {"type":"node","schema":"dbo","table":"TwitterUser","id":4}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":0}
*/

--you can referr to the first column by useing $edge_id only
SELECT $edge_id, $from_id, $to_id FROM dbo.Follows;
GO

--It is  recommended to create an index on the $from_id and $to_id columns for faster lookups in the direction of the edge table

CREATE CLUSTERED INDEX ixcl ON dbo.Follows($from_id, $to_id);
GO

------------------------------
-- The MATCH clause
------------------------------

--all users followed by the user with the username @MilosSQL:
SELECT t2.UserName
FROM dbo.TwitterUser t1 
INNER JOIN dbo.UserFollows uf ON t1.UserId = uf.UserId
INNER JOIN dbo.TwitterUser t2  ON t2.UserId = uf.FollowingUserId
WHERE t1.UserName = '@MilosSQL';
/*
UserName
----------------------
@DejanSarka
@sql_williamd
@tomaz_tsql
@WienerSportklub
*/

--The same result can be achieved by using the new MATCH clause, as in the following code:
SELECT t2.UserName
FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
WHERE MATCH (t1-(Follows)->t2) AND t1.UserName = '@MilosSQL';
/*
UserName
----------------------
@DejanSarka
@sql_williamd
@tomaz_tsql
@WienerSportklub
*/

--To get the list of users who follow the user @MilosSQL, you can use one of the following two logically equivalent statements:

SELECT t2.UserName
FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
WHERE MATCH (t1<-(Follows)-t2) AND t1.UserName = '@MilosSQL';
GO
SELECT t1.UserName
FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
WHERE MATCH (t1-(Follows)->t2) AND t2.UserName = '@MilosSQL';
GO
/*
UserName
----------------------------------------------------------------------------------------------------
@DejanSarka
@tomaz_tsql
@WienerSportklub

UserName
----------------------------------------------------------------------------------------------------
@DejanSarka
@tomaz_tsql
@WienerSportklub
*/

--get all followers of @MilosSQL followers:
SELECT DISTINCT t3.UserName
FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows f1, dbo.TwitterUser t3, dbo.Follows f2
WHERE MATCH (t1-(f1)->t2-(f2)->t3) AND t1.UserName = '@MilosSQL';
/*
UserName
------------------ 
@DejanSarka
@MilosSQL
@nkolimpija
@sql_williamd
@tomaz_tsql
*/

--The same query with relational tables
SELECT DISTINCT u3.UserName
FROM dbo.TwitterUser u1
INNER JOIN dbo.UserFollows  f ON u1.UserId = f.UserId
INNER JOIN dbo.TwitterUser u2 ON f.FollowingUserId = u2.UserId
INNER JOIN dbo.UserFollows f2 ON u2.UserId = f2.UserId
INNER JOIN dbo.TwitterUser u3 ON f2.FollowingUserId = u3.UserId
WHERE u1.UserName = '@MilosSQL';
/*
UserName
------------------ 
@DejanSarka
@MilosSQL
@nkolimpija
@sql_williamd
@tomaz_tsql
*/
