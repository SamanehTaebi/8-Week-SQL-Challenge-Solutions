CREATE VIEW product_funnel AS

WITH cart_events AS (
    SELECT 
        ev.visit_id,
        ev.page_id,
        ev.sequence_number AS cart_seq
    FROM events ev
    INNER JOIN event_identifier ei
        ON ev.event_type = ei.event_type
    WHERE ei.event_name = 'Add to Cart'
),

purchase_events AS (
    SELECT 
        ev.visit_id,
        ev.sequence_number AS purchase_seq
    FROM events ev
    INNER JOIN event_identifier ei
        ON ev.event_type = ei.event_type
    WHERE ei.event_name = 'Purchase'
),

cart_status AS (
    SELECT 
        ce.visit_id,
        ce.page_id,
        ph.page_name,
        ph.product_id,
        ce.cart_seq,
        pe.purchase_seq,
        CASE 
            WHEN pe.purchase_seq IS NULL THEN 'abandoned' 
            ELSE 'purchased' 
        END AS cart_status 
    FROM cart_events ce
    LEFT JOIN purchase_events pe
        ON ce.visit_id = pe.visit_id
        AND ce.cart_seq < pe.purchase_seq
    INNER JOIN page_hierarchy ph
        ON ce.page_id = ph.page_id
),

cart_counts AS (
    SELECT
        page_id,
        page_name,
        product_id,
        COUNT(*) AS cart_add_count,
        SUM(CASE WHEN cart_status = 'purchased' THEN 1 ELSE 0 END) AS purchased_count,
        SUM(CASE WHEN cart_status = 'abandoned' THEN 1 ELSE 0 END) AS abandoned_count
    FROM cart_status
    GROUP BY page_id, page_name, product_id
),

view_events AS (
    SELECT 
        ev.visit_id,
        ev.page_id,
        ph.page_name
    FROM events ev
    INNER JOIN event_identifier ei
        ON ev.event_type = ei.event_type
    INNER JOIN page_hierarchy ph
        ON ev.page_id = ph.page_id
    WHERE ei.event_name = 'Page View'
      AND ph.product_id IS NOT NULL
),

view_counts AS (
    SELECT
        page_id,
        page_name,
        COUNT(*) AS view_count
    FROM view_events
    GROUP BY page_id, page_name
)

SELECT
    vc.page_id,
    cc.product_id,
    vc.page_name as product_name,
    vc.view_count,
    cc.cart_add_count,
    cc.purchased_count,
    cc.abandoned_count
FROM view_counts vc
LEFT JOIN cart_counts cc
    ON vc.page_id = cc.page_id;
    
    
CREATE VIEW category_funnel AS

SELECT
    ph.product_category,
    SUM(pf.view_count) AS view_count,
    SUM(pf.cart_add_count) AS cart_add_count,
    SUM(pf.purchased_count) AS purchased_count,
    SUM(pf.abandoned_count) AS abandoned_count
FROM product_funnel pf
INNER JOIN page_hierarchy ph
    ON pf.page_id = ph.page_id
GROUP BY ph.product_category;
    

-- 1. Which product had the most views, cart adds and purchases?
SELECT 'Most Views' AS metric,
       product_name,
       view_count AS value
FROM product_funnel
WHERE view_count = (SELECT MAX(view_count) FROM product_funnel)

UNION ALL

SELECT 'Most Cart Adds',
       product_name,
       cart_add_count
FROM product_funnel
WHERE cart_add_count = (SELECT MAX(cart_add_count) FROM product_funnel)

UNION ALL

SELECT 'Most Purchases',
       product_name,
       purchased_count
FROM product_funnel
WHERE purchased_count = (SELECT MAX(purchased_count) FROM product_funnel);



-- 2. Which product was most likely to be abandoned?

SELECT
    product_name,
    abandoned_count / cart_add_count * 100 AS abandonment_rate
FROM product_funnel
ORDER BY abandonment_rate DESC;



-- 3. Which product had the highest view to purchase percentage?

SELECT
    product_name,
    purchased_count / view_count * 100 AS view_to_purchase_rate
FROM product_funnel
ORDER BY view_to_purchase_rate DESC;



-- 4. What is the average conversion rate from view to cart add?

SELECT
    AVG(cart_add_count / view_count * 100) AS avg_conversion_rate
FROM product_funnel;



-- 5. What is the average conversion rate from cart add to purchase?

SELECT
    AVG(purchased_count / cart_add_count * 100) AS avg_conversion_rate
FROM product_funnel;

select * from product_funnel;
