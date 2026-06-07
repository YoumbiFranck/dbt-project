with source as (

    select * from {{ source('raw', 'orders') }}

),

renamed as (

    select
        id                                          as order_id,
        customer_id,
        product_id,
        quantity,
        cast(unit_price as numeric(10, 2))          as unit_price,
        quantity * cast(unit_price as numeric(10, 2)) as order_total,
        lower(trim(status))                         as status,
        cast(ordered_at as date)                    as ordered_at

    from source

    where id is not null

)

select * from renamed
