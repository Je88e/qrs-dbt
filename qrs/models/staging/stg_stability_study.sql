{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='study_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['lims', 'stability', 'quality']
    )
}}

/*
    Model: stg_stability_study
    Description: LIMS稳定性研究记录Staging层
*/

with source as (
    select * from {{ source('lims_raw', 'lims_stability_study') }}
),

final as (
    select
        -- 生成雪花ID
        -- {{ dbt_utils.generate_surrogate_key(['study_id']) }} as snowflake_id,
        {{ generate_snowflake_id() }}::text as snowflake_id,

        -- 主键
        study_id,
        study_code,

        -- 产品批次
        product_id,
        batch_number,

        -- 研究条件
        study_type,
        storage_condition,
        timepoint,
        cast(timepoint_months as integer) as timepoint_months,

        -- 样品和检验
        sample_id,
        test_item_id,
        test_item_name,
        test_value,
        test_unit,
        specification,

        -- 结果
        result_status,

        -- 检测信息
        cast(test_date as date) as test_date,
        analyst_id,

        -- 状态
        study_status,

        -- 时间字段
        cast(create_date as timestamp) as create_date,

        -- 加载时间戳
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

    from source
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}