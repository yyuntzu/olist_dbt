-- models/staging/stg_products.sql
-- 目的：商品主檔，直接把葡文品類名稱翻成英文，下游不用重複join翻譯表
with products as (
   select * from {{ source('olist_raw', 'products') }}
),
category_translation as (
   select * from {{ source('olist_raw', 'category_translation') }}
),
cleaned as (
   select
       p.product_id,
       p.product_category_name           as category_name_pt,
       t.string_field_1                  as category_name_en
   from products p
   left join category_translation t
       on p.product_category_name = t.string_field_0
)
select * from cleaned
