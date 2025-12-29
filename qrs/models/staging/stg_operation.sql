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
        operation_code,
        operation_name,
        operation_type,
        standard_duration,
        duration_unit,
        equipment_type,
        skill_requirement,
        sop_document,
        status as operation_status,
        create_date
    from source_data
)

select * from final