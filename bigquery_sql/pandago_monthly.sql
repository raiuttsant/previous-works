WITH date_bucket AS (
  SELECT
    date AS actual_date,
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month
  FROM UNNEST(GENERATE_DATE_ARRAY('2020-01-01', '2025-12-31')) AS date
  ORDER BY date),

updated_month AS (
  SELECT 
    CASE 
      WHEN rider.vendor.name LIKE '%McDonald%' THEN 'McDonalds'
      WHEN rider.vendor.name LIKE '%KFC%' THEN 'KFC'
      WHEN rider.vendor.name LIKE '%Pizza Hut%' OR rider.vendor.name LIKE '%PHD%' THEN 'Pizza Hut/PHD'
      -- WHEN rider.vendor.name LIKE '%PHD%' THEN 'PHD'
      WHEN rider.vendor.name LIKE '%FLASH COFFEE%' THEN 'Flash Coffee'
      WHEN rider.vendor.name LIKE '%Watsons%' THEN 'Watsons'
      ELSE 'Others' END AS vendor,
  year,
  month,
  # order number
  COUNT(DISTINCT lgo.order_code) AS order_number,
  # average delivery fee
  AVG(rider.delivery_fee_local/100) AS delivery_fee,
  # average delivery time
  AVG((rd.actual_delivery_time_in_seconds/60)) AS delivery_time_min_avg,
  # 30 min lateness
  COUNT(DISTINCT IF(rd.delivery_delay_in_seconds/60 > 30,lgo.order_code,NULL))/
  COUNT(DISTINCT lgo.order_code) AS late_by_30_min
  FROM `fulfillment-dwh-production.pandata_curated.lg_orders` lgo
  LEFT JOIN UNNEST(rider.deliveries) rd
  LEFT JOIN date_bucket
  ON DATE(rd.rider_accepted_at_local) = actual_date
  WHERE created_date_utc >= '2022-01-01'
    AND DATE(rd.rider_accepted_at_local) BETWEEN '2022-01-01' AND CURRENT_DATE()
    AND global_entity_id = 'FP_HK'
    AND rider.order_status = 'completed'
    AND rider.vendor.vertical_type = 'courier_business'
    AND NOT is_preorder
  GROUP BY vendor, year, month
  ORDER BY year, month, order_number DESC
  ),

prev_month AS (
SELECT 
  CASE 
    WHEN rider.vendor.name LIKE '%McDonald%' THEN 'McDonalds'
    WHEN rider.vendor.name LIKE '%KFC%' THEN 'KFC'
    WHEN rider.vendor.name LIKE '%Pizza Hut%' OR rider.vendor.name LIKE '%PHD%' THEN 'Pizza Hut/PHD'
    -- WHEN rider.vendor.name LIKE '%PHD%' THEN 'PHD'
    WHEN rider.vendor.name LIKE '%FLASH COFFEE%' THEN 'Flash Coffee'
    WHEN rider.vendor.name LIKE '%Watsons%' THEN 'Watsons'
    ELSE 'Others' END AS vendor,
EXTRACT(YEAR FROM DATE_ADD(actual_date, INTERVAL 1 MONTH)) AS next_period_year,
EXTRACT(MONTH FROM DATE_ADD(actual_date, INTERVAL 1 MONTH)) AS next_period_month,
year,
month,
# order number
COUNT(DISTINCT lgo.order_code) AS prev_order_number,
# average delivery fee
AVG(rider.delivery_fee_local/100) AS prev_delivery_fee,
# average delivery time
AVG((rd.actual_delivery_time_in_seconds/60)) AS prev_delivery_time_min_avg,
# 30 min lateness
COUNT(DISTINCT IF(rd.delivery_delay_in_seconds/60 > 30,lgo.order_code,NULL))/
COUNT(DISTINCT lgo.order_code) AS prev_late_by_30_min
FROM `fulfillment-dwh-production.pandata_curated.lg_orders` lgo
LEFT JOIN UNNEST(rider.deliveries) rd
LEFT JOIN date_bucket
ON DATE(rd.rider_accepted_at_local) = actual_date
WHERE created_date_utc >= '2022-01-01'
  AND DATE(rd.rider_accepted_at_local) BETWEEN '2022-01-01' AND CURRENT_DATE()
  AND global_entity_id = 'FP_HK'
  AND rider.order_status = 'completed'
  AND rider.vendor.vertical_type = 'courier_business'
  AND NOT is_preorder
GROUP BY vendor, year, month,
next_period_year, next_period_month
ORDER BY 
next_period_year, next_period_month, 
year, month, prev_order_number DESC
)

SELECT 
  updated_month.vendor, updated_month.year, updated_month.month, 
  -- next_period_year, next_period_month,
  order_number, delivery_fee, delivery_time_min_avg, late_by_30_min,
  prev_order_number, prev_delivery_fee, prev_delivery_time_min_avg, prev_late_by_30_min
FROM updated_month
LEFT JOIN prev_month
ON 
updated_month.vendor = prev_month.vendor AND
updated_month.year = prev_month.next_period_year AND
updated_month.month = prev_month.next_period_month
ORDER BY year, month, vendor
