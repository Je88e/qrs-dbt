{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
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