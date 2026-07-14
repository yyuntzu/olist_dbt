with source as (
    select * from {{ source('olist_raw', 'geolocation') }}
)

select
    geolocation_zip_code_prefix as zip_code_prefix,
    geolocation_lat as lat,
    geolocation_lng as lng,
    lower(geolocation_city) as city,
    geolocation_state as seller_state
from source