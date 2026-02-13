{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='report_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_report
    Description: LIMS检验报告原始数据清洗层 - Staging层
    Source: LIMS系统检验报告表
    Grain: 每行代表一份检验报告
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_report') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        report_id,
        request_id,
        report_code,
        sample_id,
        material_id,
        batch_number,
        conclusion,
        report_date,
        reporter,
        reviewer,
        review_date,
        approver,
        approval_date,
        status as report_status,
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