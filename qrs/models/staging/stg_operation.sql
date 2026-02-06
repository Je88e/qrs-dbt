{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_operation
    Description: MES工序定义原始数据清洗层 - Staging层
    Source: MES系统工序定义表
    Grain: 每行代表一个工序
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_operation') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        operation_id,
        operation_code,
        operation_name,
        operation_type,
        standard_duration,
        duration_unit,
        equipment_type,
        skill_requirement,
        sop_document,
        status as operation_status,
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