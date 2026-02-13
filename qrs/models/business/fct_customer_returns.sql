{{
    config(
        materialized='view',
        tags=['quality', 'pqr', 'returns', 'customer']
    )
}}

/*
    Model: fct_customer_returns
    Description: PQR §23 成品退货事实表 - 提供退货明细与基础衍生指标（响应周期等）
*/

with customer_return as (
    select * from {{ ref('stg_customer_return') }}
),

final as (
    select
        -- 主键
        return_id,

        -- 退货信息
        return_code,
        product_id,
        batch_number,
        customer_name,
        return_date,
        return_quantity,
        unit,
        return_reason,
        return_type,
        return_status,

        -- 衍生字段
        case
            when return_status in ('已完成', '已关闭') then true
            when return_status in ('待处理', '处理中') then false
            else null
        end as is_closed,

        -- 审计字段
        create_date,
        loaded_at

    from customer_return
)

select * from final

