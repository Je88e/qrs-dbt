{{
    config(
        materialized='view',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_production_line
    Description: MES产线主数据原始数据清洗层 - Staging层
    Source: MES系统产线主数据表
    Grain: 每行代表一条产线
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_production_line') }}
),

final as (
    select
        production_line_id,
        production_line_name,
        workshop_id,
        line_type,
        capacity,
        line_status,
        created_at,
        updated_at
    from source_data
)

select * from final