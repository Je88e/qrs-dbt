{{
    config(
        materialized='view',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_material_consumption
    Description: MES物料消耗记录原始数据清洗层 - Staging层
    Source: MES系统物料消耗记录表
    Grain: 每行代表一条物料消耗记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_material_consumption') }}
),

final as (
    select
        consumption_id,
        work_order_number,
        material_id,
        batch_number,
        consumption_quantity,
        unit,
        consumption_date,
        operator_id,
        created_at
    from source_data
)

select * from final