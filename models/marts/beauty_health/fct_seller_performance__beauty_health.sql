with items as (

    select * from {{ ref('int_beauty_health_order_items') }}
    where order_status not in ('canceled', 'unavailable')

),

seller_agg as (

    select
        seller_id,
        seller_state,
        seller_city,
        count(order_item_id)  as total_units_sold,
        sum(price)       as total_revenue,
        avg(delivery_delay_days) as avg_delivery_delay_days

    from items
    group by 1, 2, 3

),

with_share as (

    select
        *,
        total_revenue / sum(total_revenue) over ()        as revenue_share,
        sum(total_revenue) over (order by total_revenue desc
            rows between unbounded preceding and current row)
            / sum(total_revenue) over ()                   as cumulative_revenue_share

    from seller_agg

)

select * from with_share