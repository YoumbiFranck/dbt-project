with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

final as (

    select
        o.order_id,
        o.customer_id,
        o.product_id,

        -- Attributs client dénormalisés
        c.first_name || ' ' || c.last_name     as customer_full_name,
        c.email                                 as customer_email,
        c.country                               as customer_country,

        -- Attributs produit dénormalisés
        p.name                                  as product_name,
        p.category                              as product_category,

        -- Mesures de la commande
        o.quantity,
        o.unit_price,
        o.order_total,
        o.status,
        o.ordered_at

    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join products  p on o.product_id  = p.product_id

)

select * from final
