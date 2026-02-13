{% snapshot snap_change_impact %}

{{
    config(
        target_schema='snapshots',
        unique_key='impact_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'qms', 'quality', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_change_impact
        Description: QMS变更影响评估快照
        
        业务场景:
        - 变更影响评估状态追踪
        - 风险评估历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    impact_id,
    change_id,
    impact_area,
    impact_description,
    impact_level,
    affected_documents,
    affected_processes,
    risk_assessment,
    mitigation_measures,
    assessor,
    assessment_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_change_impact') }}

{% endsnapshot %}
