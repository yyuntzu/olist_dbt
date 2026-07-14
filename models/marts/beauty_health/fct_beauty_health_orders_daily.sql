with items as (

    select * from {{ ref('int_beauty_health_order_items') }}
    where order_status not in ('canceled', 'unavailable')

),

daily_orders as (

    select
        date(order_purchase_ts)  as order_date,
        count(distinct order_id) as total_orders

    from items
    group by 1

)

select * from daily_orders