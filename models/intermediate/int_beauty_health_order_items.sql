with base as (

    select * from {{ ref('int_orders_joined') }}

)

select *
from base
where product_category_name_en in ('health_beauty', 'perfumery')