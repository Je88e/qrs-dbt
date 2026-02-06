{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'pv', 'quality']
    )
}}

/*
    Model: stg_complaint
    Description: PV产品投诉记录原始数据清洗层 - Staging层
    Source: PV系统产品投诉记录表
    Grain: 每行代表一条产品投诉记录
*/

with source_data as (
    select * from {{ source('pv_raw', 'pv_complaint') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        complaint_id,
        complaint_code,
        complaint_type,
        complaint_source,
        product_id,
        batch_number,
        complaint_date,
        receive_date,
        complaint_description,
        contact_name,
        contact_phone,
        priority,
        status as complaint_status,
        investigator,
        investigation_result,
        corrective_action,
        response_date,
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