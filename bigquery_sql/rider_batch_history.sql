WITH array_batches AS (
SELECT lgr.id, lgr.uuid, lgr.lg_country_code, b.number, b.active_from_local, b.active_until_local FROM 
`fulfillment-dwh-production.pandata_curated.lg_riders` lgr
LEFT JOIN UNNEST(batches) b
WHERE (lg_country_code = 'hk' OR lg_country_code = 'dp-hk')
)
SELECT rd.rider_accepted_at_local, rd.lg_rider_id, ab.number AS batch_number 
FROM `fulfillment-dwh-production.pandata_curated.lg_orders` lgo
LEFT JOIN UNNEST(rider.deliveries) rd
LEFT JOIN array_batches ab
ON ab.id = rd.lg_rider_id
WHERE created_date_utc >= '2021-01-01'
AND rider.order_status = 'completed'
AND rider.vendor.vertical_type = 'fashion'
AND rd.rider_accepted_at_local 
BETWEEN ab.active_from_local AND ab.active_until_local
ORDER BY 2,1
