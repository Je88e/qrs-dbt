{{
    config(
        materialized='view',
        tags=['staging', 'pv', 'safety']
    )
}}

/*
    Model: stg_product_recall
    Description: PV产品召回记录原始数据清洗层 - Staging层
    Source: PV系统产品召回记录表
    Grain: 每行代表一条产品召回记录
*/

with source_data as (
    select * from {{ source('pv_raw', 'pv_product_recall') }}
),

final as (
    select
        recall_id,
        recall_code,
        recall_level,
        recall_reason,
        recall_scope,
        product_id,
        batch_numbers,
        recall_date,
        notification_date,
        recall_qty as recall_quantity,
        recall_unit,
        actual_return_qty as actual_return_quantity,
        status as recall_status,
        responsible,
        regulatory_report_date,
        close_date,
        create_date
    from source_data
)

select * from final