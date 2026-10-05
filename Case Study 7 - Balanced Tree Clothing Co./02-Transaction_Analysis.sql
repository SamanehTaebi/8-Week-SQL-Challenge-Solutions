-- 1: How many unique transactions were there?

SELECT COUNT(DISTINCT txn_id) AS total_unique_transactions
FROM sales;


-- 2: What is the average unique products purchased in each transaction?


SELECT AVG(unique_products_per_transaction) AS avg_unique_products_per_transaction
FROM (
    SELECT 
        txn_id,
        COUNT(DISTINCT prod_id) AS unique_products_per_transaction
    FROM sales
    GROUP BY txn_id
) AS transaction_summary;


-- 3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?


WITH transaction_revenue AS (
    SELECT
        txn_id,
        SUM(qty * price) AS revenue
    FROM sales
    GROUP BY txn_id
),

ranked_revenue AS (
    SELECT
        revenue,
        ROW_NUMBER() OVER (ORDER BY revenue) AS row_num,
        COUNT(*) OVER () AS total_transactions
    FROM transaction_revenue
),

percentile_positions AS (
    SELECT DISTINCT
        (total_transactions - 1) * 0.25 + 1 AS p25,
        (total_transactions - 1) * 0.50 + 1 AS p50,
        (total_transactions - 1) * 0.75 + 1 AS p75
    FROM ranked_revenue
),

percentile_values AS (
    SELECT
        p.p25,
        p.p50,
        p.p75,

        MAX(CASE
            WHEN r.row_num = FLOOR(p.p25)
            THEN r.revenue
        END) AS p25_lower,

        MAX(CASE
            WHEN r.row_num = CEIL(p.p25)
            THEN r.revenue
        END) AS p25_upper,

        MAX(CASE
            WHEN r.row_num = FLOOR(p.p50)
            THEN r.revenue
        END) AS p50_lower,

        MAX(CASE
            WHEN r.row_num = CEIL(p.p50)
            THEN r.revenue
        END) AS p50_upper,

        MAX(CASE
            WHEN r.row_num = FLOOR(p.p75)
            THEN r.revenue
        END) AS p75_lower,

        MAX(CASE
            WHEN r.row_num = CEIL(p.p75)
            THEN r.revenue
        END) AS p75_upper

    FROM percentile_positions AS p
    CROSS JOIN ranked_revenue AS r
    GROUP BY
        p.p25,
        p.p50,
        p.p75
)

SELECT
    p25_lower + (p25 - FLOOR(p25)) * (p25_upper - p25_lower) AS percentile_25,
    p50_lower + (p50 - FLOOR(p50)) * (p50_upper - p50_lower) AS percentile_50,
    p75_lower + (p75 - FLOOR(p75)) * (p75_upper - p75_lower) AS percentile_75
FROM percentile_values;



-- 4: What is the average discount value per transaction?


SELECT
    AVG(total_discount) AS avg_discount_per_transaction
FROM (
    SELECT
        txn_id,
        SUM(qty * price * discount / 100) AS total_discount
    FROM sales
    GROUP BY txn_id
) AS transaction_discounts;



-- 5: What is the percentage split of all transactions for members vs non-members?


SELECT
    COUNT(DISTINCT CASE WHEN member = 't' THEN txn_id END)
        / COUNT(DISTINCT txn_id) * 100 AS member_percentage,

    COUNT(DISTINCT CASE WHEN member = 'f' THEN txn_id END)
        / COUNT(DISTINCT txn_id) * 100 AS non_member_percentage

FROM sales;


-- 6: What is the average revenue for member transactions and non-member transactions?


WITH transaction_revenue AS (
    SELECT
        txn_id,
        member,
        SUM(qty * price) AS revenue
    FROM sales
    GROUP BY txn_id, member
)

SELECT
    AVG(CASE WHEN member = 't' THEN revenue END) AS avg_member_revenue,
    AVG(CASE WHEN member = 'f' THEN revenue END) AS avg_non_member_revenue
FROM transaction_revenue;