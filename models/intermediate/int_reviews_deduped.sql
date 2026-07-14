with reviews as (
    select * from {{ ref('stg_reviews') }}
),

order_items_enriched as (
    select distinct
        order_id,
        seller_id,
        product_id
    from {{ ref('int_order_items_enriched') }}
)

select
    r.review_id,
    r.order_id,
    r.review_score,
    oie.seller_id,
    oie.product_id
from reviews r
inner join order_items_enriched oie
    on r.order_id = oie.order_id