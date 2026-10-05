-- Advanced Analysis: Dynamic SQL
-- This section performs the same 12-week before-and-after sales analysis
-- for each business metric, using a Stored Procedure and Dynamic SQL
-- to avoid repeating the same query structure.
use data_mart;
DELIMITER //

CREATE PROCEDURE analyze_sales_by_metric(IN metric_column VARCHAR(50))
BEGIN

    SET @sql = CONCAT(
        'WITH baseline AS (
            SELECT DISTINCT week_number
            FROM clean_weekly_sales
            WHERE calendar_year = ''2020''
              AND week_date = ''2020-06-15''
        ),

        weeks AS (
            SELECT
                ', metric_column, ',
                week_number,
                SUM(sales) AS total_sales
            FROM clean_weekly_sales
            WHERE calendar_year = ''2020''
              AND week_number BETWEEN
                  (SELECT week_number FROM baseline) - 12
                  AND
                  (SELECT week_number FROM baseline) + 11
            GROUP BY
                ', metric_column, ',
                week_number
        ),

        before_after AS (
            SELECT
                ', metric_column, ',

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
            GROUP BY ', metric_column, '
        )

        SELECT
            ', metric_column, ',
            sales_before,
            sales_after,
            sales_after - sales_before AS actual_change,
            (sales_after - sales_before)
                / sales_before * 100 AS percentage_change
        FROM before_after
        ORDER BY percentage_change;
    ');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END //

DELIMITER ;

CALL analyze_sales_by_metric('region');

CALL analyze_sales_by_metric('platform');

CALL analyze_sales_by_metric('age_band');

CALL analyze_sales_by_metric('demographic');

CALL analyze_sales_by_metric('customer_type');


-- for different combinations of business metrics without
-- repeating the same query structure.

DELIMITER //

CREATE PROCEDURE analyze_sales_by_metrics(
    IN metric_column_1 VARCHAR(50),
    IN metric_column_2 VARCHAR(50)
)
BEGIN

    SET @sql = CONCAT(

        'WITH baseline AS (
            SELECT DISTINCT
                week_number
            FROM clean_weekly_sales
            WHERE calendar_year = ''2020''
              AND week_date = ''2020-06-15''
        ),

        weeks AS (
            SELECT
                ', metric_column_1, ',
                ', metric_column_2, ',
                week_number,
                SUM(sales) AS total_sales
            FROM clean_weekly_sales
            WHERE calendar_year = ''2020''
              AND week_number BETWEEN
                  (SELECT week_number FROM baseline) - 12
                  AND
                  (SELECT week_number FROM baseline) + 11
            GROUP BY
                ', metric_column_1, ',
                ', metric_column_2, ',
                week_number
        ),

        before_after AS (
            SELECT
                ', metric_column_1, ',
                ', metric_column_2, ',

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
                ', metric_column_1, ',
                ', metric_column_2, '
        )

        SELECT
            ', metric_column_1, ',
            ', metric_column_2, ',
            sales_before,
            sales_after,
            sales_after - sales_before AS actual_change,
            (sales_after - sales_before)
                / sales_before * 100 AS percentage_change

        FROM before_after

        ORDER BY percentage_change;
    ');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END //

DELIMITER ;


-- Example 1: Analyze sales performance by region and platform

CALL analyze_sales_by_metrics('region', 'platform');


-- Example 2: Analyze sales performance by platform and customer type

CALL analyze_sales_by_metrics('platform', 'customer_type');