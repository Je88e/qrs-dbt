{{
    config(
        materialized='table',
        tags=['mes', 'equipment', 'calibration']
    )
}}

/*
    Model: stg_equipment_calibration
    Description: MES设备校准记录Staging层
*/

with source as (
    select * from {{ source('mes_raw', 'mes_equipment_calibration') }}
),

final as (
    select
        -- 生成雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,

        -- 主键
        calibration_id,
        calibration_code,

        -- 设备关联
        equipment_id,

        -- 校准信息
        calibration_type,
        cast(calibration_date as date) as calibration_date,
        cast(next_calibration_date as date) as next_calibration_date,
        cast(calibration_cycle as integer) as calibration_cycle,

        -- 标准器信息
        standard_equipment,
        standard_certificate,

        -- 校准结果
        calibration_result,
        cast(deviation_value as numeric) as deviation_value,
        cast(tolerance as numeric) as tolerance,
        cast(is_within_tolerance as boolean) as is_within_tolerance,

        -- 人员
        calibrator,
        reviewer,

        -- 证书
        certificate_no,

        -- 状态
        calibration_status,

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