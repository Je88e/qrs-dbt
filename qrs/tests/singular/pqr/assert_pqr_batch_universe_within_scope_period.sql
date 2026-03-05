with universe as (
    select * from {{ ref('int_pqr__batch_universe') }}
),

scope as (
    select
        review_scope_id,
        version_no,
        period_start_date,
        period_end_date
    from {{ ref('dim_pqr_review_scope') }}
)

select
    u.review_scope_id,
    u.version_no,
    u.batch_number,
    u.batch_start_at,
    s.period_start_date,
    s.period_end_date
from universe u
inner join scope s
    on u.review_scope_id = s.review_scope_id
   and u.version_no = s.version_no
where u.batch_start_at is not null
  and u.batch_start_at::date not between s.period_start_date and s.period_end_date
