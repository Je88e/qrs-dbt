{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_request
    Description: LIMS检验申请原始数据清洗层 - Staging层
    Source: LIMS系统检验申请单表
    Grain: 每行代表一个检验申请
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_request') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        request_id,
        material_id,
        batch_number,
        sample_type,
        request_date,
        requester,
        inspection_type,
        priority,
        request_status,
        planned_completion_date,
        actual_completion_date,
        sample_qty as sample_quantity,
        sample_unit,
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