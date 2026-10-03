-- 1- What is the unique count and total amount for each transaction type?

SELECT
    txn_type,
    COUNT(*) AS txn_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;


-- 2- What is the average total historical deposit counts and amounts for all customers?

WITH txn_customers AS (
    SELECT
        customer_id,
        COUNT(*) AS deposit_count,
        SUM(txn_amount) AS deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT
    AVG(deposit_count) AS avg_deposit_count,
    AVG(deposit_amount) AS avg_deposit_amount
FROM txn_customers;


-- 3- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH monthly_transactions AS (
    SELECT
        customer_id,
        MONTH(txn_date) AS txn_month,

        SUM(CASE
            WHEN txn_type = 'deposit' THEN 1
            ELSE 0
        END) AS deposit_count,

        SUM(CASE
            WHEN txn_type = 'purchase' THEN 1
            ELSE 0
        END) AS purchase_count,

        SUM(CASE
            WHEN txn_type = 'withdrawal' THEN 1
            ELSE 0
        END) AS withdrawal_count

    FROM customer_transactions
    GROUP BY
        customer_id,
        MONTH(txn_date)
)

SELECT
    txn_month,
    COUNT(*) AS customer_count
FROM monthly_transactions
WHERE deposit_count > 1
  AND (purchase_count = 1 OR withdrawal_count = 1)
GROUP BY txn_month
order by txn_month;


-- 4- What is the closing balance for each customer at the end of the month?

WITH monthly_transactions AS (
    SELECT
        customer_id,
        MONTH(txn_date) AS txn_month,

        SUM(CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE 0
        END) AS deposit_amount,

        SUM(CASE
            WHEN txn_type = 'purchase' THEN txn_amount
            ELSE 0
        END) AS purchase_amount,

        SUM(CASE
            WHEN txn_type = 'withdrawal' THEN txn_amount
            ELSE 0
        END) AS withdrawal_amount

    FROM customer_transactions
    GROUP BY
        customer_id,
        MONTH(txn_date)
),

monthly_changes AS (
    SELECT
        customer_id,
        txn_month,
        deposit_amount - (purchase_amount + withdrawal_amount) AS monthly_change
    FROM monthly_transactions
),

closing_balance AS (
    SELECT
        customer_id,
        txn_month,
        SUM(monthly_change) OVER (
            PARTITION BY customer_id
            ORDER BY txn_month
        ) AS closing_balance
    FROM monthly_changes
)

SELECT *
FROM closing_balance
ORDER BY customer_id, txn_month;



-- 5- What is the percentage of customers who increase their closing balance by more than 5%?

WITH monthly_transactions AS (
    SELECT
        customer_id,
        MONTH(txn_date) AS txn_month,

        SUM(CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE 0
        END) AS deposit_amount,

        SUM(CASE
            WHEN txn_type = 'purchase' THEN txn_amount
            ELSE 0
        END) AS purchase_amount,

        SUM(CASE
            WHEN txn_type = 'withdrawal' THEN txn_amount
            ELSE 0
        END) AS withdrawal_amount

    FROM customer_transactions
    GROUP BY
        customer_id,
        MONTH(txn_date)
),

monthly_changes AS (
    SELECT
        customer_id,
        txn_month,
        deposit_amount - (purchase_amount + withdrawal_amount) AS monthly_change
    FROM monthly_transactions
),

closing_balance AS (
    SELECT
        customer_id,
        txn_month,
        SUM(monthly_change) OVER (
            PARTITION BY customer_id
            ORDER BY txn_month
        ) AS closing_balance
    FROM monthly_changes
),

balance_with_previous AS (
    SELECT
        customer_id,
        txn_month,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id
            ORDER BY txn_month
        ) AS previous_closing_balance
    FROM closing_balance
),

balance_percentage AS (
    SELECT
        customer_id,
        txn_month,
        closing_balance,
        previous_closing_balance,
        (closing_balance - previous_closing_balance)
        / previous_closing_balance AS percentage_change
    FROM balance_with_previous
)

SELECT
    COUNT(DISTINCT customer_id) * 100.0
    / (
        SELECT COUNT(DISTINCT customer_id)
        FROM customer_transactions
    ) AS percentage_customers
FROM balance_percentage
WHERE percentage_change > 0.05;