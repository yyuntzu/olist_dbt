with items as (

    select * from {{ ref('int_beauty_health_order_items') }}
    where order_status not in ('canceled', 'unavailable')

),

product_agg as (

    select
        product_id,
        product_category_name_en,
        count(distinct order_id)      as total_orders,
        count(order_item_id)          as total_units_sold,
        sum(price)               as total_revenue,
        avg(price)               as avg_price,
        sum(freight_value)            as total_freight,
        avg(freight_to_price_ratio)   as avg_freight_ratio

    from items
    group by 1, 2

),

ranked as (

    select
        *,
        ntile(4) over (order by total_units_sold desc) as volume_quartile,
        ntile(4) over (order by total_revenue desc)     as revenue_quartile

    from product_agg

),

quadrant as (

    select
        *,
        case
            when volume_quartile = 1 and revenue_quartile = 1 then 'Star (走量高額雙高)'
            when volume_quartile = 1 and revenue_quartile > 1 then 'High Volume Low Value (走量款)'
            when volume_quartile > 1 and revenue_quartile = 1 then 'Premium Niche (高單價低量款)'
            else 'Long Tail (冷門款)'
        end as product_quadrant

    from ranked

)

select * from quadrant