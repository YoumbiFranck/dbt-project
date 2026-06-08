SELECT
    order_date,
    region,
    COUNT(*) as order_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as avg_order_value
FROM {{ source('raw', 'orders_exercise') }}
WHERE order_date = '2024-01-15'
  AND status = 'completed'
  AND region = 'North'
GROUP BY order_date, region