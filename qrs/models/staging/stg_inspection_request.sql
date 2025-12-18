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

renamed as (
    select
        request_id,
        material_id,
        batch_number,
        inspection_type,
        request_date,
        request_status,
        requester,
        priority,
        expected_completion_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

