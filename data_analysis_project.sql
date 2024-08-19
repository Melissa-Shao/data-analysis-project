use Data_Analysis_Project

select * from [dbo].[OrdersData]

-- Q1. Write a SQL query to list all distinct cities where orders have been shipped
SELECT DISTINCT city FROM OrdersData

-- Q2. Calculate the total selling price and profits for all orders.
SELECT 
	[Order Id], 
	SUM(Quantity * [Unit Selling Price]) AS 'Total Selling Price',
	CAST(SUM(Quantity * [Unit Profit]) AS DECIMAL(10, 2)) AS 'Total Profit'
FROM OrdersData
GROUP BY [Order Id]
ORDER BY [Total Profit] DESC

-- Q3. Write a query to find all orders from the 'Technology' category that were shipped using 'Second Class' ship mode, ordered by order date.
SELECT 
	[Order Id], FORMAT([Order Date], 'yyyy-MM-dd') AS [Order Date]
FROM OrdersData
WHERE Category = 'Technology' AND [Ship Mode] = 'Second Class'
ORDER BY [Order Date]

-- Q4. Write a query to find the average order value
SELECT CAST(AVG(Quantity * [Unit Selling Price]) AS DECIMAL(10, 2)) AS avgValue
FROM OrdersData

-- Q5. Find the city with the highest total quantity of products ordered.
SELECT TOP 1
	City, 
	SUM(Quantity) AS 'Total Quantity'
FROM OrdersData
GROUP BY City 
ORDER BY [Total Quantity] DESC

-- Q6. Use a window function to rank orders in each region by quantity in descending order.
SELECT 
	[Order Id],
	Region,
	Quantity AS 'Total Quantity',
	DENSE_RANK() OVER (PARTITION BY Region ORDER BY Quantity DESC) AS OrderRank
FROM OrdersData
ORDER BY Region, OrderRank

-- Q7. Write a SQL query to list all orders placed in the first quarter of any year (January to March), including the total cost for these orders.
SELECT 
	[Order Id],
	SUM(Quantity * [Unit Selling Price]) AS 'Total Cost'
FROM OrdersData
WHERE MONTH([Order Date]) in (1, 2, 3)
GROUP BY [Order Id]
ORDER BY [Total Cost] DESC

-- Q8. Find top 10 highest profit generating products.
-- method one
SELECT TOP 10
	[Product Id],
	SUM([Total Profit]) AS Profit
FROM OrdersData
GROUP BY [Product Id]
ORDER BY Profit DESC

-- method two
WITH CTE AS (
	SELECT
		[Product Id],
		SUM([Total Profit]) AS Profit,
		DENSE_RANK() OVER (ORDER BY SUM([Total Profit]) DESC ) AS OrderRank
	FROM 
		OrdersData	
	GROUP BY 
		[Product Id]
)

SELECT 
	[Product Id], Profit
FROM CTE
WHERE OrderRank <= 10

--Q9. Find top 3 highest selling products in each region
WITH CTE AS (
	SELECT
		[Product Id],
		Region,
		SUM(Quantity * [Unit Selling Price]) AS Sales,
		ROW_NUMBER() OVER (PARTITION BY Region ORDER BY SUM(Quantity * [Unit Selling Price]) DESC) AS SalesRank
	FROM OrdersData
	GROUP BY Region, [Product Id]	
)

SELECT *
FROM CTE
WHERE SalesRank <= 3

-- Q10. Find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
WITH CTE AS (
	SELECT
		YEAR([Order Date]) AS OrderYear,
		MONTH([Order Date]) AS OrderMonth,
		SUM(Quantity * [Unit Selling Price]) AS Sales
	FROM 
		OrdersData
	GROUP BY 
		YEAR([Order Date]),
		MONTH([Order Date])
)

SELECT 
	OrderMonth,
	ROUND(SUM((CASE WHEN OrderYear = 2022 THEN Sales ELSE 0 END)), 2) AS Sales2022,
	ROUND(SUM((CASE WHEN OrderYear = 2023 THEN Sales ELSE 0 END)), 2) AS Sales2023,
	CONCAT(
		ROUND(
			CASE 
			WHEN SUM(CASE WHEN OrderYear = 2022 THEN Sales ELSE 0 END) = 0 THEN 0
			ELSE 
				(SUM(CASE WHEN OrderYear = 2023 THEN Sales ELSE 0 END) - SUM(CASE WHEN OrderYear = 2022 THEN Sales ELSE 0 END)) 
				/ SUM(CASE WHEN OrderYear = 2022 THEN Sales ELSE 0 END) * 100
			END, 2), '%'
    ) AS PercentageGrowth
FROM CTE
GROUP BY OrderMonth 
ORDER BY OrderMonth 

-- Q11. For each category which month had highest sales
WITH CTE AS (
	SELECT 
		Category,
		FORMAT([Order Date], 'yyyy-MM') AS 'Order Date',
		SUM(Quantity * [Unit Selling Price]) AS 'Total Sales',
		ROW_NUMBER() OVER (PARTITION BY Category ORDER BY SUM(Quantity * [Unit Selling Price]) DESC) AS SalesRank
	FROM OrdersData
	GROUP BY Category, FORMAT([Order Date], 'yyyy-MM')
)

SELECT Category, [Order Date], [Total Sales]
FROM CTE
WHERE SalesRank=1

-- Q12. Which sub category had highest growth by sales in 2023 compare to 2022.
-- step1: calculate the total sales in each sub category in the year 2022 and 2023
WITH CTE AS (
	SELECT 
		[Sub Category],
		YEAR([Order Date]) AS OrderYear,
		SUM(Quantity * [Unit Selling Price]) AS 'Total Sales'
	FROM 
		OrdersData
	GROUP BY 
		[Sub Category],
		YEAR([Order Date])
),
-- step2: base on the result of step1, put the total sales in the same row in the year 2022 and 2023
CTE2 AS(
	SELECT 
		[Sub Category],
		ROUND(SUM((CASE WHEN OrderYear = 2022 THEN [Total Sales] ELSE 0 END)), 2) AS Sales2022,
		ROUND(SUM((CASE WHEN OrderYear = 2023 THEN [Total Sales] ELSE 0 END)), 2) AS Sales2023
	FROM 
		CTE
	GROUP BY 
		[Sub Category]
)
-- step3: final query
SELECT TOP 1
    [Sub Category], 
    Sales2022,
    Sales2023,
    (Sales2023 - Sales2022) AS 'Diff in Amount'	
FROM 
	CTE2
ORDER BY 
	(Sales2023 - Sales2022) DESC