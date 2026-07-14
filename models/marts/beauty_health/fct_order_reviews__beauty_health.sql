with items as (

    select * from {{ ref('int_beauty_health_order_items') }}

),

reviews as (

    select * from {{ ref('stg_reviews') }}

),

joined as (

    select
        i.order_id,
        i.order_item_id,
        i.product_id,
        i.price,
        i.delivery_delay_days,
        i.order_status,

        r.review_score,

        case
            when i.delivery_delay_days > 0 then 'Delayed'
            when i.delivery_delay_days <= 0 then 'On Time or Early'
            else 'Unknown'
        end as delivery_status

    from items i
    left join reviews r on i.order_id = r.order_id

)

select * from joined