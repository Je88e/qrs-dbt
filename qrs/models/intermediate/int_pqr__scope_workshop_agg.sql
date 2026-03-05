{{
    config(
        materialized='view',
        tags=["intermediate", "pqr", "scope"]
    )
}}

with scope_workshop as (
    select * from {{ ref('stg_pqr_scope_workshops') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
),

final as (
    select
        sw.review_scope_id,
        sw.version_no,
        count(distinct sw.workshop_id) as workshop_count,
        string_agg(
            distinct coalesce(ws.workshop_name, sw.workshop_id)::text,
            ', ' order by coalesce(ws.workshop_name, sw.workshop_id)::text
        ) as workshop_list
    from scope_workshop sw
    left join workshop ws on sw.workshop_id = ws.workshop_id
    group by 1, 2
)

select * from final
