-- Q1. Which interests have been present in all month_year dates in our dataset?

SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
WHERE month_year IS NOT NULL
GROUP BY interest_id
HAVING total_months = (
    SELECT COUNT(DISTINCT month_year)
    FROM interest_metrics
    WHERE month_year IS NOT NULL
);

-- Q2. Using this same total_months measure - calculate the cumulative
-- percentage of all records starting at 14 months - which total_months
-- value passes the 90% cumulative percentage value?

WITH monthly_interests AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS total_months
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
),

month_summary AS (
    SELECT
        total_months,
        COUNT(*) AS interest_count,
        SUM(COUNT(*)) OVER (
            ORDER BY total_months DESC
        ) AS cumulative_count
    FROM monthly_interests
    GROUP BY total_months
),

total_interests AS (
    SELECT
        COUNT(*) AS total_interest_count
    FROM monthly_interests
),

cumulative_percentages AS (
    SELECT
        ms.total_months,
        ms.interest_count,
        ms.cumulative_count,
        ti.total_interest_count,
        ROUND(
            ms.cumulative_count / ti.total_interest_count * 100,
            2
        ) AS cumulative_percentage
    FROM month_summary AS ms
    CROSS JOIN total_interests AS ti
)

SELECT
    total_months,
    cumulative_percentage
FROM cumulative_percentages
WHERE cumulative_percentage > 90
ORDER BY total_months DESC
LIMIT 1;



-- Q3. If we were to remove all interest_id values which have a
-- total_months value lower than the threshold found in the previous question,
-- how many total data points would we be removing?

WITH monthly_interests AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS total_months
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
)

SELECT
    COUNT(*) AS data_points_to_remove
FROM interest_metrics AS m
JOIN monthly_interests AS mi
    ON m.interest_id = mi.interest_id
WHERE mi.total_months < 6;


-- Q4. Does this decision make sense from a business perspective?
--
-- Yes, removing these data points is reasonable for long-term segment analysis.
-- The 400 data points represent a small portion of the dataset, while interests
-- with fewer than 6 months of data have limited and often discontinuous coverage.
-- This makes it difficult to identify reliable trends over time.
-- In contrast, interests present across all 14 months provide more consistent
-- data for analysing segment behaviour and trends.





