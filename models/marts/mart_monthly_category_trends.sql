-- models/marts/mart_monthly_category_trends.sql
-- 目的：月度時間序列，涵蓋銷售、鋪貨量(賣家數+SKU數)兩大構面
-- 供 (1) Looker Studio 趨勢頁 (2) Python 迴歸模型的 lag feature 來源
-- 已排除 2016-09 ~ 2016-12 不完整月份，分析區間鎖定在有完整資料的月份

with base_items as (
    select * from {{ ref('int_health_beauty_order_items') }}
    where order_status = 'delivered'
),

monthly as (
    select
        date_trunc(date(order_purchase_ts), month) as order_month,
        count(distinct order_id)                    as order_count,
        count(distinct seller_id)                    as active_seller_count,
        count(distinct product_id)                   as active_sku_count,
        sum(price)                                    as revenue,

        -- 鋪貨廣度：平均每個賣家上架幾個SKU
        safe_divide(count(distinct product_id), count(distinct seller_id)) as sku_per_seller,

        -- 單位鋪貨效益：每個SKU帶來多少營收（用來看邊際效益是否遞減）
        safe_divide(sum(price), count(distinct product_id)) as revenue_per_sku

    from base_items
    where date(order_purchase_ts) between '2017-01-01' and '2018-08-31'
    group by order_month
)

select
    *,
    -- lag features：給下游預測模型用，用「這個月」的鋪貨指標對應「下個月」revenue
    lag(active_seller_count) over (order by order_month) as prev_active_seller_count,
    lag(active_sku_count) over (order by order_month)    as prev_active_sku_count,
    lag(revenue) over (order by order_month)              as prev_revenue
from monthly
order by order_month
