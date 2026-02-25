{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='change_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_change_control
    Description: QMS变更控制原始数据清洗层 - Staging层
    Source: QMS系统变更控制主表
    Grain: 每行代表一个变更控制记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_change_control') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        change_id,
        change_code,
        change_title,
        change_type,
        change_category,
        change_description,
        initiator,
        initiate_date,
        priority,
        status as change_status,
        planned_completion,
        actual_completion,
        reviewer,
        approver,
        CAST(approval_date as date) as approval_date,
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
