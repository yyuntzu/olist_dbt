-- models/staging/stg_sellers.sql

with source as (
    select * from {{ source('olist_raw', 'sellers') }}
),

cleaned as (
    select
        seller_id,
        seller_state,
        seller_city
    from source
)

select * from cleaned