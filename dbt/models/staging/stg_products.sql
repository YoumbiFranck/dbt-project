with source as (

    select * from {{ source('raw', 'products') }}

),

renamed as (

    select
        id                                      as product_id,
        trim(name)                              as name,
        trim(category)                          as category,
        cast(unit_price as numeric(10, 2))      as unit_price,
        case
            when lower(is_active) = 'true'  then true
            when lower(is_active) = 'false' then false
            else null
        end                                     as is_active

    from source

    where id is not null

)

select * from renamed
