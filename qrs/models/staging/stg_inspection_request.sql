{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_request
    Description: LIMS检验申请原始数据清洗层 - Staging层
    Source: LIMS系统检验申请单表
    Grain: 每行代表一个检验申请
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_request') }}
),

final as (
    select
        request_id,
        material_id,
        batch_number,
        sample_type,
        request_date,
        requester,
        inspection_type,
        priority,
        request_status,
        planned_completion_date,
        actual_completion_date,
        sample_qty as sample_quantity,
        sample_unit
    from source_data
)

select * from final