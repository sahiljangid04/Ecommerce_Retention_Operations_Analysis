USE db

/*Delivery Time Distribution*/
SELECT delivery_buckets, COUNT(*) AS order_count,
100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS pct_orders
FROM (
SELECT *,
CASE WHEN delivery_days <= 2 THEN '0–2 days' WHEN delivery_days BETWEEN 3 AND 5 THEN '3–5 days' ELSE '6+ days' END AS delivery_buckets
FROM fact_orders) AS t2
GROUP BY delivery_buckets

SELECt AVG(delivery_days) AS average_delivery_days
FROM fact_orders

SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_days) OVER () AS Median
FROM fact_orders

/*SLA Breach Analysis*/
WITH late_orders AS (SELECT COUNT(order_id) AS late_orders_count
FROM (
SELECT order_id, estimated_delivery_date, delivered_date
FROM clean_orders
WHERE status = 'delivered') AS t1
WHERE delivered_date > estimated_delivery_date),

total_orders AS (SELECT COUNT(order_id) AS total_order_count
FROM clean_orders
WHERE status = 'delivered')

SELECT 1.0 * late_orders_count/(SELECT total_order_count FROM total_orders) AS prct_late_deliveries
FROM late_orders


SELECT order_id, estimated_delivery_date, delivered_date
FROM clean_orders
WHERE status = 'delivered'

WITH delivered_orders AS (
SELECT *, DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS months,
CASE WHEN delivered_date > estimated_delivery_date THEN 1 ELSE 0 END AS late_flag
FROM clean_orders
WHERE status = 'delivered')

SELECT city, (SUM(CASE WHEN late_flag = 1 THEN 1 ELSE 0 END) * 1.0) * 100/COUNT(order_id) prct_late_deliveries
FROM delivered_orders o
JOIN dim_customers d ON d.customer_id = o.customer_id
GROUP BY city

SELECT months, (SUM(CASE WHEN late_flag = 1 THEN 1 ELSE 0 END) * 1.0) * 100/COUNT(order_id) prct_late_deliveries
FROM delivered_orders
GROUP BY months
ORDER BY months


/*Review Score Distribution*/
WITH order_reviews AS (
SELECT f.order_id, f.customer_id, order_date, delivered_date, status, delivery_days, order_month,
order_revenue, score, review_date,
CASE WHEN delivery_days <= 2 THEN '0–2 days' WHEN delivery_days BETWEEN 3 AND 5 THEN '3–5 days' ELSE '6+ days' END AS delivery_buckets
FROM fact_orders f
JOIN reviews r ON f.order_id = r.order_id)

SELECT (SUM(CASE WHEN score IN (1,2) THEN 1 ELSE 0 END) * 100.0)/COUNT(*) AS prct_for_1_to_2_reviews
FROM order_reviews

SELECT score, COUNT(*) AS review_count, SUM(COUNT(*)) OVER () AS total_count,
COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS prct_per_score
GROUP BY score

SELECT AVG(score) AS average_review_score,
FROM order_reviews


/*Delivery Time vs Rating (Core Insight Section)*/
WITH order_reviews AS (
SELECT f.order_id, f.customer_id, order_date, delivered_date, status, delivery_days, order_month,
order_revenue, score, review_date,
CASE WHEN delivery_days <= 2 THEN '0–2 days' WHEN delivery_days BETWEEN 3 AND 5 THEN '3–5 days' ELSE '6+ days' END AS delivery_buckets
FROM fact_orders f
JOIN reviews r ON f.order_id = r.order_id)

SELECT delivery_buckets, AVG(score) AS average_rating
FROM order_reviews
GROUP BY delivery_buckets



/*Revenue Risk from Poor Delivery*/
WITH order_reviews AS (
SELECT  f.customer_id, f.order_id, f.order_date, f.order_revenue, f.delivery_days, r.score, r.review_date,
CASE WHEN r.score IN (1,2) THEN 'Low' WHEN r.score = 3 THEN 'Neutral' WHEN r.score IN (4,5) THEN 'High' END AS rating_type,
CASE WHEN f.delivery_days <= 2 THEN '0–2 days' WHEN f.delivery_days BETWEEN 3 AND 5 THEN '3–5 days' ELSE '6+ days' END AS delivery_bucket
FROM fact_orders f 
JOIN reviews r ON f.order_id = r.order_id
),
first_review AS (
SELECT customer_id, rating_type, MIN(review_date) AS first_review_date
FROM order_reviews
GROUP BY customer_id, rating_type
),

future_behavior AS (
SELECT fr.customer_id,fr.rating_type, SUM(CASE WHEN f.order_date > fr.first_review_date THEN f.order_revenue ELSE 0 END) AS future_revenue,
COUNT(CASE WHEN f.order_date > fr.first_review_date THEN 1 END) AS future_orders
FROM first_review fr
LEFT JOIN fact_orders f ON fr.customer_id = f.customer_id
GROUP BY fr.customer_id, fr.rating_type
)

SELECT delivery_bucket, COUNT(customer_id) AS customers, COUNT(CASE WHEN future_orders = 0 THEN 1 END) * 100.0 /COUNT(customer_id) AS churn_rate_pct
FROM 
(SELECT fr.customer_id,orv.delivery_bucket, COUNT(CASE WHEN f.order_date > fr.first_review_date THEN 1 END) AS future_orders
FROM first_review fr JOIN order_reviews orv ON fr.customer_id = orv.customer_id
LEFT JOIN fact_orders f ON fr.customer_id = f.customer_id
GROUP BY fr.customer_id, orv.delivery_bucket
) t
GROUP BY delivery_bucket

SELECT SUM(CASE WHEN score IN (1,2) THEN order_revenue ELSE 0 END) * 100.0/SUM(order_revenue) AS pct_revenue_from_low_ratings
FROM order_reviews

SELECT rating_type, COUNT(customer_id) AS customers, COUNT(CASE WHEN future_orders > 0 THEN 1 END) * 100.0 /COUNT(customer_id) AS reorder_rate_pct,
AVG(future_revenue) AS avg_future_revenue
FROM future_behavior
GROUP BY rating_type

/*Operational Trends Over Time*/
SELECT order_month, AVG(delivery_days) AS delivery_time, AVG(score) AS ratings
FROM fact_orders f
JOIN reviews r ON f.order_id= r.order_id
GROUP BY order_month
ORDER BY order_month


/*City-Level Performance*/
WITH delivered_orders AS (
SELECT c.order_id, c.customer_id,c.delivery_days, c.estimated_delivery_date, c.delivered_date,
CASE WHEN c.delivered_date > c.estimated_delivery_date THEN 1 ELSE 0 END AS late_flag
FROM clean_orders c
WHERE c.status = 'delivered'
),

city_sla AS (
SELECT d.city, COUNT(DISTINCT o.order_id) AS total_orders, SUM(late_flag) AS late_orders, SUM(late_flag) * 100.0 / COUNT(DISTINCT o.order_id) AS perc_SLA_breach, AVG(o.delivery_days) AS avg_delivery_time
FROM delivered_orders o
JOIN dim_customers d ON o.customer_id = d.customer_id
GROUP BY d.city
),

city_ratings AS (
SELECT d.city, AVG(r.score) AS avg_rating
FROM delivered_orders o
JOIN reviews r ON o.order_id = r.order_id
JOIN dim_customers d ON o.customer_id = d.customer_id
GROUP BY d.city
)

SELECT s.city, s.total_orders, s.late_orders, s.perc_SLA_breach, s.avg_delivery_time, r.avg_rating
FROM city_sla s
LEFT JOIN city_ratings r ON s.city = r.city
ORDER BY s.perc_SLA_breach DESC