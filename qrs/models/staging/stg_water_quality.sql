{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='test_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['lims', 'water', 'quality']
    )
}}

/*
    Model: stg_water_quality
    Description: LIMS工艺用水质量检测记录Staging层
*/

with source as (
    select * from {{ source('lims_raw', 'lims_water_quality') }}
),

final as (
    select
        -- 生成雪花ID
        -- {{ dbt_utils.generate_surrogate_key(['test_id']) }} as snowflake_id,
        {{ generate_snowflake_id() }}::text as snowflake_id,

        -- 主键
        test_id,

        -- 监测点信息
        monitoring_point_id,
        monitoring_point_name,
        water_type,

        -- 检测参数
        parameter_name,
        cast(test_value as numeric) as test_value,
        test_unit,
        cast(limit_min as numeric) as limit_min,
        cast(limit_max as numeric) as limit_max,
        result_status,

        -- 关联信息
        analyst_id,
        equipment_id,
        batch_number,

        -- 时间字段
        cast(test_date as date) as test_date,
        cast(create_date as timestamp) as create_date,

        -- 加载时间戳
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

    from source
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("high_frequency_lookback_minutes", 2) }} minutes'
    from {{ this }}
)
{% endif %}
