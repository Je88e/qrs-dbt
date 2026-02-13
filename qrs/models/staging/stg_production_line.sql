{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='line_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_production_line
    Description: MES产线主数据原始数据清洗层 - Staging层
    Source: MES系统产线主数据表
    Grain: 每行代表一条产线
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_production_line') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        line_id,
        line_code,
        line_name,
        workshop_id,
        product_type,
        capacity,
        capacity_unit,
        status as line_status,
        manager as line_manager,
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