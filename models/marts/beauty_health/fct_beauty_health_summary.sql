-- models/marts/beauty_health/fct_beauty_health_summary.sql
with orders as (
    select sum(total_orders) as total_orders from {{ ref('fct_beauty_health_orders_daily') }}
),
products as (
    select sum(total_revenue) as total_revenue from {{ ref('dim_products__beauty_health') }}
)
select
    o.total_orders,
    p.total_revenue,
    safe_divide(p.total_revenue, o.total_orders) as avg_order_value
from orders o, products p