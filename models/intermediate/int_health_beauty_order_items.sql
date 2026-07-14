-- models/intermediate/int_health_beauty_order_items.sql
-- 目的：篩出 health_beauty 品類的訂單品項，並關聯上賣家州別
-- 這是整個專案的核心篩選層，後面 marts 都以這張表為基礎，
-- 未來如果要換分析品類，只需要改這裡的 category filter

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

sellers as (
    select * from {{ ref('stg_sellers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

filtered as (
    select
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        s.seller_state,
        o.order_status,
        o.order_purchase_ts,
        o.actual_delivery_days,
        o.estimated_delivery_days,
        o.is_late_delivery
    from order_items oi
    inner join products p
        on oi.product_id = p.product_id
        and p.category_name_en = 'health_beauty'
    left join sellers s
        on oi.seller_id = s.seller_id
    left join orders o
        on oi.order_id = o.order_id
)

select * from filtered
