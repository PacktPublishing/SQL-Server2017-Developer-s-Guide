--------------------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide
--------	Chapter 16 - Graph Databases
--------  Advanced Queries with the MATCH Clause
--------------------------------------------------------------------

----------------------------------------------------
-- Create Node and Edge Tables
----------------------------------------------------

CREATE SCHEMA graph
GO
--node table Movie
CREATE TABLE graph.Movie(
Id INT NOT NULL,
Name NVARCHAR(300) NOT NULL,
ReleaseYear INT NULL,
CONSTRAINT PK_Movie PRIMARY KEY CLUSTERED (Id ASC),
CONSTRAINT UQ_Movie UNIQUE NONCLUSTERED ($node_id)
) AS NODE
GO

--node table Actor
CREATE TABLE graph.Actor(
Id INT NOT NULL,
Name NVARCHAR(150) NOT NULL,
CONSTRAINT PK_Actor PRIMARY KEY CLUSTERED (Id ASC),
CONSTRAINT UQ_Actor UNIQUE NONCLUSTERED ($node_id)
) AS NODE
GO

--node table Director
CREATE TABLE graph.Director(
Id INT NOT NULL,
Name NVARCHAR(150) NOT NULL,
CONSTRAINT PK_Director PRIMARY KEY CLUSTERED (Id ASC),
CONSTRAINT UQ_Director UNIQUE NONCLUSTERED ($node_id)
) AS NODE
GO

--edge table ActsIn
CREATE TABLE graph.ActsIn AS EDGE;
GO
CREATE CLUSTERED INDEX IX2 ON graph.ActsIn($from_id, $to_id); 
GO
CREATE INDEX IX3 ON graph.ActsIn($to_id, $from_id);
GO

--edge table DirectedBy
CREATE TABLE graph.DirectedBy AS EDGE;
GO
CREATE CLUSTERED INDEX IX2 ON graph.DirectedBy($from_id, $to_id);
GO
CREATE INDEX IX3 ON graph.DirectedBy($to_id, $from_id);
GO

/*


TableName                                          RowCnt
-------------------------------------------------- ------------
graph.Movie                                        436323
graph.Actor                                        3228397
graph.Director                                     676655
graph.ActsIn                                       1797978
graph.DirectedBy                                   437241
*/


----------------------------------------------------------------------------
-- Queries
----------------------------------------------------------------------------


--The 10 most recently produced movies directed by Martin Scorsese:
SELECT TOP (10) Movie.Name AS MovieName,  Movie.ReleaseYear
FROM graph.Movie, graph.DirectedBy, graph.Director
WHERE 
    Director.Name = 'Martin Scorsese'
    AND MATCH (Movie-(DirectedBy)->Director)
ORDER BY ReleaseYear DESC;

/*
MovieName                                          ReleaseYear
-------------------------------------------------- -----------
The Irishman                                       2018
Silence                                            2016
The 50 Year Argument                               2014
The Wolf of Wall Street                            2013
Hugo                                               2011
George Harrison: Living in the Material World      2011
A Letter to Elia                                   2010
Shutter Island                                     2010
Public Speaking                                    2010
*/


-- find Martin Scorsese's top 5 favorite actors:
SELECT TOP (5) Actor.Name AS ActorName,  COUNT(*) AS Cnt
FROM graph.Movie, graph.DirectedBy, graph.Director, graph.Actor, graph.ActsIn
WHERE  
    Director.Name = 'Martin Scorsese'
    AND MATCH (Movie-(DirectedBy)->Director)
    AND MATCH (Actor-(ActsIn)->Movie)
GROUP BY Actor.Name ORDER BY Cnt DESC;

/*
ActorName                                          Cnt
-------------------------------------------------- -----------
Robert De Niro                                     9
Mardik Martin                                      6
Leonardo DiCaprio                                  5
Harvey Keitel                                      4
Joe Pesci                                          3
*/


--check for Robert De Niro's favorite directors:
SELECT TOP (5) Director.Name AS DirectorName, COUNT(*) AS Cnt
FROM graph.Movie, graph.DirectedBy, graph.Director, graph.Actor, graph.ActsIn
WHERE  
    Actor.Name = 'Robert De Niro'
    AND MATCH (Movie-(DirectedBy)->Director)
    AND MATCH (Actor-(ActsIn)->Movie)
GROUP BY  Director.Name ORDER BY Cnt DESC;



--actors that act in the same movies as Robert De Niro:
SELECT TOP (5) a2.Name AS ActorName,  COUNT(*) AS Cnt
FROM graph.Movie, graph.ActsIn, graph.Actor a1, graph.Actor a2
WHERE  
    a1.Name = 'Robert De Niro'
    AND MATCH (a1-(ActsIn)->Movie)
    AND MATCH (a2-(ActsIn)->Movie)
    AND a2.Name <> 'Robert De Niro'
GROUP BY a2.Name ORDER BY Cnt DESC;

/*
Msg 13903, Level 16, State 1, Line 48
Edge table 'ActsIn' used in more than one MATCH pattern.
*/

--you need to add another instance of the edge table in the FROM clause:
SELECT TOP (5) a2.Name AS ActorName,  COUNT(*) AS Cnt
FROM graph.Movie, graph.ActsIn, graph.Actor a1, graph.ActsIn ActsIn2, graph.Actor a2
WHERE  
    a1.Name = 'Robert De Niro'
    AND MATCH (a1-(ActsIn)->Movie)
    AND MATCH (a2-(ActsIn2)->Movie)
    AND a2.Name <> 'Robert De Niro'
GROUP BY a2.Name ORDER BY Cnt DESC;
/*
ActorName                                          Cnt
-------------------------------------------------- -----------
Joe Pesci                                          5
Al Pacino                                          4
Harvey Keitel                                      4
Arnon Milchan                                      3
Ben Stiller                                        3
*/

-- list of movies with Robert de Niro and Al Pacino:
SELECT Movie.Name AS MovieName, Movie.ReleaseYear
FROM graph.Movie, graph.ActsIn, graph.Actor, graph.ActsIn ActsIn2, graph.Actor Actor2
WHERE 
    Actor.Name = 'Robert De Niro' 
    AND Actor2.Name = 'Al Pacino'
    AND MATCH (Movie<-(ActsIn)-Actor)
    AND MATCH (Movie<-(ActsIn2)-Actor2)
ORDER BY ReleaseYear;
/*
MovieName                                          ReleaseYear
-------------------------------------------------- -----------
The Godfather: Part II                             1974
Heat                                               1995
Righteous Kill                                     2008
The Irishman                                       2018
*/
