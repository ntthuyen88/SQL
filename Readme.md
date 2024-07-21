# Danny’s Dinner

[https://8weeksqlchallenge.com/case-study-1/](https://8weeksqlchallenge.com/case-study-1/)

# Solution

I am utilising PostgreSQL to solve these questions.

- 1. What is the total amount each customer spent at the restaurant?

- 2. How many days has each customer visited the restaurant?
    
    

- 3. What was the first item from the menu purchased by each customer?
    - Create a CTE with the new column ranking that sort customer information by order_date in ascending order, numbering each row sequentially by using RANK() window function.
    - In the outer query, select the appropriate columns and apply filter in the WHERE clause to retrieve only the rows where the ranking column equals 1, which represents the first row within each customer_id.
    - Using DISTINCT on the SELECT query selecting only one result if there is a same product is bought at the same day.
    
    ```sql
    WITH cte AS
    (
      SELECT
    		  customer_id,
    	 		product_name,
      		order_date,
      		RANK() OVER(PARTITION by customer_id ORDER BY order_date) as ranking
      FROM sales
      	JOIN menu ON menu.product_id = sales.product_id
      )
      
     SELECT DISTINCT customer_id, product_name
     FROM cte
     WHERE ranking = 1;
    ```
    
    Answer:
    
    ![Screenshot 2024-04-13 at 10.36.01 PM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-13_at_10.36.01_PM.png)
    
- Customer A’s first order are curry and sushi.
- Customer B’s first order is curry.
- Customer C’s first order is ramen.

- **4. What is the most purchased item on the menu and how many times was it purchased by all customers.**
    
    
    - Using COUNT() aggregation  to calculate times_purchased  of each product.
    - Using subquery on HAVING() clause with the subquery to filter products have the most times_purchased.
    
    ```sql
    SELECT
    	product_name,
    	COUNT(*) as times_purchased
    FROM sales
     JOIN menu
    	 ON menu.product_id = sales.product_id
    GROUP BY product_name
    HAVING COUNT(*) = (SELECT COUNT(*) as times_purchased
                       FROM sales JOIN menu ON menu.product_id = sales.product_id
                       GROUP BY product_id 
    	                 ORDER BY times_purchased
    	                 DESC LIMIT 1)
    ```
    
    Answer:
    
    ![Screenshot 2024-04-13 at 11.01.29 PM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-13_at_11.01.29_PM.png)
    
- The most purchased item on the menu is ramen which is 8 items.

- **5. Which item was the most popular for each customer?**
    
    
    - Create a CTE with the new column ranking that sort customer_id by times_purchased in ascending order, numbering each row sequentially by using RANK() window function.
    - In the outer query, select the appropriate columns and apply filter in the WHERE clause to retrieve only the rows where the ranking column equals 1, which represents the first row within each customer_id.
    
    ```sql
    WITH temple AS
    (
      SELECT
    		customer_id,
    		product_name,
        count(*) as times_purchased,
        RANK() OVER(PARTITION by customer_id ORDER BY count(*)) as ranking
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
    ```
    
    Answer:
    
    ![Screenshot 2024-04-13 at 11.15.27 PM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-13_at_11.15.27_PM.png)
    
- Customer A favourite item is sushi
- Customer B’s enjoys all items on the menu which are sushi, curry, and ramen.

### **6. Which item was purchased first by the customer after they became a member?**

The order_date of the data was not indicated a certain time of purchase,. I assumed that the items was purchased on the join date will be treated as a purchase after customer became a member.

- Create a CTE with the new column ranking that sort customer_id by order_date in ascending order, numbering each row sequentially by using RANK() window function.
- JOIN tables sales, menu, and members. Using WHERE clause in order to filter only include sales that occurred after customers became a member.
- In the outer query, select the appropriate columns and apply filter in the WHERE clause to retrieve only the rows where the ranking column equals 1, which represents the first row within each customer_id.

```sql
WITH cte AS
(
  SELECT
		sales.customer_id,
  	product_name,
  	order_date,
  	join_date,
  	RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) as ranking
  FROM sales
  	JOIN menu ON menu.product_id = sales.product_id
  	JOIN members ON members.customer_id = sales.customer_id
	WHERE order_date >= join_date
)

SELECT customer_id, product_name
FROM cte
WHERE ranking = 1;
```

Answer:

![Screenshot 2024-04-13 at 11.51.54 PM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-13_at_11.51.54_PM.png)

- Customer A’s first order as a member is curry.
- Customer B’s first order as a member is sushi.

### 7. Which item was purchased just before the customer became a member?

The order_date of the data is not indicate a certain time of purchase, so I have a few assumptions on this query.

**Assumption:** 

- There would have the products which are bought at the same day. I assume that the query will be “Which items was purchased just before the customer became a member”.
- The items was purchased on the join date will be treated as a purchase after customer became a member.

```sql
with cte AS
(
  select sales.customer_id,
  		product_name,
  		order_date,
  		join_date,
  		rank() over(partition by sales.customer_id order by order_date DESC) as ranking
  from sales
  	left join menu on menu.product_id = sales.product_id
  	join members on members.customer_id = sales.customer_id
	where order_date < join_date
)
select customer_id, product_name
from cte
where ranking = 1;
```

Result:

![Screenshot 2024-04-14 at 12.01.27 AM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-14_at_12.01.27_AM.png)

- 8. What is the total items and amount spent for each member before they became a member?
    
    **Assumption**: The items was purchased on the join date will be treated as a purchase after customer became a member.
    
    ```sql
    SELECT sales.customer_id,
    		COUNT(*) AS total_items,
        SUM(price) AS amount_spent
    FROM sales
    	JOIN menu ON menu.product_id = sales.product_id
    	JOIN members ON members.customer_id = sales.customer_id
    WHERE order_date < join_date
    GROUP BY sales.customer_id
    ORDER BY sales.customer_id;
    ```
    
    Result:
    
    ![Screenshot 2024-04-14 at 12.13.40 AM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-14_at_12.13.40_AM.png)
    

- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
    
    **Assumption 1**: The customer who is either member or  non-member.
    
    ```sql
    select customer_id,
    	sum(CASE
            	when product_name = 'sushi' then 20*price
            	ELSE 10*price
            end) as total_points
    from sales
    	LEFT JOIN menu on menu.product_id = sales.product_id
    group by customer_id
    order by customer_id;
    ```
    
    Result:
    
    ![Screenshot 2024-04-14 at 12.29.13 AM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-14_at_12.29.13_AM.png)
    
    **Assumption 2**: 
    
    - The customer who is only member.
    - The items was purchased on the join date will be treated as a purchase after customer became a member.
    
    ```sql
    select sales.customer_id,
    	sum(CASE
            	when product_name = 'sushi' then 20*price
            	ELSE 10*price
            end) as total_points
    from sales
    	JOIN menu on menu.product_id = sales.product_id
        JOIn members on members.customer_id = sales.customer_id
    WHERe order_date >= join_date
    group by sales.customer_id
    order by sales.customer_id;
    ```
    
    Result:
    
    ![Screenshot 2024-04-14 at 12.33.45 AM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-14_at_12.33.45_AM.png)
    

- 10. In the first week after a customer joints the program (including their join date) the earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
    
    The points is only counted since the customer became a member.
    
    ```sql
    with cte as
    (
    select sales.customer_id,
    	product_name,
      	price,
      	order_date,
      	join_date,
    	join_date + INTERVAL'6 day' as firstweek_ends_date
    from sales
    	JOIN menu on menu.product_id = sales.product_id
        JOIn members on members.customer_id = sales.customer_id
    )
    select customer_id,
    	sum(CASE
            	when product_name = 'sushi' then 20*price
            	when order_date BETWEEN join_date and firstweek_ends_date then 20*price
            	ELSE 10*price
            end) as total_points
    from cte
    where order_date < '2021-02-01' and order_date >= join_date
    group by customer_id
    order by customer_id;
    ```
    
    Result:
    
    ![Screenshot 2024-04-14 at 1.23.16 AM.png](Danny%E2%80%99s%20Dinner%207f84ba63e6104991849d5311ade68170/Screenshot_2024-04-14_at_1.23.16_AM.png)
    

- Bonus question -
    
    
    What 
    
    ```sql
    WITH tmp AS
    (
    SELECT sales.customer_id,
        product_name,
        CASE
        	when order_date >= join_date then count(*)
      		else NULL
        END as times_purchased
    FROM sales
    	LEFT join menu on menu.product_id = sales.product_id
        LEFT join members on members.customer_id = sales.customer_id
    GROUP BY sales.customer_id, product_name, order_date, join_date
    )
    
    SELECT customer_id,
    	product_name,
        CASE
       		WHEN times_purchased is NULL then NULL
        	ELSE DENSE_RANK() over(partition by customer_id order by times_purchased DESC nulls LAST)
        end as ranking
    FROM tmp;
    ```
    
    Result