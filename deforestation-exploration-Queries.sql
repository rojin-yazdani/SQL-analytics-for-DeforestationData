-- Creates a View called “forestation” by joining all three tables - forest_area, land_area, and regions. 
CREATE VIEW forestation AS 
SELECT r.region, 
	   r.income_group AS region_income_group, 
	   r.country_code, 
	   r.country_name, 
	   la.year, 
	   la.total_area_sq_mi * 2.59 AS total_area_sqkm, 
	   fa.forest_area_sqkm,
	   round(((fa.forest_area_sqkm * 100) / (la.total_area_sq_mi * 2.59))::NUMERIC, 2) AS forest_percent
FROM  forest_area fa 
JOIN land_area la ON fa.country_code=la.country_code AND fa.year=la.year
JOIN regions r ON fa.country_code = r.country_code
ORDER BY 1,3,5;      

--Part 1
-- Finds the total forest area of the world in 1990 1nd 2016, then finds how it changed. 
WITH 
	world_1990 AS 
	(SELECT f.country_name, f.forest_area_sqkm forest_area_1990
	 FROM forestation f
	 WHERE f.country_name='World' AND f.year=1990
    ),
	world_2016 AS 
	(SELECT f.country_name, f.forest_area_sqkm forest_area_2016
	 FROM forestation f
	 WHERE f.country_name='World' AND f.year=2016
	)      
SELECT  
  y1990.forest_area_1990, 
  y2016.forest_area_2016,
  ROUND((y1990.forest_area_1990 - y2016.forest_area_2016)::NUMERIC,2) diff_fa,
  ROUND(((y2016.forest_area_2016 - y1990.forest_area_1990) / y1990.forest_area_1990 * 100)::NUMERIC,2) diff_percent
FROM world_1990 y1990
JOIN world_2016 y2016 ON y1990.country_name = y2016.country_name;

-- Finds the largest country whose total land area is less than the lost forest area between 1990 and 2016.
SELECT f.country_name, ROUND(f.total_area_sqkm)
FROM forestation f
WHERE f.year=2016 AND f.total_area_sqkm <= 1324449
ORDER BY f.total_area_sqkm DESC
LIMIT 1;

--Part 2
-- Finds the percent of the total forest area of the world in 1990, 2016.
SELECT f.year, f.forest_percent
FROM forestation f	 
WHERE f.country_name='World' AND f.year in (1990,2016);

-- Finds the percent of the total forest area of each region in 2016.
SELECT f.region, 
ROUND(((SUM(f.forest_area_sqkm) * 100)/SUM(f.total_area_sqkm))::numeric,2) forest_percent_2016
FROM forestation f
WHERE f.year=2016 AND f.region != 'World'
GROUP BY f.region
ORDER BY 1;

-- Finds the percent of the total forest area of each region in 1990.
SELECT f.region, 
ROUND(((SUM(f.forest_area_sqkm) * 100)/SUM(f.total_area_sqkm))::numeric,2) forest_percent_1990
FROM forestation f
WHERE f.year=1990 AND f.region != 'World'
GROUP BY f.region
ORDER BY 1;

--Part 3 - A
-- Finds top 2 countries with maximum amount increase in forest area between 1990 and 2016.
SELECT  y1990.country_name, 
		ROUND((y2016.forest_area_sqkm -y1990.forest_area_sqkm)::NUMERIC)  increased_amount
FROM forestation y1990
JOIN forestation y2016 ON y1990.country_code = y2016.country_code 
WHERE y1990.year = 1990 
      AND y2016.year = 2016 
      AND y1990.forest_area_sqkm IS NOT NULL 
      AND y2016.forest_area_sqkm IS NOT NULL
      AND y1990.country_name != 'World'      
ORDER BY 2 DESC
LIMIT 2;

-- Finds top country with maximum percent increase in forest area between 1990 and 2016.
SELECT  y1990.country_name, 
		ROUND((((y2016.forest_percent_2016 - y1990.forest_percent_1990)/y1990.forest_percent_1990) * 100)::NUMERIC,2) increased_percent
FROM
(SELECT f.country_code, f.country_name, 
        f.forest_percent forest_percent_1990
 FROM forestation f
 WHERE f.year=1990 AND f.forest_percent IS NOT NULL) y1990 
JOIN (SELECT f.country_code, f.country_name, 
             f.forest_percent forest_percent_2016
      FROM forestation f
      WHERE f.year=2016 AND f.forest_percent IS NOT NULL) y2016
  ON y1990.country_code = y2016.country_code
WHERE y1990.country_name != 'World' AND y1990.forest_percent_1990 != 0
ORDER BY 2 DESC
LIMIT 1;

--Part 3 - B
-- Finds top 5 countries with maximum amount decrease in forest area between 1990 and 2016.
WITH 
	forestation_1990 AS 
	(SELECT f.country_code, 
			f.country_name, 
			f.region,
	        f.forest_area_sqkm forest_area_1990
	 FROM forestation f
	 WHERE f.year=1990 AND f.forest_area_sqkm IS NOT NULL
	),
	forestation_2016 AS 
	(SELECT f.country_code, 
			f.country_name, 
			f.region,
	        f.forest_area_sqkm forest_area_2016
	FROM forestation f
	WHERE f.year=2016 AND f.forest_area_sqkm IS NOT NULL
	)      
SELECT  y1990.country_name, 
		y1990.region, 
		ROUND(ABS(y2016.forest_area_2016 - y1990.forest_area_1990)::NUMERIC)  decreased_amount
FROM forestation_1990 y1990 
JOIN forestation_2016 y2016
  ON y1990.country_code = y2016.country_code
WHERE y1990.country_name != 'World'AND y2016.forest_area_2016 < y1990.forest_area_1990
ORDER BY 3 DESC
LIMIT 5;  

-- Finds top 5 countries with maximum percent decrease in forest area between 1990 and 2016.
WITH 
	forestation_1990 AS 
	(SELECT f.country_code, 
			f.country_name, 
			f.region,
	        f.forest_percent forest_percent_1990
	 FROM forestation f
	 WHERE f.year=1990 AND f.forest_percent IS NOT NULL
	),
	forestation_2016 AS 
	(SELECT f.country_code, 
			f.country_name, 
			f.region,
	        f.forest_percent forest_percent_2016
	FROM forestation f
	WHERE f.year=2016 AND f.forest_percent IS NOT NULL
	)      
SELECT  y1990.country_name, 
		y1990.region, 
		ROUND(((y2016.forest_percent_2016 - y1990.forest_percent_1990) / y1990.forest_percent_1990 * 100)::NUMERIC,2) decreased_percent
FROM forestation_1990 y1990 
JOIN forestation_2016 y2016 
  ON y1990.country_code = y2016.country_code
WHERE y1990.country_name != 'World' AND y1990.forest_percent_1990 != 0
ORDER BY 3 ASC
LIMIT 5;

--Part 3 - C
-- Counts the countries grouped by forestation percent quartiles in 2016.
WITH quartiles AS
	(SELECT 
	    f.country_name,
	    f.forest_percent,
	    CASE WHEN f.forest_percent <= 25 THEN 1 
	    	 WHEN f.forest_percent <= 50 THEN 2 
	    	 WHEN f.forest_percent <= 75 THEN 3 
	    	 ELSE 4
	    END quartile_no
	FROM forestation f
	WHERE f.year=2016 AND f.forest_percent IS NOT NULL
	)
SELECT q.quartile_no, COUNT(*) num_countries
FROM quartiles q
GROUP BY q.quartile_no
ORDER BY 1;

-- Finds the countries in quartile no. 4 of forestation percent quartiles in 2016.
WITH quartiles AS
	(SELECT 
	    f.country_name,
	    f.region,
	    f.forest_percent,
	    CASE WHEN f.forest_percent <= 25 THEN 1 
	    	 WHEN f.forest_percent <= 50 THEN 2 
	    	 WHEN f.forest_percent <= 75 THEN 3 
	    	 ELSE 4
	    END quartile_no
	FROM forestation f
	WHERE f.year=2016 AND f.forest_percent IS NOT NULL
	)
SELECT q.country_name, q.region, q.forest_percent
FROM quartiles q
WHERE q.quartile_no = 4
ORDER BY q.forest_percent DESC;

-- Part 4 
-- Finds the annually decreased forest area of the world between 1990 and 2016.
SELECT 
       sub.year,
       sub.forest_area - LAG(sub.forest_area) OVER (ORDER BY sub.year) AS forest_area_difference
FROM 
( SELECT f.region, f.year,
         ROUND(SUM(f.forest_area_sqkm)) AS forest_area
  FROM forestation f 
  WHERE f.region='World'
  GROUP BY f.region, f.year
  ORDER BY 1,2
) sub;
