{{
    config(
        materialized='view',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_work_order
    Description: MES生产工单原始数据清洗层 - Staging层
    Source: MES系统生产工单主表
    Grain: 每行代表一个生产工单
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_work_order') }}
),

renamed as (
    select
        work_order_number,
        product_id,
        batch_number,
        planned_quantity,
        actual_quantity,
        unit,
        work_order_status,
        priority,
        planned_start_date,
        planned_end_date,
        actual_start_date,
        actual_end_date,
        production_line_id,
        workshop_id,
        created_at,
        updated_at
    from source_data
)

select * from renamed

