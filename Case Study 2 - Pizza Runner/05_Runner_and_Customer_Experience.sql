use pizza_runner;

-- 1. How many runners signed up for each 1 week period?
-- Week 1 starts on 2021-01-01, with each following week covering a 7-day period.
-- DATEDIFF calculates the number of days since 2021-01-01,
-- and FLOOR groups registration dates into weekly periods.

SELECT
    FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) + 1 AS week_number,
    COUNT(*) AS runner_count
FROM runners
GROUP BY week_number
ORDER BY week_number;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?
-- TIMESTAMPDIFF calculates the time between the order and pickup in minutes.
-- The results are grouped by runner to calculate the average pickup time for each runner.

SELECT
    ro.runner_id,
    AVG(TIMESTAMPDIFF(MINUTE, cr.order_date, ro.pickup_time)) AS avg_pickup_time_minutes
FROM customer_orders AS cr
INNER JOIN runner_orders AS ro
    ON cr.order_id = ro.order_id
GROUP BY ro.runner_id
ORDER BY ro.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- First, calculate the number of pizzas and preparation time for each order.
-- Then, calculate the average preparation time for each number of pizzas.
-- The results show that preparation time increases as the number of pizzas increases.

WITH pizza_prep AS (
    SELECT
        cr.order_id,
        COUNT(*) AS pizza_count,
        TIMESTAMPDIFF(
            MINUTE,
            MIN(cr.order_date),
            MIN(ro.pickup_time)
        ) AS preparation_time_minutes
    FROM customer_orders AS cr
    INNER JOIN runner_orders AS ro
        ON cr.order_id = ro.order_id
    GROUP BY cr.order_id
)
SELECT
    pizza_count,
    AVG(preparation_time_minutes) AS avg_preparation_time_minutes
FROM pizza_prep
GROUP BY pizza_count
ORDER BY pizza_count;


-- 4. What was the average distance travelled for each customer?
-- Join customer_orders with runner_orders using order_id,
-- then calculate the average delivery distance for each customer.

SELECT
    cr.customer_id,
    AVG(ro.distance) AS avg_distance
FROM customer_orders AS cr
INNER JOIN runner_orders AS ro
    ON cr.order_id = ro.order_id
GROUP BY cr.customer_id
ORDER BY cr.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
-- Calculate the difference between the longest and shortest delivery durations.

SELECT
    MAX(duration) - MIN(duration) AS delivery_time_difference
FROM runner_orders;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- First, calculate the speed for each delivery using distance divided by duration.
-- Then, calculate the average delivery speed for each runner.

WITH delivery_speeds AS (
    SELECT
        runner_id,
        distance / duration AS speed
    FROM runner_orders
)
SELECT
    runner_id,
    AVG(speed) AS avg_speed
FROM delivery_speeds
GROUP BY runner_id
ORDER BY runner_id;


-- Insight:
-- Runner 2 had the highest average speed (1.05), followed by Runner 1 (0.76)
-- and Runner 3 (0.67). Delivery speeds varied across orders,
-- indicating that speed was not consistent between deliveries.


-- 7. What percentage of successful deliveries occurred for each runner?
-- First, count the successful deliveries for each runner.
-- Then, calculate the total number of successful deliveries.
-- Finally, calculate each runner's share of all successful deliveries.

WITH successful_deliveries AS (
    SELECT
        runner_id,
        COUNT(*) AS successful_deliveries
    FROM runner_orders
    WHERE cancellation IS NULL
    GROUP BY runner_id
),
total_successful AS (
    SELECT
        COUNT(*) AS total_deliveries
    FROM runner_orders
    WHERE cancellation IS NULL
)
SELECT
    sd.runner_id,
    sd.successful_deliveries,
    sd.successful_deliveries / ts.total_deliveries * 100
        AS percentage_of_successful_deliveries
FROM successful_deliveries AS sd
CROSS JOIN total_successful AS ts
ORDER BY sd.runner_id;