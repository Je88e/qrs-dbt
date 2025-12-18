{{
    config(
        materialized='view',
        tags=['mes', 'production', 'master_data', 'pqr']
    )
}}

/*
 * 车间信息业务模型
 * 数据来源: MES系统
 * 业务描述: 提供车间主数据信息
 */

with workshop as (
    select * from {{ ref('mes_workshop') }}
)

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

from workshop

