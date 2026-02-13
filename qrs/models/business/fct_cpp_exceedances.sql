{{
    config(
        materialized='view',
        tags=['scada', 'cpp', 'quality', 'pqr']
    )
}}

/*
    Model: fct_cpp_exceedances
    Description: PQR §9.2 CPP超限事实表 - 将SCADA参数采集值与受控限度联接，按批次/工序/参数/日期聚合超限统计
    Notes:
      - 依赖 dim_process_limits (受控口径)
      - 依赖 stg_equipment_data (参数采集值)
*/

with equipment_data as (
    select * from {{ ref('stg_equipment_data') }}
),

equipment_data_typed as (
    select
        batch_number,
        work_order_number,
        operation_id,
        nullif(trim(param_name::text), '') as param_name,
        nullif(trim(unit::text), '') as unit,
        collection_time::timestamptz as collected_at,
        case
            when nullif(trim(param_value::text), '') is null then null
            when trim(param_value::text) ~ '^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$'
                then trim(param_value::text)::numeric
            else null
        end as param_value,
        loaded_at
    from equipment_data
),

work_orders as (
    select * from {{ ref('stg_work_order') }}
),

process_limits as (
    select * from {{ ref('dim_process_limits') }}
),

enriched as (
    select
        pl.limit_id,
        wo.product_id,
        ed.batch_number,
        ed.work_order_number,
        ed.operation_id,
        ed.param_name,
        ed.param_value as param_value,
        ed.unit as param_unit,
        ed.collected_at as collected_at,
        pl.min_value as spec_min_value,
        pl.max_value as spec_max_value,
        pl.unit as spec_unit,
        pl.limit_version,
        pl.effective_start_date,
        pl.effective_end_date,
        ed.loaded_at as source_loaded_at
    from equipment_data_typed ed
    left join work_orders wo
        on ed.work_order_number = wo.work_order_number
    inner join process_limits pl
        on wo.product_id = pl.product_id
        and ed.operation_id = pl.operation_id
        and trim(lower(ed.param_name)) = trim(lower(pl.param_name))
        and (pl.effective_start_date is null or ed.collected_at::date >= pl.effective_start_date)
        and (pl.effective_end_date is null or ed.collected_at::date <= pl.effective_end_date)
),

flagged as (
    select
        *,
        case
            when param_value is null then null
            when (spec_min_value is not null and param_value < spec_min_value)
              or (spec_max_value is not null and param_value > spec_max_value)
            then true
            else false
        end as is_out_of_spec,
        case
            when param_value is null then null
            when spec_min_value is not null and param_value < spec_min_value then 'below_min'
            when spec_max_value is not null and param_value > spec_max_value then 'above_max'
            else 'within_limits'
        end as exceedance_type
    from enriched
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'limit_id',
            'batch_number',
            'work_order_number',
            'operation_id',
            'param_name',
            "date_trunc('day', collected_at)::date"
        ]) }} as cpp_exceedance_id,
        limit_id,
        product_id,
        batch_number,
        work_order_number,
        operation_id,
        param_name,
        spec_min_value,
        spec_max_value,
        spec_unit,
        limit_version,
        date_trunc('day', collected_at)::date as collected_date,
        count(*) as total_points,
        sum(case when is_out_of_spec then 1 else 0 end) as out_of_spec_points,
        min(param_value) as observed_min_value,
        max(param_value) as observed_max_value,
        avg(param_value) as observed_avg_value,
        min(case when is_out_of_spec then collected_at end) as first_oos_at,
        max(case when is_out_of_spec then collected_at end) as last_oos_at,
        max(source_loaded_at) as source_loaded_at_max
    from flagged
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
)

select * from final

