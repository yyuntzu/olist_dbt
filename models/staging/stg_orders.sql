-- models/staging/stg_orders.sql
-- 目的：清理訂單主表，統一型別，計算配送相關的衍生欄位
-- 只保留 order_status = 'delivered' 的邏輯留到 intermediate 層再篩選，
-- staging 層原則上不做業務篩選，只做型別/欄位清理

with source as (
    select * from {{ source('olist_raw', 'orders') }}
),

cleaned as (
    select
        order_id,
        customer_id,
        order_status,
        timestamp(order_purchase_timestamp)         as order_purchase_ts,
        timestamp(order_delivered_customer_date)     as order_delivered_ts,
        timestamp(order_estimated_delivery_date)     as order_estimated_delivery_ts,

        -- 衍生欄位：實際配送天數
        date_diff(
            date(timestamp(order_delivered_customer_date)),
            date(timestamp(order_purchase_timestamp)),
            day
        ) as actual_delivery_days,

        -- 衍生欄位：預估配送天數
        date_diff(
            date(timestamp(order_estimated_delivery_date)),
            date(timestamp(order_purchase_timestamp)),
            day
        ) as estimated_delivery_days,

        -- 衍生欄位：是否逾期送達
        case
            when timestamp(order_delivered_customer_date) > timestamp(order_estimated_delivery_date)
            then true
            else false
        end as is_late_delivery

    from source
)

select * from cleaned
