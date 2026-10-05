-- Q1. Update the month_year column to a DATE data type with the start of each month.

ALTER TABLE fresh_segments.interest_metrics
MODIFY COLUMN month_year VARCHAR(10);

UPDATE fresh_segments.interest_metrics
SET month_year = CONCAT(
    RIGHT(month_year, 4),
    '-',
    LEFT(month_year, 2),
    '-01'
)
WHERE month_year IS NOT NULL;

ALTER TABLE fresh_segments.interest_metrics
MODIFY COLUMN month_year DATE;

-- Q2. Count the number of records for each month_year,
-- ordered chronologically with NULL values appearing first.

SELECT
    month_year,
    COUNT(*) AS record_count
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year IS NOT NULL, month_year;


-- Q3. What should we do with the NULL values in the month_year column?
-- Keep the NULL values because there is not enough information to determine
-- the correct month and year. Do not delete the records or invent dates.


SELECT COUNT(distinct m.interest_id)
FROM interest_metrics m
WHERE NOT EXISTS (
    SELECT 1
    FROM interest_map i
    WHERE i.id = m.interest_id
);


-- Q4. How many unique interest_id values exist in interest_metrics
-- but not in interest_map, and vice versa?

-- interest_id values in interest_metrics but not in interest_map
SELECT COUNT(DISTINCT m.interest_id) AS missing_from_interest_map
FROM interest_metrics AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM interest_map AS i
    WHERE i.id = m.interest_id
);

-- interest_id values in interest_map but not in interest_metrics
SELECT COUNT(DISTINCT i.id) AS missing_from_interest_metrics
FROM interest_map AS i
WHERE NOT EXISTS (
    SELECT 1
    FROM interest_metrics AS m
    WHERE m.interest_id = i.id
);



-- Q5. Summarise the id values in the interest_map by total record count.

SELECT
    id,
    COUNT(*) AS total_record_count
FROM interest_map
GROUP BY id;



-- Q6. What type of join should we perform for this analysis, and why?
-- Check the output for interest_id = 21246, including all columns from
-- interest_metrics and all columns from interest_map except id.

SELECT
    m.*,
    i.interest_name,
    i.interest_summary,
    i.created_at
FROM interest_metrics AS m
INNER JOIN interest_map AS i
    ON i.id = m.interest_id
WHERE m.interest_id = 21246;



-- Q7. Are there any records where month_year is before created_at?
-- Are these records valid and why?

SELECT
    m.*,
    i.*
FROM interest_metrics AS m
INNER JOIN interest_map AS i
    ON m.interest_id = i.id
WHERE m.month_year < i.created_at;

-- Result:
-- Yes, there are records where month_year is earlier than created_at.
-- These records can be considered valid because an interest may have
-- appeared in the metrics before it was identified and added to interest_map.