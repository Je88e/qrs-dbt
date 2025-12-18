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

renamed as (
    select
        work_order_operation_id,
        work_order_number,
        operation_id,
        sequence_number,
        operation_status,
        planned_start_time,
        planned_end_time,
        actual_start_time,
        actual_end_time,
        operator_id,
        equipment_id,
        created_at,
        updated_at
    from source_data
)

select * from renamed

