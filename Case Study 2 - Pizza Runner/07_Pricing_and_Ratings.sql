use pizza_runner;

-- 1: Calculate the total income earned by each runner
-- from successfully delivered pizzas, with no delivery fees.

WITH delivered_orders AS (
    -- Keep only successfully delivered orders
    SELECT 
        runner_id,
        order_id
    FROM runner_orders
    WHERE cancellation IS NULL
),

pizza_counts AS (
    -- Count the number of each pizza type delivered by each runner
    -- and assign the price based on the pizza name
    SELECT
        do.runner_id,
        COUNT(*) AS pizza_count,
        CASE
            WHEN pn.pizza_name = 'Meat Lovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
        END AS price
    FROM customer_orders AS cr
    INNER JOIN delivered_orders AS do
        ON cr.order_id = do.order_id
    INNER JOIN pizza_names AS pn
        ON cr.pizza_id = pn.pizza_id
    GROUP BY 
        do.runner_id,
        cr.pizza_id
)

-- Calculate total income for each runner
SELECT
    pc.runner_id,
    SUM(pc.price * pc.pizza_count) AS income
FROM pizza_counts AS pc
GROUP BY pc.runner_id;



-- 2: Calculate the total income for each runner,
-- including a $1 charge for each pizza extra.

WITH delivered_orders AS (
    -- Keep only successfully delivered orders
    SELECT 
        runner_id,
        order_id
    FROM runner_orders
    WHERE cancellation IS NULL
),

pizza_details AS (
    -- Get each delivered pizza along with its price
    -- and calculate the number of extras added to it
    SELECT
        do.runner_id,
        cr.order_id,
        cr.pizza_id,
        COALESCE(
            LENGTH(cr.extras) - LENGTH(REPLACE(cr.extras, ',', '')) + 1,
            0
        ) AS extra_count,
        CASE
            WHEN pn.pizza_name = 'Meat Lovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
        END AS price
    FROM customer_orders AS cr
    INNER JOIN delivered_orders AS do
        ON cr.order_id = do.order_id
    INNER JOIN pizza_names AS pn
        ON cr.pizza_id = pn.pizza_id
)

-- Calculate total income for each runner
-- by adding $1 for each extra
SELECT
    pd.runner_id,
    SUM(pd.price + (pd.extra_count * 1)) AS income
FROM pizza_details AS pd
GROUP BY pd.runner_id;


-- 3: The Pizza Runner team now wants to add an additional ratings system
-- that allows customers to rate their runner.
-- Design an additional table for this new dataset,
-- generate a schema for this new table,
-- and insert your own ratings between 1 and 5 for each successful customer order.

-- Create a new table to store customer ratings for runners
CREATE TABLE ratings (
    order_id INT PRIMARY KEY,
    rating INT,
    CHECK (rating BETWEEN 1 AND 5)
);

-- Insert a random rating between 1 and 5 for each successful order
INSERT INTO ratings (order_id, rating)
SELECT 
    order_id,
    FLOOR(RAND() * 5) + 1 AS rating
FROM runner_orders
WHERE cancellation IS NULL;


-- 4: Using your newly generated table, join all of the information together
-- to form a table containing the following information for successful deliveries:
-- customer_id, order_id, runner_id, rating, order_time, pickup_time,
-- time between order and pickup, delivery duration, average speed,
-- and total number of pizzas.

WITH total_pizza AS (
    SELECT 
        order_id,
        COUNT(*) AS total_pizza
    FROM customer_orders
    GROUP BY order_id
)

SELECT 
    co.customer_id,
    ro.order_id,
    ro.runner_id,
    r.rating,
    co.order_date,
    ro.pickup_time,
    TIMEDIFF(ro.pickup_time, co.order_date) AS time_between_order_and_pickup,
    ro.duration AS delivery_duration,
    ro.distance / (ro.duration / 60) AS average_speed,
    tp.total_pizza
FROM runner_orders ro
LEFT JOIN ratings r
    ON ro.order_id = r.order_id
INNER JOIN customer_orders co
    ON ro.order_id = co.order_id
LEFT JOIN total_pizza tp
    ON ro.order_id = tp.order_id
WHERE ro.cancellation IS NULL;


-- 5: If a Meat Lovers pizza was $12 and a Vegetarian pizza was $10
-- with no cost for extras, and each runner is paid $0.30 per kilometre traveled,
-- how much money does Pizza Runner have left over after these deliveries?

-- Calculate the income generated from each successful order
WITH successful_delivery AS (
    SELECT 
        cr.order_id,
        SUM(
            CASE 
                WHEN pn.pizza_name = 'Meat Lovers' THEN 12
                WHEN pn.pizza_name = 'Vegetarian' THEN 10
            END
        ) AS income
    FROM customer_orders cr
    INNER JOIN runner_orders ro
        ON cr.order_id = ro.order_id
    INNER JOIN pizza_names pn
        ON cr.pizza_id = pn.pizza_id
    WHERE ro.cancellation IS NULL
    GROUP BY cr.order_id
)

-- Calculate the total money left after paying the runners
SELECT 
    SUM(sd.income - ro.distance * 0.30) AS remaining_money
FROM runner_orders ro
INNER JOIN successful_delivery sd
    ON ro.order_id = sd.order_id
WHERE ro.cancellation IS NULL;



