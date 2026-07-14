with order_items as (

    select * from {{ ref('stg_order_items') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

category_translation as (

    select * from {{ ref('stg_category_translation') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

sellers as (

    select * from {{ ref('stg_sellers') }}

),

joined as (

    select
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        oi.freight_value / nullif(oi.price, 0) as freight_to_price_ratio,

        o.customer_id,
        o.order_status,
        o.order_purchase_ts,
        o.order_delivered_ts,
        o.order_estimated_delivery_ts,
        date_diff(
            date(o.order_delivered_ts),
            date(o.order_estimated_delivery_ts),
            day
        ) as delivery_delay_days,

        p.category_name_pt,
        coalesce(product_category_name_english, p.category_name_pt) as product_category_name_en,

        c.customer_unique_id,
        c.customer_state,
        c.customer_city,

        s.seller_state,
        s.seller_city

    from order_items oi
    left join orders o on oi.order_id = o.order_id
    left join products p on oi.product_id = p.product_id
    left join category_translation ct on p.category_name_pt = ct.product_category_name
    left join customers c on o.customer_id = c.customer_id
    left join sellers s on oi.seller_id = s.seller_id

)

select * from joined