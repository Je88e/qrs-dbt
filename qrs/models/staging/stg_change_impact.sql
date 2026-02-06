{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
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
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
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
        assess_date as assessment_date,
        create_date,
        update_date,
        _airbyte_extracted_at as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where _loaded_at > (
    select coalesce(max(_loaded_at), '1900-01-01'::timestamp)
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}