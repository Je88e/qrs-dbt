{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'pv', 'safety']
    )
}}

/*
    Model: stg_adverse_event
    Description: PV不良反应报告原始数据清洗层 - Staging层
    Source: PV系统不良反应报告表
    Grain: 每行代表一条不良反应报告
*/

with source_data as (
    select * from {{ source('pv_raw', 'pv_adverse_event') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        event_id,
        event_code,
        product_id,
        batch_number,
        event_date,
        report_date,
        event_type,
        severity,
        description as event_description,
        patient_age,
        patient_gender,
        outcome,
        causality_assessment,
        reporter_type,
        reporter_name,
        status as event_status,
        investigator,
        close_date,
        create_date,
        update_date,
        _airbyte_extracted_at as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where _loaded_at > (
    select coalesce(max(_loaded_at), '1900-01-01'::timestamp)
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}