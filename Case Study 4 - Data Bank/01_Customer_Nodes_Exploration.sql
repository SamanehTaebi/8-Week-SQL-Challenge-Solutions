use data_bank;

-- 1- How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;


-- 2- What is the number of nodes per region?

SELECT region_id, COUNT(DISTINCT node_id) AS node_count
FROM customer_nodes
GROUP BY region_id;


-- 3- How many customers are allocated to each region?

SELECT region_id, COUNT(customer_id) AS customer_count
FROM customer_nodes
GROUP BY region_id;


-- 4- How many days on average are customers reallocated to a different node?

SELECT AVG(DATEDIFF(end_date, start_date)) AS avg_reallocation_days
FROM customer_nodes
WHERE end_date <> '9999-12-31';




-- 5- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH date_diff AS (
    SELECT
        region_id,
        DATEDIFF(end_date, start_date) AS relocated_days
    FROM customer_nodes
    WHERE end_date <> '9999-12-31'
),

ranked AS (
    SELECT
        region_id,
        relocated_days,
        ROW_NUMBER() OVER (
            PARTITION BY region_id
            ORDER BY relocated_days
        ) AS row_num,
        COUNT(*) OVER (
            PARTITION BY region_id
        ) AS total_rows
    FROM date_diff
),

positions AS (
    SELECT
        region_id,
        MAX(total_rows) AS total_rows,
        1 + (MAX(total_rows) - 1) * 0.50 AS median_pos,
        1 + (MAX(total_rows) - 1) * 0.80 AS percentile_80_pos,
        1 + (MAX(total_rows) - 1) * 0.95 AS percentile_95_pos
    FROM ranked
    GROUP BY region_id
)

SELECT
    p.region_id,

    CASE
        WHEN p.median_pos = FLOOR(p.median_pos)
        THEN MAX(CASE
            WHEN r.row_num = p.median_pos
            THEN r.relocated_days
        END)
        ELSE
            MAX(CASE
                WHEN r.row_num = FLOOR(p.median_pos)
                THEN r.relocated_days
            END)
            +
            (
                MAX(CASE
                    WHEN r.row_num = CEIL(p.median_pos)
                    THEN r.relocated_days
                END)
                -
                MAX(CASE
                    WHEN r.row_num = FLOOR(p.median_pos)
                    THEN r.relocated_days
                END)
            ) * (p.median_pos - FLOOR(p.median_pos))
    END AS median,

    CASE
        WHEN p.percentile_80_pos = FLOOR(p.percentile_80_pos)
        THEN MAX(CASE
            WHEN r.row_num = p.percentile_80_pos
            THEN r.relocated_days
        END)
        ELSE
            MAX(CASE
                WHEN r.row_num = FLOOR(p.percentile_80_pos)
                THEN r.relocated_days
            END)
            +
            (
                MAX(CASE
                    WHEN r.row_num = CEIL(p.percentile_80_pos)
                    THEN r.relocated_days
                END)
                -
                MAX(CASE
                    WHEN r.row_num = FLOOR(p.percentile_80_pos)
                    THEN r.relocated_days
                END)
            ) * (p.percentile_80_pos - FLOOR(p.percentile_80_pos))
    END AS percentile_80,

    CASE
        WHEN p.percentile_95_pos = FLOOR(p.percentile_95_pos)
        THEN MAX(CASE
            WHEN r.row_num = p.percentile_95_pos
            THEN r.relocated_days
        END)
        ELSE
            MAX(CASE
                WHEN r.row_num = FLOOR(p.percentile_95_pos)
                THEN r.relocated_days
            END)
            +
            (
                MAX(CASE
                    WHEN r.row_num = CEIL(p.percentile_95_pos)
                    THEN r.relocated_days
                END)
                -
                MAX(CASE
                    WHEN r.row_num = FLOOR(p.percentile_95_pos)
                    THEN r.relocated_days
                END)
            ) * (p.percentile_95_pos - FLOOR(p.percentile_95_pos))
    END AS percentile_95

FROM positions p
JOIN ranked r
    ON p.region_id = r.region_id
GROUP BY
    p.region_id,
    p.median_pos,
    p.percentile_80_pos,
    p.percentile_95_pos;