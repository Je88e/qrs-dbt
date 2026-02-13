{{
    config(
        materialized='view',
        tags=['pqr', 'cpp', 'quality', 'dim']
    )
}}

/*
    Model: dim_process_limits
    Description: CPP/中控参数限度维度表 - 为超限判定提供受控的标准范围与版本信息
*/

with process_limits as (
    select * from {{ ref('stg_process_limits') }}
),

final as (
    select
        limit_id,
        product_id,
        operation_id,
        param_name,
        min_value,
        max_value,
        unit,
        effective_start_date,
        effective_end_date,
        limit_version,
        limit_status,
        case
            when (effective_start_date is null or effective_start_date <= current_date)
             and (effective_end_date is null or effective_end_date >= current_date)
             and coalesce(limit_status, '') not in ('停用', '已停用', 'inactive', 'disabled')
            then true
            else false
        end as is_effective_currently,
        loaded_at
    from process_limits
)

select * from final

