{{
    config(
        materialized='view',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_production_report
    Description: MES生产报工记录原始数据清洗层 - Staging层
    Source: MES系统生产报工记录表
    Grain: 每行代表一条生产报工记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_production_report') }}
),

renamed as (
    select
        report_id,
        work_order_number,
        operation_id,
        report_date,
        report_quantity,
        qualified_quantity,
        defect_quantity,
        unit,
        operator_id,
        shift,
        created_at
    from source_data
)

select * from renamed

