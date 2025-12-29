{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'master_data']
    )
}}

/*
    Model: stg_test_item
    Description: LIMS检验项目主数据原始数据清洗层 - Staging层
    Source: LIMS系统检验项目定义表
    Grain: 每行代表一个检验项目
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_test_item') }}
),

final as (
    select
        test_item_id,
        item_code,
        item_name,
        test_method,
        standard_id,
        min_value,
        max_value,
        unit,
        required_equipment,
        test_duration,
        test_duration_unit,
        status as item_status,
        create_date
    from source_data
)

select * from final