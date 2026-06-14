-- PHASE 3.3 — Customer Behaviour, Retention & Value

/* Customer Order Distribution */
WITH customer_segment AS (SELECT customer_id, orders,
CASE WHEN orders = 1 THEN '1' WHEN orders BETWEEN 2 AND 4 THEN '2–4' WHEN orders >= 5 THEN '5+' END AS customer_segment
FROM (
SELECT customer_id, COUNT(DISTINCT order_id) AS orders
FROM fact_orders
GROUP BY customer_id) AS t1)


SELECT customer_segment, COUNT(customer_id) AS users,
(SELECT COUNT(customer_id) FROM customer_segment) AS total_users,
(COUNT(customer_id)/(SELECT (1.0 * COUNT(customer_id)) FROM customer_segment) * 100) AS perc_users
FROM customer_segment
GROUP BY customer_segment


/*Revenue by Customer Segment*/
WITH customer_segment AS (SELECT customer_id, orders,
CASE WHEN orders = 1 THEN '1' WHEN orders BETWEEN 2 AND 4 THEN '2–4' WHEN orders >= 5 THEN '5+' END AS customer_segment
FROM (
SELECT customer_id, COUNT(DISTINCT order_id) AS orders
FROM fact_orders
GROUP BY customer_id) AS t1)

SELECT customer_segment, SUM(order_revenue) AS revenue,
SUM(SUM(order_revenue)) OVER() AS total_revenue,
SUM(order_revenue) /SUM(SUM(order_revenue)) OVER() perc_revenue
FROM (
SELECT c.customer_id, c.customer_segment, f.order_revenue
FROM customer_segment c
JOIN fact_orders f ON c.customer_id=f.customer_id) AS t1
GROUP BY customer_segment


/*Lifetime Value (LTV)*/
SELECT AVG(LTV) AS average_ltv
FROM (
SELECT customer_id, SUM(order_revenue) AS LTV
FROM fact_orders
GROUP BY customer_id) AS t1


/*LTV by segment?*/
WITH customer_segment AS (
SELECT customer_id, orders,
CASE WHEN orders = 1 THEN '1' WHEN orders BETWEEN 2 AND 4 THEN '2–4' WHEN orders >= 5 THEN '5+' END AS customer_segment
FROM (
SELECT customer_id, COUNT(DISTINCT order_id) AS orders
FROM fact_orders
GROUP BY customer_id) AS t1),

customer_ltv AS (
SELECT customer_id, SUM(order_revenue) AS LTV
FROM fact_orders
GROUP BY customer_id)

SELECT customer_segment, AVG(LTV) AS avergae_ltv
FROM customer_segment s
JOIN customer_ltv l ON s.customer_id = l.customer_id
GROUP BY customer_segment

/*Do certain cities or signup cohorts have higher LTV?*/
WITH signup_cohort AS (SELECT customer_id, city, DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1) AS signup_month
FROM dim_customers),

customer_ltv AS (
SELECT customer_id, SUM(order_revenue) AS LTV
FROM fact_orders
GROUP BY customer_id)

SELECT city, AVG(LTV) AS average_ltv
FROM signup_cohort s
JOIN customer_ltv c ON s.customer_id = c.customer_id
GROUP BY city
ORDER BY average_ltv DESC

SELECT signup_month, AVG(LTV) AS average_ltv
FROM signup_cohort s
JOIN customer_ltv c ON s.customer_id = c.customer_id
GROUP BY signup_month
ORDER BY average_ltv DESC


/*New vs Repeat Revenue Over Time
Each month, how much revenue comes from:

First-time customers?

Returning customers?

Is revenue growth driven by acquisition or retention?*/
WITH first_order AS (
SELECT customer_id, MIN(order_month) AS first_order_month
  FROM fact_orders
  GROUP BY customer_id
)

SELECT f.order_month, 
SUM(CASE WHEN f.order_month = fo.first_order_month THEN f.order_revenue ELSE 0 END) AS new_revenue,
SUM(CASE WHEN f.order_month > fo.first_order_month THEN f.order_revenue ELSE 0 END) AS repeat_revenue,
SUM(f.order_revenue) AS total_revenue,
ROUND(100 * SUM(CASE WHEN f.order_month = fo.first_order_month THEN f.order_revenue ELSE 0 END)/SUM(1.0 * f.order_revenue), 2) AS new_pct,
ROUND(100 * SUM(CASE WHEN f.order_month > fo.first_order_month THEN f.order_revenue ELSE 0 END)/SUM(1.0 * f.order_revenue), 2) AS repeat_pct
FROM fact_orders f JOIN first_order fo ON f.customer_id = fo.customer_id
GROUP BY f.order_month
ORDER BY f.order_month

/*Cohort Analysis*/
final_table AS (SELECT f.customer_id, cohort_month,  order_month, DATEDIFF(month, cohort_month, order_month) AS months_since_acquisition
FROM fact_orders f JOIN first_order fo ON f.customer_id = fo.customer_id),

cohort AS (
SELECT cohort_month, months_since_acquisition, COUNT(DISTINCT customer_id) AS users
FROM final_table
GROUP BY cohort_month, months_since_acquisition)

SELECT *, 1.0 * users/cohort_size AS retention
FROM (
SELECT *,SUM(CASE WHEN months_since_acquisition = 0 THEN users ELSE 0 END) OVER (PARTITION BY cohort_month) AS cohort_size
FROM cohort) AS t1


/*Repeat Purchase Time Gap*/
WITH customer_segment AS (
SELECT customer_id, orders,
CASE WHEN orders = 1 THEN '1' WHEN orders BETWEEN 2 AND 4 THEN '2–4' WHEN orders >= 5 THEN '5+' END AS customer_segment
FROM (
SELECT customer_id, COUNT(DISTINCT order_id) AS orders
FROM fact_orders
GROUP BY customer_id) AS t1),

days_between_orders AS (
SELECT order_id, customer_id, order_month, DATEDIFF(day, previous_order_date, order_date) AS time_between_orders
FROM (
SELECT order_id, customer_id, order_date, order_month, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
FROM fact_orders) AS t1
WHERE previous_order_date IS NOT NULL)

SELECT customer_segment, AVG(time_between_orders) AS avergae_days
FROM customer_segment c
JOIN days_between_orders d ON c.customer_id = d.customer_id
GROUP BY customer_segment

SELECT order_month, AVG(time_between_orders) AS average_days
FROM days_between_orders
GROUP BY order_month
ORDER BY order_month


/*Customer Churn*/
WITH customer_latest AS (
SELECT customer_id, MAX(order_date) AS last_order_date
FROM fact_orders
GROUP BY customer_id ),

max_order_date AS (
SELECT MAX(order_date) AS analysis_date FROM fact_orders 
),

churned_cte AS (
SELECT customer_id, CASE WHEN days_since_last_order > 270 THEN 'Churned' ELSE 'Active' END AS churn
FROM (
SELECT customer_id, DATEDIFF(day, last_order_date, analysis_date) AS days_since_last_order
FROM (
SELECT customer_id, last_order_date, analysis_date
FROM customer_latest
CROSS JOIN max_order_date) AS t1) AS t2),

customer_segment AS (
SELECT customer_id, orders,
CASE WHEN orders = 1 THEN '1' WHEN orders BETWEEN 2 AND 4 THEN '2–4' WHEN orders >= 5 THEN '5+' END AS customer_segment
FROM (
SELECT customer_id, COUNT(DISTINCT order_id) AS orders
FROM fact_orders
GROUP BY customer_id) AS t1),

final_cte AS (SELECT s.customer_id, c.churn, s.customer_segment
FROM churned_cte c
JOIN customer_segment s ON c.customer_id = s.customer_id)

SELECT customer_segment, COUNT(DISTINCT customer_id) AS total_users,
COUNT(CASE WHEN churn = 'Churned' THEN customer_id END) AS churned_users,
(COUNT(CASE WHEN churn = 'Churned' THEN customer_id END) * 1.0) * 100/COUNT(DISTINCT customer_id) AS prct_churn
FROM final_cte
GROUP BY customer_segment

SELECT COUNT(CASE WHEN churn = 'Churned' THEN customer_id END) * 100/(SELECT  1.0 * COUNT(DISTINCT customer_id) FROM final_cte)  AS churned_pct
FROM final_cte


/*Revenue Risk
If we lost our top 10% of customers, how much revenue would disappear?*/
WITH customer_revenue AS (SELECT customer_id, SUM(order_revenue) AS revenue 
FROM fact_orders
GROUP BY customer_id
),

ranked AS (SELECT *, NTILE(10) OVER (ORDER BY revenue DESC) AS decile
FROM customer_revenue
)

SELECT (top_10_revenue * 1.0) * 100/total_revenue AS top_10pct_revenue_share
FROM (
SELECT SUM(revenue) AS top_10_revenue,
(SELECT SUM(revenue) FROM customer_revenue) AS total_revenue
FROM ranked
WHERE decile = 1) AS t1
