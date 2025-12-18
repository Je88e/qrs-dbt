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

renamed as (
    select
        workshop_id,
        workshop_name,
        workshop_type,
        manager,
        workshop_status,
        created_at,
        updated_at
    from source_data
)

select * from renamed

