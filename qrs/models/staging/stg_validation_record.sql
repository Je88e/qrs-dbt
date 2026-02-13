{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='validation_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['qms', 'validation', 'gxp']
    )
}}

/*
    Model: stg_validation_record
    Description: QMS验证确认记录Staging层
*/

with source as (
    select * from {{ source('qms_raw', 'qms_validation_record') }}
),

final as (
    select
        -- 生成雪花ID
        -- {{ dbt_utils.generate_surrogate_key(['validation_id']) }} as snowflake_id,
        {{ generate_snowflake_id() }}::text as snowflake_id,

        -- 主键
        validation_id,
        validation_code,

        -- 验证信息
        validation_type,
        validation_title,
        protocol_no,

        -- 关联信息
        product_id,
        equipment_id,
        batch_numbers,

        -- 日期信息
        cast(start_date as date) as start_date,
        cast(end_date as date) as end_date,

        -- 验证结果
        validation_result,
        cast(deviation_count as integer) as deviation_count,

        -- 审批流程
        responsible,
        reviewer,
        approver,
        cast(approval_date as date) as approval_date,

        -- 再验证
        cast(next_revalidation_date as date) as next_revalidation_date,

        -- 状态
        validation_status,

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