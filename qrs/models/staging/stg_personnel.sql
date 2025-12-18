{{
    config(
        materialized='view',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_personnel
    Description: MES生产人员主数据原始数据清洗层 - Staging层
    Source: MES系统生产人员主数据表
    Grain: 每行代表一个生产人员
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_personnel') }}
),

renamed as (
    select
        personnel_id,
        personnel_name,
        personnel_type,
        workshop_id,
        position,
        skill_level,
        personnel_status,
        hire_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

