SELECT * FROM walmart_sales;



--total transaction
SELECT COUNT(*) FROM walmart_sales;


--distinct payment type
SELECT DISTINCT payment_method FROM walmart_sales;

--total transactions in different payment method
SELECT payment_method,COUNT(*)
FROM walmart_sales
GROUP BY payment_method


--count of distinct branch
SELECT COUNT(DISTINCT(branch))
FROM walmart_sales;

--max quantity
SELECT MAX(quantity) FROM walmart_sales;

--business problems

--Q1. Find different payment method and number of transcation ,number of qty sold
SELECT payment_method,COUNT(*),
SUM(quantity) as no_quantity_sold
FROM walmart_sales
GROUP BY payment_method

--Q2.Identify the highest -rated category in each branch,displaying the branch,category avg rating
SELECT * 
FROM
(

SELECT branch,category,AVG(rating) as avg_rating,
RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
FROM walmart_sales
GROUP BY 1,2
)
WHERE RANK =1


--Q3.Identify the busiest day for each branch based on the number of transactions
SELECT * FROM
(SELECT
  branch,
  TO_CHAR(TO_DATE(date,'DD/MM/YY'),'Day') as day_name,
  COUNT(*) AS no_transctions,
  RANK()OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
  FROM walmart_sales
  GROUP BY 1,2
  )
WHERE rank=1

--Q4.cal the total quantity of items sold per payment method .List payment_method and total_quantity
SELECT payment_method,COUNT(*) as no_payments,
SUM(quantity) as no_qty_sold
FROM walmart_sales
GROUP BY payment_method

--Q5.Determine the avg,min,and max rating of category for  each city.list the city,average_rating,min_rating ,and max_rating
SELECT city,category,
MIN(rating) as min_rating,
MAX(rating) as max_rating,
AVG(rating) as avg_rating
FROM walmart_sales
GROUP BY 1,2

-- Q.6
-- Calculate the total profit for each category by considering total_profit as
-- (unit_price * quantity * profit_margin). 
-- List category and total_profit, ordered from highest to lowest profit.
SELECT 
 category,SUM(total*profit_margin) AS profit,
 SUM(total) as total_revenue
FROM walmart_sales
GROUP BY 1


-- Q.7
-- Determine the most common payment method for each Branch. 
-- Display Branch and the preferred_payment_method.
WITH cte 
AS
(SELECT 
	branch,
	payment_method,
	COUNT(*) as total_trans,
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
FROM walmart_sales
GROUP BY 1, 2
)
SELECT *
FROM cte
WHERE rank = 1


-- Q.8
-- Categorize sales into 3 group MORNING, AFTERNOON, EVENING 
-- Find out each of the shift and number of invoices

SELECT
	branch,
CASE 
		WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END day_time,
	COUNT(*)
FROM walmart_sales
GROUP BY 1, 2
ORDER BY 1, 3 DESC


-- #9 Identify 5 branch with highest decrese ratio in 
-- revevenue compare to last year(current year 2023 and last year 2022)

-- rdr == last_rev-cr_rev/ls_rev*100
SELECT *,
EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) as formated_date
FROM walmart_sales

-- 2022 sales
WITH revenue_2022
AS
(
	SELECT 
		branch,
		SUM(total) as revenue
	FROM walmart_sales
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022 -- psql
	-- WHERE YEAR(TO_DATE(date, 'DD/MM/YY')) = 2022 -- mysql
	GROUP BY 1
),

revenue_2023
AS
(

	SELECT 
		branch,
		SUM(total) as revenue
	FROM walmart_sales
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)

SELECT 
	ls.branch,
	ls.revenue as last_year_revenue,
	cs.revenue as cr_year_revenue,
	ROUND(
		(ls.revenue - cs.revenue)::numeric/
		ls.revenue::numeric * 100, 
		2) as rev_dec_ratio
FROM revenue_2022 as ls
JOIN
revenue_2023 as cs
ON ls.branch = cs.branch
WHERE 
	ls.revenue > cs.revenue
ORDER BY 4 DESC
LIMIT 5