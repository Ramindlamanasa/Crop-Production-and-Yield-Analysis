USE AGRICULTURE;

Select * from CropData;

ALTER TABLE CropData
ALTER COLUMN Crop_Year INT;

----REPLACE EMPTY VALUES WITH NULL

  UPDATE dbo.CropData
SET Production = NULL
WHERE Production IS NOT NULL
  AND LTRIM(RTRIM(Production)) = '';
------------------------------------------------------------------------------------------------------------------------
--1.Calculate crop yield (production per unit area) to assess which crops are the most efficient in production.
-----------------------------------------------------------------------------------------------------------------
SELECT Crop, SUM(PRODUCTION)/SUM(AREA) AS Crop_yield FROM CropData
GROUP BY Crop 
ORDER BY SUM(PRODUCTION)/SUM(AREA) DESC;

---------------------------------------------------------------------------------------------------------------
--2.calculates the year-over-year percentage growth in crop production for each state and crop.
WITH PreviousYear AS (
    SELECT
        State_Name, Crop,Crop_Year,Production, 
		LAG(Production) OVER (PARTITION BY State_Name, Crop ORDER BY Crop_Year) AS Previous_Production
     FROM CropData )
SELECT State_Name, Crop,Crop_Year,Production,Previous_Production,
((Production - Previous_Production)/ NULLIF(Previous_Production, 0)) * 100 AS YoY_Growth_Percentage
FROM PreviousYear ORDER BY State_Name, Crop, Crop_Year;

-----------------------------------------------------------------------------------------------------------------------------------------------

---3.calculates each state's average yield (production per area) and identifies the top N states with the highest average yield over multiple years.
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT TOP 5 State_Name, SUM(Production)/SUM(Area) AS 'Avg_Yield'
FROM CropData
GROUP BY State_Name
ORDER BY SUM(Production)/SUM(Area) DESC;
---2ND WAY
WITH Yield AS
(
    SELECT 
        State_Name,
        SUM(Production) * 1.0 / SUM(Area) AS Avg_Yield
    FROM CropData
    GROUP BY State_Name
)
SELECT *,
       RANK() OVER (ORDER BY Avg_Yield DESC) AS rn
FROM Yield;
--------------------------------------------------------------------------------
--4.calculates the variance in production across different crops and states. (tip: use VAR function).

SELECT State_Name, Crop , VAR(Production) AS 'Prod_Variance'
FROM CropData
GROUP BY State_Name, Crop;

---------------------------------------------------------------------------------------


---5.Identifies states that have the largest increase in cultivated area for a specific crop between two year
----------------------------------------------------------------------------------
WITH Yearly_Area AS
(
    SELECT State_Name, Crop, Crop_Year, SUM(Area) AS Total_Area FROM CropData
    GROUP BY State_Name,Crop,Crop_Year),
Area_Increase AS(
    SELECT State_Name, Crop,Crop_Year, Total_Area,
	LAG(Total_Area) OVER( PARTITION BY State_Name, Crop ORDER BY Crop_Year) AS Prev_Year_Area FROM Yearly_Area)

SELECT State_Name,Crop,Crop_Year, Total_Area, Prev_Year_Area,
Total_Area - Prev_Year_Area AS Area_Increase,
(Total_Area - Prev_Year_Area) * 100.0
        / NULLIF(Prev_Year_Area, 0) AS Area_Increase_Percent
FROM Area_Increase
WHERE Prev_Year_Area IS NOT NULL
ORDER BY Area_Increase_Percent DESC;