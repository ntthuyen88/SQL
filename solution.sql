-- This is solution for case study 1 challenge
-- CREATING DATA SET

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- QUESTIONS AND SOLUTIONS
-- 1 What the total amount each customer spent at the restaurant?

-- 2 How many days has each customer visited the restaurant?

-- 3 What was the first item from the menu purchased by each customer?
WITH cte AS
(
  SELECT
	customer_id,
	product_name,
  	order_date,
  	RANK() OVER(PARTITION by customer_id ORDER BY order_date) as ranking
  FROM sales
	JOIN menu
	ON menu.product_id = sales.product_id
 )
  
 SELECT DISTINCT customer_id, product_name
 FROM cte
 WHERE ranking = 1;

-- 4 What is the most purchased item on the menu and how many times was it purchased by all customers.
SELECT
	product_name,
	COUNT(*) as times_purchased
FROM sales
	JOIN menu
	ON menu.product_id = sales.product_id
GROUP BY product_name
HAVING COUNT(*) = (SELECT COUNT(*) as times_purchased
                   FROM dannys_diner.sales 
                   JOIN dannys_diner.menu ON menu.product_id = sales.product_id
                   GROUP BY sales.product_id
                   ORDER BY times_purchased
                   DESC LIMIT 1);

-- 5 Which item was the most popular for each customer?
WITH temple AS
(
  SELECT
	customer_id,
	product_name,
	COUNT (*) as times_purchased,
	RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*)) as ranking
FROM sales
	JOIN menu
	ON menu.product_id = sales.product_id
	GROUP BY customer_id, product_name
)

SELECT
	customer_id,
	product_name,
	times_purchased
FROM temple
WHERE ranking = 1;

-- 6 Which item was purchased first by the customer after they became a member?
WITH cte AS
(
  SELECT
	sales.customer_id,
  	product_name,
  	order_date,
  	join_date,
  	RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) as ranking
  FROM sales
	JOIN menu
		ON menu.product_id = sales.product_id
  	JOIN members
		ON members.customer_id = sales.customer_id
  WHERE order_date >= join_date
)

SELECT customer_id, product_name
FROM cte
WHERE ranking = 1;

-- 7 Which item was purchased just before the customer became a member?
(
  SELECT
	sales.customer_id,
  	product_name,
  	order_date,
  	join_date,
  	RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) as ranking
  FROM sales
	JOIN menu
		ON menu.product_id = sales.product_id
  	JOIN members
		ON members.customer_id = sales.customer_id
  WHERE order_date < join_date
)

SELECT customer_id, product_name
FROM cte
WHERE ranking = 1;

-- 8 What is the total items and amount spent for each member before they became a member?
SELECT
	sales.customer_id,
	COUNT(*) AS total_items,
	SUM(price) AS amount_spent
FROM sales
	JOIN menu
		ON menu.product_id = sales.product_id
	JOIN members
		ON members.customer_id = sales.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 9 If each $1 spent equates to 10 points and sushi has a 2x points multipler - how many points would each customer have?
SELECT
	customer_id,
	SUM(CASE
        	WHEN product_name = 'sushi' THEN 20*price
        	ELSE 10*price
        END) as total_points
FROM sales
	LEFT JOIN menu
		ON menu.product_id = sales.product_id
GROUP BY customer_id
ORDER BY customer_id;

/* 10 In the first week after a customer joints the program (including their join date) the earn 2x points on all items, not just sushi.
How many points do customer A and B have at the end of January?*/
WITH cte AS
(
SELECT
	sales.customer_id,
	product_name,
	price,
	order_date,
	join_date,
	join_date + INTERVAL'6 day' as firstweek_ends_date
FROM sales
	JOIN menu
		ON menu.product_id = sales.product_id
	JOIN members
		ON members.customer_id = sales.customer_id
)

SELECT
	customer_id,
	SUM(CASE
        	WHEN product_name = 'sushi' THEN 20*price
        	WHEN order_date BETWEEN join_date AND firstweek_ends_date THEN 20*price
        	ELSE 10*price
        END) as total_points
FROM cte
WHERE order_date < '2021-02-01' AND order_date >= join_date
GROUP BY customer_id
ORDER BY customer_id;

-- Bonus Questions
/* Join All The Things
Recreate the given table output using the available data*/
SELECT
	sales.customer_id,
	order_date,
	product_name,
	price,
	CASE
		WHEN join_date >= order_date THEN 'N'
		WHEN join_date <= order_date THEN 'Y'
		ELSE 'N'
	END as member_status
FROM sales
LEFT JOIN members
	ON sales.customer_id = members.customer_id
JOIN menu
	ON sales.product_id = menu.product_id
ORDER BY sales.customer_id, order_date


/* Rank All The Things
Danny also requires further information about the ranking of customer products,
but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records
when customers are not yet part of the loyalty program.*/
WITH tmp AS
(
SELECT
	sales.customer_id,
	product_name,
	CASE
		WHEN order_date >= join_date THEN COUNT(*)
		ELSE NULL
	END as times_purchased
FROM sales
	LEFT JOIN menu
		ON menu.product_id = sales.product_id
	LEFT JOIN members
		ON members.customer_id = sales.customer_id
GROUP BY sales.customer_id, product_name, order_date, join_date
)

SELECT
	customer_id,
	product_name,
	CASE
		WHEN times_purchased IS NULL THEN NULL
		ELSE DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY times_purchased DESC nulls LAST)
	END as ranking
FROM tmp;

