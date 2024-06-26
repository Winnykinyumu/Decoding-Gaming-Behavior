--The query changes the date with time stamp into date without time stamp
select start_time, CONVERT(Date,start_time) as start_datetime
from [Game Analysis].dbo.level_details2

ALTER Table [Game Analysis].dbo.level_details2
Add start_datetime Date

update [Game Analysis].dbo.level_details2
set start_datetime= CONVERT(Date,start_time) 

--Dropping the column with timestamp

select*
from [Game Analysis].dbo.level_details2

--we had to drop the primary key in timestamp first using the below code for us to delete the column 
ALTER TABLE [Game Analysis].dbo.level_details2
DROP CONSTRAINT PK_level_details2

--deleting the column with timestamp
ALTER TABLE [Game Analysis].dbo.level_details2
DROP COLUMN start_time

--creating the primary key constraint
ALTER TABLE [Game Analysis].dbo.level_details2
ALTER COLUMN start_datetime date NOT NULL

ALTER TABLE [Game Analysis].dbo.level_details2
ADD CONSTRAINT PK_level_details2 PRIMARY KEY (P_ID,Dev_ID,start_datetime)

SELECT P_ID, Dev_ID, start_datetime,
COUNT(*)
FROM [Game Analysis].dbo.level_details2
GROUP BY P_ID, Dev_ID, start_datetime
HAVING COUNT(*) > 1

--Deleting duplicates so as to be able to set specific columns as primary keys
WITH CTE As (
SELECT*,
           ROW_NUMBER() OVER
		   (
		   PARTITION BY P_ID, Dev_ID, start_datetime 
		   order by P_ID
 	) as rownum
 FROM [Game Analysis].dbo.level_details2
 )
DELETE
FROM CTE
WHERE rownum > 1

--Updating the specific columns as primary keys
ALTER TABLE [Game Analysis].dbo.level_details2
ADD CONSTRAINT PK_level_details2 PRIMARY KEY (P_ID,Dev_ID,start_datetime)

--Dropping the unknown column in the player details table
ALTER TABLE [Game Analysis].dbo.player_details
DROP COLUMN column1

--Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0. 

select player.P_ID, Dev_ID,PName,Difficulty
from [Game Analysis].dbo.level_details2 AS level
INNER JOIN  
[Game Analysis].dbo.player_details AS player
ON 
level.P_ID= player.P_ID
where Level=0
GROUP BY player.P_ID, Dev_ID,PName,Difficulty

--Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 
--stages are crossed.
Select L1_Code, AVG(kill_count) as averagekillcount
from [Game Analysis].dbo.level_details2 AS level
INNER JOIN  
[Game Analysis].dbo.player_details AS player
ON 
level.P_ID= player.P_ID
where Lives_Earned=2 AND Stages_crossed>=3
GROUP BY L1_Code

--Find the total number of stages crossed at each difficulty level for Level 2 with players 
--using `zm_series` devices. Arrange the result in decreasing order of the total number of 
--stages crossed. 
select Difficulty, SUM(Stages_crossed)as total_number_of_stagescrossed
from [Game Analysis].dbo.level_details2
WHERE Level=2 AND Dev_ID like '%zm%'
GROUP BY Difficulty
ORDER BY total_number_of_stagescrossed DESC

--Extract `P_ID` and the total number of unique dates for those players who have played 
--games on multiple days. 
Select P_ID, COUNT (DISTINCT DAY(start_datetime)) AS unique_dates
from [Game Analysis].dbo.level_details2
GROUP BY P_ID
Having COUNT (DISTINCT DAY(start_datetime)) >1

--Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the 
--average kill count for Medium difficulty. 
With killcountCTE as
(
select P_ID, Level, AVG(Kill_Count)as avgkillcount
from [Game Analysis].dbo.level_details2 
WHERE Difficulty='Medium'
GROUP BY P_ID, Level
) 
Select ld2.P_ID, ld2.Level, SUM(ld2.Kill_Count)as totalkill_count
FROM [Game Analysis].dbo.level_details2 as ld2
JOIN killcountCTE cte
ON ld2.P_ID=cte.P_ID
Where ld2.Kill_count>cte.avgkillcount
GROUP BY ld2.P_ID, ld2.Level
Order BY totalkill_count 

-- Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 
--0. Arrange in ascending order of level. 
SELECT leveld.Level,player.L1_Code,player.L2_Code,
Sum(leveld.Lives_Earned) AS sum_of_livesearned
from [Game Analysis].dbo.level_details2 AS leveld
INNER JOIN  
[Game Analysis].dbo.player_details AS player
ON 
leveld.P_ID= player.P_ID
where Level <>0
GROUP BY leveld.Level,player.L1_Code,player.L2_Code
ORDER BY leveld.Level ASC

--Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using 
--Row_Number`. Display the difficulty as well. 

WITH row_numCTE AS 
(
SELECT Score, Dev_ID, Difficulty,
ROW_NUMBER () OVER
 (
PARTITION BY Score, Dev_ID, Difficulty 
order by Score ASC
 ) AS rownum
 FROM [Game Analysis].dbo.level_details2
 ) 
SELECT TOP 3 Score,Dev_ID, Difficulty,rownum
FROM row_numCTE
order by Score ASC

--Find the `first_login` datetime for each device ID.
SELECT Dev_ID, MIN(start_datetime) as first_login
FROM [Game Analysis].dbo.level_details2
GROUP BY Dev_ID
 
 --Find the top 5 scores based on each difficulty level and rank them in increasing order 
--using `Rank`. Display `Dev_ID` as well
WITH row_numCTE AS 
(
SELECT Score, Dev_ID, Difficulty,
Rank () OVER
 (
PARTITION BY Difficulty 
order by Score ASC
 ) AS rank
 FROM [Game Analysis].dbo.level_details2
 ) 
SELECT Score,Dev_ID,Difficulty,rank
FROM row_numCTE
order by Score ASC

-- Find the device ID that is first logged in (based on `start_datetime`) for each player 
--(`P_ID`). Output should contain player ID, device ID, and first login datetime. 

SELECT P_ID, Dev_ID, MIN(start_datetime) AS first_logged_in
from [Game Analysis].dbo.level_details2
GROUP BY P_ID,Dev_ID

-- For each player and date, determine how many `kill_counts` were played by the player 
--so far. 
--a) Using window functions 
select DISTINCT(level.P_ID),player.PName,Level.start_datetime,
SUM(level.Kill_Count) OVER (PARTITION BY level.P_ID) as number_of_killcounts
FROM [Game Analysis].dbo.level_details2 as level
INNER JOIN 
[Game Analysis].dbo.player_details as player
ON 
level.P_ID=player.P_ID
ORDER BY number_of_killcounts


--b) Without window functions 
select level.P_ID,player.PName, Level.start_datetime,
SUM(level.Kill_Count) as number_of_killcounts
FROM [Game Analysis].dbo.level_details2 as level
INNER JOIN 
[Game Analysis].dbo.player_details as player
ON 
level.P_ID=player.P_ID
GROUP BY player.PName, Level.start_datetime, level.Kill_Count, level.P_ID
ORDER BY number_of_killcounts


--Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, 
--excluding the most recent `start_datetime`. 

WITH cumulativeCTE as 
(
SELECT P_ID,Stages_crossed,start_datetime, 
SUM(Stages_crossed) OVER (ORDER BY start_datetime ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulativesum,
ROW_NUMBER () OVER (PARTITION BY P_ID ORDER BY start_datetime DESC) AS row_num
FROM [Game Analysis].dbo.level_details2
)
SELECT P_ID,cumulativesum,start_datetime,row_num
from cumulativeCTE
WHERE row_num > 1
GROUP BY P_ID, start_datetime,cumulativesum,row_num


-- Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`. 

With sumCTE AS 
(
SELECT Dev_ID, P_ID, 
SUM(Score) as sumscores,
ROW_NUMBER () OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC ) AS rownum
from [Game Analysis].dbo.level_details2
GROUP BY Dev_ID, P_ID
)
SELECT TOP 3 sumscores,Dev_ID,P_ID
FROM sumCTE 
ORDER BY sumscores DESC

--Find players who scored more than 50% of the average score, scored by the sum of 
--scores for each `P_ID`. 

SELECT P_ID, SUM(Score) AS Sum_score
from [Game Analysis].dbo.level_details2
GROUP BY P_ID
HAVING SUM(Score) >0.5* 
(
SELECT AVG(Score)
from [Game Analysis].dbo.level_details2
)




--Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` 
--and rank them in increasing order using `Row_Number`. Display the difficulty as well.

CREATE PROCEDURE shotscount
@n INT
AS
WITH row_numCTE AS 
(
SELECT Headshots_Count, Dev_ID, Difficulty,
ROW_NUMBER () OVER
 (
PARTITION BY Headshots_Count, Dev_ID, Difficulty 
order by Headshots_Count ASC
 ) AS rownum
 FROM [Game Analysis].dbo.level_details2
 ) 
SELECT TOP ('n') Headshots_Count,Dev_ID, Difficulty,rownum
FROM row_numCTE
order by Headshots_Count ASC

EXEC shotscount

