{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='event_id',
        on_schema_change='append_new_columns',
        tags=['staging', 'pv', 'safety'],
        incremental_predicates=["DBT_INTERNAL_DEST.loaded_at < current_date - interval '7 days'"]
    )
}}

/***
incremental_predicates 是 dbt Core 为增量模型（incremental model） 提供的配置参数，
用于在增量同步过程中添加自定义的 SQL 过滤谓词（WHERE 子句条件），补充或细化默认的增量筛选逻辑，精准控制哪些数据会被纳入增量更新范围，
核心目的是优化增量模型的性能（减少扫描 / 处理的数据量）。
***/

with source_data as (
    select * from {{ source('pv_raw', 'pv_adverse_event') }}
),

-- 在增量模式下，保留目标表中已存在的 snowflake_id
{% if is_incremental() %}
existing_records as (
    select 
        event_id,
        snowflake_id
    from {{ this }}
),
{% endif %}

final as (
    select
        -- 关键：对于已存在的记录，使用目标表的 snowflake_id；新记录才生成新的
        {% if is_incremental() -%}
        coalesce(
            existing.snowflake_id,
            {{ generate_snowflake_id() }}::text
        ) as snowflake_id,
        {% else -%}
        {{ generate_snowflake_id() }}::text as snowflake_id,
        {% endif -%}
        
        source.event_id,
        source.event_code,
        source.product_id,
        source.batch_number,
        source.event_date,
        source.report_date,
        source.event_type,
        source.severity,
        source.description as event_description,
        source.patient_age,
        source.patient_gender,
        source.outcome,
        source.causality_assessment,
        source.reporter_type,
        source.reporter_name,
        source.status as event_status,
        source.investigator,
        source.close_date,
        source.create_date,
        source.update_date,
        CAST(source._airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
    
    from source_data source
    
    {% if is_incremental() -%}
    left join existing_records existing
        on source.event_id = existing.event_id
    {% endif -%}
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}
