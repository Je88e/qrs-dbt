{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='purchase_order_number',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'procurement']
    )
}}

/*
    Model: stg_purchase_order
    Description: ERP采购订单原始数据清洗层 - Staging层
    Source: ERP系统采购订单主表
    Grain: 每行代表一个采购订单

    升级说明:
    - 新增 snowflake_id: 分布式唯一标识符
    - 新增 _loaded_at: dbt处理时间戳，用于增量控制
    - 物化策略: incremental (merge)
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_purchase_order') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,

        -- 主键
        po_number as purchase_order_number,

        -- 供应商信息
        supplier_id,

        -- 订单信息
        po_type as order_type,
        po_status as order_status,
        order_date,
        expected_delivery_date,
        actual_delivery_date,

        -- 金额信息
        total_amount,
        currency,

        -- 审批信息
        buyer,
        approver,
        approval_date,

        -- 审计字段（源系统时间，用于业务分析）
        create_date,
        update_date,

        -- 新增：dbt处理时间戳（用于增量控制）
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

    from source_data
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}
