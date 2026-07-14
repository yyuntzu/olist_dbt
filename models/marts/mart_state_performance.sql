-- models/marts/mart_state_performance.sql
-- 目的：這是整個「排除法」故事線的核心輸出表，一列 = 一個州
-- 整合四個維度：效率(revenue_per_seller)、定價、服務品質(review)、配送效率
-- 供 Looker Studio 直接讀取，作為 Page 3 地區分析頁面的資料來源

with base_items as (
    select * from {{ ref('int_health_beauty_order_items') }}
    where order_status = 'delivered'
),

-- 效率與定價指標
state_sales as (
    select
        seller_state,
        count(distinct seller_id)                          as seller_count,
        count(distinct order_id)                            as order_count,
        count(*)                                             as item_count,
        sum(price)                                           as revenue,
        safe_divide(sum(price), count(distinct seller_id))   as revenue_per_seller,
        safe_divide(count(*), count(distinct seller_id))     as items_per_seller,
        round(avg(price), 2)                                 as avg_item_price,
        round(avg(freight_value), 2)                         as avg_freight
    from base_items
    group by seller_state
),

-- 配送效率指標
state_delivery as (
    select
        seller_state,
        round(avg(actual_delivery_days), 1)      as avg_delivery_days,
        round(avg(estimated_delivery_days), 1)   as avg_estimated_days,
        round(avg(actual_delivery_days - estimated_delivery_days), 1) as avg_days_vs_estimate,
        round(100 * sum(case when is_late_delivery then 1 else 0 end) / count(*), 1) as late_delivery_pct
    from base_items
    group by seller_state
),

-- 服務品質指標
state_reviews as (
    select
        seller_state,
        count(distinct review_id)         as review_count,
        round(avg(review_score), 2)       as avg_review_score
    from {{ ref('int_health_beauty_order_seller_reviews') }}
    group by seller_state
),

joined as (
    select
        s.seller_state,
        s.seller_count,
        s.order_count,
        s.item_count,
        s.revenue,
        s.revenue_per_seller,
        s.items_per_seller,
        s.avg_item_price,
        s.avg_freight,
        d.avg_delivery_days,
        d.avg_estimated_days,
        d.avg_days_vs_estimate,
        d.late_delivery_pct,
        r.review_count,
        r.avg_review_score,

        -- 樣本量門檻標註：review_count < 20 視為統計上不可靠，
        -- 在 Looker 上會用這個欄位控制顏色/篩選器，避免小樣本誤導結論
        case when r.review_count >= 20 then true else false end as is_reliable_sample

    from state_sales s
    left join state_delivery d on s.seller_state = d.seller_state
    left join state_reviews r on s.seller_state = r.seller_state
)

select * from joined
order by revenue_per_seller desc
