{{
    config(
        materialized='view',
        tags=['report', 'pqr']
    )
}}

with events as (
    select * from {{ ref('fct_pqr_complaint_return_recall') }}
),

final as (
    select
        review_scope_id,
        version_no,
        event_type,
        count(*) as event_count,
        count(distinct batch_number) as affected_batch_count,
        sum(event_quantity) as total_event_quantity,
        min(event_date) as first_event_date,
        max(event_date) as last_event_date
    from events
    group by 1, 2, 3
)

select * from final
