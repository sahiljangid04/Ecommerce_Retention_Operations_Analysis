-- PHASE 3.2 — Product & Category Performance

/*Category-Level Revenue Concentration*/
SELECT p.category, SUM(quantity * price) AS revenue,
SUM(SUM(quantity * price)) OVER () AS total_revenue,
(SUM(quantity * price)/SUM(SUM(quantity * price)) OVER ()) * 100 AS perc_revenue
FROM clean_orders c 
JOIN clean_order_items i ON c.order_id = i.order_id
JOIN dim_products p ON i.product_id = p.product_id
WHERE c.status = 'delivered'
GROUP BY p.category
ORDER BY perc_revenue DESC


/*Orders vs Revenue by Category*/
SELECT category, revenue, RANK() OVER(ORDER BY revenue DESC) AS revenue_rnk,
order_count, RANK() OVER(ORDER BY order_count DESC) AS orders_rnk,
AOV
FROM (
SELECT p.category, SUM(quantity * price) AS revenue,
COUNT(DISTINCT c.order_id) AS order_count,
SUM(quantity * price)/COUNT(DISTINCT c.order_id) AS AOV
FROM clean_orders c 
JOIN clean_order_items i ON c.order_id = i.order_id
JOIN dim_products p ON i.product_id = p.product_id
WHERE c.status = 'delivered'
GROUP BY p.category) AS t1


/*Average Order Value (AOV) by Category*/
SELECT p.category,
SUM(quantity * price)/COUNT(DISTINCT c.order_id) AS AOV
FROM clean_orders c 
JOIN clean_order_items i ON c.order_id = i.order_id
JOIN dim_products p ON i.product_id = p.product_id
WHERE c.status = 'delivered'
GROUP BY p.category
ORDER BY AOV DESC

/* Top Products Within Each Category*/
SELECT * FROM ( SELECT category, product_name, SUM(quantity * price) AS revenue, RANK() OVER(PARTITION BY category ORDER BY SUM(quantity * price)) AS rnk 
FROM clean_orders c 
JOIN clean_order_items i ON c.order_id = i.order_id 
JOIN dim_products p ON i.product_id = p.product_id 
WHERE c.status = 'delivered' GROUP BY category, product_name) AS t1 
WHERE rnk <= 4

/*Product Breadth vs Depth*/
WITH product_revenue AS ( 
SELECT p.category, product_name, SUM(quantity * price) AS revenue
FROM clean_orders c 
JOIN clean_order_items i ON c.order_id = i.order_id
JOIN dim_products p ON i.product_id = p.product_id
WHERE c.status = 'delivered'
GROUP BY  p.category, product_name)


SELECT * 
FROM (
SELECT category, product_name, revenue, SUM(revenue) OVER (PARTITION BY category) AS category_total,
100.0 * revenue/ SUM(revenue) OVER (PARTITION BY category) AS product_revenue_pct,
RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk,
SUM(revenue) OVER (PARTITION BY category ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)/SUM(revenue) OVER (PARTITION BY category) AS cumulative_revenue_pct
FROM product_revenue) AS t1
WHERE rnk <= 4


/*Category Stability Over Time*/
SELECT *, CASE WHEN ABS(z_score) > 2 THEN 'abnormal month' ELSE 'normal' END AS x_flag
FROM (
SELECT *, (revenue - prev_month_revenue) / prev_month_revenue AS MOM, STDEV(revenue) OVER (PARTITION BY category) AS std,
(revenue - AVG(revenue) OVER (PARTITION BY category)) / STDEV(revenue) OVER (PARTITION BY category) AS z_score
FROM (
SELECT category, delivered_month, revenue, 
LAG(revenue) OVER (PARTITION BY category ORDER BY delivered_month) AS prev_month_revenue
FROM (
SELECT category, DATEFROMPARTS(YEAR(delivered_date), MONTH(delivered_date), 1) AS delivered_month,
SUM(quantity * price) AS revenue, COUNT(DISTINCT c.order_id) AS total_orders
FROM clean_orders c 
JOIN clean_order_items i ON c.order_id = i.order_id
JOIN dim_products p ON i.product_id = p.product_id
WHERE c.status = 'delivered'
GROUP BY category, DATEFROMPARTS(YEAR(delivered_date), MONTH(delivered_date), 1)) AS t1) AS t2) AS t3
