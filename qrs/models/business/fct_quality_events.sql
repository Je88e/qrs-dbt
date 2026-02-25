{{
    config(
        materialized='table',
        tags=['quality', 'events', 'pqr']
    )
}}

with deviations as (
    select * from {{ ref('stg_deviation') }}
),

capas_raw as (
    select * from {{ ref('stg_capa') }}
),

capas as (
    select
        c.*,
        d.product_id as linked_product_id,
        d.batch_number as linked_batch_number
    from capas_raw c
    left join deviations d
        on c.source_type in ('偏差', 'deviation', 'Deviation')
        and c.source_id = d.deviation_id
),

change_controls_raw as (
    select * from {{ ref('stg_change_control') }}
),

change_controls as (
    select
        c.*,
        null::text as product_id,
        null::text as batch_number
    from change_controls_raw c
),

complaints as (
    select * from {{ ref('stg_complaint') }}
),

product_recalls as (
    select * from {{ ref('stg_product_recall') }}
),

unioned as (
    select
        'qms' as source_system,
        'deviation' as event_type,
        deviation_id as source_event_id,
        deviation_code as event_code,
        deviation_title as event_title,
        deviation_type as event_subtype,
        deviation_category as event_category,
        deviation_description as event_description,
        product_id,
        batch_number,
        create_date,
        close_date,
        deviation_status as status_raw,
        null::text as priority_raw,
        null::text as recall_level_raw,
        root_cause as root_cause_raw,
        loaded_at as source_loaded_at
    from deviations

    union all

    select
        'qms' as source_system,
        'capa' as event_type,
        capa_id as source_event_id,
        capa_code as event_code,
        capa_title as event_title,
        capa_type as event_subtype,
        null::text as event_category,
        capa_description as event_description,
        coalesce(linked_product_id, null)::text as product_id,
        coalesce(linked_batch_number, null)::text as batch_number,
        create_date,
        actual_completion as close_date,
        capa_status as status_raw,
        null::text as priority_raw,
        null::text as recall_level_raw,
        root_cause_analysis as root_cause_raw,
        loaded_at as source_loaded_at
    from capas

    union all

    select
        'qms' as source_system,
        'change_control' as event_type,
        change_id as source_event_id,
        change_code as event_code,
        change_title as event_title,
        change_type as event_subtype,
        change_category as event_category,
        change_description as event_description,
        null::text as product_id,
        null::text as batch_number,
        create_date,
        actual_completion as close_date,
        change_status as status_raw,
        priority as priority_raw,
        null::text as recall_level_raw,
        null::text as root_cause_raw,
        loaded_at as source_loaded_at
    from change_controls

    union all

    select
        'pv' as source_system,
        'complaint' as event_type,
        complaint_id as source_event_id,
        complaint_code as event_code,
        null::text as event_title,
        null::text as event_subtype,
        complaint_type as event_category,
        complaint_description as event_description,
        product_id,
        batch_number,
        create_date,
        close_date,
        complaint_status as status_raw,
        priority as priority_raw,
        null::text as recall_level_raw,
        null::text as root_cause_raw,
        loaded_at as source_loaded_at
    from complaints

    union all

    select
        'pv' as source_system,
        'product_recall' as event_type,
        recall_id as source_event_id,
        recall_code as event_code,
        null::text as event_title,
        null::text as event_subtype,
        null::text as event_category,
        recall_reason as event_description,
        product_id,
        split_part(batch_numbers, ',', 1) as batch_number,
        create_date,
        close_date,
        recall_status as status_raw,
        null::text as priority_raw,
        recall_level as recall_level_raw,
        null::text as root_cause_raw,
        loaded_at as source_loaded_at
    from product_recalls
),

normalized as (
    select
        {{ dbt_utils.generate_surrogate_key(['source_system', 'event_type', 'source_event_id']) }} as event_id,
        source_system,
        event_type,
        source_event_id,
        event_code,
        event_title,
        event_subtype,
        event_category,
        event_description,
        product_id,
        batch_number,
        create_date,
        close_date,
        status_raw,
        case
            when status_raw is null then 'unknown'
            when status_raw in ('已关闭', '已完成', '已结束', 'Closed', 'closed', '完成') then 'closed'
            when status_raw in ('进行中', '调查中', '处理中', 'In Progress', 'in progress') then 'in_progress'
            when status_raw in ('待审核', '待审批', 'Pending', 'pending') then 'pending'
            else 'unknown'
        end as status_code,
        case
            when status_raw in ('已关闭', '已完成', '已结束', 'Closed', 'closed', '完成') then true
            else false
        end as is_closed,
        nullif(trim(priority_raw::text), '') as priority_raw,
        nullif(trim(recall_level_raw::text), '') as recall_level_raw,
        nullif(trim(root_cause_raw::text), '') as root_cause_raw,
        source_loaded_at
    from unioned
),

risk_mapping as (
    select
        source_system,
        event_type,
        raw_value,
        risk_level_code,
        priority
    from {{ ref('stg_risk_mapping') }}
    where is_active is distinct from false
),

risk_candidates as (
    select
        n.event_id,
        rm.risk_level_code,
        rm.priority,
        row_number() over (partition by n.event_id order by rm.priority nulls last, rm.risk_level_code) as rn
    from normalized n
    left join risk_mapping rm
        on n.source_system = rm.source_system
        and n.event_type = rm.event_type
        and coalesce(n.priority_raw, n.recall_level_raw) = rm.raw_value
),

risk_selected as (
    select
        event_id,
        risk_level_code
    from risk_candidates
    where rn = 1
),

root_cause_mapping as (
    select
        source_system,
        event_type,
        match_type,
        match_value,
        root_cause_category_code,
        priority
    from {{ ref('stg_root_cause_mapping') }}
    where is_active is distinct from false
),

root_cause_candidates as (
    select
        n.event_id,
        rcm.root_cause_category_code,
        rcm.priority,
        row_number() over (partition by n.event_id order by rcm.priority nulls last, rcm.root_cause_category_code) as rn
    from normalized n
    left join root_cause_mapping rcm
        on n.source_system = rcm.source_system
        and n.event_type = rcm.event_type
        and n.root_cause_raw is not null
        and (
            (rcm.match_type = 'contains' and n.root_cause_raw ilike ('%' || rcm.match_value || '%'))
            or (rcm.match_type = 'equals' and n.root_cause_raw = rcm.match_value)
        )
),

root_cause_selected as (
    select
        event_id,
        root_cause_category_code
    from root_cause_candidates
    where rn = 1
),

final as (
    select
        n.event_id,
        n.source_system,
        n.event_type,
        n.source_event_id,
        n.event_code,
        n.event_title,
        n.event_subtype,
        n.event_category,
        n.event_description,
        n.product_id,
        n.batch_number,
        n.create_date,
        n.close_date,
        n.status_raw,
        n.status_code,
        n.is_closed,
        rs.risk_level_code,
        rcs.root_cause_category_code,
        n.root_cause_raw,
        case
            when n.close_date is not null and n.create_date is not null and n.close_date >= n.create_date
            then n.close_date - n.create_date
            else null
        end as cycle_time_days,
        n.source_loaded_at
    from normalized n
    left join risk_selected rs
        on n.event_id = rs.event_id
    left join root_cause_selected rcs
        on n.event_id = rcs.event_id
)

select * from final
