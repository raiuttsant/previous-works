WITH time AS (
  SELECT
  # timestamps using rider accepted at local
  DATETIME(datetime_start) AS datetime_start,
  DATETIME_SUB(DATETIME_ADD(DATETIME(datetime_start), INTERVAL 30 MINUTE), INTERVAL 1 MICROSECOND) AS datetime_end
  FROM 
  UNNEST(GENERATE_TIMESTAMP_ARRAY(
    DATETIME_SUB(DATETIME_TRUNC(CURRENT_TIMESTAMP(),DAY), INTERVAL 7 DAY),
    DATETIME_SUB(DATETIME_TRUNC(CURRENT_TIMESTAMP(),DAY), INTERVAL 1 MICROSECOND),
    INTERVAL 30 MINUTE)
  ) datetime_start
),
transitions_temp AS (
        SELECT
        datetime_start,
        datetime_end,
        lg_rider_starting_point_id,
        vehicle.name AS vehicle_name,
        rider.vendor.vertical_type AS vertical_type,
        # Metrics
        SUM(IF(ts.state = 'accepted', 1 ,0)) AS accepted_ct,
        SUM(IF(ts.state = 'courier_notified', 1 ,0)) AS notified_ct,
        COUNT(IF(ts.undispatch_type='manual_undispatch',ts.undispatch_type,NULL)) AS manual_undispatched_count
        FROM `fulfillment-dwh-production.pandata_curated.lg_orders` lgo,
        UNNEST(rider.deliveries) rd
        INNER JOIN time 
            ON rd.rider_accepted_at_local BETWEEN datetime_start AND datetime_end
        LEFT JOIN UNNEST (rd.transitions) ts
        WHERE created_date_utc >= '2022-1-1'
        AND lgo.global_entity_id = 'FP_HK'
        AND delivery_type = 'OWN_DELIVERY'
        GROUP BY 1,2,3,4,5
        ORDER BY 1,2,3,4,5
),
raw_lgo_metrics AS (
        SELECT
        datetime_start,
        datetime_end,
        lg_rider_starting_point_id,
        vehicle.name AS vehicle_name,
        rider.vendor.vertical_type AS vertical_type,
        # total orders
        COUNT(DISTINCT lgo.order_code) AS total_orders_count,
         # completed orders
        COUNT(DISTINCT IF(rider.order_status = 'completed',lgo.order_code,NULL)) AS completed_orders_count,
        # cancelled orders
        COUNT(DISTINCT IF(rider.order_status = 'cancelled',lgo.order_code,NULL)) AS cancelled_orders_count,
        # delayed orders 10 min+
        COUNT(DISTINCT IF(rd.delivery_delay_in_seconds/60 > 10, lgo.order_code,NULL)) AS delay_10_mins_count,
        # delayed orders 30 min+
        COUNT(DISTINCT IF(rd.delivery_delay_in_seconds/60 > 30, lgo.order_code,NULL)) AS delay_30_mins_count,
        # orders on time
        COUNT(DISTINCT IF(rd.delivery_delay_in_seconds/60 BETWEEN -10 AND 10, lgo.order_code,NULL)) AS  orders_on_time_count,
        # stacked delivery count
        COUNT(DISTINCT IF(rd.stacked_deliveries_count > 0, lgo.order_code,NULL)) AS stacked_delivery_count,
        # intravendor stacked delivery count
        COUNT(DISTINCT IF(is_stacked_intravendor = true, lgo.order_code,NULL)) AS intravendor_stacked_delivery_count,
        # delivery_time_total
        SUM(IF(is_preorder=false,rd.actual_delivery_time_in_seconds/60, NULL)) AS delivery_time_total,
        # delivery_time_count
        COUNT(DISTINCT IF(rd.actual_delivery_time_in_seconds IS NOT NULL AND is_preorder=false, lgo.order_code,NULL)) AS delivery_time_count,
        # pu_distance_total
        SUM(rd.pickup_distance_manhattan_in_meters/1000) AS pu_distance_total,
        # pu_distance_count
        COUNT(rd.pickup_distance_manhattan_in_meters) AS pu_distance_count,
        # pu_do_distance_total
        SUM(rd.delivery_distance_in_meters) AS pu_do_distance_total,
        # pu_do_distance_count
        COUNT(rd.delivery_distance_in_meters) AS pu_do_distance_count,
        # dispatching_time_total
        SUM(rd.dispatching_time_in_seconds/60) AS dispatching_time_total,
        # dispatching_time_count
        COUNT(rd.dispatching_time_in_seconds) AS dispatching_time_count,

        FROM `fulfillment-dwh-production.pandata_curated.lg_orders` lgo,
        UNNEST(rider.deliveries) rd
        INNER JOIN time 
            ON rd.rider_accepted_at_local BETWEEN datetime_start AND datetime_end
        WHERE created_date_utc >= '2022-1-1'
        AND lgo.global_entity_id = 'FP_HK'
        AND delivery_type = 'OWN_DELIVERY'
        GROUP BY 1,2,3,4,5
        ORDER BY 1,2,3,4,5
)
SELECT
  datetime_start,
  datetime_end,
  lg_rider_starting_point_id,
  vehicle_name,
  vertical_type,
  # from raw_lgo_metrics
  SUM(total_orders_count) AS total_orders,
  SUM(completed_orders_count) AS completed_orders,
  SUM(cancelled_orders_count) AS cancelled_orders,
  SUM(delay_10_mins_count) AS delay_10_mins,
  SUM(delay_30_mins_count) AS delay_30_mins,
  SUM(orders_on_time_count) AS orders_on_time,
  SUM(stacked_delivery_count) AS stacked_delivery,
  SUM(intravendor_stacked_delivery_count) AS intravendor_stacked_delivery,
  SUM(delivery_time_total) AS total_delivery_time,
  SUM(delivery_time_count) AS count_delivery_time,
  SUM(pu_distance_total) AS total_pu_distance,
  SUM(pu_distance_count) AS count_pu_distance,
  SUM(pu_do_distance_total) AS total_pu_do_distance,
  SUM(pu_do_distance_count) AS count_pu_do_distance,
  SUM(dispatching_time_total) AS total_dispatching_time,
  SUM(dispatching_time_count) AS count_dispatching_time, 

  # 3 metrics from transitions temporary table
  SUM(accepted_ct) AS accepted,
  SUM(notified_ct) AS notified,
  SUM(manual_undispatched_count) AS manual_dispatch
FROM raw_lgo_metrics
LEFT JOIN transitions_temp USING(datetime_start, datetime_end, lg_rider_starting_point_id, vehicle_name, vertical_type)
GROUP BY 1,2,3,4,5
ORDER BY 1,2,3,4,5
