-- models/staging/stg_reviews.sql
-- 目的：評價資料的原始粒度是「一筆review對一個order_id」
-- 這裡不做任何join，純粹清理欄位，去重邏輯留在intermediate層處理
-- （因為review要對應到seller/state層級時，需要先處理order_items的一對多關係）
with source as (
   select * from {{ source('olist_raw', 'olist_order_reviews_clean') }}
),
cleaned as (
   select
       review_id,
       order_id,
       review_score
   from source
)
select * from cleaned