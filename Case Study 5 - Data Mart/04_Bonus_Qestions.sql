-- Which areas of the business have the highest negative impact on sales performance in 2020?
-- Combined Results for Visual Comparison
-- This section combines the results of all five business metrics
-- into one table to make comparison and analysis easier.

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        week_number
),

region_analysis AS (
    SELECT
        'Region' AS metric,
        region AS category,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY region
),

platform_analysis AS (
    SELECT
        'Platform' AS metric,
        platform AS category,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY platform
),

age_band_analysis AS (
    SELECT
        'Age Band' AS metric,
        age_band AS category,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY age_band
),

demographic_analysis AS (
    SELECT
        'Demographic' AS metric,
        demographic AS category,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY demographic
),

customer_type_analysis AS (
    SELECT
        'Customer Type' AS metric,
        customer_type AS category,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY customer_type
),

combined_results AS (
    SELECT * FROM region_analysis
    UNION ALL
    SELECT * FROM platform_analysis
    UNION ALL
    SELECT * FROM age_band_analysis
    UNION ALL
    SELECT * FROM demographic_analysis
    UNION ALL
    SELECT * FROM customer_type_analysis
)

SELECT
    metric,
    category,
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before) / sales_before * 100 AS percentage_change
FROM combined_results
ORDER BY
    CASE metric
        WHEN 'Region' THEN 1
        WHEN 'Platform' THEN 2
        WHEN 'Age Band' THEN 3
        WHEN 'Demographic' THEN 4
        WHEN 'Customer Type' THEN 5
    END,
    percentage_change;
    
    
    
    -- Q4: Region × Platform Analysis
-- Investigating the sales decline by combining region and platform.

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        region,
        platform,
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY
        region,
        platform,
        week_number
),

before_after AS (
    SELECT
        region,
        platform,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY
        region,
        platform
)

SELECT
    region,
    platform,
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before)
        / sales_before * 100 AS percentage_change
FROM before_after
ORDER BY percentage_change;

-- Investigating the sales decline by combining platform and customer type.

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        platform,
        customer_type,
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY
        platform,
        customer_type,
        week_number
),

before_after AS (
    SELECT
        platform,
        customer_type,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY
        platform,
        customer_type
)

SELECT
    platform,
    customer_type,
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before)
        / sales_before * 100 AS percentage_change
FROM before_after
ORDER BY percentage_change;



-- Investigating the sales decline by combining region and customer type.

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        region,
        customer_type,
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY
        region,
        customer_type,
        week_number
),

before_after AS (
    SELECT
        region,
        customer_type,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY
        region,
        customer_type
)

SELECT
    region,
    customer_type,
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before)
        / sales_before * 100 AS percentage_change
FROM before_after
ORDER BY percentage_change;



-- Investigating the sales decline by combining region, platform, and customer type.

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        region,
        platform,
        customer_type,
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY
        region,
        platform,
        customer_type,
        week_number
),

before_after AS (
    SELECT
        region,
        platform,
        customer_type,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY
        region,
        platform,
        customer_type
)

SELECT
    region,
    platform,
    customer_type,
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before)
        / sales_before * 100 AS percentage_change
FROM before_after
ORDER BY percentage_change;


-- Q4: Region × Age Band Analysis
-- Investigating the sales decline by combining region and age band,
-- with a focus on unknown age-band values.

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        region,
        age_band,
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY
        region,
        age_band,
        week_number
),

before_after AS (
    SELECT
        region,
        age_band,

        SUM(
            CASE
                WHEN week_number < (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number >= (SELECT week_number FROM baseline)
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY
        region,
        age_band
)

SELECT
    region,
    age_band,
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before)
        / sales_before * 100 AS percentage_change
FROM before_after
WHERE age_band = 'unknown'
ORDER BY percentage_change;