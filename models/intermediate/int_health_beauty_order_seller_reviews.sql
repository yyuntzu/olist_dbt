-- models/intermediate/int_health_beauty_order_seller_reviews.sql
-- 目的：處理 review 一對多的重複計算問題
-- review 是綁在 order_id，但一個order可能有多個seller/多個品項
-- 這裡先把 health_beauty 的 order_id + seller_id 去重，
-- 再join review，確保一筆review在同一個seller底下只被算一次

with health_beauty_items as (
    select distinct
        order_id,
        seller_id,
        seller_state
    from {{ ref('int_health_beauty_order_items') }}
),

reviews as (
    select * from {{ ref('stg_reviews') }}
),

joined as (
    select
        hb.seller_state,
        hb.seller_id,
        hb.order_id,
        r.review_id,
        r.review_score
    from health_beauty_items hb
    inner join reviews r
        on hb.order_id = r.order_id
)

select * from joined