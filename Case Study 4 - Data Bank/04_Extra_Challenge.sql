-- Calculate the running account balance for each customer
-- by adding deposits and subtracting withdrawals and purchases.
WITH running_balance AS (
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

-- Use LEAD() to find the next transaction date for each customer.
-- This allows us to determine how many days the current balance
-- remained unchanged.
daily_balance AS (
    SELECT
        customer_id,
        txn_date,
        running_balance,
        LEAD(txn_date) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
        ) AS next_date
    FROM running_balance
),

-- Calculate the number of days each balance was held.
-- The calculation is limited to the current month so that
-- interest can later be aggregated correctly on a monthly basis.
daily_balance_days AS (
    SELECT
        customer_id,
        txn_date,
        running_balance,
        next_date,

        CASE
            -- If there is no next transaction, the balance remains
            -- until the end of the month.
            WHEN next_date IS NULL THEN
                DATEDIFF(
                    LAST_DAY(txn_date),
                    txn_date
                ) + 1

            -- If the next transaction occurs in a later month/year,
            -- only count the remaining days of the current month.
            WHEN YEAR(next_date) > YEAR(txn_date)
              OR MONTH(next_date) > MONTH(txn_date) THEN
                DATEDIFF(
                    LAST_DAY(txn_date),
                    txn_date
                ) + 1

            -- Otherwise, the balance remains unchanged until
            -- the next transaction date.
            ELSE
                DATEDIFF(
                    next_date,
                    txn_date
                )
        END AS days_at_balance
    FROM daily_balance
),

-- Calculate simple daily interest.
-- Annual interest rate = 6%, converted to a daily rate using 365 days.
-- No interest is added back to the balance, so there is no compounding.
interest AS (
    SELECT
        customer_id,
        txn_date,
        running_balance,

        running_balance * (0.06 / 365) * days_at_balance
            AS interest_amount

    FROM daily_balance_days
),

-- Aggregate the calculated interest for each customer by month.
monthly_interest AS (
    SELECT
        customer_id,
        YEAR(txn_date) AS year,
        MONTH(txn_date) AS month,
        SUM(interest_amount) AS total_interest
    FROM interest
    GROUP BY
        customer_id,
        YEAR(txn_date),
        MONTH(txn_date)
),

-- Combine all customers' interest amounts
-- to calculate the total data required by Data Bank each month.
monthly_total AS (
    SELECT
        year,
        month,
        SUM(total_interest) AS total_interest
    FROM monthly_interest
    GROUP BY
        year,
        month
)

-- Return the final monthly interest requirement
-- in chronological order.
SELECT
    year,
    month,
    total_interest
FROM monthly_total
ORDER BY
    year,
    month;
    
    
    
-- Extra Challenge: Calculate daily compounded interest
WITH RECURSIVE

-- Find the first transaction date for each customer
-- and the last transaction date in the dataset
min_max AS (
    SELECT
        customer_id,
        MIN(txn_date) AS start_date,
        (
            SELECT MAX(txn_date)
            FROM customer_transactions
        ) AS end_date
    FROM customer_transactions
    GROUP BY customer_id
),

-- Generate every calendar day for each customer
-- from their first transaction date to the end of the dataset
dates AS (
    SELECT
        customer_id,
        start_date AS date,
        end_date
    FROM min_max

    UNION ALL

    SELECT
        customer_id,
        DATE_ADD(date, INTERVAL 1 DAY),
        end_date
    FROM dates
    WHERE date < end_date
),

-- Calculate the net transaction amount for each customer on each day
daily_transactions AS (
    SELECT
        customer_id,
        txn_date,
        SUM(
            CASE
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                WHEN txn_type = 'purchase' THEN -txn_amount
                ELSE 0
            END
        ) AS daily_change
    FROM customer_transactions
    GROUP BY
        customer_id,
        txn_date
),

-- Combine all dates with daily transaction changes
-- Days without transactions are assigned a daily change of 0
daily_changes AS (
    SELECT
        d.customer_id,
        d.date,
        COALESCE(dt.daily_change, 0) AS daily_change,
        d.end_date
    FROM dates d
    LEFT JOIN daily_transactions dt
        ON d.customer_id = dt.customer_id
        AND d.date = dt.txn_date
),

-- Calculate daily compounded interest using a recursive CTE
recursive_balance AS (

    -- Anchor: start the calculation from each customer's first day
    SELECT
        dc.customer_id,
        dc.date,
        dc.daily_change,

        -- On the first day, the balance equals the day's net transaction
        dc.daily_change AS balance_before_interest,

        -- Calculate interest for the first day
        dc.daily_change * (0.06 / 365) AS interest,

        dc.end_date

    FROM daily_changes dc
    JOIN min_max mm
        ON dc.customer_id = mm.customer_id
        AND dc.date = mm.start_date

    UNION ALL

    -- Recursive part: calculate the balance and interest for the next day
    SELECT
        dc.customer_id,
        dc.date,
        dc.daily_change,

        -- Previous day's balance
        -- + previous day's interest
        -- + today's transaction change
        r.balance_before_interest
            + r.interest
            + dc.daily_change AS balance_before_interest,

        -- Calculate today's interest based on the updated balance
        (
            r.balance_before_interest
            + r.interest
            + dc.daily_change
        ) * (0.06 / 365) AS interest,

        r.end_date

    FROM recursive_balance r
    JOIN daily_changes dc
        ON r.customer_id = dc.customer_id
        AND dc.date = DATE_ADD(r.date, INTERVAL 1 DAY)

    -- Stop recursion after reaching the final date
    WHERE r.date < r.end_date
),

-- Sum daily compounded interest for each month
monthly_interest AS (
    SELECT
        YEAR(date) AS year,
        MONTH(date) AS month,
        SUM(interest) AS total_interest
    FROM recursive_balance
    GROUP BY
        YEAR(date),
        MONTH(date)
)

SELECT
    year,
    month,
    total_interest
FROM monthly_interest
ORDER BY
    year,
    month;