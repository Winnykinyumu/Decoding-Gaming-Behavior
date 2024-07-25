# Game-Analysis

![video game resized](https://github.com/user-attachments/assets/21f81119-6bd0-4356-80a5-095b12e9f332)


## Project Overview
The objective of this analysis is to leverage player and gameplay data to enhance the game's design, improve player experience and optimize retention and engagement strategies.

## Data Source
The data for this project entailed two tables:
- Player Details Table , "Player_details.csv" file
- Level Details2 Table ,  "Level_details2.csv" file

## Tools used
SQL for data cleaning and analysis.
[Download here](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16)

## Dataset Description

**Player Details Table:**
- `P_ID`: Player ID
- `PName`: Player Name
- `L1_status`: Level 1 Status
- `L2_status`: Level 2 Status
- `L1_code`: Systemgenerated Level 1 Code
- `L2_code`: Systemgenerated Level 2 Code
  
**Level Details Table:**
- `P_ID`: Player ID
- `Dev_ID`: Device ID
- `start_time`: Start Time
- `stages_crossed`: Stages Crossed
- `level`: Game Level
- `difficulty`: Difficulty Level
- `kill_count`: Kill Count
- `headshots_count`: Headshots Count
- `score`: Player Score
- `lives_earned`: Extra Lives Earne

## Data Cleaning/Preparation

![Data cleaning resized](https://github.com/user-attachments/assets/4fb3fe74-99ae-43d6-ba1e-39b91de9fdfa)


**1. Data type conversation: Changed timestamp into date format.**

   ```SQL
   select start_time, CONVERT(Date,start_time) as start_datetime
   from [Game Analysis].dbo.level_details2

   ALTER Table [Game Analysis].dbo.level_details2
   Add start_datetime Date

   update [Game Analysis].dbo.level_details2
   set start_datetime= CONVERT(Date,start_time)
   ```

**2. Deleting Duplicates**
```SQL
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
```
**3. Creating Primary Key Constraints**
```SQL
ALTER TABLE [Game Analysis].dbo.level_details2
ADD CONSTRAINT PK_level_details2 PRIMARY KEY (P_ID,Dev_ID,start_datetime)
```
  
## Data Analysis
1. Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.
   ```SQL
   select player.P_ID, Dev_ID,PName,Difficulty
   from [Game Analysis].dbo.level_details2 AS level
   INNER JOIN  
   [Game Analysis].dbo.player_details AS player
   ON 
   level.P_ID= player.P_ID
   where Level=0
   GROUP BY player.P_ID, Dev_ID,PName,Difficulty
   ```
   
   ![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/0015ac35-c0f8-43d4-b036-2e8a83ac1942)

2. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed.
   
   ```SQL
   Select L1_Code, AVG(kill_count) as averagekillcount
   from [Game Analysis].dbo.level_details2 AS level
   INNER JOIN  
   [Game Analysis].dbo.player_details AS player
   ON 
   level.P_ID= player.P_ID
   where Lives_Earned=2 AND Stages_crossed>=3
   GROUP BY L1_Code
   ```
   ![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/cd229c0a-77bc-4a9e-9ade-486b549f859f)

4. Find the total number of stages crossed at each difficulty level for Level 2 with players using `zm_series` devices.
   Arrange the result in decreasing order of the total number of stages crossed.
   
   ```SQL
   select Difficulty, SUM(Stages_crossed)as total_number_of_stagescrossed
   from [Game Analysis].dbo.level_details2
   WHERE Level=2 AND Dev_ID like '%zm%'
   GROUP BY Difficulty
   ORDER BY total_number_of_stagescrossed DESC
   ```
   ![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/c0d02a01-01e8-4f41-9d65-f63dde73bc69)

5. Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days.
   
   ```SQL
   Select P_ID, COUNT (DISTINCT DAY(start_datetime)) AS unique_dates
   from [Game Analysis].dbo.level_details2
   GROUP BY P_ID
   Having COUNT (DISTINCT DAY(start_datetime)) >1
   ```
   ![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/aeb0a791-9bcb-44e3-a0a5-0455bc699172)

6. Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for Medium difficulty.
   
```SQL
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
```
   ![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/395a2d79-d293-4e5a-a433-fb2a94473fbc)
   
7. Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. Arrange in ascending order of level.
   
```SQL
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
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/364a111a-aea3-4f95-aaed-82adfb3905a2)

8. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well.

```SQL
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
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/77261e96-c88c-45d5-8c76-4b4671f1131b)
   
9. Find the `first_login` datetime for each device ID.

```SQL
SELECT Dev_ID, MIN(start_datetime) as first_login
FROM [Game Analysis].dbo.level_details2
GROUP BY Dev_ID
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/458ca56c-d3a2-4e85-acb1-58822dd14b0e)

10. Find the top 5 scores based on each difficulty level and rank them in increasing order using `Rank`. Display `Dev_ID` as well.

```SQL
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
SELECT Top 5 Score,Dev_ID,Difficulty,rank
FROM row_numCTE
order by Score ASC
```

![image](https://github.com/Winnykinyumu/Decoding-Gaming-Behavior/assets/124139386/ef11d4aa-222e-4ad0-b7e6-8248016d640c)


11. Find the device ID that is first logged in (based on `start_datetime`) for each player (`P_ID`). Output should contain player ID, device ID, and first login datetime.

```SQL
SELECT P_ID, Dev_ID, MIN(start_datetime) AS first_logged_in
from [Game Analysis].dbo.level_details2
GROUP BY P_ID,Dev_ID
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/fde98203-78bc-4426-a186-ee4bae3dbd33)

12. For each player and date, determine how many `kill_counts` were played by the player so far.
a) Using window functions

```SQL
select DISTINCT(level.P_ID),player.PName,Level.start_datetime,
SUM(level.Kill_Count) OVER (PARTITION BY level.P_ID) as number_of_killcounts
FROM [Game Analysis].dbo.level_details2 as level
INNER JOIN 
[Game Analysis].dbo.player_details as player
ON 
level.P_ID=player.P_ID
ORDER BY number_of_killcounts
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/db9c2d24-4e51-4b27-b050-e2470b6d77a3)

b) Without window functions
```SQL
select level.P_ID,player.PName, Level.start_datetime,
SUM(level.Kill_Count) as number_of_killcounts
FROM [Game Analysis].dbo.level_details2 as level
INNER JOIN 
[Game Analysis].dbo.player_details as player
ON 
level.P_ID=player.P_ID
GROUP BY player.PName, Level.start_datetime, level.Kill_Count, level.P_ID
ORDER BY number_of_killcounts
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/72bda4ab-444a-4305-91f7-2b2b68da28a8)

13. Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.

```SQL
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
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/d2f805d8-8a61-49fd-9cfb-844a5a205fd2)

14. Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.
```SQL
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
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/42b61f5a-416b-4666-8eec-06a24455027c)

15. Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`.

```SQL
SELECT P_ID, SUM(Score) AS Sum_score
from [Game Analysis].dbo.level_details2
GROUP BY P_ID
HAVING SUM(Score) >0.5* 
(
SELECT AVG(Score)
from [Game Analysis].dbo.level_details2
)
```
![image](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/1bbf0d58-4719-407e-ae90-3e116bec5f38)

## Key Insights

- There was a significant number of unique play dates per player which highlighted that more players frequently played the game.
- There was a notable increase in the average number of scores and stages crossed at the difficult level compared to the low and medium levels which proved the game to be less 	 
  challenging.
- At the different game levels, level 2 presented to have more lives earned compared to level 1 which implied that the level design was less challenging and easier to navigate for most players.
- The top score presented for the game was 6850 which was earned at the difficult level while the lowest score for the game was 40 which was earned at the medium level. This presented that the game was highly competitive with highly skilled players.

## Recommendation

- Implement targeted incentives like rewards for top players to improve play and retention rates.
- Implement systems to gather player feedback. This can provide valuable insights into potential issues and areas for improvement.

## Limitation

- The analysis did not account for external factors that may influence a player behavior such as game updates or seasonal events.
- The data set does not contain demographic details such as age, location, which could have provided additional context for player behavior and preferences.










  
      
    
  


   
  
  
    



