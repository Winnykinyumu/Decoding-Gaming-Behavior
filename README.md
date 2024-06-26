# Game-Analysis

![presentation](https://github.com/Winnykinyumu/Game-Analysis/assets/124139386/80f19331-5895-44cc-8647-4cf52985e593)

## Project Overview
The objective of this analysis is to leverage player and gameplay data to enhance the game's design, improve player experience and optimize retention and engagement strategies.

## Data Source
The data for this project entailed two tables:
- Player Details Table , "Player_details.csv" file
- Level Details2 Table ,  "Level_details2.csv" file

## Tools used
SQL for data cleaning and analysis.
[Download here](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16)

## Data Cleaning/Preparation

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
                PARTITION BY P_ID, Dev_ID,start_datetime
                order by P_ID
          ) as rownum
         FROM [Game Analysis].dbo.level_details2
       )
    DELETE
    FROM CTE 
    WHERE rownum>1
    ```

  
      
    
  


   
  
  
    



