{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_result
    Description: LIMS检验结果原始数据清洗层 - Staging层
    Source: LIMS系统检验结果记录表
    Grain: 每行代表一条检验结果记录
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_result') }}
),

final as (
    select
        result_id,
        task_id,
        test_item_id,
        sample_id,
        test_value,
        test_unit,
        standard_min,
        standard_max,
        result_status,
        test_date,
        analyst_id,
        reviewer_id,
        review_date,
        review_status,
        remark,
        created_at
    from source_data
)

select * from final