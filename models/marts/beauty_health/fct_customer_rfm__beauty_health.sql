with items as (

    select * from {{ ref('int_beauty_health_order_items') }}
    where order_status not in ('canceled', 'unavailable')

),

customer_agg as (

    select
        customer_unique_id,
        customer_state,
        customer_city,

        min(date(order_purchase_ts)) as first_purchase_date,
        max(date(order_purchase_ts)) as last_purchase_date,
        count(distinct order_id)     as frequency,
        sum(price)              as monetary,
        date_diff(
            current_date(),
            max(date(order_purchase_ts)),
            day
        ) as recency_days

    from items
    group by 1, 2, 3

),

rfm_scored as (

    select
        *,
        ntile(4) over (order by recency_days asc)  as recency_score,
        ntile(4) over (order by frequency desc)     as frequency_score,
        ntile(4) over (order by monetary desc)      as monetary_score,

        case
            when frequency > 1 then true else false
        end as is_repeat_customer

    from customer_agg

)

select * from rfm_scored