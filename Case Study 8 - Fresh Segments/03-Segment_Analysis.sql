--  Q1. Using the filtered dataset by removing the interests
-- with less than 6 months worth of data, which are the top 10 and bottom 10
-- interests which have the largest composition values in any month_year?
-- Only use the maximum composition value for each interest but keep the
-- corresponding month_year.


WITH monthly_interests AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS total_months
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
),

ranked_interests AS (
    SELECT
        m.interest_id,
        m.composition,
        m.month_year,
        RANK() OVER (
            PARTITION BY m.interest_id
            ORDER BY m.composition DESC
        ) AS composition_rank
    FROM interest_metrics AS m
    JOIN monthly_interests AS mi
        ON m.interest_id = mi.interest_id
    WHERE mi.total_months >= 6
),

max_compositions AS (
    SELECT
        interest_id,
        composition,
        month_year
    FROM ranked_interests
    WHERE composition_rank = 1
)

(
    SELECT
        'Top 10' AS ranking_group,
        mc.interest_id,
        i.interest_name,
        mc.composition,
        mc.month_year
    FROM max_compositions AS mc
    INNER JOIN interest_map AS i
        ON mc.interest_id = i.id
    ORDER BY mc.composition DESC
    LIMIT 10
)

UNION ALL

(
    SELECT
        'Bottom 10' AS ranking_group,
        mc.interest_id,
        i.interest_name,
        mc.composition,
        mc.month_year
    FROM max_compositions AS mc
    INNER JOIN interest_map AS i
        ON mc.interest_id = i.id
    ORDER BY mc.composition ASC
    LIMIT 10
);



-- Q2. Which 5 interests had the lowest average ranking value?

SELECT
    m.interest_id,
    i.interest_name,
    AVG(m.ranking) AS avg_ranking
FROM interest_metrics AS m
INNER JOIN interest_map AS i
    ON m.interest_id = i.id
GROUP BY
    m.interest_id,
    i.interest_name
ORDER BY avg_ranking ASC
LIMIT 5;



-- Q3. Which 5 interests had the largest standard deviation
-- in their percentile_ranking value?

SELECT
    m.interest_id,
    i.interest_name,
    STDDEV(m.percentile_ranking) AS std_dev
FROM interest_metrics AS m
INNER JOIN interest_map AS i
    ON m.interest_id = i.id
WHERE m.interest_id IS NOT NULL
GROUP BY
    m.interest_id,
    i.interest_name
ORDER BY std_dev DESC
LIMIT 5;



-- Q4. For the 5 interests found in the previous question, what were the
-- minimum and maximum percentile_ranking values for each interest and their
-- corresponding month_year values? Can you describe what is happening for
-- these 5 interests?


WITH top_std_dev_interests AS (
    SELECT
        interest_id,
        STDDEV(percentile_ranking) AS std_dev
    FROM interest_metrics
    WHERE interest_id IS NOT NULL
    GROUP BY interest_id
    ORDER BY std_dev DESC
    LIMIT 5
),

interest_min_max AS (
    SELECT
        m.interest_id,
        MIN(m.percentile_ranking) AS min_percentile_ranking,
        MAX(m.percentile_ranking) AS max_percentile_ranking
    FROM interest_metrics AS m
    INNER JOIN top_std_dev_interests AS t
        ON m.interest_id = t.interest_id
    GROUP BY m.interest_id
)

SELECT
    m.interest_id,
    i.interest_name,
    m.percentile_ranking,
    CASE
        WHEN m.percentile_ranking = mm.min_percentile_ranking THEN 'Minimum'
        WHEN m.percentile_ranking = mm.max_percentile_ranking THEN 'Maximum'
    END AS ranking_type,
    m.month_year
FROM interest_metrics AS m
INNER JOIN interest_min_max AS mm
    ON m.interest_id = mm.interest_id
INNER JOIN interest_map AS i
    ON m.interest_id = i.id
WHERE m.percentile_ranking = mm.min_percentile_ranking
   OR m.percentile_ranking = mm.max_percentile_ranking
ORDER BY m.interest_id, m.percentile_ranking;


-- Q5. How would you describe our customers in this segment based off
-- their composition and ranking values? What sort of products or services
-- should we show to these customers and what should we avoid?
--
-- Based on the composition and ranking values, this segment appears to have
-- strong interests in shopping, fashion, fitness, luxury products, and travel.
--
-- The highest composition values include interests such as Luxury Retail
-- Shoppers, Luxury Bedding Shoppers, Shoe Shoppers, Cosmetics and Beauty
-- Shoppers, Gym Equipment Owners, Luxury Boutique Hotel Researchers,
-- and Luxury Hotel Guests. This indicates a strong preference for consumer
-- products, premium brands, active lifestyles, and travel experiences.
--
-- The ranking results support this pattern. Winter Apparel Shoppers,
-- Fitness Activity Tracker Users, Mens Shoe Shoppers, Elite Cycling Gear
-- Shoppers, and Shoe Shoppers had the lowest average ranking values,
-- meaning these interests had the strongest average positions.
--
-- Based on these findings, we should prioritize products and services related to:
--   - Fitness and active lifestyle products
--   - Sportswear, cycling gear, and fitness trackers
--   - Fashion, shoes, and beauty products
--   - Luxury retail and premium brands
--   - Hotels, travel, and premium travel experiences
--   - Premium home products such as furniture and bedding
--
-- We should avoid prioritizing interests with consistently low composition,
-- such as gaming, specific video games, astrology, and certain vehicle-related
-- interests, as they appear less relevant to this segment.
--
-- Overall, this segment is highly consumer-oriented and shows a strong
-- preference for premium shopping, fitness, fashion, and travel-related
-- products and services.
