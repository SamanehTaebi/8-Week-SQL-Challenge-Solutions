-- 1: What are the top 3 products by total revenue before discount?

SELECT
    s.prod_id,
    pd.product_name,
    SUM(s.qty * s.price) AS total_revenue_before_discount
FROM sales AS s
INNER JOIN product_details AS pd
    ON s.prod_id = pd.product_id
GROUP BY
    s.prod_id,
    pd.product_name
ORDER BY total_revenue_before_discount DESC
LIMIT 3;


-- 2: What is the total quantity, revenue and discount for each segment?


SELECT
    pd.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue_before_discount,
    SUM(s.qty * s.price * s.discount / 100) AS total_discount
FROM sales AS s
INNER JOIN product_details AS pd
    ON s.prod_id = pd.product_id
GROUP BY pd.segment_name;


-- 3: What is the top selling product for each segment?


SELECT
    product_name,
    segment_name,
    total_quantity
FROM (
    SELECT
        pd.product_name,
        pd.segment_name,
        SUM(s.qty) AS total_quantity,
        RANK() OVER (
            PARTITION BY pd.segment_name
            ORDER BY SUM(s.qty) DESC
        ) AS product_rank
    FROM sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        pd.segment_name,
        pd.product_name
) AS ranked_products
WHERE product_rank = 1;


-- 4: What is the total quantity, revenue and discount for each category?

SELECT
    pd.category_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue_before_discount,
    SUM(s.qty * s.price * s.discount / 100) AS total_discount
FROM sales AS s
INNER JOIN product_details AS pd
    ON s.prod_id = pd.product_id
GROUP BY pd.category_name;


-- 5: What is the top selling product for each category?

SELECT
    product_name,
    category_name,
    total_quantity
FROM (
    SELECT
        pd.product_name,
        pd.category_name,
        SUM(s.qty) AS total_quantity,
        RANK() OVER (
            PARTITION BY pd.category_name
            ORDER BY SUM(s.qty) DESC
        ) AS product_rank
    FROM sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        pd.category_name,
        pd.product_name
) AS ranked_products
WHERE product_rank = 1;


-- 6: What is the percentage split of revenue by product for each segment?

SELECT
    segment_name,
    product_name,
    product_revenue,
    product_revenue / segment_revenue * 100 AS revenue_percentage
FROM (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * s.price) AS product_revenue,
        SUM(SUM(s.qty * s.price)) OVER (
            PARTITION BY pd.segment_name
        ) AS segment_revenue
    FROM sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        pd.segment_name,
        pd.product_name
) AS product_revenue_summary;



-- 7: What is the percentage split of revenue by segment for each category?

SELECT
    category_name,
    segment_name,
    segment_revenue,
    segment_revenue / category_revenue * 100 AS revenue_percentage
FROM (
    SELECT
        pd.category_name,
        pd.segment_name,
        SUM(s.qty * s.price) AS segment_revenue,
        SUM(SUM(s.qty * s.price)) OVER (
            PARTITION BY pd.category_name
        ) AS category_revenue
    FROM sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        pd.category_name,
        pd.segment_name
) AS segment_revenue_summary;




-- Q8: What is the percentage split of total revenue by category?

SELECT
    category_name,
    all_revenue,
    category_revenue / all_revenue * 100 AS revenue_percentage
FROM (
    SELECT
        pd.category_name,
        SUM(s.qty * s.price) AS category_revenue,
        SUM(SUM(s.qty * s.price)) OVER () AS all_revenue
    FROM sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        pd.category_name
) AS category_revenue_summary;


-- 9: What is the total transaction “penetration” for each product?

SELECT
    product_transactions.prod_id,
    product_transactions.product_name,
    product_transactions.product_transactions,
    total_transactions.total_transactions,
    product_transactions.product_transactions
        / total_transactions.total_transactions * 100 AS penetration
FROM (
    SELECT
        s.prod_id,
        pd.product_name,
        COUNT(DISTINCT s.txn_id) AS product_transactions
    FROM sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        s.prod_id,
        pd.product_name
) AS product_transactions
CROSS JOIN (
    SELECT
        COUNT(DISTINCT txn_id) AS total_transactions
    FROM sales
) AS total_transactions;


-- 10: What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

SELECT
    pd1.product_name AS product_1,
    pd2.product_name AS product_2,
    pd3.product_name AS product_3,
    COUNT(*) AS combination_count
FROM sales AS s1
INNER JOIN sales AS s2
    ON s1.txn_id = s2.txn_id
    AND s1.prod_id < s2.prod_id
INNER JOIN sales AS s3
    ON s2.txn_id = s3.txn_id
    AND s2.prod_id < s3.prod_id
INNER JOIN product_details AS pd1
    ON s1.prod_id = pd1.product_id
INNER JOIN product_details AS pd2
    ON s2.prod_id = pd2.product_id
INNER JOIN product_details AS pd3
    ON s3.prod_id = pd3.product_id
GROUP BY
    s1.prod_id,
    s2.prod_id,
    s3.prod_id,
    pd1.product_name,
    pd2.product_name,
    pd3.product_name
ORDER BY combination_count DESC
LIMIT 1;