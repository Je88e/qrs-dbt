{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='impact_id',
        merge_exclude_columns=['snowflake_id'],
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
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}