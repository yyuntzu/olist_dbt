-- models/staging/stg_order_items.sql
-- 目的：訂單品項明細，一列 = 一個order裡的一個商品

with source as (
    select * from {{ source('olist_raw', 'order_items') }}
),

cleaned as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        price,
        freight_value
    from source
)

select * from cleaned