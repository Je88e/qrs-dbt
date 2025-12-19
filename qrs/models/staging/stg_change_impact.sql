{{
    config(
        materialized='view',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_change_impact
    Description: QMS变更影响评估原始数据清洗层 - Staging层
    Source: QMS系统变更影响评估表
    Grain: 每行代表一条变更影响评估记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_change_impact') }}
),

final as (
    select
        impact_id,
        change_id,
        impact_area,
        impact_level,
        impact_description,
        mitigation_plan,
        assessor,
        assessment_date,
        created_at
    from source_data
)

select * from final