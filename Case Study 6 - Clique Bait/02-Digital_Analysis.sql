-- 1. How many users are there?

SELECT COUNT(DISTINCT user_id)
FROM users;


-- 2. How many cookies does each user have on average?

WITH user_cookie_counts AS (
    SELECT 
        user_id,
        COUNT(DISTINCT cookie_id) AS cookie_count
    FROM users
    GROUP BY user_id
)
SELECT AVG(cookie_count) AS average_cookies_per_user
FROM user_cookie_counts;


-- 3. What is the unique number of visits by all users per month?

SELECT 
    MONTH(event_time) AS month,
    COUNT(DISTINCT visit_id) AS unique_visits
FROM events
GROUP BY MONTH(event_time)
ORDER BY MONTH(event_time);


-- 4. What is the number of events for each event type?

SELECT 
    event_type,
    COUNT(event_type) AS event_count
FROM events
GROUP BY event_type;


-- 5. What is the percentage of visits which have a purchase event?

WITH purchase_visits AS (
    SELECT COUNT(DISTINCT visit_id) AS purchase_visit_count
    FROM events ev
    INNER JOIN event_identifier ei
        ON ev.event_type = ei.event_type
    WHERE ei.event_name = 'Purchase'
)
SELECT 
    purchase_visit_count /
    (SELECT COUNT(DISTINCT visit_id) FROM events) * 100
    AS purchase_visit_percentage
FROM purchase_visits;




-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH checkout_visits_without_purchase AS (
    SELECT DISTINCT visit_id
    FROM events ev
    INNER JOIN page_hierarchy ph
        ON ev.page_id = ph.page_id
    WHERE ph.page_name = 'Checkout'
      AND NOT EXISTS (
          SELECT 1
          FROM events ev2
          INNER JOIN event_identifier ei
              ON ev2.event_type = ei.event_type
          WHERE ei.event_name = 'Purchase'
            AND ev2.visit_id = ev.visit_id
      )
)
SELECT 
    COUNT(DISTINCT visit_id) /
    (SELECT COUNT(DISTINCT visit_id) FROM events) * 100
    AS checkout_without_purchase_percentage
FROM checkout_visits_without_purchase;


-- 7. What are the top 3 pages by number of views?

SELECT 
    ph.page_id,
    ph.page_name,
    COUNT(ev.visit_id) AS view_count
FROM events ev
INNER JOIN page_hierarchy ph
    ON ev.page_id = ph.page_id
GROUP BY 
    ph.page_id,
    ph.page_name
ORDER BY view_count DESC
LIMIT 3;


-- 8. What is the number of views and cart adds for each product category?

SELECT 
    ph.product_category,
    COUNT(CASE WHEN ei.event_name = 'Page View' THEN 1 END) AS view_count,
    COUNT(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 END) AS cart_add_count
FROM events ev
INNER JOIN event_identifier ei
    ON ev.event_type = ei.event_type
INNER JOIN page_hierarchy ph
    ON ev.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category;


SELECT 
    ph.product_category,
    ph.product_id,
    COUNT(ev.visit_id) AS purchase_count
FROM events ev
INNER JOIN page_hierarchy ph
    ON ev.page_id = ph.page_id
inner join event_identifier ei
on ev.event_type= ei.event_type
where ei.event_name='Purchase'
GROUP BY 
    ph.product_id,
    ph.product_category
ORDER BY purchase_count DESC
LIMIT 3;



-- 9. What are the top 3 products by purchases?

SELECT 
    ph.product_id,
    ph.page_name AS product_name,
    COUNT(ev.visit_id) AS purchase_count
FROM events ev
INNER JOIN page_hierarchy ph
    ON ev.page_id = ph.page_id
INNER JOIN event_identifier ei
    ON ev.event_type = ei.event_type
WHERE ei.event_name = 'Purchase'
GROUP BY 
    ph.product_id,
    ph.page_name
ORDER BY purchase_count DESC
LIMIT 3;

select ph.page_id,
    COUNT(CASE WHEN ei.event_name = 'Purchase' 
    THEN 1 END) AS purchase_count,
    COUNT(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 END) AS cart_add_count,
    count(CASE WHEN ei.event_name = 'Page View' THEN 1 END ) AS view_count
from events ev inner join page_hierarchy ph
on ev.page_id = ph.page_id
inner join event_identifier ei
on ev.event_type= ei.event_type
group by ph.page_id;