with monthly_sales as (

    select
        product_id,
        date_trunc(order_date, month) as order_month,
        sum(revenue) as monthly_revenue
    from {{ ref('fct_beauty_health_sales_daily') }}
    group by 1, 2

),

date_bounds as (

    select max(order_month) as latest_month
    from monthly_sales

),

growth as (

    select
        m.product_id,
        sum(case when m.order_month > date_sub(d.latest_month, interval 6 month)
            then m.monthly_revenue else 0 end) as recent_6mo_revenue,
        sum(case when m.order_month <= date_sub(d.latest_month, interval 6 month)
            and m.order_month > date_sub(d.latest_month, interval 12 month)
            then m.monthly_revenue else 0 end) as prior_6mo_revenue
    from monthly_sales m
    cross join date_bounds d
    group by 1

),

growth_rate as (

    select
        product_id,
        recent_6mo_revenue,
        prior_6mo_revenue,
        safe_divide(
            recent_6mo_revenue - prior_6mo_revenue,
            nullif(prior_6mo_revenue, 0)
        ) as revenue_growth_rate_6mo

    from growth

),

review_agg as (

    select
        product_id,
        avg(review_score)        as avg_review_score,
        avg(delivery_delay_days) as avg_delivery_delay_days
    from {{ ref('fct_order_reviews__beauty_health') }}
    where review_score is not null
    group by 1

),

products as (

    select
        product_id,
        product_category_name_en,
        total_units_sold,
        total_revenue,
        product_quadrant
    from {{ ref('dim_products__beauty_health') }}

),

combined as (

    select
        p.product_id,
        p.product_category_name_en,
        p.total_units_sold,
        p.total_revenue,
        p.product_quadrant,
        g.revenue_growth_rate_6mo,
        r.avg_review_score,
        r.avg_delivery_delay_days

    from products p
    left join growth_rate g on p.product_id = g.product_id
    left join review_agg r on p.product_id = r.product_id

),

action_label as (

    select
        *,
        case
            -- Star 象限:銷量與營收都高,樣本量足以判斷趨勢,用成長率 + 評價
            when product_quadrant = 'Star (走量高額雙高)'
                 and revenue_growth_rate_6mo > 0
                 and avg_review_score >= 4
                then '🟢 建議加碼備貨'

            when product_quadrant = 'Star (走量高額雙高)'
                 and (revenue_growth_rate_6mo <= 0 or revenue_growth_rate_6mo is null)
                 and avg_review_score < 3.5
                then '🔴 建議檢討/下架'

            when product_quadrant = 'Star (走量高額雙高)'
                then '🟡 觀察'

            -- 非 Star 商品:單量過小時,6個月增長率統計上不可信,不下結論
            when total_units_sold < 5
                then '⚪ 樣本量過小,暫不下結論'

            -- 單量 >= 5 但非 Star:改用評價 + 到貨表現(較不受單月波動影響)判斷
            when avg_review_score >= 4.5 and avg_delivery_delay_days <= 0
                then '🟢 建議加碼備貨(高評價/準時到貨)'

            when avg_review_score < 3.5
                then '🔴 建議檢討/下架'

            else '🟡 觀察'

        end as inventory_action

    from combined

)

select * from action_label