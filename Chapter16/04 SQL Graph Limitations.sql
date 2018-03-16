--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 16 - Graph Databases
--------	   SQL Graph Limitations
--------------------------------------------------------------------


-----------------------------------------
--Validation issues in edge tables
-----------------------------------------

--prevent duplicates in the table (cannot fopllow the same person multiple times)
ALTER TABLE dbo.UserFollows ADD CONSTRAINT CHK_UserFollows CHECK (UserId <> FollowingUserId); 
GO
INSERT INTO dbo.UserFollows VALUES (1, 1);
GO
/*
Msg 547, Level 16, State 0, Line 15
The INSERT statement conflicted with the CHECK constraint "CHK_UserFollows". The conflict occurred in database "bwinBCF_CI", table "dbo.UserFollows".
The statement has been terminated.
*/

--in the edge table, you need a trigger
CREATE TRIGGER dbo.TG1 ON dbo.Follows
    FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS(SELECT 1 FROM inserted WHERE inserted.$from_id = inserted.$to_id)
    BEGIN
        RAISERROR('User cannot follow himself!',16,1);
        ROLLBACK TRAN;
    END
END
GO

--let's try
INSERT INTO dbo.Follows  VALUES('{"type":"node","schema":"dbo","table":"TwitterUser","id":0}','{"type":"node","schema":"dbo","table":"TwitterUser","id":0}');
GO
/*
Msg 50000, Level 16, State 1, Procedure TG1, Line 7 [Batch Start Line 36]
User cannot follow himself!
Msg 3609, Level 16, State 1, Line 37
The transaction ended in the trigger. The batch has been aborted.
*/


-------------------------------------
--Referencing a non-existing node
-------------------------------------

--there are no nodes with the id of 45 and 65 and thus the next statement should not work
INSERT INTO dbo.Follows  VALUES('{"type":"node","schema":"dbo","table":"TwitterUser","id":45}','{"type":"node","schema":"dbo","table":"TwitterUser","id":65}');
GO
/*

(1 row affected)
*/

--again trigger
CREATE TRIGGER dbo.TG2 ON dbo.Follows
    FOR INSERT, UPDATE
AS
BEGIN
    IF NOT EXISTS(SELECT 1 FROM inserted 
        INNER JOIN dbo.TwitterUser tu ON inserted.$from_id = tu.$node_id
        INNER JOIN dbo.TwitterUser tu2 ON inserted.$to_id = tu2.$node_id
        )
    BEGIN
        RAISERROR('At least one node does not exist!',16,1);
        ROLLBACK TRAN;
    END
END
GO

--try again
INSERT INTO dbo.Follows  VALUES('{"type":"node","schema":"dbo","table":"TwitterUser","id":87}','{"type":"node","schema":"dbo","table":"TwitterUser","id":94}');
GO
/*
Msg 50000, Level 16, State 1, Procedure TG2, Line 10 [Batch Start Line 73]
At least one node does not exist!
Msg 3609, Level 16, State 1, Line 74
The transaction ended in the trigger. The batch has been aborted.
*/


--If you specify a non-existing node table, the INSERT will fail:
INSERT INTO dbo.Follows  VALUES('{"type":"node","schema":"dbo","table":"Table7","id":87}','{"type":"node","schema":"dbo","table":"TwitterUser","id":94}');
GO
/*
Msg 515, Level 16, State 2, Line 85
Cannot insert the value NULL into column 'from_obj_id_9F2B153136974F9D82EB1038C3114951', table 'bwinBCF_CI.dbo.Follows'; column does not allow nulls. INSERT fails.
The statement has been terminated.
*/
--This issue is prevented by design and you don't need to use a trigger


-------------------------------------
---Duplicates in an edge table
-------------------------------------
INSERT INTO dbo.Follows  VALUES('{"type":"node","schema":"dbo","table":"TwitterUser","id":0}','{"type":"node","schema":"dbo","table":"TwitterUser","id":1}');
GO
/*
(1 row affected)

*/
--When you check the content of the edge table 
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
{"type":"edge","schema":"dbo","table":"Follows","id":15}                                                                                                                                                                                                         {"type":"node","schema":"dbo","table":"TwitterUser","id":45}                                                                                                                                                                                                     {"type":"node","schema":"dbo","table":"TwitterUser","id":65}
{"type":"edge","schema":"dbo","table":"Follows","id":18}                                                                                                                                                                                                         {"type":"node","schema":"dbo","table":"TwitterUser","id":0}                                                                                                                                                                                                      {"type":"node","schema":"dbo","table":"TwitterUser","id":1}
*/

---Of course, the problem will be solved with another trigger, but before that
--you have to delete the last entry in this table by using the following statement:
DELETE FROM dbo.Follows WHERE $edge_id='{"type":"edge","schema":"dbo","table":"Follows","id":18}';
DELETE FROM dbo.Follows WHERE $edge_id='{"type":"edge","schema":"dbo","table":"Follows","id":15}';

--trigger
CREATE TRIGGER dbo.TG3 ON dbo.Follows
    FOR INSERT, UPDATE
AS
BEGIN
    IF (( SELECT COUNT(*) FROM inserted INNER JOIN dbo.Follows f ON inserted.$from_id = f.$from_id AND inserted.$to_id = f.$to_id  ) >0)
    BEGIN
        RAISERROR('Duplicates not allowed!',16,1);
        ROLLBACK TRAN;
    END
END
GO

--try
INSERT INTO dbo.Follows  VALUES('{"type":"node","schema":"dbo","table":"TwitterUser","id":0}','{"type":"node","schema":"dbo","table":"TwitterUser","id":1}');
GO
/*
Msg 50000, Level 16, State 1, Procedure TG3, Line 7 [Batch Start Line 147]
Duplicates not allowed!
Msg 3609, Level 16, State 1, Line 148
The transaction ended in the trigger. The batch has been aborted.
*/


------------------------------------------------
---Deleting parent records with children 
------------------------------------------------

BEGIN TRAN
    SELECT t2.UserName
    FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
    WHERE MATCH (t1-(Follows)->t2) AND t1.UserName = '@MilosSQL';

    DELETE dbo.TwitterUser WHERE UserId = 5;

    SELECT t2.UserName
    FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
    WHERE MATCH (t1-(Follows)->t2) AND t1.UserName = '@MilosSQL';
ROLLBACK
/*
Msg 547, Level 16, State 0, Line 167
The DELETE statement conflicted with the REFERENCE constraint "FK_UserFollows_TwitterUser1". The conflict occurred in database "bwinBCF_CI", table "dbo.UserFollows", column 'UserId'.
The statement has been terminated.
*/


BEGIN TRAN
    SELECT t2.UserName
    FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
    WHERE MATCH (t1-(Follows)->t2) AND t1.UserName = '@MilosSQL';

    ALTER TABLE dbo.UserFollows DROP CONSTRAINT FK_UserFollows_TwitterUser1;
    ALTER TABLE dbo.UserFollows DROP CONSTRAINT FK_UserFollows_TwitterUser2;

    DELETE dbo.TwitterUser WHERE UserId = 5;

    SELECT t2.UserName
    FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
    WHERE MATCH (t1-(Follows)->t2) AND t1.UserName = '@MilosSQL';
ROLLBACK
/*
UserName
----------------------------------------------------------------------------------------------------
@DejanSarka
@sql_williamd
@tomaz_tsql
@WienerSportklub

UserName
----------------------------------------------------------------------------------------------------
@DejanSarka
@sql_williamd
@tomaz_tsql
NULL
*/

--another trigger
CREATE TRIGGER dbo.TG4 ON dbo.TwitterUser
    FOR DELETE
AS
BEGIN
    IF (
        EXISTS(SELECT 1 FROM deleted INNER JOIN dbo.Follows f ON f.$from_id = deleted.$node_id)
        OR 
        EXISTS(SELECT 1 FROM deleted INNER JOIN dbo.Follows f ON f.$to_id = deleted.$node_id)
    )
    BEGIN
        RAISERROR('Node cannot be deleted if it is referenced in an edge table',16,1);
        ROLLBACK TRAN;
    END
END
GO

--repeat the second command
BEGIN TRAN
    SELECT t2.UserName
    FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
    WHERE MATCH (t1-(Follows)->t2) AND t1.UserName = '@MilosSQL';

    ALTER TABLE dbo.UserFollows DROP CONSTRAINT FK_UserFollows_TwitterUser1;
    ALTER TABLE dbo.UserFollows DROP CONSTRAINT FK_UserFollows_TwitterUser2;

    DELETE dbo.TwitterUser WHERE UserId = 5;

    SELECT t2.UserName
    FROM dbo.TwitterUser t1, dbo.TwitterUser t2, dbo.Follows
    WHERE MATCH (t1-(Follows)->t2) AND t1.UserName = '@MilosSQL';
ROLLBACK

/*
UserName
----------------------------------------------------------------------------------------------------
@DejanSarka
@sql_williamd
@tomaz_tsql
@WienerSportklub

Msg 50000, Level 16, State 1, Procedure TG4, Line 11 [Batch Start Line 227]
Node cannot be deleted if it is referenced in an edge table
Msg 3609, Level 16, State 1, Line 236
The transaction ended in the trigger. The batch has been aborted.
*/

