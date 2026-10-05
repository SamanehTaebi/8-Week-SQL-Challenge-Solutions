-- Q1. What is the top 10 interests by the average composition for each month?

WITH interest_avg_composition AS (
    SELECT
        month_year,
        interest_id,
        ROUND(AVG(composition / index_value), 2) AS avg_composition,
        ROW_NUMBER() OVER (
            PARTITION BY month_year
            ORDER BY ROUND(AVG(composition / index_value), 2) DESC
        ) AS composition_rank
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY
        month_year,
        interest_id
)

SELECT
    a.month_year,
    a.interest_id,
    i.interest_name,
    a.avg_composition
FROM interest_avg_composition AS a
INNER JOIN interest_map AS i
    ON a.interest_id = i.id
WHERE a.composition_rank <= 10
ORDER BY
    a.month_year,
    a.composition_rank;
    
    
-- Q2. For all of these top 10 interests - which interest appears the most often?

WITH interest_avg_composition AS (
    SELECT
        month_year,
        interest_id,
        ROUND(AVG(composition / index_value), 2) AS avg_composition,
        ROW_NUMBER() OVER (
            PARTITION BY month_year
            ORDER BY ROUND(AVG(composition / index_value), 2) DESC
        ) AS composition_rank
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY
        month_year,
        interest_id
),

monthly_top_interests AS (
    SELECT
        a.month_year,
        a.interest_id,
        i.interest_name,
        a.avg_composition
    FROM interest_avg_composition AS a
    INNER JOIN interest_map AS i
        ON a.interest_id = i.id
    WHERE a.composition_rank <= 10
)

SELECT
    interest_id,
    interest_name,
    COUNT(*) AS appearance_count
FROM monthly_top_interests
GROUP BY
    interest_id,
    interest_name
ORDER BY appearance_count DESC
LIMIT 1;



-- Q3. What is the average of the average composition for the top 10
-- interests for each month?

WITH interest_avg_composition AS (
    SELECT
        month_year,
        interest_id,
        ROUND(AVG(composition / index_value), 2) AS avg_composition,
        ROW_NUMBER() OVER (
            PARTITION BY month_year
            ORDER BY ROUND(AVG(composition / index_value), 2) DESC
        ) AS composition_rank
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY
        month_year,
        interest_id
)

SELECT
    month_year,
    ROUND(AVG(avg_composition), 2) AS avg_top10_composition
FROM interest_avg_composition
WHERE composition_rank <= 10
GROUP BY month_year
ORDER BY month_year;



-- Q4. What is the 3 month rolling average of the max average composition
-- value from September 2018 to August 2019 and include the previous top
-- ranking interests in the same output shown below?

WITH interest_avg_composition AS (
    SELECT
        month_year,
        interest_id,
        ROUND(AVG(composition / index_value), 2) AS avg_composition,
        ROW_NUMBER() OVER (
            PARTITION BY month_year
            ORDER BY ROUND(AVG(composition / index_value), 2) DESC
        ) AS composition_rank
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY
        month_year,
        interest_id
),

monthly_top_interest AS (
    SELECT
        a.month_year,
        a.interest_id,
        i.interest_name,
        a.avg_composition
    FROM interest_avg_composition AS a
    INNER JOIN interest_map AS i
        ON a.interest_id = i.id
    WHERE a.composition_rank = 1
),

monthly_top_with_history AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        avg_composition,

        LAG(interest_name, 1) OVER (
            ORDER BY month_year
        ) AS one_month_ago_interest,

        LAG(avg_composition, 1) OVER (
            ORDER BY month_year
        ) AS one_month_ago_composition,

        LAG(interest_name, 2) OVER (
            ORDER BY month_year
        ) AS two_months_ago_interest,

        LAG(avg_composition, 2) OVER (
            ORDER BY month_year
        ) AS two_months_ago_composition

    FROM monthly_top_interest
),

monthly_top_with_rolling_avg AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        avg_composition,
        one_month_ago_interest,
        one_month_ago_composition,
        two_months_ago_interest,
        two_months_ago_composition,

        ROUND(
            AVG(avg_composition) OVER (
                ORDER BY month_year
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS three_month_moving_avg

    FROM monthly_top_with_history
)

SELECT
    month_year,
    interest_name,
    avg_composition AS max_index_composition,
    three_month_moving_avg,

    CASE
        WHEN one_month_ago_interest IS NOT NULL
        THEN CONCAT(
            one_month_ago_interest,
            ': ',
            one_month_ago_composition
        )
    END AS one_month_ago,

    CASE
        WHEN two_months_ago_interest IS NOT NULL
        THEN CONCAT(
            two_months_ago_interest,
            ': ',
            two_months_ago_composition
        )
    END AS two_months_ago

FROM monthly_top_with_rolling_avg
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01'
ORDER BY month_year;



-- Q5. Provide a possible reason why the max average composition might change
-- from month to month? Could it signal something is not quite right with
-- the overall business model for Fresh Segments?
--
-- The max average composition may change from month to month due to changes
-- in customer behaviour, seasonal trends, changes in advertising campaigns,
-- or changes in the customer base.
--
-- For example, travel-related interests may become more prominent during
-- certain periods, while other interests may increase at different times
-- of the year.
--
-- A change in the max average composition does not necessarily indicate
-- that there is a problem with Fresh Segments' business model. Changes in
-- customer interests and engagement are expected over time.
--
-- However, a consistent and significant decline across multiple interests
-- could be a reason to investigate factors such as customer engagement,
-- changes in the customer base, advertising performance, or data quality.
--
-- Therefore, the month-to-month change itself is not necessarily a problem;
-- the long-term trend and the reasons behind the changes are more important.
        