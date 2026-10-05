-- 1.What day of the week is used for each week_date value?

SELECT DISTINCT
    DAYNAME(week_date) AS start_of_week
FROM clean_weekly_sales;



-- 2. What range of week numbers are missing from the dataset?
WITH RECURSIVE week_range AS (
    SELECT
        MIN(week_number) AS min_week,
        MAX(week_number) AS max_week
    FROM clean_weekly_sales
),
week_numbers AS (
    SELECT min_week AS week_number
    FROM week_range

    UNION ALL

    SELECT week_number + 1
    FROM week_numbers
    CROSS JOIN week_range
    WHERE week_number < max_week
)

SELECT w.week_number
FROM week_numbers w
WHERE NOT EXISTS (
    SELECT c.week_number
    FROM clean_weekly_sales c
    WHERE c.week_number = w.week_number
);

-- 3. What was the total number of transactions for each year?

SELECT
    calendar_year,
    SUM(transactions) AS total_transaction
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;


-- 4. What is the total sales for each region for each month?

SELECT
    region,
    month_number,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

-- 5. What is the total count of transactions for each platform?

SELECT
    platform,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;


-- 6. What is the percentage of sales for Retail vs Shopify for each month?

WITH monthly_sales AS (
    SELECT
        month_number,

        SUM(
            CASE
                WHEN platform = 'Retail' THEN sales
                ELSE 0
            END
        ) AS retail_sales,

        SUM(
            CASE
                WHEN platform = 'Shopify' THEN sales
                ELSE 0
            END
        ) AS shopify_sales

    FROM clean_weekly_sales
    GROUP BY month_number
)

SELECT
    month_number,

    retail_sales / (retail_sales + shopify_sales) * 100 AS retail_perc,

    shopify_sales / (retail_sales + shopify_sales) * 100 AS shopify_perc

FROM monthly_sales;


-- 7. What is the percentage of sales by demographic for each year in the dataset?

WITH demographic_sales AS (
    SELECT
        calendar_year,
        demographic,
        SUM(sales) AS demographic_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year, demographic
)

SELECT
    calendar_year,
    demographic,
    demographic_sales
        / SUM(demographic_sales) OVER (PARTITION BY calendar_year)
        * 100 AS sales_percentage
FROM demographic_sales
ORDER BY calendar_year, demographic;



-- 8. Which age_band and demographic values contribute the most to Retail sales?

SELECT
    age_band,
    demographic,
    total_sales
FROM (
    SELECT
        age_band,
        demographic,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    WHERE platform = 'Retail'
    GROUP BY age_band, demographic
) AS sales
ORDER BY total_sales DESC
LIMIT 1;



-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

WITH yearly_sales AS (
    SELECT
        calendar_year,

        -- calculate total Retail sales for each year
        SUM(
            CASE
                WHEN platform = 'Retail' THEN sales
                ELSE 0
            END
        ) AS retail_sales,

        -- calculate total Shopify sales for each year
        SUM(
            CASE
                WHEN platform = 'Shopify' THEN sales
                ELSE 0
            END
        ) AS shopify_sales,

        -- calculate total Retail transactions for each year
        SUM(
            CASE
                WHEN platform = 'Retail' THEN transactions
                ELSE 0
            END
        ) AS retail_transactions,

        -- calculate total Shopify transactions for each year
        SUM(
            CASE
                WHEN platform = 'Shopify' THEN transactions
                ELSE 0
            END
        ) AS shopify_transactions

    FROM clean_weekly_sales
    GROUP BY calendar_year
)

SELECT
    calendar_year,

    retail_sales / retail_transactions AS avg_retail,
 
    shopify_sales / shopify_transactions AS avg_shopify

FROM yearly_sales;