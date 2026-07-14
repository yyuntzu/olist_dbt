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

monthly_base as (
    select
        oie.seller_state,
        date_trunc(date(o.order_purchase_ts), month) as order_month,
        o.order_id,
        oie.seller_id,
        oie.product_id,
        oie.price,
        o.actual_delivery_days,
        o.is_late_delivery
    from order_items_enriched oie
    inner join orders o
        on oie.order_id = o.order_id
    where o.order_status = 'delivered'
),

monthly_reviews as (
    select
        mb.seller_state,
        mb.order_month,
        rd.review_score
    from monthly_base mb
    inner join reviews_deduped rd
        on mb.order_id = rd.order_id
        and mb.seller_id = rd.seller_id
        and mb.product_id = rd.product_id
)

select
    mb.seller_state,
    mb.order_month,
    count(distinct mb.order_id) as order_count,
    sum(mb.price) as revenue,
    round(avg(mb.actual_delivery_days), 1) as avg_delivery_days,
    round(100 * sum(case when mb.is_late_delivery then 1 else 0 end) / count(*), 1) as late_delivery_pct,
    round(avg(mr.review_score), 2) as avg_review_score
from monthly_base mb
left join monthly_reviews mr
    on mb.seller_state = mr.seller_state
    and mb.order_month = mr.order_month
group by mb.seller_state, mb.order_month
order by mb.seller_state, mb.order_month