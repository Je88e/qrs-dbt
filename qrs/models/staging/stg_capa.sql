{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_capa
    Description: QMS CAPA主数据原始数据清洗层 - Staging层
    Source: QMS系统CAPA主表
    Grain: 每行代表一条CAPA记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_capa') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        capa_id,
        capa_code,
        capa_title,
        capa_type,
        source_type,
        source_id,
        description as capa_description,
        root_cause_analysis,
        corrective_action,
        preventive_action,
        responsible,
        planned_completion,
        actual_completion,
        status as capa_status,
        effectiveness_check,
        effectiveness_date,
        creator,
        approver,
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