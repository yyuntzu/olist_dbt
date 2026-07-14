select
 seller_state,
 avg(lat) as state_lat,
 avg(lng) as state_lng
from {{ ref('stg_geolocation') }}
group by seller_state