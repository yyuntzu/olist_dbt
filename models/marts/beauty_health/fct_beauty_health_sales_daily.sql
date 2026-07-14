with items as (

    select * from {{ ref('int_beauty_health_order_items') }}
    where order_status not in ('canceled', 'unavailable')

),

daily as (

    select
        date(order_purchase_ts)         as order_date,
        product_id,
        product_category_name_en,

        case
            when price < 30  then 'R$0-30'
            when price < 60  then 'R$30-60'
            when price < 100 then 'R$60-100'
            else 'R$100+'
        end as price_band,

        count(order_item_id)   as units_sold,
        sum(price)        as revenue,
        sum(freight_value)     as freight_total,
        avg(freight_to_price_ratio) as avg_freight_ratio

    from items
    group by 1, 2, 3, 4

)

select * from daily