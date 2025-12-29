{{
    config(
        materialized='view',
        tags=['mes', 'production', 'master_data', 'pqr']
    )
}}

/*
    Model: dim_workshops
    Description: 提供车间主数据信息
*/

with workshop as (
    select * from {{ ref('stg_workshop') }}
)

select
    -- 车间主键
    workshop_id,
    
    -- 车间信息
    workshop_code,
    workshop_name,
    workshop_type,
    
    -- 车间规模
    workshop_area,
    clean_level,
    
    -- 管理信息
    workshop_manager,
    contact_phone,
    
    -- 车间状态
    workshop_status,
    
    -- 审计字段
    create_date

from workshop

