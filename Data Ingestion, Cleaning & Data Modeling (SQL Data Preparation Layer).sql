/*Data Ingestion, Cleaning & Data Modeling (SQL Data Preparation Layer)*/

CREATE TABLE customers_new (
    customer_id INT,
    signup_date DATE,
    city VARCHAR(50),
    state VARCHAR(10)
);

CREATE TABLE orders 
    order_id INT,
    customer_id INT,
    order_date DATE,
    approved_date DATE,
    delivered_date DATE NULL,
    estimated_delivery_date DATE,
    status VARCHAR(20)
);

CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    price FLOAT,
    freight_value FLOAT
);

CREATE TABLE payments (
    order_id INT,
    payment_type VARCHAR(20),
    payment_value FLOAT
);

CREATE TABLE products (
    product_id INT,
    category VARCHAR(50),
    product_name VARCHAR(100)
);

CREATE TABLE reviews (
    order_id INT,
    score INT,
    review_date DATE
);

BULK INSERT customers_new
FROM 'C:\temp\ecommerce\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT orders
FROM 'C:\temp\ecommerce\orders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT order_items
FROM 'C:\temp\ecommerce\order_items.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT payments
FROM 'C:\temp\ecommerce\payments.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT products
FROM 'C:\temp\ecommerce\products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT reviews
FROM 'C:\temp\ecommerce\reviews.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);


SELECT COUNT(*) FROM customers_new;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM reviews;


SELECT status, COUNT(*) AS order_count
FROM orders
GROUP BY status


SELECT COUNT(*) AS missing_delivered_date
FROM orders
WHERE delivered_date IS NULL

SELECT COUNT(DISTINCT o.order_id) AS bad_orders
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL

CREATE VIEW clean_orders AS
SELECT
    order_id,
    customer_id,
    order_date,
    approved_date,
    delivered_date,
    estimated_delivery_date,
    status,

    CASE 
        WHEN status = 'delivered'
         AND delivered_date IS NOT NULL
         AND delivered_date >= approved_date
        THEN DATEDIFF(day, approved_date, delivered_date)
        ELSE NULL
    END AS delivery_days,

    CASE 
        WHEN status = 'delivered' THEN 1
        ELSE 0
    END AS is_delivered
FROM orders
WHERE order_date >= '2022-01-01'
  AND order_date <= GETDATE()


CREATE VIEW clean_order_items AS
SELECT
    order_id,
    product_id,
    quantity,
    price,
    freight_value
FROM order_items
WHERE quantity > 0
  AND price > 0


CREATE VIEW fact_orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.delivered_date,
    o.status,
    o.delivery_days,
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS order_month,
    SUM(oi.quantity * oi.price) AS order_revenue
FROM clean_orders o
JOIN clean_order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'delivered'
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_date,
    o.delivered_date,
    o.status,
    o.delivery_days

CREATE VIEW dim_customers AS
SELECT
    c.customer_id,
    c.signup_date,
    c.city,
    c.state,
    MIN(o.order_date) AS first_order_date
FROM customers_new c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.signup_date,
    c.city,
    c.state

CREATE VIEW dim_products AS
SELECT
    product_id,
    category,
    product_name
FROM products


SELECT order_month, COUNT(*) AS orders
FROM fact_orders
GROUP BY order_month
ORDER BY order_month


SELECT SUM(order_revenue) AS total_revenue
FROM fact_orders

