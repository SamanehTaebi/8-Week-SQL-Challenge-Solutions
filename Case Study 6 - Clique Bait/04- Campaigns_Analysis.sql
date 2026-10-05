-- Campaign Analysis: Create a single row for every unique visit_id

CREATE OR REPLACE VIEW clique_bait.campaign_visit_summary AS

WITH visit_summary AS (
    SELECT
        u.user_id,
        e.visit_id,
        MIN(e.event_time) AS visit_start_time,
        COUNT(CASE WHEN ei.event_name = 'Page View' THEN 1 END) AS page_views,
        COUNT(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 END) AS cart_adds,
        MAX(CASE WHEN ei.event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
        COUNT(CASE WHEN ei.event_name = 'Ad Impression' THEN 1 END) AS impression,
        COUNT(CASE WHEN ei.event_name = 'Ad Click' THEN 1 END) AS click
    FROM events e
    INNER JOIN users u
        ON e.cookie_id = u.cookie_id
    INNER JOIN event_identifier ei
        ON e.event_type = ei.event_type
    GROUP BY
        u.user_id,
        e.visit_id
),

cart_products AS (
    SELECT
        e.visit_id,
        GROUP_CONCAT(
            ph.page_name
            ORDER BY e.sequence_number
            SEPARATOR ', '
        ) AS cart_products
    FROM events e
    INNER JOIN page_hierarchy ph
        ON e.page_id = ph.page_id
    INNER JOIN event_identifier ei
        ON e.event_type = ei.event_type
    WHERE ei.event_name = 'Add to Cart'
    GROUP BY e.visit_id
)

SELECT
    vs.user_id,
    vs.visit_id,
    vs.visit_start_time,
    vs.page_views,
    vs.cart_adds,
    vs.purchase,
    ci.campaign_name,
    vs.impression,
    vs.click,
    cp.cart_products
FROM visit_summary vs
LEFT JOIN campaign_identifier ci
    ON vs.visit_start_time BETWEEN ci.start_date AND ci.end_date
LEFT JOIN cart_products cp
    ON vs.visit_id = cp.visit_id;
    
    

-- Compare users who received impressions during each campaign
-- period with users who did not receive impressions.

SELECT
    campaign_name,

    CASE
        WHEN impression > 0 THEN 'Impression'
        ELSE 'No Impression'
    END AS impression_group,

    COUNT(DISTINCT user_id) AS users,
    SUM(page_views) AS page_views,
    SUM(cart_adds) AS cart_adds,
    SUM(purchase) AS purchases,
    SUM(click) AS clicks

FROM campaign_visit_summary

WHERE campaign_name IS NOT NULL

GROUP BY
    campaign_name,
    CASE
        WHEN impression > 0 THEN 'Impression'
        ELSE 'No Impression'
    END

ORDER BY
    campaign_name,
    impression_group;
    
    
-- Does clicking on an impression lead to higher purchase rates?  
WITH user_campaign AS (
    SELECT
        campaign_name,
        user_id,
        SUM(click) AS total_clicks,
        SUM(purchase) AS total_purchases
    FROM campaign_visit_summary
    WHERE campaign_name IS NOT NULL
      AND impression > 0
    GROUP BY
        campaign_name,
        user_id
)

SELECT
    campaign_name,

    CASE
        WHEN total_clicks > 0 THEN 'Clicked'
        ELSE 'Not Clicked'
    END AS click_group,

    COUNT(*) AS users,

    SUM(
        CASE
            WHEN total_purchases > 0 THEN 1
            ELSE 0
        END
    ) AS purchasers,

    ROUND(
        100 * SUM(
            CASE
                WHEN total_purchases > 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS purchase_rate

FROM user_campaign

GROUP BY
    campaign_name,
    CASE
        WHEN total_clicks > 0 THEN 'Clicked'
        ELSE 'Not Clicked'
    END

ORDER BY
    campaign_name,
    click_group;
    
    
    

-- What is the uplift in purchase rate when comparing users
-- who click on a campaign impression versus users who do not
-- receive an impression?
-- What if we compare them with users who received an impression
-- but did not click?

WITH user_campaign AS (
    SELECT
        campaign_name,
        user_id,
        SUM(impression) AS total_impressions,
        SUM(click) AS total_clicks,
        SUM(purchase) AS total_purchases
    FROM campaign_visit_summary
    WHERE campaign_name IS NOT NULL
    GROUP BY
        campaign_name,
        user_id
),

group_purchase_rate as(SELECT
    campaign_name,

    CASE
        WHEN total_impressions > 0 AND total_clicks > 0
            THEN 'Impression + Click'
        WHEN total_impressions > 0 AND total_clicks = 0
            THEN 'Impression + No Click'
        WHEN total_impressions = 0
            THEN 'No Impression'
    END AS user_group,

    ROUND(
        100 * SUM(
            CASE
                WHEN total_purchases > 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS purchase_rate

FROM user_campaign

GROUP BY
    campaign_name,
    CASE
        WHEN total_impressions > 0 AND total_clicks > 0
            THEN 'Impression + Click'
        WHEN total_impressions > 0 AND total_clicks = 0
            THEN 'Impression + No Click'
        WHEN total_impressions = 0
            THEN 'No Impression'
    END),
purchase_rates as(SELECT
    campaign_name,

    MAX(
        CASE
            WHEN user_group = 'Impression + Click'
            THEN purchase_rate
        END
    ) AS click_rate,

    MAX(
        CASE
            WHEN user_group = 'Impression + No Click'
            THEN purchase_rate
        END
    ) AS no_click_rate,

    MAX(
        CASE
            WHEN user_group = 'No Impression'
            THEN purchase_rate
        END
    ) AS no_impression_rate

FROM group_purchase_rate

GROUP BY campaign_name)
SELECT
    campaign_name,

    ROUND(
        (click_rate - no_impression_rate)
        / no_impression_rate * 100,
        2
    ) AS uplift1,

    ROUND(
        (click_rate - no_click_rate)
        / no_click_rate * 100,
        2
    ) AS uplift2

FROM purchase_rates;
