with seed_map as (
    select
        review_scope_id,
        version_no,
        workshop_id
    from {{ ref('stg_pqr_scope_workshops') }}
),

bridge_map as (
    select
        review_scope_id,
        version_no,
        workshop_id
    from {{ ref('bridge_pqr_scope_workshop') }}
),

missing_in_bridge as (
    select
        s.review_scope_id,
        s.version_no,
        s.workshop_id,
        'missing_in_bridge'::text as issue
    from seed_map s
    left join bridge_map b
        on s.review_scope_id = b.review_scope_id
       and s.version_no = b.version_no
       and s.workshop_id = b.workshop_id
    where b.review_scope_id is null
),

extra_in_bridge as (
    select
        b.review_scope_id,
        b.version_no,
        b.workshop_id,
        'extra_in_bridge'::text as issue
    from bridge_map b
    left join seed_map s
        on s.review_scope_id = b.review_scope_id
       and s.version_no = b.version_no
       and s.workshop_id = b.workshop_id
    where s.review_scope_id is null
)

select * from missing_in_bridge
union all
select * from extra_in_bridge
