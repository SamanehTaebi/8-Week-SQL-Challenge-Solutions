-- Data Cleaning and Validation


CREATE TABLE data_mart.clean_weekly_sales AS

SELECT
    -- convert week_date to DATE format
    STR_TO_DATE(week_date, '%e/%c/%y') AS week_date,

    -- calculate week number within the calendar year
    FLOOR(
        DATEDIFF(
            STR_TO_DATE(week_date, '%e/%c/%y'),
            MAKEDATE(
                YEAR(STR_TO_DATE(week_date, '%e/%c/%y')),
                1
            )
        ) / 7
    ) + 1 AS week_number,

    -- extract calendar month from week_date
    MONTH(STR_TO_DATE(week_date, '%e/%c/%y')) AS month_number,

    -- extract calendar year from week_date
    YEAR(STR_TO_DATE(week_date, '%e/%c/%y')) AS calendar_year,

    -- keep original columns
    region,
    platform,

    -- replace string 'null' with 'unknown'
    CASE
        WHEN segment = 'null' THEN 'unknown'
        ELSE segment
    END AS segment,

    -- create age band based on the number in segment
    CASE
        WHEN segment = 'null' THEN 'unknown'
        WHEN CAST(RIGHT(segment, 1) AS UNSIGNED) = 1
            THEN 'Young Adults'
        WHEN CAST(RIGHT(segment, 1) AS UNSIGNED) = 2
            THEN 'Middle Aged'
        WHEN CAST(RIGHT(segment, 1) AS UNSIGNED) IN (3, 4)
            THEN 'Retirees'
        ELSE 'unknown'
    END AS age_band,

    -- create demographic based on the first letter of segment
    CASE
        WHEN segment = 'null' THEN 'unknown'
        WHEN LEFT(segment, 1) = 'C'
            THEN 'Couples'
        WHEN LEFT(segment, 1) = 'F'
            THEN 'Families'
        ELSE 'unknown'
    END AS demographic,

    -- keep original columns
    customer_type,
    transactions,
    sales,

    -- calculate average transaction value
    ROUND(sales / transactions, 2) AS avg_transaction

FROM data_mart.weekly_sales;


-- check for actual NULL values

SELECT
    SUM(week_date IS NULL) AS week_date_null,
    SUM(week_number IS NULL) AS week_number_null,
    SUM(month_number IS NULL) AS month_number_null,
    SUM(calendar_year IS NULL) AS calendar_year_null,
    SUM(region IS NULL) AS region_null,
    SUM(platform IS NULL) AS platform_null,
    SUM(segment IS NULL) AS segment_null,
    SUM(age_band IS NULL) AS age_band_null,
    SUM(demographic IS NULL) AS demographic_null,
    SUM(customer_type IS NULL) AS customer_type_null,
    SUM(transactions IS NULL) AS transactions_null,
    SUM(sales IS NULL) AS sales_null,
    SUM(avg_transaction IS NULL) AS avg_transaction_null

FROM data_mart.clean_weekly_sales;


-- check for remaining string 'null' values

SELECT
    SUM(segment = 'null') AS segment_null,
    SUM(region = 'null') AS region_null,
    SUM(platform = 'null') AS platform_null,
    SUM(age_band = 'null') AS age_band_null,
    SUM(demographic = 'null') AS demographic_null,
    SUM(customer_type = 'null') AS customer_type_null

FROM data_mart.clean_weekly_sales;