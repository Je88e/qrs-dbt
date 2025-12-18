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

renamed as (
    select
        recall_id,
        recall_number,
        product_id,
        batch_number,
        recall_type,
        recall_level,
        recall_reason,
        recall_date,
        notification_date,
        affected_quantity,
        recovered_quantity,
        recall_status,
        created_at,
        updated_at
    from source_data
)

select * from renamed

