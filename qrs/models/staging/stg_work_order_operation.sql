{{
    config(
        materialized='view',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_work_order_operation
    Description: MES工单工序执行原始数据清洗层 - Staging层
    Source: MES系统工单工序执行表
    Grain: 每行代表一个工单工序执行记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_work_order_operation') }}
),

final as (
    select
        woo_id as work_order_operation_id,
        wo_number as work_order_number,
        operation_id,
        sequence as operation_sequence,
        planned_start,
        planned_end,
        actual_start,
        actual_end,
        status  as operation_status,
        equipment_id,
        operator_id,
        yield_qty as yield_quantity,
        defect_qty as defect_quantity,
        create_date
    from source_data
)

select * from final