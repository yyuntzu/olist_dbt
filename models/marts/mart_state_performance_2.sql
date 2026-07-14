 

WITH stg_products AS (

SELECT

p.product_id,

p.product_category_name AS category_name_pt,

t.string_field_1 AS category_name_en

FROM `focus-heuristic-438521-v4.olist_raw.products` p

LEFT JOIN `focus-heuristic-438521-v4.olist_raw.category_translation` t

ON p.product_category_name = t.string_field_0

),

stg_orders AS (

SELECT

order_id,

order_status,

TIMESTAMP(order_purchase_timestamp) AS order_purchase_ts,

TIMESTAMP(order_delivered_customer_date) AS order_delivered_ts,

TIMESTAMP(order_estimated_delivery_date) AS order_estimated_delivery_ts,

DATE_DIFF(DATE(TIMESTAMP(order_delivered_customer_date)), DATE(TIMESTAMP(order_purchase_timestamp)), DAY) AS actual_delivery_days,

DATE_DIFF(DATE(TIMESTAMP(order_estimated_delivery_date)), DATE(TIMESTAMP(order_purchase_timestamp)), DAY) AS estimated_delivery_days,

CASE WHEN TIMESTAMP(order_delivered_customer_date) > TIMESTAMP(order_estimated_delivery_date) THEN TRUE ELSE FALSE END AS is_late_delivery

FROM `focus-heuristic-438521-v4.olist_raw.orders`

),

int_health_beauty_order_items AS (

SELECT

oi.order_id,

oi.order_item_id,

oi.product_id,

oi.seller_id,

oi.price,

oi.freight_value,

s.seller_state,

o.order_status,

o.order_purchase_ts,

o.actual_delivery_days,

o.estimated_delivery_days,

o.is_late_delivery

FROM `focus-heuristic-438521-v4.olist_raw.order_items` oi

INNER JOIN stg_products p

ON oi.product_id = p.product_id

AND p.category_name_en = 'health_beauty'

LEFT JOIN `focus-heuristic-438521-v4.olist_raw.sellers` s

ON oi.seller_id = s.seller_id

LEFT JOIN stg_orders o

ON oi.order_id = o.order_id

),

int_health_beauty_order_seller_reviews AS (

SELECT

hb.seller_state,

hb.seller_id,

hb.order_id,

r.review_id,

r.review_score

FROM (

SELECT DISTINCT order_id, seller_id, seller_state

FROM int_health_beauty_order_items

) hb

INNER JOIN `focus-heuristic-438521-v4.olist_raw.olist_order_reviews_clean` r

ON hb.order_id = r.order_id

),

base_items AS (

SELECT * FROM int_health_beauty_order_items

WHERE order_status = 'delivered'

),

state_sales AS (

SELECT

seller_state,

COUNT(DISTINCT seller_id) AS seller_count,

COUNT(DISTINCT order_id) AS order_count,

COUNT(*)  AS item_count,

SUM(price) AS revenue,

SAFE_DIVIDE(SUM(price), COUNT(DISTINCT seller_id)) AS revenue_per_seller,

SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT seller_id))   AS items_per_seller,

ROUND(AVG(price), 2)  AS avg_item_price,

ROUND(AVG(freight_value), 2) AS avg_freight

FROM base_items

GROUP BY seller_state

),

state_delivery AS (

SELECT

seller_state,

ROUND(AVG(actual_delivery_days), 1)  AS avg_delivery_days,

ROUND(AVG(estimated_delivery_days), 1) AS avg_estimated_days,

ROUND(AVG(actual_delivery_days - estimated_delivery_days), 1) AS avg_days_vs_estimate,

ROUND(100 * SUM(CASE WHEN is_late_delivery THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_delivery_pct

FROM base_items

GROUP BY seller_state

),

state_reviews AS (

SELECT

seller_state,

COUNT(DISTINCT review_id)   AS review_count,

ROUND(AVG(review_score), 2) AS avg_review_score

FROM int_health_beauty_order_seller_reviews

GROUP BY seller_state

)

SELECT

s.seller_state,

s.seller_count,

s.order_count,

s.item_count,

s.revenue,

s.revenue_per_seller,

s.items_per_seller,

s.avg_item_price,

s.avg_freight,

d.avg_delivery_days,

d.avg_estimated_days,

d.avg_days_vs_estimate,

d.late_delivery_pct,

r.review_count,

r.avg_review_score,

CASE WHEN r.review_count >= 20 THEN TRUE ELSE FALSE END AS is_reliable_sample

FROM state_sales s

LEFT JOIN state_delivery d ON s.seller_state = d.seller_state

LEFT JOIN state_reviews r ON s.seller_state = r.seller_state

ORDER BY revenue_per_seller DESC