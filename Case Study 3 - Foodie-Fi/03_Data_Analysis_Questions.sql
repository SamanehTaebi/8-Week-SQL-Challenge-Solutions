USE foodie_fi;

-- 1. How many customers has Foodie-Fi ever had?

SELECT 
    COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset?
-- Use the start of the month as the group by value.

SELECT
    DATE_FORMAT(start_date, '%Y-%m-01') AS month,
    COUNT(*) AS total
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATE_FORMAT(start_date, '%Y-%m-01')
ORDER BY month;


-- 3. What plan start_date values occur after the year 2020 for our dataset?
-- Show the breakdown by count of events for each plan_name.

SELECT
    p.plan_name,
    COUNT(*) AS total
FROM plans AS p
INNER JOIN subscriptions AS s
    ON p.plan_id = s.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_name;

-- 4. What is the customer count and percentage of customers who have churned
-- rounded to 1 decimal place?

SELECT
    COUNT(*) AS churned_customers,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id)
         FROM subscriptions),
        1
    ) AS churn_percentage
FROM subscriptions
WHERE plan_id = 4;



-- 5. How many customers have churned straight after their initial free trial?
-- What percentage is this rounded to the nearest whole number?

WITH previous_plans AS (
    SELECT 
        customer_id,
        plan_id,
        LAG(plan_id) OVER (
            PARTITION BY customer_id
            ORDER BY start_date
        ) AS previous_plan
    FROM subscriptions
)
SELECT
    COUNT(DISTINCT customer_id) AS churned_after_trial,
    ROUND(
        COUNT(DISTINCT customer_id) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id)
         FROM subscriptions),
        0
    ) AS churn_percentage
FROM previous_plans
WHERE plan_id = 4
AND previous_plan = 0;


-- 6. What is the number and percentage of customer plans after their initial free trial?

WITH next_plans AS (
    SELECT 
        customer_id,
        plan_id,
        LEAD(plan_id) OVER (
            PARTITION BY customer_id
            ORDER BY start_date
        ) AS next_plan
    FROM subscriptions
)
SELECT
    p.plan_name,
    COUNT(DISTINCT n.customer_id) AS total_customers,
    ROUND(
        COUNT(DISTINCT n.customer_id) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id)
         FROM subscriptions),
        1
    ) AS percentage
FROM next_plans AS n
JOIN plans AS p
    ON n.next_plan = p.plan_id
WHERE n.plan_id = 0
GROUP BY p.plan_name;



-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH plans_before_date AS (
    SELECT *
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
),
latest_date AS (
    SELECT
        customer_id,
        MAX(start_date) AS latest_date
    FROM plans_before_date
    GROUP BY customer_id
),
customer_status AS (
    SELECT
        ld.customer_id,
        s.plan_id
    FROM latest_date ld
    INNER JOIN subscriptions s
        ON ld.customer_id = s.customer_id
        AND s.start_date = ld.latest_date
)

SELECT
    p.plan_name,
    COUNT(DISTINCT cs.customer_id) AS total_customers,
    ROUND(
        COUNT(DISTINCT cs.customer_id) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id)
         FROM subscriptions),
        1
    ) AS percentage
FROM plans p
LEFT JOIN customer_status cs
    ON p.plan_id = cs.plan_id
GROUP BY p.plan_name;


-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT
    COUNT(DISTINCT s.customer_id) AS customer_count
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual'
  AND s.start_date >= '2020-01-01'
  AND s.start_date < '2021-01-01';
  
  
  -- 9. How many days on average does it take for a customer to an annual plan
-- from the day they join Foodie-Fi?

WITH trial_dates AS (
    -- Get the date each customer joined Foodie-Fi
    -- by identifying their initial free trial
    SELECT
        customer_id,
        start_date AS join_date
    FROM subscriptions
    WHERE plan_id = 0
),

annual_dates AS (
    -- Get the date each customer started the annual plan
    SELECT
        s.customer_id,
        s.start_date AS annual_date
    FROM subscriptions AS s
    INNER JOIN plans AS p
        ON s.plan_id = p.plan_id
    WHERE p.plan_name = 'pro annual'
)


SELECT
    ROUND(AVG(DATEDIFF(ad.annual_date, td.join_date)), 1) AS avg_days
FROM trial_dates AS td
INNER JOIN annual_dates AS ad
    ON td.customer_id = ad.customer_id;
    
    
    
-- 10. Can you further breakdown this average value into 30 day periods
-- (i.e. 0-30 days, 31-60 days etc)

WITH trial_dates AS (
    -- Get the date each customer joined Foodie-Fi
    SELECT
        customer_id,
        start_date AS join_date
    FROM subscriptions
    WHERE plan_id = 0
),

annual_dates AS (
    -- Get the date each customer started the annual plan
    SELECT
        s.customer_id,
        s.start_date AS annual_date
    FROM subscriptions AS s
    INNER JOIN plans AS p
        ON s.plan_id = p.plan_id
    WHERE p.plan_name = 'pro annual'
),

days_to_annual AS (
    -- Calculate the number of days from joining to the annual plan
    SELECT
        td.customer_id,
        DATEDIFF(ad.annual_date, td.join_date) AS days_to_annual
    FROM trial_dates AS td
    INNER JOIN annual_dates AS ad
        ON td.customer_id = ad.customer_id
),

periods AS (
    -- Assign each customer to a 30-day period
    SELECT
        customer_id,
        FLOOR((days_to_annual - 1) / 30) AS period
    FROM days_to_annual
)

SELECT
    CONCAT(
        period * 30 + 1,
        '-',
        period * 30 + 30,
        ' days'
    ) AS days_period,
    COUNT(DISTINCT customer_id) AS customer_count
FROM periods
GROUP BY period
ORDER BY period;



-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH pro_monthly_customers AS (
    -- Get customers who started a pro monthly plan in 2020
    SELECT
        s.customer_id,
        s.start_date AS pro_monthly_date
    FROM subscriptions AS s
    INNER JOIN plans AS p
        ON s.plan_id = p.plan_id
    WHERE p.plan_name = 'pro monthly'
      AND s.start_date >= '2020-01-01'
      AND s.start_date < '2021-01-01'
),

basic_monthly_customers AS (
    -- Get customers who started a basic monthly plan in 2020
    SELECT
        s.customer_id,
        s.start_date AS basic_monthly_date
    FROM subscriptions AS s
    INNER JOIN plans AS p
        ON s.plan_id = p.plan_id
    WHERE p.plan_name = 'basic monthly'
      AND s.start_date >= '2020-01-01'
      AND s.start_date < '2021-01-01'
)

SELECT
    COUNT(DISTINCT pm.customer_id) AS customer_count
FROM pro_monthly_customers AS pm
INNER JOIN basic_monthly_customers AS bm
    ON pm.customer_id = bm.customer_id
    AND bm.basic_monthly_date > pm.pro_monthly_date;
    