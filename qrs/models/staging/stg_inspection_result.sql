{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='result_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_result
    Description: LIMS检验结果原始数据清洗层 - Staging层
    Source: LIMS系统检验结果记录表
    Grain: 每行代表一条检验结果记录
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_result') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        result_id,
        task_id,
        test_item_id,
        sample_id,
        test_value,
        test_unit,
        standard_min,
        standard_max,
        result_status,
        test_date,
        analyst_id,
        reviewer_id,
        review_date,
        review_status,
        remark,
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