{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
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
        approval_date,
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