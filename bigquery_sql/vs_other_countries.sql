SELECT 
 --  monthly basis, also convert from string to datetime
  EXTRACT(YEAR FROM CAST(created_date_utc AS DATETIME)) AS year,
  EXTRACT(MONTH FROM CAST(created_date_utc AS DATETIME)) AS month,
  global_entity_id AS region,
 --   group by different verticals
  CASE WHEN rider.vendor.vertical_type IN ('darkstores','restaurants') 
    THEN rider.vendor.vertical_type
    WHEN rider.vendor.vertical_type IN ('courier_business')  
    THEN 'pandago'
    WHEN rider.vendor.vertical_type IN ('caterers')  
    THEN 'caterers'
    ELSE 'shops' END AS vertical_type,
 --   aggregate order numbers
  COUNT(DISTINCT lgo.order_code) AS order_number
FROM `fulfillment-dwh-production.pandata_curated.lg_orders` lgo
LEFT JOIN UNNEST(rider.deliveries) rd
WHERE created_date_utc >= '2022-01-01'
    AND DATE(rd.rider_accepted_at_local) >= '2022-01-01'
--  list of countries
    AND global_entity_id IN ('FP_HK', 'FP_SG', 'FP_TW', 'FP_MY', 'FP_PH','FP_TH', 'FP_PK')
    AND rider.order_status = 'completed'
    AND delivery_type = 'OWN_DELIVERY'
GROUP BY 1,2,3,4
ORDER BY year, month, region, order_number DESC
