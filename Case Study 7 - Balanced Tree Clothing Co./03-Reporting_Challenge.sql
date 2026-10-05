DELIMITER //

CREATE PROCEDURE monthly_report(
    IN p_report_month DATE
)
BEGIN
    -- Define the start and end date of the reporting month
 
    DECLARE v_month_start DATE;
    DECLARE v_month_end DATE;
    DECLARE v_total_transactions INT;

    SET v_month_start =
        DATE_SUB(
            p_report_month,
            INTERVAL DAYOFMONTH(p_report_month) - 1 DAY
        );

    SET v_month_end =
        DATE_ADD(v_month_start, INTERVAL 1 MONTH);
        
        
    -- Remove temporary tables from previous procedure calls
    DROP TEMPORARY TABLE IF EXISTS monthly_sales;
    DROP TEMPORARY TABLE IF EXISTS monthly_sales_2;
    DROP TEMPORARY TABLE IF EXISTS monthly_sales_3;

    -- Create temporary table containing only the month's sales

    DROP TEMPORARY TABLE IF EXISTS monthly_sales;

    CREATE TEMPORARY TABLE monthly_sales AS
    SELECT *
    FROM sales
    WHERE start_txn_time >= v_month_start
      AND start_txn_time < v_month_end;
      
    CREATE TEMPORARY TABLE monthly_sales_2 AS
    SELECT *
    FROM monthly_sales;

    CREATE TEMPORARY TABLE monthly_sales_3 AS
    SELECT *
    FROM monthly_sales;

    -- Q1: What are the top 3 products by total revenue

    SELECT
        s.prod_id,
        pd.product_name,
        SUM(s.qty * s.price) AS total_revenue_before_discount
    FROM monthly_sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        s.prod_id,
        pd.product_name
    ORDER BY total_revenue_before_discount DESC
    LIMIT 3;

    -- Q2: What is the total quantity, revenue and discount


    SELECT
        pd.segment_name,
        SUM(s.qty) AS total_quantity,
        SUM(s.qty * s.price) AS total_revenue_before_discount,
        SUM(s.qty * s.price * s.discount / 100) AS total_discount
    FROM monthly_sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name;

    -- Q3: What is the top selling product for each segment?

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
        FROM monthly_sales AS s
        INNER JOIN product_details AS pd
            ON s.prod_id = pd.product_id
        GROUP BY
            pd.segment_name,
            pd.product_name
    ) AS ranked_products
    WHERE product_rank = 1;


    -- Q4: What is the total quantity, revenue and discount

    SELECT
        pd.category_name,
        SUM(s.qty) AS total_quantity,
        SUM(s.qty * s.price) AS total_revenue_before_discount,
        SUM(s.qty * s.price * s.discount / 100) AS total_discount
    FROM monthly_sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name;

    -- Q5: What is the top selling product for each category?

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
        FROM monthly_sales AS s
        INNER JOIN product_details AS pd
            ON s.prod_id = pd.product_id
        GROUP BY
            pd.category_name,
            pd.product_name
    ) AS ranked_products
    WHERE product_rank = 1;

    -- Q6: What is the percentage split of revenue by product


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
        FROM monthly_sales AS s
        INNER JOIN product_details AS pd
            ON s.prod_id = pd.product_id
        GROUP BY
            pd.segment_name,
            pd.product_name
    ) AS product_revenue_summary;


    -- Q7: What is the percentage split of revenue by segment

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
        FROM monthly_sales AS s
        INNER JOIN product_details AS pd
            ON s.prod_id = pd.product_id
        GROUP BY
            pd.category_name,
            pd.segment_name
    ) AS segment_revenue_summary;

    -- Q8: What is the percentage split of total revenue

    SELECT
        category_name,
        all_revenue,
        category_revenue / all_revenue * 100 AS revenue_percentage
    FROM (
        SELECT
            pd.category_name,
            SUM(s.qty * s.price) AS category_revenue,
            SUM(SUM(s.qty * s.price)) OVER () AS all_revenue
        FROM monthly_sales AS s
        INNER JOIN product_details AS pd
            ON s.prod_id = pd.product_id
        GROUP BY
            pd.category_name
    ) AS category_revenue_summary;

SELECT COUNT(DISTINCT txn_id)
INTO v_total_transactions
FROM monthly_sales;

-- Q9: What is the total transaction "penetration" for each product?

SELECT
    product_transactions.prod_id,
    product_transactions.product_name,
    product_transactions.product_transactions,
    v_total_transactions AS total_transactions,
    product_transactions.product_transactions
        / v_total_transactions * 100 AS penetration
FROM (
    SELECT
        s.prod_id,
        pd.product_name,
        COUNT(DISTINCT s.txn_id) AS product_transactions
    FROM monthly_sales AS s
    INNER JOIN product_details AS pd
        ON s.prod_id = pd.product_id
    GROUP BY
        s.prod_id,
        pd.product_name
) AS product_transactions;

-- Q10: What is the most common combination of any 3

SELECT
    pd1.product_name AS product_1,
    pd2.product_name AS product_2,
    pd3.product_name AS product_3,
    COUNT(*) AS combination_count
FROM monthly_sales AS s1
INNER JOIN monthly_sales_2 AS s2
    ON s1.txn_id = s2.txn_id
    AND s1.prod_id < s2.prod_id
INNER JOIN monthly_sales_3 AS s3
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

END //

DELIMITER ;


CALL monthly_report('2021-01-01');

