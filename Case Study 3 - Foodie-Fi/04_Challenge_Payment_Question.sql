use foodie_fi;

WITH RECURSIVE

-- Get previous and next subscription for each customer
subscription_lag AS (
    SELECT
        s.customer_id,
        s.plan_id,
        s.start_date,

        LAG(s.plan_id) OVER (
            PARTITION BY s.customer_id
            ORDER BY s.start_date
        ) AS previous_plan_id,

        LAG(s.start_date) OVER (
            PARTITION BY s.customer_id
            ORDER BY s.start_date
        ) AS previous_start_date,

        LEAD(s.plan_id) OVER (
            PARTITION BY s.customer_id
            ORDER BY s.start_date
        ) AS next_plan_id,

        LEAD(s.start_date) OVER (
            PARTITION BY s.customer_id
            ORDER BY s.start_date
        ) AS next_start_date

    FROM subscriptions s
),

-- Add plan details for current and previous subscriptions
subscription_data AS (
    SELECT
        sl.customer_id,
        sl.plan_id,
        p.plan_name,
        p.price,
        sl.start_date AS current_start_date,

        sl.previous_plan_id,
        sl.previous_start_date,
        pp.plan_name AS previous_plan_name,
        pp.price AS previous_price,

        sl.next_plan_id,
        sl.next_start_date

    FROM subscription_lag sl

    INNER JOIN plans p
        ON sl.plan_id = p.plan_id

    LEFT JOIN plans pp
        ON sl.previous_plan_id = pp.plan_id
),

-- Generate monthly payments using recursive CTE
monthly_payments AS (

    -- First payment
    SELECT
        customer_id,
        plan_id,
        plan_name,
        price,
        previous_plan_name,
        previous_price,
        current_start_date,
        current_start_date AS current_payment_date,
        next_start_date

    FROM subscription_data

    WHERE plan_name LIKE '%monthly%'

    UNION ALL

    -- Generate the next monthly payment
    SELECT
        mp.customer_id,
        mp.plan_id,
        mp.plan_name,
        mp.price,
        mp.previous_plan_name,
        mp.previous_price,
        mp.current_start_date,

        DATE_ADD(
            mp.current_payment_date,
            INTERVAL 1 MONTH
        ) AS current_payment_date,

        mp.next_start_date

    FROM monthly_payments mp

    WHERE
        (
            mp.next_start_date IS NOT NULL
            AND DATE_ADD(
                mp.current_payment_date,
                INTERVAL 1 MONTH
            ) < mp.next_start_date
        )
        OR
        (
            mp.next_start_date IS NULL
            AND DATE_ADD(
                mp.current_payment_date,
                INTERVAL 1 MONTH
            ) < '2021-01-01'
        )
),

-- Calculate payment date for annual plans
annual_payments AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        price,
        previous_plan_name,
        previous_price,
        current_start_date,

        DATE_ADD(
            previous_start_date,
            INTERVAL GREATEST(
                TIMESTAMPDIFF(
                    MONTH,
                    previous_start_date,
                    current_start_date
                ),
                1
            ) MONTH
        ) AS current_payment_date

    FROM subscription_data

    WHERE plan_name LIKE '%annual%'
),

-- Combine monthly and annual payments
all_payments AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        price,
        previous_plan_name,
        previous_price,
        current_start_date,
        current_payment_date

    FROM monthly_payments

    UNION ALL

    SELECT
        customer_id,
        plan_id,
        plan_name,
        price,
        previous_plan_name,
        previous_price,
        current_start_date,
        current_payment_date

    FROM annual_payments
),

-- Keep only payments made during 2020
payment_2020 AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        price,
        previous_plan_name,
        previous_price,
        current_start_date,
        current_payment_date AS payment_date

    FROM all_payments

    WHERE current_payment_date >= '2020-01-01'
      AND current_payment_date < '2021-01-01'
),

-- Calculate payment amount and payment order
final_payments AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        payment_date,

        CASE
            WHEN previous_plan_name = 'basic monthly'
             AND plan_name = 'pro monthly'
             AND payment_date = current_start_date
            THEN price - previous_price

            WHEN previous_plan_name = 'basic monthly'
             AND plan_name = 'pro annual'
            THEN price - previous_price

            ELSE price
        END AS amount,

        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY payment_date
        ) AS payment_order

    FROM payment_2020
)

-- Return the final payment history
SELECT
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    payment_order
FROM final_payments
ORDER BY customer_id, payment_order;