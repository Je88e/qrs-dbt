{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'sample', 'pqr']
    )
}}

/*
    Model: dim_samples
    Description: 提供样品主数据信息
*/

with sample as (
    select * from {{ ref('stg_sample') }}
),

material as (
    select * from {{ ref('stg_material_master') }}
)

select
    -- 样品主键
    s.sample_id,
    
    -- 样品信息
    s.sample_code,
    s.sample_type,
    s.sample_qty as sample_quantity,
    s.sample_unit,
    
    -- 物料信息
    s.material_id,
    m.material_name,
    m.material_type,
    s.batch_number,
    
    -- 取样信息
    s.sample_date,
    s.sampler,
    
    -- 存储信息
    s.storage_condition,
    s.location,
    s.expiry_date,
    
    -- 样品状态
    s.sample_status,
    
    -- 有效期剩余天数
    case
        when s.expiry_date is not null
        then {{ date_diff_days('s.expiry_date', 'current_date') }}
        else null
    end as days_until_expiry,
    
    -- 审计字段
    s.create_date

from sample s
left join material m on s.material_id = m.material_id

