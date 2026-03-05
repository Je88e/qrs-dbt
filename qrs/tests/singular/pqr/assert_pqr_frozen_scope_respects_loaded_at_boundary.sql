with frozen_scopes as (
    select
        review_scope_id,
        version_no,
        source_loaded_at_max
    from {{ ref('dim_pqr_review_scope') }}
    where is_frozen
),

universe as (
    select
        review_scope_id,
        version_no,
        product_id,
        batch_number,
        workshop_id
    from {{ ref('int_pqr__batch_universe') }}
),

work_orders as (
    select
        product_id,
        batch_number,
        workshop_id,
        loaded_at
    from {{ ref('stg_work_order') }}
),

scope_ws_loaded as (
    select
        review_scope_id,
        version_no,
        max(loaded_at) as max_scope_workshops_loaded_at
    from {{ ref('stg_pqr_scope_workshops') }}
    group by 1, 2
),

wo_loaded as (
    select
        u.review_scope_id,
        u.version_no,
        max(w.loaded_at) as max_work_orders_loaded_at
    from universe u
    inner join work_orders w
        on u.product_id = w.product_id
       and u.batch_number = w.batch_number
       and u.workshop_id = w.workshop_id
    group by 1, 2
)

select
    s.review_scope_id,
    s.version_no,
    s.source_loaded_at_max,
    w.max_work_orders_loaded_at,
    sw.max_scope_workshops_loaded_at
from frozen_scopes s
left join wo_loaded w
    on s.review_scope_id = w.review_scope_id
   and s.version_no = w.version_no
left join scope_ws_loaded sw
    on s.review_scope_id = sw.review_scope_id
   and s.version_no = sw.version_no
where (w.max_work_orders_loaded_at is not null and w.max_work_orders_loaded_at > s.source_loaded_at_max)
   or (sw.max_scope_workshops_loaded_at is not null and sw.max_scope_workshops_loaded_at > s.source_loaded_at_max)
