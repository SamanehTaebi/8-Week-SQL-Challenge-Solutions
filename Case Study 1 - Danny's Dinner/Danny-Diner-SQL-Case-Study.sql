-- Danny's Diner SQL Case Study
-- MySQL


-- Question 1:
-- What is the total amount each customer spent at the restaurant?

SELECT 
    s.customer_id,
    SUM(m.price) AS total_spent
FROM sales s
INNER JOIN menu m 
    ON s.product_id = m.product_id
GROUP BY s.customer_id;



-- Question 2:
-- How many days has each customer visited the restaurant?

SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS total_visit
FROM sales
GROUP BY customer_id;



-- Question 3:
-- What was the first item from the menu purchased by each customer?

SELECT *
FROM
(
    SELECT 
        s.customer_id,
        m.product_name,
        RANK() OVER(
            PARTITION BY s.customer_id
            ORDER BY s.order_date
        ) AS rnk
    FROM sales s
    INNER JOIN menu m
        ON s.product_id = m.product_id
) AS t
WHERE rnk = 1;



-- Question 4:
-- What is the most purchased item on the menu 
-- and how many times was it purchased by all customers?

SELECT 
    m.product_name,
    COUNT(*) AS total_sale
FROM sales s
INNER JOIN menu m
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_sale DESC
LIMIT 1;



-- Question 5:
-- Which item was the most popular for each customer?

WITH t AS
(
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS total
    FROM sales s
    INNER JOIN menu m
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
),

t2 AS
(
    SELECT
        customer_id,
        product_name,
        total,
        RANK() OVER(
            PARTITION BY customer_id
            ORDER BY total DESC
        ) AS rnk
    FROM t
)

SELECT
    customer_id,
    product_name,
    total
FROM t2
WHERE rnk = 1;



-- Question 6:
-- Which item was purchased first by the customer 
-- after they became a member?

WITH after_member AS
(
    SELECT 
        s.customer_id,
        s.order_date,
        s.product_id,
        mem.join_date
    FROM sales s
    INNER JOIN members mem
        ON s.customer_id = mem.customer_id
    WHERE s.order_date >= mem.join_date
),

after_purchase AS
(
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM after_member
    GROUP BY customer_id
)

SELECT 
    ap.customer_id,
    m.product_name
FROM after_purchase ap
INNER JOIN sales s
    ON s.customer_id = ap.customer_id
    AND s.order_date = ap.first_order_date
INNER JOIN menu m
    ON s.product_id = m.product_id;


-- Question 7:
-- Which item was purchased just before the customer became a member?

WITH before_member AS
(
    SELECT 
        s.customer_id,
        s.order_date,
        s.product_id,
        mem.join_date
    FROM sales s
    INNER JOIN members mem
        ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
),

before_purchase AS
(
    SELECT 
        customer_id,
        MAX(order_date) AS before_order_date
    FROM before_member
    GROUP BY customer_id
)

SELECT 
    bp.customer_id,
    m.product_name
FROM before_purchase bp
INNER JOIN sales s
    ON s.customer_id = bp.customer_id
    AND s.order_date = bp.before_order_date
INNER JOIN menu m
    ON s.product_id = m.product_id;



-- Question 8:
-- What is the total items and amount spent for each member 
-- before they became a member?

WITH before_member AS
(
    SELECT 
        s.customer_id,
        s.order_date,
        s.product_id,
        mem.join_date
    FROM sales s
    INNER JOIN members mem
        ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
)

SELECT 
    bm.customer_id,
    COUNT(bm.product_id) AS total_items,
    SUM(m.price) AS total_spent
FROM before_member bm
INNER JOIN menu m
    ON bm.product_id = m.product_id
GROUP BY bm.customer_id;



-- Question 9:
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier,
-- how many points would each customer have?

SELECT 
    s.customer_id,
    SUM(
        CASE
            WHEN m.product_name = 'sushi'
            THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales s
INNER JOIN menu m
    ON s.product_id = m.product_id
GROUP BY s.customer_id;



-- Question 10:
-- In the first week after a customer joins the program 
-- (including their join date) they earn 2x points on all items,
-- not just sushi.
-- How many points do customer A and B have at the end of January?

SELECT 
    s.customer_id,
    SUM(
        CASE
            WHEN s.order_date BETWEEN mem.join_date 
                 AND DATE_ADD(mem.join_date, INTERVAL 7 DAY)
            THEN m.price * 10 * 2
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales s
INNER JOIN menu m
    ON s.product_id = m.product_id
INNER JOIN members mem
    ON s.customer_id = mem.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;



-- Bonus Question:
-- Join All The Things
--
-- Create a table that combines sales, menu and members information.
-- The output should include customer_id, order_date, product_name,
-- price and member status.

SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date >= mem.join_date
        THEN 'Y'
        ELSE 'N'
    END AS member
FROM sales s
INNER JOIN menu m
    ON s.product_id = m.product_id
LEFT JOIN members mem
    ON s.customer_id = mem.customer_id;



-- Bonus Question:
-- Rank All The Things
--
-- Add ranking information for customer purchases.
-- Ranking should only apply after membership.
-- Non-member purchases should have NULL ranking.
--
-- Note:
-- The dataset does not contain a unique transaction ID.
-- Therefore, ranking results are joined back using customer_id,
-- order_date and product_name.
-- In a real-world dataset, a unique transaction_id should be used.

WITH customer_orders AS
(
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price,
        CASE
            WHEN s.order_date >= mem.join_date
            THEN 'Y'
            ELSE 'N'
        END AS member
    FROM sales s
    INNER JOIN menu m
        ON s.product_id = m.product_id
    LEFT JOIN members mem
        ON s.customer_id = mem.customer_id
),

ranked_orders AS
(
    SELECT
        customer_id,
        order_date,
        product_name,
        RANK() OVER(
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS ranking
    FROM customer_orders
    WHERE member = 'Y'
)

SELECT
    co.customer_id,
    co.order_date,
    co.product_name,
    co.price,
    co.member,
    ro.ranking
FROM customer_orders co
LEFT JOIN ranked_orders ro
    ON co.customer_id = ro.customer_id
    AND co.order_date = ro.order_date
    AND co.product_name = ro.product_name;