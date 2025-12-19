{{
    config(
        materialized='view',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_operation
    Description: MES工序定义原始数据清洗层 - Staging层
    Source: MES系统工序定义表
    Grain: 每行代表一个工序
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_operation') }}
),

final as (
    select
        operation_id,
        operation_name,
        operation_type,
        standard_duration,
        equipment_id,
        operation_status,
        created_at,
        updated_at
    from source_data
)

select * from final