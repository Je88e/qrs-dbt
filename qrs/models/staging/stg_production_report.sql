{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='report_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_production_report
    Description: MES生产报工记录原始数据清洗层 - Staging层
    Source: MES系统生产报工记录表
    Grain: 每行代表一条生产报工记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_production_report') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        report_id,
        wo_number as work_order_number,
        operation_id,
        batch_number,
        report_date,
        shift,
        output_qty as output_quantity,
        defect_qty as defect_quantity,
        defect_reason,
        scrap_qty as scrap_quantity,
        scrap_reason,
        operator_id,
        reviewer_id,
        review_status,
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