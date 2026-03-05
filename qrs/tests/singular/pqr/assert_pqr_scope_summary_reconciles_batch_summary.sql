with scope_summary as (
    select * from {{ ref('fct_pqr_review_scope_summary') }}
),

batch_summary as (
    select * from {{ ref('fct_pqr_batch_summary') }}
),

recalc as (
    select
        review_scope_id,
        version_no,
        count(distinct batch_number) as batch_count_calc,
        count(distinct workshop_id) as workshop_count_calc,
        sum(planned_quantity) as total_planned_quantity_calc,
        sum(actual_quantity) as total_actual_quantity_calc
    from batch_summary
    group by 1, 2
)

select
    s.review_scope_id,
    s.version_no,
    s.batch_count as batch_count_model,
    r.batch_count_calc,
    s.workshop_count as workshop_count_model,
    r.workshop_count_calc,
    s.total_planned_quantity as total_planned_quantity_model,
    r.total_planned_quantity_calc,
    s.total_actual_quantity as total_actual_quantity_model,
    r.total_actual_quantity_calc
from scope_summary s
left join recalc r
    on s.review_scope_id = r.review_scope_id
   and s.version_no = r.version_no
where coalesce(s.batch_count, 0) <> coalesce(r.batch_count_calc, 0)
   or coalesce(s.workshop_count, 0) <> coalesce(r.workshop_count_calc, 0)
   or coalesce(s.total_planned_quantity, 0) <> coalesce(r.total_planned_quantity_calc, 0)
   or coalesce(s.total_actual_quantity, 0) <> coalesce(r.total_actual_quantity_calc, 0)
