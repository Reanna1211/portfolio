-- To create the subscriptions table, ensuring the correct data types are used
CREATE TABLE subscriptions (
    id INT PRIMARY KEY,                        -- Unique identifier for each subscription
    subscription_start DATE,                   -- Start date of the subscription
    subscription_end VARCHAR(255) NULL,                -- End date of the subscription (NULL if still active)
    segment INT                                -- Segment type (e.g., 87, 30)
);

-- --------------------------------------------------------------
-- CLEANING DATA: Ensure subscription_end column is free from invalid or empty values
-- --------------------------------------------------------------

-- To check for rows with invalid date formats in subscription_end
SELECT id, subscription_end
FROM subscriptions
WHERE STR_TO_DATE(subscription_end, '%Y-%m-%d') IS NULL;

-- To replace invalid date strings (empty or non-date values) with NULL
UPDATE subscriptions
SET subscription_end = NULL
WHERE subscription_end = '';  -- Empty strings are set to NULL

-- To disable safe updates to allow mass updates (used cautiously)
SET SQL_SAFE_UPDATES = 0;

-- If needed, could have cleaned up invalid date values with:
-- UPDATE subscriptions
-- SET subscription_end = NULL
-- WHERE STR_TO_DATE(subscription_end, '%Y-%m-%d') IS NULL;

-- But only empty spaces where found, all other values were the correct date format.

-- to check if the data was cleaned correctly
SELECT *
FROM subscriptions;

-- To re-enable safe updates to prevent accidental mass updates in future queries
SET SQL_SAFE_UPDATES = 1;

-- --------------------------------------------------------------
-- CHURN RATE CALCULATION: 
-- In this analysis, we calculate the churn rate for different customer segments over three months (Jan-Mar 2017).
-- The churn rate is calculated as the percentage of canceled subscriptions out of the total active subscriptions.

-- --------------------------------------------------------------

-- To create a series of months (January to March) for churn calculation
-- WITH months AS (
--   SELECT '2017-01-01' AS first_day, '2017-01-31' AS last_day
--   UNION
--   SELECT '2017-02-01', '2017-02-28'
--   UNION
--   SELECT '2017-03-01', '2017-03-31'
-- ), 

-- -- To cross join months with subscriptions to get combinations for each month
-- cross_join AS (
--   SELECT *
--   FROM subscriptions
--   CROSS JOIN months
-- ), 

-- -- To calculate whether each subscription is active or canceled based on subscription_start and subscription_end
-- status AS (
--   SELECT first_day AS month, 
--     CASE 
--       WHEN (segment = 87) AND (subscription_start < first_day) AND 
--            ((subscription_end >= first_day) OR (subscription_end IS NULL)) THEN 1
--       ELSE 0
--     END AS is_active_87,
--     
--     CASE 
--       WHEN (segment = 30) AND (subscription_start < first_day) AND 
--            ((subscription_end >= first_day) OR (subscription_end IS NULL)) THEN 1
--       ELSE 0
--     END AS is_active_30,
--     
--     CASE 
--       WHEN (segment = 87) AND (subscription_start < first_day) AND 
--            (subscription_end BETWEEN first_day AND last_day) THEN 1
--       ELSE 0
--     END AS is_canceled_87,
--     
--     CASE 
--       WHEN (segment = 30) AND (subscription_start < first_day) AND 
--            (subscription_end BETWEEN first_day AND last_day) THEN 1
--       ELSE 0
--     END AS is_canceled_30
--   FROM cross_join
-- ), 

-- -- To aggregate results by month to calculate the total active and canceled subscriptions for each segment
-- status_aggregate AS (
--   SELECT 
--     month, 
--     SUM(is_active_87) AS sum_active_87, 
--     SUM(is_active_30) AS sum_active_30, 
--     SUM(is_canceled_87) AS sum_canceled_87, 
--     SUM(is_canceled_30) AS sum_canceled_30
--   FROM status
--   GROUP BY month
-- )

-- -- Final query to calculate the churn rate for each segment
-- SELECT 
--   month, 
--   (1.0 * sum_canceled_87 / sum_active_87) * 100 AS churn_rate_87, 
--   (1.0 * sum_canceled_30 / sum_active_30) * 100 AS churn_rate_30
-- FROM status_aggregate
-- ORDER BY month;


-- -------------------------------------------------------------
-- CHURN RATE CALCULATION FOR MULTIPLE SEGMENTS:
-- If we had more than 2 segments and wanted to calculate churn 
-- rates for each, we could modify the code as shown below.
-- This is based on the earlier example with only 2 segments, 
-- but it can be easily extended to accommodate multiple segments.
-- -------------------------------------------------------------

-- Define months to cover the period from January to March.
WITH months AS (
  SELECT '2017-01-01' AS first_day, '2017-01-31' AS last_day
  UNION
  SELECT '2017-02-01' AS first_day, '2017-02-28' AS last_day
  UNION
  SELECT '2017-03-01' AS first_day, '2017-03-31' AS last_day
), 

-- Cross join the subscriptions table with the months to get 
-- combinations of each subscription with the months in the period.
cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
),

-- Calculate whether each subscription is active or canceled based on 
-- subscription_start and subscription_end for each month.
status AS (
  SELECT id, segment, first_day AS month, 
    -- Check if the subscription is active for a given month
    CASE 
      WHEN (subscription_start < first_day)
      AND ((subscription_end >= first_day) OR (subscription_end IS NULL)) 
      THEN 1 
      ELSE 0 
    END AS is_active,
    
    -- Check if the subscription was canceled during the month
    CASE 
      WHEN (subscription_start < first_day)
      AND (subscription_end BETWEEN first_day AND last_day)
      THEN 1 
      ELSE 0 
    END AS is_canceled
  FROM cross_join
),

-- Aggregate the results by segment and month to calculate 
-- the total active and canceled subscriptions for each segment and month.
status_aggregate AS (
  SELECT segment, month, 
         SUM(is_active) AS sum_active, 
         SUM(is_canceled) AS sum_canceled
  FROM status
  GROUP BY segment, month
)

-- Final query to calculate the churn rate for each segment, 
-- based on the total active and canceled subscriptions.
SELECT segment, month, 
       (1.0 * sum_canceled / sum_active) * 100 AS churn_rate
FROM status_aggregate
ORDER BY segment, month;


-- -------------------------------------------------------------
-- ACTIONABLE INSIGHTS:
-- After calculating churn rates for each segment, we can derive the following insights:
-- 1. Segment 87 has a significantly higher churn rate compared to Segment 30. This suggests that Segment 87 might be less satisfied, and strategies such as personalized retention efforts, promotions, or feedback solicitation should be considered.
-- 2. Churn rates are increasing towards March, which could signal seasonality. Implementing retention campaigns (e.g., discounts, extended trials) during this period might help reduce churn.
-- 3. Segment 30 has a lower churn rate, indicating that this group might be more engaged. Consider analyzing what makes Segment 30 more loyal and try to replicate those strategies for Segment 87.
-- 
-- Based on these insights, the following actions are recommended:
-- - Develop targeted retention strategies for Segment 87 to improve engagement.
-- - Consider implementing seasonal campaigns to reduce churn during March.
-- - Conduct further analysis to identify features that increase retention in Segment 30 and apply those learnings to other segments.

