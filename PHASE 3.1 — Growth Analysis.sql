-- PHASE 3.1 — Growth Analysis
USE db

/*Are we growing overall?*/
/*How many orders are we getting per month?
How much revenue are we generating per month?
Is growth consistent or volatile?*/

SELECT order_month, COUNT(DISTINCT order_id) AS no_of_orders, SUM(order_revenue) AS revenue,
ROUND(SUM(order_revenue)/COUNT(DISTINCT order_id), 2) AS AOV
FROM fact_orders
GROUP BY order_month
ORDER BY order_month

/*Month-over-Month Growth Rate*/
CREATE VIEW MOM AS 
SELECT order_month, (CASE WHEN previous_orders IS NOT NULL AND previous_orders != 0 THEN CAST(ROUND(100.0 * (no_of_orders - previous_orders)/previous_orders, 2) AS DECIMAL(10, 2)) ELSE 0 END) AS MOM_orders,
(CASE WHEN previous_revenue IS NOT NULL AND previous_revenue != 0 THEN ROUND(100.0 * (revenue - previous_revenue)/previous_revenue, 2) ELSE 0 END) AS MOM_revenue
FROM (
SELECT order_month, no_of_orders, LAG(no_of_orders) OVER(ORDER BY order_month) AS previous_orders,
revenue,  LAG(revenue) OVER(ORDER BY order_month) AS previous_revenue
FROM(
SELECT order_month, COUNT(DISTINCT order_id) AS no_of_orders, SUM(order_revenue) AS revenue
FROM fact_orders
GROUP BY order_month) AS t1) AS t2

SELECT * 
FROM MOM
WHERE MOM_orders < 0 OR MOM_revenue < 0


/*Seasonality & Patterns*/
SELECT FORMAT(order_month, 'MMM') AS month_name, COUNT(DISTINCT order_id) AS no_of_orders, SUM(order_revenue) AS revenue
FROM fact_orders
GROUP BY FORMAT(order_month, 'MMM')
ORDER BY FORMAT(order_month, 'MMM')

/*Average Order Value (AOV) Trend*/
SELECT order_month, SUM(order_revenue) AS revenue,
ROUND(SUM(order_revenue)/COUNT(DISTINCT order_id), 2) AS AOV
FROM fact_orders
GROUP BY order_month
ORDER BY order_month


/*New vs Returning Customer Contribution to Growth*/
SELECT c.customer_segment, SUM(order_revenue) AS revenue
FROM fact_orders f
JOIN customer_segment c ON f.customer_id = c.customer_id
GROUP BY c.customer_segment


SELECT  order_month, new_customer_revenue, repeat_customer_revenue, total_revenue, new_customer_revenue_pct, repeat_customer_revenue_pct,
new_customer_revenue - LAG(new_customer_revenue) OVER (ORDER BY order_month) AS mom_new_revenue_change,
repeat_customer_revenue - LAG(repeat_customer_revenue) OVER (ORDER BY order_month) AS mom_repeat_revenue_change,
total_revenue - LAG(total_revenue) OVER (ORDER BY order_month) AS mom_total_revenue_growth
FROM (
SELECT f.order_month,
SUM(CASE WHEN c.customer_segment = 'New' THEN order_revenue ELSE 0 END) AS new_customer_revenue,
SUM(CASE WHEN c.customer_segment = 'Repeat' THEN order_revenue ELSE 0 END) AS repeat_customer_revenue,
SUM(f.order_revenue) AS total_revenue,
ROUND(1.0 * SUM(CASE WHEN c.customer_segment = 'New' THEN order_revenue ELSE 0 END)/SUM(f.order_revenue), 2) AS new_customer_revenue_pct,
ROUND(1.0 * SUM(CASE WHEN c.customer_segment = 'Repeat' THEN order_revenue ELSE 0 END)/SUM(f.order_revenue), 2) AS repeat_customer_revenue_pct
FROM fact_orders f
JOIN customer_segment c ON f.customer_id = c.customer_id
GROUP BY  f.order_month) AS t1
ORDER BY order_month


/*Growth Stability & Risk Signals*/
SELECT *,CASE	WHEN mom_orders_change IS NULL THEN 'First month' WHEN mom_orders_change > 0 AND mom_revenue_change < 0 THEN 'Orders up, Revenue down'
WHEN mom_orders_change <= 0 AND mom_revenue_change > 0 THEN 'Revenue up, Orders flat/down' END AS growth_mismatch_type
FROM (
SELECT order_month,no_of_orders, no_of_orders - LAG(no_of_orders) OVER(ORDER BY order_month) AS mom_orders_change, revenue,
revenue - LAG(revenue) OVER(ORDER BY order_month) AS mom_revenue_change
FROM(
SELECT order_month, COUNT(DISTINCT order_id) AS no_of_orders, SUM(order_revenue) AS revenue
FROM fact_orders
GROUP BY order_month) AS t1) AS t2
WHERE
  (mom_orders_change > 0 AND mom_revenue_change < 0)
   OR
  (mom_orders_change <= 0 AND mom_revenue_change > 0)
