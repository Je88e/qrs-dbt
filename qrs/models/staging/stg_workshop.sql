{{
    config(
        materialized='view',
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
    create_date
    from source_data
)

select * from final