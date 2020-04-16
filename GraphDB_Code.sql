
/***
Create database for graph tables
***/
CREATE DATABASE ScratchDatabase;
GO 

/***
Create some Node tables and an Edge table
Node = Thing/Entity
Edge = Directed Relationship
***/

USE [ScratchDatabase]
GO 

CREATE TABLE dbo.Person (
PersonID INT IDENTITY(1,1) PRIMARY KEY, 
PersonName VARCHAR(50) NOT NULL
)
AS NODE --New Graph Syntax
GO 

CREATE TABLE dbo.Post (
PostID INT IDENTITY(1,1) PRIMARY KEY, 
PostContent VARCHAR(8000) NOT NULL, 
PostedBy INT NOT NULL
CONSTRAINT FK_PostedBy FOREIGN KEY(PostedBy) REFERENCES dbo.Person(PersonID)
)
AS NODE --New Graph Syntax
GO 

/***
Notice the lack of columns in the edge table
***/
CREATE TABLE dbo.Likes
AS EDGE --New Graph Syntax

GO 

/***
Examine the node tables
***/
USE [ScratchDatabase]
GO 
SELECT * 
from dbo.Person

SELECT * 
FROM dbo.Post


/***
Populate the graph tables
***/
USE [ScratchDatabase]
GO 

INSERT INTO dbo.Person (PersonName) 
VALUES 
('Tom'), 
('Dave'), 
('Sally'), 
('Suzy'), 
('Bill')
GO 

USE [ScratchDatabase]
GO 
INSERT INTO dbo.Post (PostContent, PostedBy)
VALUES 
('I can''t wait to go get some pizza when this is all over!', 1), 
('Working from home is the best thing ever! I''m wearing workout shorts right now', 1), 
('I have not seen another human being in weeks!', 3), 
('I really have no idea what day it is...', 4)
GO 


/***
Let's take a look at the Node Tables
***/
USE [ScratchDatabase]
GO 

SELECT * 
FROM dbo.Person

SELECT * 
FROM dbo.Post

/***
$node_id is automatically generated for each record
It is a JSON entry that contains the details of the object, and a BIGINT id

Next, use the object explorer to review any keys and indexes created
***/


/***
Take a look at new metadata about graph objects in sys.tables
***/

SELECT * 
FROM sys.tables 
WHERE [object_id] = OBJECT_ID('dbo.Person')


/***
Query using the new is_node attribute in sys.tables
***/
SELECT * 
FROM sys.tables 
WHERE is_node = 1


/***
What about new data in sys.columns?
***/

SELECT * 
FROM sys.columns 
WHERE [object_id] = OBJECT_ID('dbo.Person')

/***
What is the hidden field, and what is the computed field?

With Include Actual Execution Plan turned on, 
we see something interesting
***/
SELECT *
FROM dbo.Person


/***
To look even further...
Use new T-SQL function to examine IDs generated
***/

SELECT 
GRAPH_ID_FROM_NODE_ID($node_id) AS derived_graphID, 
*
FROM dbo.Person

/***
And to create a new 'fake' node_id
***/

SELECT 
NODE_ID_FROM_PARTS(OBJECT_ID('dbo.Person'), [PersonID]) AS new_fake_nodeID, 
*
FROM dbo.Person

/***
Pause for gasps
***/


/***
Review the Likes edge table
***/

USE [ScratchDatabase]
SELECT * FROM dbo.Likes


/***
Populate Edge table with $node_ID for the direction relationship
***/

USE [ScratchDatabase]
INSERT INTO dbo.Likes ($from_id, $to_id)
VALUES 
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Tom'),(SELECT $node_id FROM dbo.Post WHERE PostID = 3)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Dave'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Sally'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Suzy'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Bill'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Suzy'),(SELECT $node_id FROM dbo.Post WHERE PostID = 2))
GO


/***
Review the Likes edge table with data
***/
USE [ScratchDatabase]
GO 

SELECT 
*
FROM dbo.likes

/***
Similar to the node tables, review the metadata for Likes
***/
SELECT * 
FROM sys.columns 
WHERE object_id = OBJECT_ID('dbo.Likes')

/***
Querying Node/Edge tables with MATCH() and viewing execution plan
***/
USE [ScratchDatabase]
GO 

SELECT 
person.personID, 
person.PersonName,
'Likes' AS Likes,
Post.PostID,
Post.PostContent
FROM Person, Post, Likes
WHERE MATCH(Person-(Likes)->Post)

/***
Same query except using aliases
***/
USE [ScratchDatabase]
GO 

SELECT 
psn.personID, 
psn.PersonName,
'Likes' AS Likes,
pst.PostID,
pst.PostContent
FROM Person psn, Post pst, Likes l
WHERE MATCH (psn-(l)->pst)


/***
Since Edge relationships are directed, we can write the 
	same query again, but reverse the MATCH syntax
***/
USE [ScratchDatabase]
GO 

SELECT 
person.personID, 
person.PersonName,
'Likes' AS 'Likes',
Post.PostID,
Post.PostContent
FROM Person, Likes, Post
WHERE MATCH (Post<-(Likes)-Person)


/***
Joins or apply cant be used with MATCH()
***/

SELECT 
person.personID, 
person.PersonName,
Post.PostID,
Post.PostContent
FROM Person
INNER JOIN Likes
    ON Likes.$from_id = Person.$node_id
INNER JOIN Post
    ON Likes.$to_id = Post.$node_id
WHERE MATCH (Post<-(Likes)-Person)


/***
Cannot use OR/NOT with MATCH
***/
SELECT 
p1.personname, 
'Likes' AS Likes, 
p2.personname 

FROM Person p1, Likes l1, Person p2, Likes l2
WHERE MATCH(p1-(l1)->p2)
OR MATCH(p2-(l2)->p1)

/***
Let's Add entries into the Edge table for another 'Like' relationship
***/

USE [ScratchDatabase]
GO 
INSERT INTO dbo.Likes
VALUES 
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Bill')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Bill'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Dave')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Dave'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy'))
GO 


/***
Let's look again at our edge table and inspect the tables of each row
***/
USE [ScratchDatabase]
GO

SELECT *
, JSON_VALUE($From_ID, '$.table') AS FromTable
, JSON_VALUE($To_ID, '$.table') AS ToTable
FROM dbo.likes

/***
How to we prevent a bad relationship, for example having a Post like a Person?
***/
ALTER TABLE Likes ADD CONSTRAINT EC_Likes_1 CONNECTION (Person TO Post, Person TO Person);


/***
Try to run an insert of Posts liking People
***/
USE [ScratchDatabase]
INSERT INTO dbo.Likes ($from_id, $to_id)
VALUES 
((SELECT $node_id FROM dbo.Post WHERE PostID = 3),(SELECT $node_id FROM dbo.Person WHERE PersonName = 'Tom')),
((SELECT $node_id FROM dbo.Post WHERE PostID = 1),(SELECT $node_id FROM dbo.Person WHERE PersonName = 'Dave')),
((SELECT $node_id FROM dbo.Post WHERE PostID = 1),(SELECT $node_id FROM dbo.Person WHERE PersonName = 'Sally')),
((SELECT $node_id FROM dbo.Post WHERE PostID = 1),(SELECT $node_id FROM dbo.Person WHERE PersonName = 'Suzy')),
((SELECT $node_id FROM dbo.Post WHERE PostID = 1),(SELECT $node_id FROM dbo.Person WHERE PersonName = 'Bill')),
((SELECT $node_id FROM dbo.Post WHERE PostID = 2),(SELECT $node_id FROM dbo.Person WHERE PersonName = 'Suzy'))
GO


/***
View the constraint metadata in the sys tables
***/
SELECT 
OBJECT_NAME(ecs.from_object_id) AS [_from],
OBJECT_NAME(ecs.to_object_id) AS [_to],
* 

FROM sys.edge_constraints ec

INNER JOIN sys.edge_constraint_clauses ecs
	ON ec.[object_id] = ecs.[object_id]

/***
We can traverse the graph multiple times through multiple hops
***/
SELECT p3.PersonName
FROM Person p1, Likes l1, Person p2, Likes l2, Person p3
WHERE MATCH(p1-(l1)->p2-(l2)->p3) 
AND p1.PersonName = 'Tom'

/***
These are the records from the Person Likes Person insert for reference
VALUES 
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Bill')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Bill'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Dave')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Dave'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy'))
***/



/***
Here is where graph processesing get's reeeeaaaalllly fun. Needs SQL Server 2019 for SHORTEST_PATH()
***/
SELECT *
FROM (	
	SELECT
		Person1.PersonName AS PersonName, 
		STRING_AGG(Person2.PersonName, '->') WITHIN GROUP (GRAPH PATH) AS Likes_Path,
		LAST_VALUE(Person2.PersonName) WITHIN GROUP (GRAPH PATH) AS LastNode
	FROM
		Person AS Person1, Likes FOR PATH AS Likes, Person FOR PATH AS Person2
	WHERE MATCH(SHORTEST_PATH(Person1(-(Likes)->Person2)+))
		AND Person1.PersonName = 'Bill'
) AS X
WHERE X.LastNode = 'Tom'


/***
Add a COUNT() aggregate function to count hops
***/
SELECT PersonName, Friends, hops
FROM (	
	SELECT
		Person1.PersonName AS PersonName, 
		STRING_AGG(Person2.PersonName, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
		LAST_VALUE(Person2.PersonName) WITHIN GROUP (GRAPH PATH) AS LastNode,
		COUNT(Person2.PersonName) WITHIN GROUP (GRAPH PATH) AS hops
	FROM
		Person AS Person1, Likes FOR PATH AS Likes, Person FOR PATH  AS Person2
	WHERE MATCH(SHORTEST_PATH(Person1(-(Likes)->Person2)+))
	AND Person1.PersonName = 'Bill'
) AS Q
WHERE Q.LastNode = 'Tom'


/***
Add more graph tables!
***/

CREATE TABLE dbo.City (
CityID INT IDENTITY(1,1) PRIMARY KEY,
CityName VARCHAR(50) NOT NULL
)
AS NODE 
GO 

CREATE TABLE dbo.PizzaPlace (
PizzaPlaceID INT IDENTITY(1,1) PRIMARY KEY,
PizzaPlaceName VARCHAR(50) NOT NULL
)
AS NODE 
GO 


CREATE TABLE dbo.LocatedIn(
CreatedDatetime DATETIME DEFAULT GETDATE(), 
CONSTRAINT EC_LocatedIn_1 CONNECTION (PizzaPlace TO City, Person TO City)
)
AS EDGE
GO 


/***
Populate the tables
***/
INSERT INTO dbo.PizzaPlace (PizzaPlaceName)
VALUES 
('Imo''s'), 
('Regina Pizzeria'),
('Minsky''s'),
('Lou Malnati''s'), 
('Modern Apizza')
GO 

INSERT INTO dbo.City (CityName)
VALUES 
('St. Louis'), 
('Boston'),
('Kansas City'),
('Chicago'), 
('New Haven')
GO 


ALTER TABLE [Likes] DROP CONSTRAINT [EC_Likes_1]
GO 
ALTER TABLE [Likes] ADD CONSTRAINT EC_Likes_1 CONNECTION (Person TO Post, Person TO Person, Person TO PizzaPlace, Person TO City);
GO 


INSERT INTO dbo.LocatedIn ($from_id, $to_id)
VALUES 
--PizzaPlace LocatedIn City
((SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_ID, '$.id') = 0),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 0)),
((SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_ID, '$.id') = 1),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 1)),
((SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_ID, '$.id') = 2),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 2)),
((SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_ID, '$.id') = 3),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 3)),
((SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_ID, '$.id') = 4),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 4)),

--Person LocatedIn City
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 0),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 0)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 1),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 1)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 2),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 2)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 3),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 3)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 4),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 4))


INSERT INTO dbo.Likes ($from_id, $to_id)
VALUES 
--Person Likes City
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 0),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 3)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 4),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 2)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 3),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 1)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 1),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 4)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 2),(SELECT $node_id FROM dbo.City WHERE JSON_VALUE($node_id, '$.id') = 0)),

--Person Likes PizzaPlace
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 0),(SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_id, '$.id') = 0)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 4),(SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_id, '$.id') = 1)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 3),(SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_id, '$.id') = 2)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 1),(SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_id, '$.id') = 3)),
((SELECT $node_id FROM dbo.Person WHERE JSON_VALUE($node_id, '$.id') = 2),(SELECT $node_id FROM dbo.PizzaPlace WHERE JSON_VALUE($node_id, '$.id') = 4))




/***
Traverse the graph
***/
SELECT 
p.PersonName, 
'Likes' AS 'Likes',
pp.PizzaPlaceName,
'which is located in' AS 'which is located in',
c.CityName

FROM Person p, Likes lk, City c, LocatedIn loc, PizzaPlace pp

WHERE MATCH(p-(lk)->pp-(loc)->c)
AND c.CityName = 'St. Louis'



/***
We can Traverse the graph in two directions
***/
SELECT
p.PersonName, 
pp.PizzaPlaceName, 
c.CityName

FROM Person p, LocatedIn loc, PizzaPlace pp, Likes lk, City c
WHERE MATCH(p-(lk)->c<-(loc)-pp)

/***
The above is functionally the same as this query
***/
SELECT
p.PersonName, 
pp.PizzaPlaceName, 
c.CityName

FROM Person p, LocatedIn loc, PizzaPlace pp, Likes lk, City c
WHERE MATCH(p-(lk)->c)
AND MATCH(c<-(loc)-pp)
