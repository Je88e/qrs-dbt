{{
    config(
        materialized='view',
        tags=['staging', 'scada', 'production']
    )
}}

/*
    Model: stg_batch_tracking
    Description: SCADA批次追踪记录原始数据清洗层 - Staging层
    Source: SCADA系统批次追踪记录表
    Grain: 每行代表一条批次追踪记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_batch_tracking') }}
),

final as (
    select
        tracking_id,
        batch_number,
        wo_number as work_order_number,
        product_id,
        operation_id,
        equipment_id,
        start_time,
        end_time,
        status as tracking_status,
        operator_id,
        yield_qty as yield_quantity,
        unit,
        quality_status,
        remark,
        create_date
    from source_data
)

select * from final