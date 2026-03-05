with scope as (
    select
        review_scope_id,
        version_no,
        workshop_count as workshop_count_dim
    from {{ ref('dim_pqr_review_scope') }}
),

universe as (
    select * from {{ ref('int_pqr__batch_universe') }}
),

universe_counts as (
    select
        review_scope_id,
        version_no,
        count(distinct workshop_id) as workshop_count_universe
    from universe
    group by 1, 2
)

select
    s.review_scope_id,
    s.version_no,
    s.workshop_count_dim,
    coalesce(u.workshop_count_universe, 0) as workshop_count_universe
from scope s
left join universe_counts u
    on s.review_scope_id = u.review_scope_id
   and s.version_no = u.version_no
where u.workshop_count_universe is not null
  and coalesce(s.workshop_count_dim, 0) <> coalesce(u.workshop_count_universe, 0)
