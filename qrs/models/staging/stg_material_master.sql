{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_material_master
    Description: ERP物料主数据原始数据清洗层 - Staging层
    Source: ERP系统物料主数据表
    Grain: 每行代表一个物料
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_material_master') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        -- 主键
        material_id,
        
        -- 物料信息
        material_name,
        material_type,
        specification as material_specification,
        unit,
        
        -- 供应商信息
        supplier_id,
        
        -- 状态信息
        approval_status,
        is_deleted,
        
        -- 审计字段
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