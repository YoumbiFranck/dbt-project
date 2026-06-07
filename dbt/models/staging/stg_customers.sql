with source as (

    select * from {{ source('raw', 'customers') }}

),

renamed as (

    select
        id                              as customer_id,
        first_name,
        last_name,
        lower(trim(email))              as email,
        country,
        cast(created_at as date)        as created_at

    from source

    -- Exclure les lignes sans identifiant
    where id is not null

)

select * from renamed
