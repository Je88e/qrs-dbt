{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_task
    Description: LIMS检验任务原始数据清洗层 - Staging层
    Source: LIMS系统检验任务表
    Grain: 每行代表一个检验任务
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_task') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        task_id,
        request_id,
        sample_id,
        test_item_id,
        assigned_analyst,
        assigned_date,
        planned_completion,
        actual_completion,
        task_status,
        priority,
        equipment_id,
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