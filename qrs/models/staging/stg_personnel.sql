{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_personnel
    Description: MES生产人员主数据原始数据清洗层 - Staging层
    Source: MES系统生产人员主数据表
    Grain: 每行代表一个生产人员
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_personnel') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        personnel_id,
        personnel_code,
        personnel_name,
        department,
        position as job_position,
        skill_level,
        certification,
        workshop_id,
        line_id,
        status as personnel_status,
        entry_date,
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