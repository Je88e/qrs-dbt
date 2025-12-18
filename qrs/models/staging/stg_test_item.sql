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

renamed as (
    select
        test_item_id,
        test_item_name,
        test_method,
        unit,
        lower_limit,
        upper_limit,
        test_item_status,
        created_at,
        updated_at
    from source_data
)

select * from renamed

