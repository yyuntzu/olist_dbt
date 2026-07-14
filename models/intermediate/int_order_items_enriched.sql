with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

sellers as (
    select * from {{ ref('stg_sellers') }}
)

select
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    p.category_name_pt,
    p.category_name_en as category,
    s.seller_state,
    s.seller_city
from order_items oi
left join products p
    on oi.product_id = p.product_id
left join sellers s
    on oi.seller_id = s.seller_id