with universe as (
    select
        version_no,
        batch_number,
        count(distinct review_scope_id) as scope_count
    from {{ ref('int_pqr__batch_universe') }}
    group by 1, 2
)

select *
from universe
where scope_count > 1
