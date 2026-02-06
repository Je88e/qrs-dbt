{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_workshop
    Description: MES车间主数据原始数据清洗层 - Staging层
    Source: MES系统车间主数据表
    Grain: 每行代表一个车间
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_workshop') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        -- 车间主键
    workshop_id,
    
    -- 车间信息
    workshop_code,
    workshop_name,
    workshop_type,
    
    -- 车间规模
    area as workshop_area,
    clean_level,
    
    -- 管理信息
    manager as workshop_manager,
    contact_phone,
    
    -- 车间状态
    status as workshop_status,
    
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