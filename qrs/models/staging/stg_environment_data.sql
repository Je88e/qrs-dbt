{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'scada', 'monitoring']
    )
}}

/*
    Model: stg_environment_data
    Description: SCADA环境监控数据原始数据清洗层 - Staging层
    Source: SCADA系统环境监控数据采集表
    Grain: 每行代表一条环境监控数据记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_environment_data') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        data_id,
        location_code,
        location_name,
        temperature,
        humidity,
        pressure_diff as pressure_difference,
        particle_count,
        collection_time,
        status as monitoring_status,
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