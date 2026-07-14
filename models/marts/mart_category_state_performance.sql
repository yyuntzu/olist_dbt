-- models/marts/mart_category_state_performance.sql
-- 目的:Health & Beauty 品類,各州賣家經營表現總覽
-- 用於 Looker Studio:週轉率、定價、評分、配送四個維度的排除法分析

with order_items_enriched as (
    select * from {{ ref('int_order_items_enriched') }}
    where category = 'health_beauty'
),

reviews_deduped as (
    select * from {{ ref('int_reviews_deduped') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

-- 1. 營收/週轉率
revenue_metrics as (
    select
        seller_state,
        count(distinct seller_id) as seller_count,
        count(order_item_id) as item_count,
        count(distinct order_id) as order_count,
        sum(price) as total_revenue,
        safe_divide(sum(price), count(distinct seller_id)) as revenue_per_seller,
        safe_divide(count(order_item_id), count(distinct seller_id)) as items_per_seller
    from order_items_enriched
    group by seller_state
),

-- 2. 定價
pricing_metrics as (
    select
        seller_state,
        round(avg(price), 2) as avg_item_price,
        round(approx_quantiles(price, 2)[offset(1)], 2) as median_price,
        round(avg(freight_value), 2) as avg_freight
    from order_items_enriched
    group by seller_state
),

-- 3. 評分(先去重到 order+seller+product 粒度,避免重複計算)
review_metrics as (
    select
        oie.seller_state,
        count(distinct rd.review_id) as review_count,
        round(avg(rd.review_score), 2) as avg_review_score
    from reviews_deduped rd
    inner join (
        select distinct order_id, seller_id, product_id, seller_state
        from order_items_enriched
    ) oie
        on rd.order_id = oie.order_id
        and rd.seller_id = oie.seller_id
        and rd.product_id = oie.product_id
    group by oie.seller_state
),

-- 4. 配送時間
-- 4. 配送時間
delivery_metrics as (
    select
        oie.seller_state,
        count(distinct o.order_id) as delivered_order_count,
        round(avg(o.actual_delivery_days), 1) as avg_delivery_days,
        round(avg(o.estimated_delivery_days), 1) as avg_estimated_days,
        round(avg(o.actual_delivery_days - o.estimated_delivery_days), 1) as avg_days_vs_estimate,
        round(100 * sum(case when o.is_late_delivery then 1 else 0 end) / count(*), 1) as late_delivery_pct
    from orders o
    inner join (
        select distinct order_id, seller_state
        from order_items_enriched
    ) oie
        on o.order_id = oie.order_id
    where o.order_status = 'delivered'
        and o.order_delivered_ts is not null
    group by oie.seller_state
),
state_geo as (
    select * from {{ ref('int_state_geo_centroid') }}
)
-- 最終合併:以 revenue_metrics 為主表左接其他三張
select
    r.seller_state,
    r.seller_count,
    r.item_count,
    r.order_count,
    r.total_revenue,
    r.revenue_per_seller,
    r.items_per_seller,
    p.avg_item_price,
    p.median_price,
    p.avg_freight,
    rv.review_count,
    rv.avg_review_score,
    d.delivered_order_count,
    d.avg_delivery_days,
    d.avg_estimated_days,
    d.avg_days_vs_estimate,
    d.late_delivery_pct,
    g.state_lat,
    g.state_lng,
    case when r.seller_count <= 3 then true else false end as is_small_sample
from revenue_metrics r
left join pricing_metrics p on r.seller_state = p.seller_state
left join review_metrics rv on r.seller_state = rv.seller_state
left join delivery_metrics d on r.seller_state = d.seller_state
left join state_geo g on r.seller_state = g.seller_state
order by r.revenue_per_seller desc