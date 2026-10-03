USE pizza_runner;

-- Check the raw runner_orders data before cleaning.

SELECT
    order_id,
    pickup_time,
    distance,
    duration,
    cancellation
FROM runner_orders;


-- Convert pickup_time from VARCHAR to DATETIME.
-- This allows the column to be used correctly in date and time calculations.

ALTER TABLE runner_orders
ADD COLUMN pickup_time_cleaned DATETIME;

UPDATE runner_orders
SET pickup_time_cleaned =
    STR_TO_DATE(
        pickup_time,
        '%Y-%m-%d %H:%i:%s'
    )
WHERE order_id >= 1;

-- Check the converted values before replacing the original column.

SELECT
    order_id,
    pickup_time,
    pickup_time_cleaned
FROM runner_orders;

-- Replace the original VARCHAR column with the cleaned DATETIME column.

ALTER TABLE runner_orders
DROP COLUMN pickup_time;

ALTER TABLE runner_orders
CHANGE COLUMN pickup_time_cleaned pickup_time DATETIME;


-- Remove the 'km' suffix and extra spaces from distance values.
-- Then convert the result from VARCHAR to DECIMAL.

ALTER TABLE runner_orders
ADD COLUMN distance_cleaned DECIMAL(5,2);

UPDATE runner_orders
SET distance_cleaned =
    CAST(
        TRIM(
            REPLACE(distance, 'km', '')
        )
        AS DECIMAL(5,2)
    )
WHERE order_id >= 1;

-- Check the cleaned distance values.

SELECT
    order_id,
    distance,
    distance_cleaned
FROM runner_orders;

-- Replace the original VARCHAR column with the cleaned numeric column.

ALTER TABLE runner_orders
DROP COLUMN distance;

ALTER TABLE runner_orders
CHANGE COLUMN distance_cleaned distance DECIMAL(5,2);


-- Remove different minute labels from duration values.
-- The raw data contains formats such as '32 minutes', '20 mins',
-- '25mins', and '15 minute'.
-- Then convert the result from VARCHAR to DECIMAL.

ALTER TABLE runner_orders
ADD COLUMN duration_cleaned DECIMAL(5,2);

UPDATE runner_orders
SET duration_cleaned =
    CAST(
        TRIM(
            REPLACE(
                REPLACE(
                    REPLACE(duration, 'minutes', ''),
                    'minute', ''
                ),
                'mins', ''
            )
        )
        AS DECIMAL(5,2)
    )
WHERE order_id >= 1;

-- Check the cleaned duration values.

SELECT
    order_id,
    duration,
    duration_cleaned
FROM runner_orders;

-- Replace the original VARCHAR column with the cleaned numeric column.

ALTER TABLE runner_orders
DROP COLUMN duration;

ALTER TABLE runner_orders
CHANGE COLUMN duration_cleaned duration DECIMAL(5,2);


-- Check the raw customer_orders data before cleaning.

SELECT
    order_id,
    customer_id,
    pizza_id,
    exclusions,
    extras,
    order_date
FROM customer_orders;


-- Check for non-standard missing values in extras.
-- 'NaN' is stored as text in the raw data but represents a missing value.

SELECT
    order_id,
    customer_id,
    pizza_id,
    extras
FROM customer_orders
WHERE extras = 'NaN';

-- Standardize 'NaN' as NULL in the extras column.

UPDATE customer_orders
SET extras = NULL
WHERE extras = 'NaN';

-- Check the cleaned extras values.

SELECT DISTINCT extras
FROM customer_orders;


-- Check the distinct exclusion values.
-- Values such as '2, 6' are kept as strings for now
-- and will be processed later in the analysis.

SELECT DISTINCT exclusions
FROM customer_orders;


-- Check the distinct extra values after cleaning.

SELECT DISTINCT extras
FROM customer_orders;


-- Check for pickup_time values recorded with the year 2020.

SELECT
    order_id,
    pickup_time
FROM runner_orders
WHERE YEAR(pickup_time) = 2020;


-- Compare pickup_time with order_date to confirm the inconsistent year.

SELECT
    r.order_id,
    c.order_date,
    r.pickup_time
FROM runner_orders AS r
JOIN customer_orders AS c
    ON r.order_id = c.order_id
WHERE YEAR(r.pickup_time) = 2020;


-- Test the correction before updating the data.
-- Adding one year preserves the month, day, and time.

SELECT
    order_id,
    pickup_time,
    DATE_ADD(
        pickup_time,
        INTERVAL 1 YEAR
    ) AS corrected_pickup_time
FROM runner_orders
WHERE YEAR(pickup_time) = 2020;


-- Correct the pickup_time values that were recorded one year earlier.
-- The corresponding order dates confirm that these records should be in 2021.

UPDATE runner_orders
SET pickup_time = DATE_ADD(
    pickup_time,
    INTERVAL 1 YEAR
)
WHERE YEAR(pickup_time) = 2020
  AND order_id >= 1;


-- Final validation of the cleaned tables.

DESC runner_orders;

DESC customer_orders;


-- Check that no unexpected 2020 pickup dates remain.

SELECT *
FROM runner_orders
WHERE YEAR(pickup_time) <> 2021
  AND pickup_time IS NOT NULL;


-- Check that no 'NaN' values remain.

SELECT *
FROM customer_orders
WHERE extras = 'NaN'
   OR exclusions = 'NaN';


-- Review the cleaned runner_orders table.

SELECT *
FROM runner_orders;


-- Review the cleaned customer_orders table.

SELECT *
FROM customer_orders;