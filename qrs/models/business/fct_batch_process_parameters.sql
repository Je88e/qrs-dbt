{{
    config(
        materialized='view',
        tags=['scada', 'cpp', 'quality', 'pqr']
    )
}}

/*
    Model: fct_batch_process_parameters
    Description: 批次×工序×参数过程参数汇总事实表 - 将 SCADA 采集点按工序窗口聚合，并与受控限度版本关联输出 OOS 统计
*/

with equipment_data as (
    select * from {{ ref('stg_equipment_data') }}
),

equipment_data_typed as (
    select
        nullif(trim(batch_number::text), '') as batch_number,
        nullif(trim(work_order_number::text), '') as work_order_number,
        nullif(trim(operation_id::text), '') as operation_id,
        nullif(trim(param_name::text), '') as param_name,
        nullif(trim(unit::text), '') as unit,
        collection_time::timestamptz as collected_at,
        {{ parse_numeric('param_value') }} as param_value_numeric,
        loaded_at as source_loaded_at
    from equipment_data
),

work_orders as (
    select
        work_order_number,
        product_id,
        batch_number as wo_batch_number
    from {{ ref('stg_work_order') }}
),

operation_windows as (
    select
        work_order_operation_id,
        work_order_number,
        operation_id,
        window_source,
        window_start_at,
        window_end_at
    from {{ ref('int_production__operation_windows') }}
),

process_limits as (
    select * from {{ ref('dim_process_limits') }}
),

enriched as (
    select
        ow.work_order_operation_id,
        wo.product_id,
        coalesce(ed.batch_number, wo.wo_batch_number) as batch_number,
        ed.work_order_number,
        ed.operation_id,
        ed.param_name,
        nullif(trim(lower(ed.param_name)), '') as param_name_norm,
        ed.unit as param_unit,
        ed.collected_at,
        ed.param_value_numeric,
        ow.window_source,
        ow.window_start_at,
        ow.window_end_at,
        pl.limit_id,
        pl.min_value as spec_min_value,
        pl.max_value as spec_max_value,
        pl.unit as spec_unit,
        pl.limit_version,
        pl.effective_start_date,
        pl.effective_end_date,
        ed.source_loaded_at
    from equipment_data_typed ed
    left join work_orders wo
        on ed.work_order_number = wo.work_order_number
    left join operation_windows ow
        on ed.work_order_number = ow.work_order_number
        and ed.operation_id = ow.operation_id
        and (ow.window_start_at is null or ed.collected_at >= ow.window_start_at)
        and (ow.window_end_at is null or ed.collected_at <= ow.window_end_at)
    left join process_limits pl
        on wo.product_id = pl.product_id
        and ed.operation_id = pl.operation_id
        and nullif(trim(lower(pl.param_name)), '') = nullif(trim(lower(ed.param_name)), '')
        and (pl.effective_start_date is null or ed.collected_at::date >= pl.effective_start_date)
        and (pl.effective_end_date is null or ed.collected_at::date <= pl.effective_end_date)
),

flagged as (
    select
        *,
        case
            when param_value_numeric is null then null
            when (spec_min_value is not null and param_value_numeric < spec_min_value)
              or (spec_max_value is not null and param_value_numeric > spec_max_value)
            then true
            else false
        end as is_out_of_spec
    from enriched
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'limit_id',
            "coalesce(work_order_operation_id::text, '')",
            'work_order_number',
            'operation_id',
            'param_name'
        ]) }} as batch_process_parameter_id,
        limit_id,
        product_id,
        batch_number,
        work_order_number,
        work_order_operation_id,
        operation_id,
        param_name,
        spec_min_value,
        spec_max_value,
        spec_unit,
        limit_version,
        window_source,
        window_start_at,
        window_end_at,
        count(*) as total_points,
        sum(case when is_out_of_spec then 1 else 0 end) as out_of_spec_points,
        min(param_value_numeric) as observed_min_value,
        max(param_value_numeric) as observed_max_value,
        avg(param_value_numeric) as observed_avg_value,
        min(collected_at) as first_collected_at,
        max(collected_at) as last_collected_at,
        min(case when is_out_of_spec then collected_at end) as first_oos_at,
        max(case when is_out_of_spec then collected_at end) as last_oos_at,
        max(source_loaded_at) as source_loaded_at_max
    from flagged
    where work_order_number is not null
      and operation_id is not null
      and param_name is not null
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
)

select
    *,
    out_of_spec_points::numeric / nullif(total_points, 0) as oos_rate
from final
