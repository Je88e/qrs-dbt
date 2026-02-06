{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_deviation
    Description: QMS偏差记录原始数据清洗层 - Staging层
    Source: QMS系统偏差记录主表
    Grain: 每行代表一条偏差记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_deviation') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        deviation_id,
        deviation_code,
        deviation_title,
        deviation_type,
        deviation_category,
        product_id,
        batch_number,
        occurrence_date,
        discovery_date,
        description as deviation_description,
        immediate_action,
        root_cause,
        corrective_action,
        preventive_action,
        status as deviation_status,
        investigator,
        reviewer,
        approver,
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