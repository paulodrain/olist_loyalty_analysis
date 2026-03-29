# olist_loyalty_analysis
Paulo Drain
Overview: SQL analysis of Olist e-commerce data exploring how to increase customer loyalty
Central Question: How to increase customer loyalty?
Tools Used: SQL

Key Findings: 
- Those who paid with a voucher first were more likely to come back
- Majority of there customer back is in the South, Sao Paulo In particular
- People who got their order late were less likely to come back

Loyalty SQL Scrips
------------------
-- Do High Delivery Times Reduce Loyalty --
-- What question is this answering: 
-- If people recieve their order late are they likely to shop again

-- What metrics answer that:
-- The time  between their orders, first and second.

-- How can I make it clearer visually:
-- Using percentages to easily see an impact

-- What would a business person ask next:

-- DateRanges --

WITH 
Date_Ranges AS (
SELECT 
	ccd.customer_unique_id AS Customer,
CASE
	WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 0 AND 3 THEN 'On Time'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) > 3 THEN 'Early'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 0 THEN 'Late'
    ELSE 'Awaiting Order'
END AS Dates_Segmented
FROM cleaned_customer_dataset ccd
JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
),

Orders_Placed AS (
Select
	customer_unique_id,
	ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY order_id) AS Order_Placed
FROM cleaned_customer_dataset ccd
JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
),
Order_Potential AS (
SELECT 
	op1.customer_unique_id NCustomer,
    
    op2.customer_unique_id RCustomer
    
FROM Orders_Placed OP1
LEFT JOIN Orders_Placed OP2
	On op1.customer_unique_id = op2.customer_unique_id AND op2.order_placed = 2
WHERE op1.order_placed = 1
LIMIT 10
)

SELECT
	Dates_Segmented,
    COUNT(NCustomer) No_Reorder,
    COUNT(RCustomer) Reordered,
    (COUNT(RCustomer) * 100) / COUNT(NCustomer)  AS Reorder_Potential
FROM Order_Potential OP
JOIN Date_Ranges DR
	ON Dr.Customer = op.NCustomer
GROUP BY Dates_Segmented
;


WITH Fundimentals AS (
Select
	customer_unique_id,
	ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY order_id) AS Orders_Ordered,
CASE
	WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 0 AND 3 THEN 'On Time'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) > 3 THEN 'Early'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 0 THEN 'Late'    ELSE 'Awaiting Order'
END AS Dates_Segmented,
	co.order_id AS Order_Total
FROM cleaned_customer_dataset ccd
JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
)


SELECT 
	Dates_Segmented,
COUNT(CASE
	WHEN Orders_Ordered = 1 THEN customer_unique_id
END) AS 'Customers',
COUNT(CASE
	WHEN Orders_Ordered= 2 THEN customer_unique_id
END) AS 'Loyal Customers',
(COUNT(CASE WHEN Orders_Ordered= 2 THEN customer_unique_id END) * 100) / COUNT(CASE WHEN Orders_Ordered = 1 THEN customer_unique_id END) AS Reorder_Potential,
AVG (Order_total) As Orders_Total 
FROM Fundimentals
GROUP BY Dates_Segmented
;


;
-- State Order Delivery Times --

WITH Delivery_Time_States AS  (
Select
	CCD.Customer_state AS State,
CASE
	WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 0 AND 3 THEN customer_unique_id
END AS On_Time,
CASE
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) > 3 THEN customer_unique_id
END AS Early,
CASE
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 0 THEN customer_unique_id
END AS Late
FROM cleaned_customer_dataset ccd
JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
)

SELECT 
	State,
    COUNT(Late)+COUNT(Early)+Count(On_Time) AS Total_Orders,
    COUNT(Late) Late_Orders,
    Count(On_Time) + COUNT(Early) AS Within_Estimate,
	(COUNT(Late) * 100) / (COUNT(Late)+COUNT(Early)+Count(On_Time)) AS Percentage_OF_Lateness
FROM Delivery_Time_States
GROUP BY State
ORDER BY 5 DESC
;

-- States with most lateness --

SELECT 
	ccd.customer_state State,
    count(DISTINCT customer_unique_id) Unique_Customers
FROM cleaned_customer_dataset ccd
JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id 
GROUP BY State
ORDER  BY 2 DESC
;

-- Most / Least Loyal States --

WITH
Customer_Orders AS (
SELECT
	DISTINCT customer_unique_id Customers,
    COUNT(DISTINCT co.order_id) As Orders
FROM cleaned_customer_dataset ccd
JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
GROUP BY customer_unique_id
HAVING orders > 1
)

SELECT
	ccd.customer_state State,
    COUNt(DISTINCT Customers) Loyal_Customers

FROM Customer_Orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_unique_id = co.customers
group by State
Order By 2 Asc
;
