-- 1. What is the total sales for the 4 weeks before and after 2020-06-15?
-- What is the growth or reduction rate in actual values and percentage of sales?

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 4
          AND
          (SELECT week_number FROM baseline) + 3
    GROUP BY week_number
),

before_after AS (
    SELECT
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
)

SELECT
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before) / sales_before * 100 AS percentage_change
FROM before_after;




-- 2. What about the entire 12 weeks before and after?

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY week_number
),

before_after AS (
    SELECT
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
)

SELECT
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before) / sales_before * 100 AS percentage_change
FROM before_after;


-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

WITH baseline AS (
    SELECT DISTINCT
        week_number
    FROM clean_weekly_sales
    WHERE calendar_year = '2020'
      AND week_date = '2020-06-15'
),

weeks AS (
    SELECT
        calendar_year,
        week_number,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE calendar_year IN ('2018', '2019', '2020')
      AND week_number BETWEEN
          (SELECT week_number FROM baseline) - 12
          AND
          (SELECT week_number FROM baseline) + 11
    GROUP BY
        calendar_year,
        week_number
),

before_after AS (
    SELECT
        calendar_year,

        SUM(
            CASE
                WHEN week_number BETWEEN
                     (SELECT week_number FROM baseline) - 12
                     AND
                     (SELECT week_number FROM baseline) - 1
                THEN total_sales
                ELSE 0
            END
        ) AS sales_before,

        SUM(
            CASE
                WHEN week_number BETWEEN
                     (SELECT week_number FROM baseline)
                     AND
                     (SELECT week_number FROM baseline) + 11
                THEN total_sales
                ELSE 0
            END
        ) AS sales_after

    FROM weeks
    GROUP BY calendar_year
)

SELECT
    calendar_year,
    sales_before,
    sales_after,
    sales_after - sales_before AS actual_change,
    (sales_after - sales_before) / sales_before * 100 AS percentage_change
FROM before_after
ORDER BY calendar_year;