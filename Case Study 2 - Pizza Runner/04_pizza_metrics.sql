USE pizza_runner;

-- 1. How many pizzas were ordered?
-- Each row in customer_orders represents one pizza ordered.

SELECT COUNT(*) AS total_pizzas
FROM customer_orders;

-- 2. How many unique customer orders were made?
-- Count distinct order_id values because each order can contain multiple pizzas.

SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
-- Count orders with no cancellation, grouped by runner.

SELECT runner_id, COUNT(*) AS runner_deliver
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
-- Join runner_orders with customer_orders to identify delivered pizzas,
-- then join pizza_names to display the pizza name and count each type.

SELECT
    cr.pizza_id,
    pn.pizza_name,
    COUNT(*) AS total_order
FROM runner_orders AS rr
INNER JOIN customer_orders AS cr
    ON rr.order_id = cr.order_id
INNER JOIN pizza_names AS pn
    ON cr.pizza_id = pn.pizza_id
WHERE rr.cancellation IS NULL
GROUP BY cr.pizza_id, pn.pizza_name;


-- 5. How many Vegetarian and Meat Lovers were ordered by each customer?
-- Count each pizza type separately for every customer.

SELECT
    cr.customer_id,
    COUNT(
        CASE
            WHEN pn.pizza_name = 'Meat Lovers' THEN 1
            ELSE NULL
        END
    ) AS Meat_Lovers,
    COUNT(
        CASE
            WHEN pn.pizza_name = 'Vegetarian' THEN 1
            ELSE NULL
        END
    ) AS Vegetarian
FROM customer_orders AS cr
INNER JOIN pizza_names AS pn
    ON cr.pizza_id = pn.pizza_id
GROUP BY cr.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
-- First count the pizzas in each successfully delivered order,
-- then find the maximum number of pizzas in a single order.

SELECT MAX(pizza_count) AS max_pizzas_in_single_order
FROM (
    SELECT
        cr.order_id,
        COUNT(cr.pizza_id) AS pizza_count
    FROM customer_orders AS cr
    INNER JOIN runner_orders AS ro
        ON cr.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
    GROUP BY cr.order_id
) AS order_counts;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- Join customer_orders with runner_orders to keep only delivered pizzas.
-- A pizza has at least one change if extras or exclusions is not NULL.
-- A pizza has no changes if both extras and exclusions are NULL.

SELECT
    cr.customer_id,
    COUNT(
        CASE
            WHEN extras IS NOT NULL
              OR exclusions IS NOT NULL
            THEN 1
            ELSE NULL
        END
    ) AS pizzas_with_changes,
    COUNT(
        CASE
            WHEN extras IS NULL
             AND exclusions IS NULL
            THEN 1
            ELSE NULL
        END
    ) AS pizzas_without_changes
FROM customer_orders AS cr
INNER JOIN runner_orders AS ro
    ON cr.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY cr.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
-- Join customer_orders with runner_orders to keep only delivered pizzas.
-- Filter for pizzas that have both exclusions and extras, then count them.

SELECT COUNT(*) AS pizzas_with_exclusions_and_extras
FROM customer_orders AS cr
INNER JOIN runner_orders AS ro
    ON cr.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  AND cr.extras IS NOT NULL
  AND cr.exclusions IS NOT NULL;
  
  -- 9. What was the total volume of pizzas ordered for each hour of the day?
-- Extract the hour from order_date and count the number of pizzas ordered in each hour.

SELECT
    HOUR(order_date) AS order_hour,
    COUNT(pizza_id) AS total_pizzas
FROM customer_orders
GROUP BY order_hour;

-- 10. What was the volume of orders for each day of the week?
-- Extract the day name from order_date and count the number of unique orders for each day.

SELECT
    DAYNAME(order_date) AS order_day,
    COUNT(DISTINCT order_id) AS total_orders
FROM customer_orders
GROUP BY DAYNAME(order_date);
