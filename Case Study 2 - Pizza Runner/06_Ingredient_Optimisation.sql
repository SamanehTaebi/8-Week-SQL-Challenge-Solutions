use pizza_runner;


-- 1. What are the standard ingredients for each pizza?
-- The toppings column contains comma-separated topping IDs.
-- JSON_TABLE converts these IDs into separate rows.
-- The topping IDs are then matched with pizza_toppings to get the ingredient names.
-- pizza_names is joined to get the name of each pizza.
-- GROUP_CONCAT combines all ingredients belonging to each pizza into one row.

SELECT
    pn.pizza_name,
    GROUP_CONCAT(pt.topping_name) AS standard_ingredients
FROM pizza_recipes pr
CROSS JOIN JSON_TABLE(
    CONCAT('[', pr.toppings, ']'),
    '$[*]' COLUMNS (
        topping_id INT PATH '$'
    )
) AS jt
JOIN pizza_toppings pt
    ON jt.topping_id = pt.topping_id
JOIN pizza_names pn
    ON pr.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name;

-- 2. What was the most commonly added extra?
-- The extras column contains comma-separated topping IDs.
-- CONCAT converts the extras string into a JSON array format.
-- JSON_TABLE separates multiple topping IDs into individual rows.
-- The topping IDs are matched with pizza_toppings to get the topping names.
-- GROUP BY groups the same extras together.
-- COUNT counts how many times each extra was added.
-- ORDER BY sorts the extras from most to least common.
-- LIMIT 1 returns the most commonly added extra.

SELECT
    pt.topping_name,
    COUNT(*) AS extra_count
FROM customer_orders co

CROSS JOIN JSON_TABLE(
    CONCAT('[', co.extras, ']'),
    '$[*]' COLUMNS (
        topping_id INT PATH '$'
    )
) AS jt

JOIN pizza_toppings pt
    ON jt.topping_id = pt.topping_id

GROUP BY pt.topping_name
ORDER BY extra_count DESC
LIMIT 1;

-- 3. What was the most common exclusion?
-- The exclusions column contains comma-separated topping IDs.
-- CONCAT converts the exclusions string into a JSON array format.
-- JSON_TABLE separates multiple topping IDs into individual rows.
-- The topping IDs are matched with pizza_toppings to get the topping names.
-- GROUP BY groups the same exclusions together.
-- COUNT counts how many times each exclusion was made.
-- ORDER BY sorts the exclusions from most to least common.
-- LIMIT 1 returns the most commonly excluded topping.

SELECT
    pt.topping_name,
    COUNT(*) AS exclusion_count
FROM customer_orders co

CROSS JOIN JSON_TABLE(
    CONCAT('[', co.exclusions, ']'),
    '$[*]' COLUMNS (
        topping_id INT PATH '$'
    )
) AS jt

JOIN pizza_toppings pt
    ON jt.topping_id = pt.topping_id

GROUP BY pt.topping_name
ORDER BY exclusion_count DESC
LIMIT 1;


-- 4. Generate an order item for each record in the customer_orders table.
-- The extras and exclusions columns contain comma-separated topping IDs.
-- JSON_TABLE converts these IDs into separate rows.
-- GROUP_CONCAT combines the topping names for each order.
-- Separate CTEs are used for extras and exclusions to avoid multiplying rows.
-- The CTEs are LEFT JOINed back to customer_orders using order_id.
-- CASE WHEN adds the exclusion and extra text only when they exist.
-- CONCAT combines the pizza name, exclusions, and extras into the final order item.

WITH extra AS (
    SELECT
        co.order_id,
        GROUP_CONCAT(pt.topping_name) AS extras
    FROM customer_orders co
    CROSS JOIN JSON_TABLE(
        CONCAT('[', co.extras, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS jt
    JOIN pizza_toppings pt
        ON jt.topping_id = pt.topping_id
    GROUP BY co.order_id
),

exclusion AS (
    SELECT
        co.order_id,
        GROUP_CONCAT(pt.topping_name) AS exclusions
    FROM customer_orders co
    CROSS JOIN JSON_TABLE(
        CONCAT('[', co.exclusions, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS jt
    JOIN pizza_toppings pt
        ON jt.topping_id = pt.topping_id
    GROUP BY co.order_id
)

SELECT
    co.order_id,
    CONCAT(
        pn.pizza_name,
        CASE
            WHEN ex.exclusions IS NULL THEN ''
            ELSE CONCAT(' - Exclude ', ex.exclusions)
        END,
        CASE
            WHEN e.extras IS NULL THEN ''
            ELSE CONCAT(' - Extra ', e.extras)
        END
    ) AS order_item
FROM customer_orders co
JOIN pizza_names pn
    ON co.pizza_id = pn.pizza_id
LEFT JOIN extra e
    ON co.order_id = e.order_id
LEFT JOIN exclusion ex
    ON co.order_id = ex.order_id;
    
    
    
-- 5. Generate an alphabetically ordered comma-separated ingredient list
-- for each pizza order and add a quantity prefix for repeated ingredients.

WITH orders AS (
    -- Create a unique ID for each pizza order record.
    -- This prevents ingredients from different pizzas within the same order
    -- from being mixed together.
    SELECT
        ROW_NUMBER() OVER () AS pizza_order_id,
        co.*
    FROM customer_orders AS co
),

base_toppings AS (
    -- Get the standard toppings for each pizza order.
    SELECT
        o.pizza_order_id,
        o.order_id,
        pj.topping_id
    FROM orders AS o
    INNER JOIN pizza_recipes AS pr
        ON o.pizza_id = pr.pizza_id
    CROSS JOIN JSON_TABLE(
        CONCAT('[', pr.toppings, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS pj
),

extras AS (
    -- Convert extra topping IDs into individual rows.
    SELECT
        o.pizza_order_id,
        o.order_id,
        jt.topping_id
    FROM orders AS o
    CROSS JOIN JSON_TABLE(
        CONCAT('[', o.extras, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS jt
),

exclusions AS (
    -- Convert excluded topping IDs into individual rows.
    SELECT
        o.pizza_order_id,
        o.order_id,
        jt.topping_id
    FROM orders AS o
    CROSS JOIN JSON_TABLE(
        CONCAT('[', o.exclusions, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS jt
),

all_toppings AS (
    -- Combine standard and extra toppings.
    -- UNION ALL preserves duplicates so repeated toppings can be counted.
    SELECT
        pizza_order_id,
        order_id,
        topping_id
    FROM base_toppings

    UNION ALL

    SELECT
        pizza_order_id,
        order_id,
        topping_id
    FROM extras
),

filtered_toppings AS (
    -- Remove toppings that were excluded from the pizza.
    -- Match by pizza_order_id so exclusions only affect their own pizza.
    SELECT
        at.pizza_order_id,
        at.order_id,
        at.topping_id
    FROM all_toppings AS at
    WHERE NOT EXISTS (
        SELECT 1
        FROM exclusions AS exc
        WHERE exc.pizza_order_id = at.pizza_order_id
          AND exc.topping_id = at.topping_id
    )
),

counted_toppings AS (
    -- Count each topping for each individual pizza order.
    SELECT
        pizza_order_id,
        order_id,
        topping_id,
        COUNT(*) AS topping_count
    FROM filtered_toppings
    GROUP BY
        pizza_order_id,
        order_id,
        topping_id
)

SELECT
    ct.pizza_order_id,
    ct.order_id,
    pn.pizza_name,
    CONCAT(
        pn.pizza_name,
        ': ',
        GROUP_CONCAT(
            CASE
                WHEN ct.topping_count > 1
                    THEN CONCAT(
                        ct.topping_count,
                        'x',
                        pt.topping_name
                    )
                ELSE pt.topping_name
            END
            ORDER BY pt.topping_name
            SEPARATOR ', '
        )
    ) AS ingredient_list

FROM counted_toppings AS ct

-- Convert topping IDs into topping names.
INNER JOIN pizza_toppings AS pt
    ON ct.topping_id = pt.topping_id

-- Get the pizza ID for each individual pizza order.
INNER JOIN orders AS o
    ON ct.pizza_order_id = o.pizza_order_id

-- Get the pizza name.
INNER JOIN pizza_names AS pn
    ON o.pizza_id = pn.pizza_id

-- One final ingredient list for each individual pizza order.
GROUP BY
    ct.pizza_order_id,
    ct.order_id,
    pn.pizza_name;
    
    
    -- 6. Calculate the total quantity of each ingredient used
-- in all delivered pizzas, sorted from most frequent to least frequent.

WITH delivered_orders AS (
    -- Keep only orders that were successfully delivered.
    -- A NULL cancellation means the order was not cancelled.
    SELECT
        ro.order_id
    FROM runner_orders AS ro
    WHERE ro.cancellation IS NULL
),

base_toppings AS (
    -- Get the standard toppings for each delivered pizza.
    SELECT
        cr.order_id,
        pj.topping_id
    FROM customer_orders AS cr
    INNER JOIN delivered_orders AS do
        ON cr.order_id = do.order_id
    INNER JOIN pizza_recipes AS pr
        ON cr.pizza_id = pr.pizza_id
    CROSS JOIN JSON_TABLE(
        CONCAT('[', pr.toppings, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS pj
),

extras AS (
    -- Convert extra topping IDs into individual rows
    -- for delivered pizzas.
    SELECT
        cr.order_id,
        jt.topping_id
    FROM customer_orders AS cr
    INNER JOIN delivered_orders AS do
        ON cr.order_id = do.order_id
    CROSS JOIN JSON_TABLE(
        CONCAT('[', cr.extras, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS jt
),

exclusions AS (
    -- Convert excluded topping IDs into individual rows
    -- for delivered pizzas.
    SELECT
        cr.order_id,
        jt.topping_id
    FROM customer_orders AS cr
    INNER JOIN delivered_orders AS do
        ON cr.order_id = do.order_id
    CROSS JOIN JSON_TABLE(
        CONCAT('[', cr.exclusions, ']'),
        '$[*]' COLUMNS (
            topping_id INT PATH '$'
        )
    ) AS jt
),

all_toppings AS (
    -- Combine standard and extra toppings.
    -- UNION ALL preserves duplicates because an extra topping
    -- should increase its total quantity.
    SELECT
        order_id,
        topping_id
    FROM base_toppings

    UNION ALL

    SELECT
        order_id,
        topping_id
    FROM extras
),

filtered_toppings AS (
    -- Remove toppings that were excluded from each pizza.
    -- The matching is done using both order_id and topping_id
    -- so an exclusion only affects its own order.
    SELECT
        at.order_id,
        at.topping_id
    FROM all_toppings AS at
    WHERE NOT EXISTS (
        SELECT 1
        FROM exclusions AS exc
        WHERE exc.order_id = at.order_id
          AND exc.topping_id = at.topping_id
    )
),

counted_toppings AS (
    -- Count the total number of times each topping
    -- was used across all delivered pizzas.
    SELECT
        topping_id,
        COUNT(*) AS total_quantity
    FROM filtered_toppings
    GROUP BY topping_id
)

-- Convert topping IDs into ingredient names
-- and sort by total quantity from highest to lowest.
SELECT
    pt.topping_name,
    ct.topping_id,
    ct.total_quantity
FROM counted_toppings AS ct
INNER JOIN pizza_toppings AS pt
    ON ct.topping_id = pt.topping_id
ORDER BY ct.total_quantity DESC;