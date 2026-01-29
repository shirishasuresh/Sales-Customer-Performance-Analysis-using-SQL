create database akash;
use akash;
select * from sales_sql_project_dataset;
select * from orders;
select * from orders_items;
/*Calculate the total revenue generated from all orders.*/
SELECT SUM(quantity * price) AS total_revenue
FROM orders_items;


/*Find total revenue by product category.*/
SELECT SUM(quantity * price) AS total_revenue
FROM orders_items group by category;
/*Show monthly sales trend (month + total revenue).*/
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
       SUM(oi.quantity * oi.price) AS monthly_revenue
FROM orders o
JOIN orders_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

/*Identify the top 5 orders by revenue.*/
SELECT o.order_id,
       SUM(oi.quantity * oi.price) AS order_revenue
FROM orders o
JOIN orders_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id
ORDER BY order_revenue DESC
LIMIT 5;

/*Find the average order value across all orders.*/
SELECT AVG(order_revenue) AS avg_order_value
FROM (
    SELECT order_id,
           SUM(quantity * price) AS order_revenue
    FROM orders_items
    GROUP BY order_id
) t;



/*Calculate total spending per customer.*/
SELECT c.customer_id,
       c.customer_name,
       SUM(oi.quantity * oi.price) AS total_spent
FROM sales_sql_project_dataset c
JOIN orders o ON c.customer_id = o.customer_id
JOIN orders_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name;

/*Identify the top 5 customers by total spending.*/
SELECT c.customer_name,
       SUM(oi.quantity * oi.price) AS total_spent
FROM sales_sql_project_dataset c
JOIN orders o ON c.customer_id = o.customer_id
JOIN orders_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 5;

/*Calculate average order value per customer.*/
SELECT c.customer_name,
       AVG(order_total) AS avg_order_value
FROM (
    SELECT o.order_id, o.customer_id,
           SUM(oi.quantity * oi.price) AS order_total
    FROM orders o
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
) t
JOIN sales_sql_project_dataset c ON t.customer_id = c.customer_id
GROUP BY c.customer_name;

/*Classify customers as repeat or one-time buyers.*/
SELECT customer_id,
       CASE 
           WHEN COUNT(order_id) > 1 THEN 'Repeat'
           ELSE 'One-Time'
       END AS customer_type
FROM orders
GROUP BY customer_id;

/*Find the percentage contribution of each customer to total revenue.*/
SELECT c.customer_name,
       ROUND(SUM(oi.quantity * oi.price) * 100 /
       (SELECT SUM(quantity * price) FROM orders_items), 2) AS revenue_percentage
FROM sales_sql_project_dataset c
JOIN orders o ON c.customer_id = o.customer_id
JOIN orders_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_name;



/*Rank customers based on total revenue using a window function.*/
SELECT customer_name,
       total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS revenue_rank
FROM (
    SELECT c.customer_name,
           SUM(oi.quantity * oi.price) AS total_spent
    FROM sales_sql_project_dataset c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_name
) t;

/*Find the top-selling product in each category.*/
SELECT category, product, total_sales
FROM (
    SELECT category, product,
           SUM(quantity) AS total_sales,
           RANK() OVER (PARTITION BY category ORDER BY SUM(quantity) DESC) AS rnk
    FROM orders_items
    GROUP BY category, product
) t
WHERE rnk = 1;

/*Identify the most preferred payment method by total revenue.*/
SELECT payment_type,
       SUM(oi.quantity * oi.price) AS revenue
FROM orders o
JOIN orders_items oi ON o.order_id = oi.order_id
GROUP BY payment_type
ORDER BY revenue DESC;

/*Find customers whose total spending is above the overall average.*/
SELECT customer_name, total_spent
FROM (
    SELECT c.customer_name,
           SUM(oi.quantity * oi.price) AS total_spent
    FROM sales_sql_project_dataset c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_name
) t
WHERE total_spent >
      (SELECT AVG(quantity * price) FROM orders_items);

/*Calculate running total of revenue by leading order date.*/
SELECT order_date,
       SUM(daily_revenue) OVER (ORDER BY order_date) AS running_total
FROM (
    SELECT o.order_date,
           SUM(oi.quantity * oi.price) AS daily_revenue
    FROM orders o
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_date
) t;



/*Categorize customers into High / Medium / Low value based on spending.*/
SELECT customer_name,
       CASE
           WHEN total_spent >= 50000 THEN 'High'
           WHEN total_spent >= 20000 THEN 'Medium'
           ELSE 'Low'
       END AS customer_value
FROM (
    SELECT c.customer_name,
           SUM(oi.quantity * oi.price) AS total_spent
    FROM sales_sql_project_dataset c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_name
) t;

/*Find orders placed within 30 days of customer signup.*/
SELECT o.order_id, c.customer_name, o.order_date
FROM sales_sql_project_dataset c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date <= DATE_ADD(c.signup_date, INTERVAL 30 DAY);

/*Identify customers who have never placed a repeat order.*/
select * from sales_sql_project_dataset;
select * from orders;
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) = 1;

/*Find products contributing more than 25% of category revenue.*/
SELECT category, product, product_revenue
FROM (
    SELECT category, product,
           SUM(quantity * price) AS product_revenue,
           SUM(SUM(quantity * price)) OVER (PARTITION BY category) AS category_revenue
    FROM orders_items
    GROUP BY category, product
) t
WHERE product_revenue / category_revenue > 0.25;

/*Identify months where revenue increased compared to previous month.*/
SELECT month, revenue
FROM (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
           SUM(oi.quantity * oi.price) AS revenue,
           LAG(SUM(oi.quantity * oi.price)) OVER (ORDER BY DATE_FORMAT(o.order_date, '%Y-%m')) AS prev_revenue
    FROM orders o
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY month
) t
WHERE revenue > prev_revenue;
