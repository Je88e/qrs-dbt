{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='training_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['qms', 'training', 'personnel']
    )
}}

/*
    Model: stg_training_record
    Description: QMS人员培训记录Staging层
*/

with source as (
    select * from {{ source('qms_raw', 'qms_training_record') }}
),

final as (
    select
        -- 生成雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,

        -- 主键
        training_id,

        -- 人员关联
        personnel_id,

        -- 课程信息
        course_code,
        course_name,
        course_type,

        -- 培训信息
        cast(training_date as date) as training_date,
        cast(training_duration as numeric) as training_duration,
        trainer,

        -- 考核信息
        cast(assessment_score as numeric) as assessment_score,
        assessment_result,
        certificate_no,

        -- 有效期
        cast(valid_from as date) as valid_from,
        cast(valid_to as date) as valid_to,

        -- 状态
        training_status,

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