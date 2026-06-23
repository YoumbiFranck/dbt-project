SELECT
    order_date,
    region,
    COUNT(*) as order_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as avg_order_value
FROM {{ source('raw', 'orders_exercise') }}
WHERE order_date = '{{ var("analysis_date") }}'
  AND status = '{{ var("order_status") }}'
  {% if var("target_region") != 'All' %}
  AND region = '{{ var("target_region") }}'
  {% endif %}
GROUP BY order_date, region