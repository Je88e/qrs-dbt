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

final as (
    select
        report_id,
        wo_number as work_order_number,
        operation_id,
        batch_number,
        report_date,
        shift,
        output_qty as output_quantity,
        defect_qty as defect_quantity,
        defect_reason,
        scrap_qty as scrap_quantity,
        scrap_reason,
        operator_id,
        reviewer_id,
        review_status,
        create_date
    from source_data
)

select * from final