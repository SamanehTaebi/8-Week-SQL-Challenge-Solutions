USE foodie_fi;

-- A. Customer Journey
-- For each customer, identify their subscription journey
-- by joining subscriptions table with plans table
-- to display the plan names instead of plan IDs.

SELECT
    s.customer_id,
    p.plan_name,
    s.start_date
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p
    ON s.plan_id = p.plan_id
ORDER BY
    s.customer_id,
    s.start_date;


-- Customer Journey Analysis:
--
-- Customer 1:
-- Started with a 7-day free trial and then subscribed to the Basic Monthly plan.
--
-- Customer 2:
-- Started with a 7-day free trial and upgraded directly to the Pro Annual plan.
--
-- Customer 11:
-- Started with a 7-day free trial and cancelled the subscription after the trial period.
--
-- Customer 13:
-- Started with a 7-day free trial, subscribed to the Basic Monthly plan,
-- and later upgraded to the Pro Monthly plan.

