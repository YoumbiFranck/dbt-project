with products as (

    select * from {{ ref('stg_products') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

sales_metrics as (

    select
        product_id,
        sum(case when status = 'completed' then quantity      else 0 end) as total_quantity_sold,
        sum(case when status = 'completed' then order_total   else 0 end) as total_revenue

    from orders
    group by product_id

),

final as (

    select
        p.product_id,
        p.name,
        p.category,
        p.unit_price,
        p.is_active,
        coalesce(s.total_quantity_sold, 0)  as total_quantity_sold,
        coalesce(s.total_revenue, 0)        as total_revenue

    from products p
    left join sales_metrics s on p.product_id = s.product_id

    -- Seuls les produits actifs dans la dimension
    where p.is_active = true

)

select * from final
