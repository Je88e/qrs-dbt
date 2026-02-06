{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_supplier_master
    Description: ERP供应商主数据原始数据清洗层 - Staging层
    Source: ERP系统供应商主数据表
    Grain: 每行代表一个供应商
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_supplier_master') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        -- 主键
        supplier_id,
        
        -- 供应商信息
        supplier_name,
        supplier_type,
        
        -- 联系信息
        contact_person,
        contact_phone,
        address,
        
        -- 资质信息
        qualification_status,
        audit_date,
        audit_score,
        
        -- 审计字段
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