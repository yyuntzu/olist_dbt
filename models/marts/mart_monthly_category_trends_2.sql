WITH stg_products AS (

SELECT

p.product_id,

t.string_field_1 AS category_name_en

FROM `focus-heuristic-438521-v4.olist_raw.products` p

LEFT JOIN `focus-heuristic-438521-v4.olist_raw.category_translation` t

ON p.product_category_name = t.string_field_0

),

int_health_beauty_order_items AS (

SELECT

oi.order_id,

oi.product_id,

oi.seller_id,

oi.price,

o.order_status,

TIMESTAMP(o.order_purchase_timestamp) AS order_purchase_ts

FROM `focus-heuristic-438521-v4.olist_raw.order_items` oi

INNER JOIN stg_products p

ON oi.product_id = p.product_id

AND p.category_name_en = 'health_beauty'

LEFT JOIN `focus-heuristic-438521-v4.olist_raw.orders` o

ON oi.order_id = o.order_id

),

base_items AS (

SELECT * FROM int_health_beauty_order_items

WHERE order_status = 'delivered'

),

monthly AS (

SELECT

DATE_TRUNC(DATE(order_purchase_ts), MONTH) AS order_month,

COUNT(DISTINCT order_id) AS order_count,

COUNT(DISTINCT seller_id)  AS active_seller_count,

COUNT(DISTINCT product_id)   AS active_sku_count,

SUM(price) AS revenue,

SAFE_DIVIDE(COUNT(DISTINCT product_id), COUNT(DISTINCT seller_id)) AS sku_per_seller,

SAFE_DIVIDE(SUM(price), COUNT(DISTINCT product_id))  AS revenue_per_sku

FROM base_items

WHERE DATE(order_purchase_ts) BETWEEN '2017-01-01' AND '2018-08-31'

GROUP BY order_month

)

SELECT

*,

LAG(active_seller_count) OVER (ORDER BY order_month) AS prev_active_seller_count,

LAG(active_sku_count) OVER (ORDER BY order_month)  AS prev_active_sku_count,

LAG(revenue) OVER (ORDER BY order_month)  AS prev_revenue,

SAFE_DIVIDE(revenue - LAG(revenue) OVER (ORDER BY order_month), LAG(revenue) OVER (ORDER BY order_month)) AS mom_growth_rate

FROM monthly

ORDER BY order_month