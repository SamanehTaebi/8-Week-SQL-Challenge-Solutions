-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment
-- where different groups of customers would be allocated data using 3 different options:
--
-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
--
-- For this multi-part challenge question, generate the following data elements:
-- - running customer balance column that includes the impact each transaction
-- - customer balance at the end of each month
-- - minimum, average and maximum values of the running balance for each customer
--
-- Using all of the data available - how much data would have been required for each option on a monthly basis?


WITH running_balance AS (
    -- Calculate the running balance for each customer
    SELECT
        customer_id,
        txn_date,
        SUM(
            CASE
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                WHEN txn_type = 'purchase' THEN -txn_amount
            END
        ) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM customer_transactions
),

last_txn AS (
    -- Find the last transaction for each customer in each month
    SELECT
        customer_id,
        txn_date,
        running_balance,
        ROW_NUMBER() OVER (
            PARTITION BY
                customer_id,
                YEAR(txn_date),
                MONTH(txn_date)
            ORDER BY txn_date DESC
        ) AS rn
    FROM running_balance
),

month_end AS (
    -- Get the customer's balance at the end of each month
    SELECT
        customer_id,
        txn_date,
        running_balance
    FROM last_txn
    WHERE rn = 1
),

-- Option 1: data is allocated based on the balance at the end of the previous month

option_a AS (
    -- Get the previous month's closing balance for each customer
    SELECT
        customer_id,
        txn_date,
        running_balance,
        COALESCE(
            LAG(running_balance) OVER (
                PARTITION BY customer_id
                ORDER BY txn_date
            ),
            0
        ) AS previous_month_balance
    FROM month_end
),

option_a_monthly AS (
    -- Keep the results at customer-month level before the final aggregation
    SELECT
        customer_id,
        YEAR(txn_date) AS year,
        MONTH(txn_date) AS month,
        previous_month_balance AS option_1
    FROM option_a
),

-- Option 2: data is allocated based on the average balance over the previous 30 days

periods AS (
    -- Define the 30-day period for each month
    SELECT DISTINCT
        YEAR(txn_date) AS year,
        MONTH(txn_date) AS month,
        LAST_DAY(txn_date) AS period_end,
        DATE_SUB(
            LAST_DAY(txn_date),
            INTERVAL 29 DAY
        ) AS period_start
    FROM month_end
),

balance_before_period AS (
    -- Find the most recent balance before the 30-day period started
    SELECT
        p.year,
        p.month,
        p.period_start,
        p.period_end,
        b.customer_id,
        b.txn_date,
        b.running_balance,
        ROW_NUMBER() OVER (
            PARTITION BY
                b.customer_id,
                p.year,
                p.month
            ORDER BY b.txn_date DESC
        ) AS rn
    FROM periods p
    JOIN running_balance b
        ON b.txn_date < p.period_start
),

balance_points AS (
    -- Add the balance at the beginning of the 30-day period
    SELECT
        b.customer_id,
        p.year,
        p.month,
        p.period_start,
        p.period_end,
        p.period_start AS txn_date,
        b.running_balance
    FROM periods p
    JOIN balance_before_period b
        ON b.year = p.year
        AND b.month = p.month
        AND b.rn = 1

    UNION ALL

    -- Add all transactions that occurred during the 30-day period
    SELECT
        b.customer_id,
        p.year,
        p.month,
        p.period_start,
        p.period_end,
        b.txn_date,
        b.running_balance
    FROM periods p
    JOIN running_balance b
        ON b.txn_date >= p.period_start
        AND b.txn_date <= p.period_end
),

balance_dates AS (
    -- Find the next transaction date to calculate how long each balance lasted
    SELECT
        customer_id,
        year,
        month,
        period_start,
        period_end,
        txn_date,
        running_balance,
        LEAD(txn_date) OVER (
            PARTITION BY
                customer_id,
                year,
                month
            ORDER BY txn_date
        ) AS next_date
    FROM balance_points
),

balance_periods AS (
    -- Define the end date for each balance period
    SELECT
        customer_id,
        year,
        month,
        period_start,
        period_end,
        txn_date,
        running_balance,
        COALESCE(next_date, period_end) AS end_date
    FROM balance_dates
),

balance_days AS (
    -- Calculate how many days each balance was maintained
    SELECT
        customer_id,
        year,
        month,
        running_balance,
        CASE
            WHEN end_date = period_end
                THEN DATEDIFF(end_date, txn_date) + 1
            ELSE DATEDIFF(end_date, txn_date)
        END AS days_at_balance
    FROM balance_periods
),

option_b_monthly AS (
    -- Calculate the time-weighted average balance over the previous 30 days
    SELECT
        customer_id,
        year,
        month,
        SUM(
            running_balance * days_at_balance
        ) / 30 AS option_2
    FROM balance_days
    GROUP BY
        customer_id,
        year,
        month
),

-- Option 3: data is updated in real time

option_c_monthly AS (
    -- Calculate the minimum, average and maximum running balance for each customer in each month
    SELECT
        customer_id,
        YEAR(txn_date) AS year,
        MONTH(txn_date) AS month,
        MIN(running_balance) AS min_balance,
        AVG(running_balance) AS avg_balance,
        MAX(running_balance) AS max_balance
    FROM running_balance
    GROUP BY
        customer_id,
        YEAR(txn_date),
        MONTH(txn_date)
),

-- Join the results of all three options at customer-month level

all_options AS (
    SELECT
        a.customer_id,
        a.year,
        a.month,
        a.option_1,
        b.option_2,
        c.min_balance,
        c.avg_balance,
        c.max_balance
    FROM option_a_monthly a
    JOIN option_b_monthly b
        ON a.customer_id = b.customer_id
        AND a.year = b.year
        AND a.month = b.month
    JOIN option_c_monthly c
        ON a.customer_id = c.customer_id
        AND a.year = c.year
        AND a.month = c.month
)

-- Calculate the monthly totals for each option

SELECT
    year,
    month,
    SUM(option_1) AS option_1,
    SUM(option_2) AS option_2,
    SUM(min_balance) AS option_3_min,
    SUM(avg_balance) AS option_3_avg,
    SUM(max_balance) AS option_3_max
FROM all_options
GROUP BY
    year,
    month
ORDER BY
    year,
    month;