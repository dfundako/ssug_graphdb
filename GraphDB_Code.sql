
--Setup 2 identical (for the most part) databases


--Create database for graph demo
CREATE DATABASE GraphDatabase;
GO 

--Create a Person and a Post Node table
USE [GraphDatabase]
GO 

CREATE TABLE dbo.Person (
PersonID INT IDENTITY(1,1) PRIMARY KEY, 
PersonName VARCHAR(50) NOT NULL
)
AS NODE --New Graph Syntax

GO 

CREATE TABLE dbo.Post (
PostID INT IDENTITY(1,1), 
PostContent VARCHAR(8000) NOT NULL, 
PostedBy INT NOT NULL
CONSTRAINT FK_PostedBy FOREIGN KEY(PostedBy) REFERENCES dbo.Person(PersonID)
)
AS NODE --New Graph Syntax

GO 

--Create a Likes Edge table
CREATE TABLE dbo.Likes (
LikeID INT IDENTITY(1,1)
)
AS EDGE --New Graph Syntax

GO 

--Copy the above without using new graph tables

CREATE DATABASE TraditionalDatabase;
GO 

USE [TraditionalDatabase]
GO 

CREATE TABLE dbo.Person (
PersonID INT IDENTITY(1,1) PRIMARY KEY, 
PersonName VARCHAR(50) NOT NULL
)
GO 

CREATE TABLE dbo.Post (
PostID INT IDENTITY(1,1) PRIMARY KEY, 
PostContent VARCHAR(8000) NOT NULL, 
PostedBy INT NOT NULL
CONSTRAINT FK_PostedBy FOREIGN KEY(PostedBy) REFERENCES dbo.Person(PersonID)
)
GO 

--Instead of an edge table, create table that can store relationships between people and posts
CREATE TABLE dbo.Likes (
LikeID INT IDENTITY(1,1), 
PersonID INT NOT NULL, 
PostID INT NOT NULL
CONSTRAINT FK_PersonID FOREIGN KEY(PersonID) REFERENCES dbo.Person(PersonID),
CONSTRAINT FK_PostID FOREIGN KEY(PostID) REFERENCES dbo.Post(PostID)
)
GO 

--select * from dbo.person
--Populate the databases
USE [GraphDatabase]
GO 

INSERT INTO dbo.Person (PersonName) 
VALUES 
('Tom'), 
('Dave'), 
('Sally'), 
('Suzy'), 
('Bill')
GO 

USE [TraditionalDatabase]
GO 

INSERT INTO dbo.Person (PersonName) 
VALUES 
('Tom'), 
('Dave'), 
('Sally'), 
('Suzy'), 
('Bill')
GO 


USE [GraphDatabase]
GO 
INSERT INTO dbo.Post (PostContent, PostedBy)
VALUES 
('Man, I have never seen this much rain in one day before!', 1), 
('Hey, I just heard that I am getting promoted!', 1), 
('The weather near me is great today. I love the sunshine!', 3), 
('Today has been rough. Meetings all day and now I have to work late!', 4)
GO 

USE [TraditionalDatabase]
GO 
 
INSERT INTO dbo.Post (PostContent, PostedBy)
VALUES 
('Man, I have never seen this much rain in one day before!', 1), 
('Hey, I just heard that I am getting promoted!', 1), 
('The weather near me is great today. I love the sunshine!', 3), 
('Today has been rough. Meetings all day and now I have to work late!', 4)
GO 

--Let's take a look at the Node Tables
USE [GraphDatabase]
GO 

SELECT * 
, JSON_VALUE($node_ID, '$.type') AS TypeName 
, JSON_VALUE($node_ID, '$.schema') AS SchemaName 
, JSON_VALUE($node_ID, '$.table') AS TableName 
, JSON_VALUE($node_ID, '$.id') AS Id 
FROM dbo.Person

SELECT * 
FROM dbo.Post


--show edge table
select * from dbo.likes




--Populate Traditional db table for Likes
USE [TraditionalDatabase]
GO 
INSERT INTO dbo.Likes(PersonID, PostID)
VALUES 
(1, 3), 
(2, 1), 
(3, 1), 
(4, 1), 
(5, 1), 
(4, 2)
GO 



--Populate Edge table with $Node_ID
USE [GraphDatabase]

INSERT INTO dbo.Likes 
VALUES 
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Tom'),(SELECT $node_id FROM dbo.Post WHERE PostID = 3)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Dave'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Sally'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Suzy'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Bill'),(SELECT $node_id FROM dbo.Post WHERE PostID = 1)),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Suzy'),(SELECT $node_id FROM dbo.Post WHERE PostID = 2))
GO


--Let's take a look at the Edge table
USE [GraphDatabase]
GO 
SELECT *
--, JSON_VALUE($from_id, '$.id') AS FromID
--, JSON_VALUE($To_id, '$.id') AS ToID
FROM dbo.likes


--Querying Node/Edge tables with MATCH() and viewing execution plan
USE [GraphDatabase]
GO 
SELECT person.personID, 
person.PersonName,
'Likes' AS Likes,
Post.PostID,
Post.PostContent
FROM Person, Likes, Post
WHERE MATCH (Person-(Likes)->Post)


--Querying traditional database
USE [TraditionalDatabase]
GO 
SELECT person.PersonID, 
person.PersonName, 
Post.PostID, 
Post.PostContent
FROM person 

INNER JOIN Likes 
    ON Likes.PersonID = Person.PersonID

INNER JOIN Post
    ON Post.PostID = Likes.PostID


--Using aliases
SELECT psn.*
FROM Person psn, Likes l, Post pst
WHERE MATCH (psn-(l)->pst)

--Functionally the same as the other query due to changing the direction 
----of traversing the graph (arrow is reversed and table names swapped)
USE [GraphDatabase]
GO 

SELECT person.personID, 
person.PersonName,
Post.PostID,
Post.PostContent
FROM Person, Likes, Post
WHERE MATCH (Post<-(Likes)-Person)

--Cant use JOIN with MATCH()
SELECT person.personID, 
person.PersonName,
Post.PostID,
Post.PostContent
FROM Person
INNER JOIN Likes
    ON Likes.PersonId = Person.PersonID
INNER JOIN Post
    ON Post.PostID = Likes.Postid
WHERE MATCH (Post<-(Likes)-Person)



--Add entries into the Edge table for another 'Like' relationship
USE [GraphDatabase]
GO 
INSERT INTO dbo.Likes
VALUES 
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Bill')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Bill'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Dave')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Dave'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom')),
((SELECT $node_ID FROM dbo.Person WHERE personname = 'Tom'),(SELECT $node_ID FROM dbo.Person WHERE personname = 'Suzy'))
GO 

--Look again at our likes edge
USE [GraphDatabase]
GO

SELECT *
--, JSON_VALUE($From_ID, '$.table') AS FromTable
--, JSON_VALUE($To_ID, '$.table') AS ToTable
FROM dbo.likes




--Return a list of all person 'like' relationships
SELECT p1.personname, 'Likes' AS Likes, p2.personname 
FROM Person p1, Likes l, Person p2
WHERE MATCH(p1-(l)->p2)

UNION 

SELECT p1.personname, 'Likes' AS Likes, p2.personname 
FROM Person p1, Likes l, Person p2
WHERE MATCH(p2-(l)->p1)




--Cannot use OR with MATCH
SELECT p1.personname, 'Likes' AS Likes, p2.personname 
FROM Person p1, Likes l, Person p2
WHERE MATCH(p1-(l)->p2)
OR MATCH(p2-(l)->p1)




--Traverse the graph multiple times
SELECT p3.PersonName
FROM Person p1, Likes l1, Person p2, Likes l2, Person p3
WHERE MATCH(p1-(l1)->p2-(l2)->p3) 
AND p1.personname = 'Tom'



--Traverse the graph in two directions
SELECT DISTINCT p1.personname
FROM Person p1, likes l1, person p2, likes l2, person p3
WHERE MATCH(p1-(l1)->p3<-(l2)-p2)
AND p3.personname = 'Suzy'



--Add another node
CREATE TABLE dbo.Forum (
ForumID INT IDENTITY(1,1) PRIMARY KEY,
ForumName VARCHAR(50) NOT NULL
)
AS NODE 
GO 

--And another edge
CREATE TABLE dbo.PostForum (
PostForumID INT IDENTITY(1,1) PRIMARY KEY
)
AS EDGE
GO 


--Populate the node
INSERT INTO dbo.Forum (ForumName)
VALUES 
('The Workplace'), 
('Weather')
GO 


--and populate edge with relationships between new node and existing node
INSERT INTO dbo.PostForum
VALUES
((SELECT $node_id FROM dbo.Post WHERE postID = 1),(SELECT $node_id FROM dbo.Forum WHERE forumID =2)),
((SELECT $node_id FROM dbo.Post WHERE postID = 2),(SELECT $node_id FROM dbo.Forum WHERE forumID =1)),
((SELECT $node_id FROM dbo.Post WHERE postID = 3),(SELECT $node_id FROM dbo.Forum WHERE forumID =2)),
((SELECT $node_id FROM dbo.Post WHERE postID = 4),(SELECT $node_id FROM dbo.Forum WHERE forumID =1))
GO 


--Traverse the graph
SELECT 
Post.PostContent,
Forum.ForumName

FROM Post, PostForum, Forum 
WHERE MATCH(Post-(PostForum)->Forum)



--Add another edge
CREATE TABLE dbo.MemberOf (
MemberOfID INT IDENTITY(1,1) PRIMARY KEY
)
AS EDGE 
GO 


--populate the edge
INSERT INTO dbo.MemberOf
VALUES 
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Tom'),(SELECT $node_id FROM dbo.Forum WHERE ForumName = 'Weather')),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Tom'),(SELECT $node_id FROM dbo.Forum WHERE ForumName = 'The Workplace')),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Sally'),(SELECT $node_id FROM dbo.Forum WHERE ForumName = 'Weather')),
((SELECT $node_id FROM dbo.Person WHERE PersonName = 'Suzy'),(SELECT $node_id FROM dbo.Forum WHERE ForumName = 'The Workplace'))
GO 


--Query who is a member of each forum
SELECT 
person.personname,
forum.forumname

FROM person, memberof, forum
WHERE MATCH(person-(memberof)->forum)


--Cannot update edge tables
UPDATE dbo.memberof
SET $from_id = (SELECT $node_id FROM dbo.Person WHERE PersonName = 'Tom') 
WHERE memberofid = 1;





