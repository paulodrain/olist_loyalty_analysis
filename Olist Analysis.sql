-- Data Analysis --

-- What states do shipping costs eat more than 20% of the value --
SELECT cp.payment_value, ci.price, ci.freight_value
FROM cleaned_payments cp
JOIN cleaned_items ci
	ON cp.order_id = ci.order_id
;

SELECT 
    cp.order_id,
    SUM(DISTINCT cp.payment_value) AS total_paid,
    SUM(ci.price + ci.freight_value) AS total_item_cost
FROM cleaned_payments cp
JOIN cleaned_items ci ON cp.order_id = ci.order_id
GROUP BY cp.order_id
;

SELECT *
FROM cleaned_geolocation
;
SELECT *
FROM cleaned_items
;
SELECT *
FROM cleaned_products
;
SELECT *
FROM cleaned_customer_dataset
;
SELECT *
FROM cleaned_payments
;
SELECT *
FROM cleaned_sellers
;
SELECT *
FROM cleaned_orders
;

SELECT ci.shipping_limit_date
FROM cleaned_orders co
JOIN cleaned_items ci
	ON ci.shipping_limit_date = co.order_purchase_timestamp 
    OR co.order_approved_at
    OR co.order_delivered_carrier_date
    OR co.order_delivered_customer_date
    OR co.order_estimated_delivery_date
;

WITH Shipping AS
(
SELECT 
	ccd.customer_state as State, 
	SUM(ci.freight_value) AS Freight_Value,
	SUM(ci.price) AS Payment_Value
FROM cleaned_payments cp
JOIN cleaned_items ci
	ON cp.order_id = ci.order_id
JOIN cleaned_orders co
	ON co.order_id = cp.order_id
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_state
)

SELECT 
	State,
    (Freight_Value / (Freight_Value + Payment_Value) * 100) As Percentage
FROM Shipping s
JOIN cleaned_geolocation cg
	ON s.state = cg.geolocation_state
ORDER BY Percentage desc
;

WITH Percantage AS
(
SELECT DISTINCT(ccd.customer_id) Buyer, ci.freight_value ShipCost, cp.payment_value ProdCost, SUM(ci.freight_value / cp.payment_value * 100) as Percentage_Of_Order
FROM cleaned_payments cp
JOIN cleaned_items ci
	ON cp.order_id = ci.order_id
JOIN cleaned_orders co
	ON co.order_id = cp.order_id
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY Buyer, ShipCost, ProdCost
)

SELECT *
FROM Percantage
Where Percentage_Of_Order > 50

;

SELECT DISTINCT(payment_type)
FROM cleaned_payments
;

-- What 5 products categories have low review scores despite having high sales? --
SELECT *
FROM cleaned_reviews
;

SELECT *
FROM cleaned_orders
;

SELECT *
FROM cleaned_products
;

SELECT *
FROM cleaned_payments
;

SELECT *
FROM cleaned_customer_dataset
;

SELECT *
FROM cleaned_items
;

SELECT *
FROM cleaned_translation2
;

WITH NOO AS
(
SELECT 
	cp.product_category_name AS Products,
	COUNT(ci.order_id) AS Number_Of_Orders,
    AVG(cr.review_score) AS Rating,
    COUNT(cr.review_score) AS Number_Of_Reviews,
    AVG(ci.freight_value) AS Average_Delivery_Cost
FROM cleaned_items ci
LEFT JOIN cleaned_reviews cr
	ON ci.order_id = cr.order_id
JOIN cleaned_products cp
	ON cp.product_id = ci.product_id
GROUP BY Products
)

Select *
FROM NOO
WHERE Number_of_Orders > 100 AND Number_Of_Reviews >10
ORDER BY 2 DESC
;

WITH Grouped_Products AS (
SELECT
	product_category_name,
	COUNT( cp.product_id) AS Number_Of_Orders
FROM cleaned_products cp
LEFT JOIN cleaned_items ci
	ON ci.product_id = cp.product_id
GROUP BY product_category_name 
ORDER BY 2 DESC
)

SELECT
	*
FROM Grouped_Products
;





WITH NOO AS
(
SELECT 
	cp.product_category_name AS Products,
	COUNT(ci.order_id) AS Number_Of_Orders,
    AVG(cr.review_score) AS Rating,
    COUNT(cr.review_score) AS Number_Of_Reviews,
    AVG(ci.freight_value) AS Average_Delivery_Cost
FROM cleaned_items ci
LEFT JOIN cleaned_reviews cr
	ON ci.order_id = cr.order_id
JOIN cleaned_products cp
	ON cp.product_id = ci.product_id
GROUP BY Products
)

Select *
FROM NOO
ORDER BY Rating ASC
;


-- What percentage of customers have made more than 1 purchase and what category is creating the most returning customers? --

SELECT *
FROM cleaned_items
;

SELECT *
FROM cleaned_payments
;

SELECT *
FROM cleaned_products
;

SELECT *
FROM cleaned_orders
;

SELECT *
FROM cleaned_customer_dataset
;

WITH Repeat_Orders AS
(
SELECT  
    ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT co.order_id) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON co.customer_id = ccd.customer_id
GROUP BY Customers
HAVING Orders > 1
)


SELECT 
	COUNT(Customers) ,
    (SELECT COUNT(Orders) FROM Repeat_Orders) AS Loyal_Customers,
    ((COUNT(Orders) * 100 )/ COUNT(Customers)) AS Percantage
FROM Repeat_Orders
GROUP BY Customers
;

WITH Repeat_Orders AS
(
SELECT  
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT co.order_id) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON co.customer_id = ccd.customer_id
GROUP BY Customers

)

SELECT 
	Orders,
    COUNT(Customers) AS Customers,
    Orders  / COUNT(Customers)* 100 AS Perc
FROM Repeat_Orders
GROUP BY Orders
ORDER BY Orders asc
;

WITH Product_Repeaters AS
(
SELECT  
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON co.customer_id = ccd.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
)

SELECT
	cp.product_category_name As Product_Category,
	COUNT(DISTINCT customers) as Repeat_Customer_Orders
FROM Product_Repeaters PR
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_unique_id = pr.customers
LEFT JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
JOIN cleaned_items ci 
	ON ci.order_id = co.order_id
JOIN cleaned_products cp 
	ON ci.product_id = cp.product_id
GROUP BY cp.product_category_name
ORDER BY Repeat_Customer_Orders DESC

;
SELECT
	SUM(Repeat_Customer_Orders)
FROM Cust
;

WITH All_Cust AS (
SELECT  
	customer_unique_id,
	ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY order_id) AS Orders_Ordered
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON co.customer_id = ccd.customer_id
)

SELECT 
	COUNT(Orders_Ordered)
FROM All_Cust
WHERE Orders_Ordered >= 2

;

WITH Test As (
SELECT
	*
FROM cleaned_orders co
JOIN cleaned_items ci
	ON co.order_id = ci.order_id

)

SELECT 
	*
FROM Test
;





WITH Loyal_Customers AS
(
SELECT  
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON co.customer_id = ccd.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
),

Grouped_Products AS (
SELECT
	*
FROM cleaned_items





;

SELECT
	cp.product_category_name As Product_Category,
	COUNT(DISTINCT customers) as Repeat_Customer_Orders
FROM Product_Repeaters PR
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_unique_id = pr.customers
LEFT JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
JOIN cleaned_items ci 
	ON ci.order_id = co.order_id
JOIN cleaned_products cp 
	ON ci.product_id = cp.product_id
GROUP BY cp.product_category_name
ORDER BY Repeat_Customer_Orders DESC







    
    
;
-- Does offering vouchers lead to multiple orders / returning customers? --
SELECT *
FROM cleaned_payments
;

SELECT *
FROM cleaned_items
;

SELECT *
FROM cleaned_orders
;

SELECT *
FROM cleaned_customer_dataset
;

SELECT 
	payment_type,
	COUNT(payment_type)
FROM cleaned_payments
GROUP BY payment_type
;

WITH Loyal_Customers AS
(
SELECT
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
)

SELECT 
	payment_type,
	COUNT(DISTINCT Customers) as Returned_Buyers
FROM cleaned_orders co
JOIN cleaned_payments cp
	ON co.order_id = cp.order_id
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
JOIN Loyal_Customers LC
	ON ccd.customer_unique_id = lc.customers
GROUP BY payment_type
;

--

WITH 
First_Purchase AS
(
SELECT
	ccd.customer_unique_id AS Customer,
    MIN(co.order_approved_at) AS First_Order
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY Customer

) ,
Payment_Method AS
( 
SELECT
	fp.customer,
    cp.payment_type
FROM First_Purchase FP
JOIN cleaned_orders co
	ON fp.first_order = co.order_approved_at
JOIN cleaned_payments cp
	ON cp.order_id = co.order_id
), 
Customer_Loyalty AS
(
SELECT
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
) 

SELECT 
	pm.payment_type,
	COUNT(pm.customer) AS First_Time_Buyers,
    COUNT(DISTINCT cl.customers) AS Loyal,
    (COUNT(DISTINCT cl.customers) * 100) / COUNT(pm.customer) AS Loyalty_Percentage
FROM  payment_method pm
LEFT JOIN Customer_Loyalty cl
	ON cl.customers = pm.customer
GROUP BY payment_type

;









;
--
SELECT 
	payment_type,
    MAX(payment_installments)
FROM cleaned_payments
GROUP BY payment_type
HAVING payment_type = 'credit_card'
;


WITH First_Purchase AS
(
SELECT
	ccd.customer_unique_id AS Customer,
    MIN(co.order_approved_at) AS First_Order
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY Customer
)
 
SELECT
	fp.customer,
    cp.payment_type
FROM First_Purchase FP
JOIN cleaned_orders co
	ON fp.first_order = co.order_approved_at
JOIN cleaned_payments cp
	ON co.order_id = cp.order_id
;

-- What point does a delivery delay trigger a 1 * review? --

SELECT *
FROM cleaned_reviews
;

SELECT *
FROM cleaned_orders
;

SELECT *
FROM cleaned_customer_dataset
;

WITH Late_Deliveries AS
(
SELECT
	order_estimated_delivery_date AS Estimated,
    order_delivered_customer_date AS Delivered,
    DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS Days_Late,
    review_score
FROM cleaned_orders co
JOIN cleaned_reviews cr
	ON co.order_id = cr.order_id
WHERE order_estimated_delivery_date < order_delivered_customer_date
)

SELECT 
	COUNT(Review_Score) AS Rating_Total,
    AVG(review_score) AS Average,
    Days_Late
FROM Late_Deliveries
GROUP BY Days_late
Order by 3 ASC
;

-- Which State has the highest Average Order Value, only including states with at least 1,000 unique orders?--

-- AOV = Average Revenue . Total Revenue / Total Number of Orders
-- WHO: States +  with 1000 Orders
-- BY: States
-- WHAT: Average Order Values With States over 1000 Unique Orders
-- HOW: JOIN, AVG

SELECT *
FROM cleaned_orders
;

SELECT *
FROM cleaned_geolocation
;

SELECT *
FROM cleaned_customer_dataset
;

SELECT *
FROM cleaned_payments
;

SELECT 
	ccd.customer_state AS State,
	COUNT(DISTINCT(cp.order_id)) AS Total_Orders,
    (SUM(payment_value) / COUNT(DISTINCT(cp.order_id))) AS Average_Order_Value
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
JOIN cleaned_payments cp
	ON cp.order_id = co.order_id
GROUP BY State
OrDER BY 3 DESC
;

SELECT
    customer_state State,
    AVG(DISTINCT co.order_id) Orders 
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
JOIN cleaned_payments cp
	ON cp.order_id = co.order_id
GROUP BY State

;
-- Find the Average Number of Items per Order for each Product Category --

-- The WHO: Product Categories
-- The BY: Product Category
-- The What: The AVG Of Items
-- The How: JOIN
-- Orders (Low Level) + PC (High Level) = Yes Rows I

SELECT *
FROM cleaned_products
;

SELECT *
FROM cleaned_orders
;

SELECT *
FROM cleaned_customer_dataset
;

SELECT *
FROM cleaned_items
;


SELECT 
	cp.product_category_name AS Product_Cat,
	COUNT(ci.order_item_id) AS AmountBrought,
    (COUNT(ci.order_item_id) / COUNT(DISTINCT(ci.order_id))) AS AverageItems
FROM cleaned_items ci
JOIN cleaned_products cp
	ON cp.product_id = ci.product_id
JOIN cleaned_orders co
	on co.order_id = ci.order_id
GROUP BY Product_Cat
Order BY 3 Desc
;

-- Find the average number of days it takes for a Loyal customer to place their second order after their first one

-- The WHO: Loyal Cutomers, Orders
-- The BY: The number of days it takes to reorder
-- Then WHAT: Customer Loyalty, AvG Days of Ordering
-- The HOW: DATEDIFF, JOIN, MIN

SELECT *
FROM cleaned_orders
;

WITH Customer_Loyalty AS
(
SELECT
	ccd.customer_unique_id AS Customer1,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_payments cp
	ON co.order_id = cp.order_id
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
),
Time_Difference AS
(
SELECT
	customer_unique_id AS Customer2,
	DATEDIFF(Max(order_purchase_timestamp), Min(order_purchase_timestamp)) Date_Difference
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY customer2
)

SELECT
	AVG(Date_Difference) AS Time_Between_Reorder
FROM Customer_Loyalty CL
JOIN Time_Difference TD
	ON TD.Customer2 = CL.Customer1
;

-- Vouchers 2nd Purchase Loyalty --

WITH Loyal_Customers AS
(
SELECT
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
)

SELECT 
	payment_type,
	COUNT(DISTINCT(co.order_id)) as Returned_Buyers
FROM cleaned_orders co
JOIN cleaned_payments cp
	ON co.order_id = cp.order_id
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
JOIN Loyal_Customers LC
	ON ccd.customer_unique_id = lc.customers
GROUP BY payment_type
;

WITH 
First_Purchase AS
(
SELECT
	ccd.customer_unique_id AS Customer,
    MIN(co.order_approved_at) AS First_Order
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY Customer

) ,
Payment_Method AS
( 
SELECT
	fp.customer,
    cp.payment_type
FROM First_Purchase FP
LEFT JOIN cleaned_orders co
	ON fp.first_order = co.order_approved_at
JOIN cleaned_payments cp
	ON cp.order_id = co.order_id
), 

Customer_Loyalty AS
(
SELECT
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
) 

SELECT 
	pm.payment_type,
	COUNT(pm.customer) AS First_Time_Buyers,
    COUNT(DISTINCT cl.customers) AS Loyal,
    COUNT(DISTINCT cl.customers) / COUNT(pm.customer) * 100 AS Loyalty_Percentage
FROM  Customer_Loyalty cl
RIGHT JOIN payment_method pm
	ON cl.customers = pm.customer
GROUP BY payment_type
;


WITH Ranked_Orders AS (
SELECT
	DISTINCT customer_unique_id AS Customer,
    co.order_id Orders,
    co.order_approved_at First_Orders,
	ROW_NUMBER() OVER(partition by customer_unique_id ORDER BY co.order_approved_at, co.order_id) AS Orders_Ranked
FROM cleaned_customer_dataset ccd
JOIN cleaned_orders co
	ON co.customer_id = ccd.customer_id
WHERE co.order_approved_at IS NOT NULL
),

First_Order AS
(
SELECT
	Customer,
    Orders AS First_Order_ID,
    First_Orders AS First_Order_Date
FROM Ranked_Orders
WHERE Orders_Ranked = 1 
),

Voucher_Filter AS (
SELECT
	First_Order_ID,
MAX(CASE
	WHEN payment_type = 'voucher' THEN 1
	ELSE 0
END) AS Payment_Filter
FROM First_Order FO
JOIN cleaned_payments CP
ON cp.order_id = fo.first_order_id
GROUP BY First_Order_ID
),

Customer_Loyalty AS
(
SELECT
	DISTINCT ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
),

Loyal_Vouchers AS (
SELECT
	fo.First_Order_ID,
	MAX(Payment_Filter) AS Payment_Filter
FROM Customer_Loyalty CL
LEFT JOIN First_Order FO
	ON cl.customers = fo.customer
JOIN Voucher_Filter VF
	ON vf.first_order_id = fo.first_order_id
GROUP BY 1
)

SELECT 
	vf.payment_filter AS Payment_Type,
    COUNT(vf.first_order_id) AS Total_Customers,
	COUNT(lv.first_order_id) AS Loyal,
    (COUNT(lv.first_order_id) * 100) /  COUNT(vf.first_order_id) AS Percentage_Of_Voucher_Reorder
FROM Voucher_Filter VF
LEFT JOIN  Loyal_Vouchers LV
	ON lv.first_order_id = vf.first_order_id
GROUP BY 1





;
Payment_Types AS (
SELECT
	DISTINCT Customer,
	cp.payment_type,
CASE 
	WHEN payment_type = 'voucher' THEN 'Voucher'
    ELSE 'Other Payment Types'
END AS Voucher_Filter
FROM First_Order FO
JOIN cleaned_payments CP
ON cp.order_id = fo.first_order_id
)

SELECT
	*
FROM Payment_Types

;

) ,
Payment_Method AS
( 
SELECT
	fp.customer,
    cp.payment_type
FROM First_Purchase FP
LEFT JOIN cleaned_orders co
	ON fp.first_order = co.order_approved_at
JOIN cleaned_payments cp
	ON cp.order_id = co.order_id
), 

Customer_Loyalty AS
(
SELECT
	ccd.customer_unique_id AS Customers,
	COUNT(DISTINCT(co.order_id)) AS Orders
FROM cleaned_orders co
JOIN cleaned_customer_dataset ccd
	ON ccd.customer_id = co.customer_id
GROUP BY ccd.customer_unique_id
HAVING Orders > 1
) 

SELECT 
	pm.payment_type,
	COUNT(pm.customer) AS First_Time_Buyers,
    COUNT(DISTINCT cl.customers) AS Loyal,
    COUNT(DISTINCT cl.customers) / COUNT(pm.customer) * 100 AS Loyalty_Percentage
FROM  Customer_Loyalty cl
RIGHT JOIN payment_method pm
	ON cl.customers = pm.customer
GROUP BY payment_type
;
