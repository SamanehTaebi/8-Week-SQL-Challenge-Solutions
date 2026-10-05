WITH RECURSIVE hierarchy AS (

    -- Start from Style level
    SELECT
        p.product_id,
        p.price,
        ph.id,
        ph.parent_id,
        ph.level_text,
        ph.level_name
    FROM product_prices p
    INNER JOIN product_hierarchy ph
        ON p.id = ph.id
    WHERE ph.level_name = 'Style'

    UNION ALL

    -- Move up the hierarchy: Style → Segment → Category
    SELECT
        h.product_id,
        h.price,
        ph.id,
        ph.parent_id,
        ph.level_text,
        ph.level_name
    FROM hierarchy h
    INNER JOIN product_hierarchy ph
        ON h.parent_id = ph.id
),

product_attributes AS (

    SELECT
        product_id,
        MAX(price) AS price,

        MAX(
            CASE
                WHEN level_name = 'Category'
                THEN id
            END
        ) AS category_id,

        MAX(
            CASE
                WHEN level_name = 'Segment'
                THEN id
            END
        ) AS segment_id,

        MAX(
            CASE
                WHEN level_name = 'Style'
                THEN id
            END
        ) AS style_id,

        MAX(
            CASE
                WHEN level_name = 'Category'
                THEN level_text
            END
        ) AS category_name,

        MAX(
            CASE
                WHEN level_name = 'Segment'
                THEN level_text
            END
        ) AS segment_name,

        MAX(
            CASE
                WHEN level_name = 'Style'
                THEN level_text
            END
        ) AS style_name

    FROM hierarchy
    GROUP BY product_id
)

SELECT
    product_id,
    price,
    CONCAT(style_name, ' ', segment_name, ' - ', category_name) AS product_name,
    category_id,
    segment_id,
    style_id,
    category_name,
    segment_name,
    style_name
FROM product_attributes;