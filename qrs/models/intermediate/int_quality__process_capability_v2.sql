{{
    config(
        materialized='view',
        tags=['intermediate', 'quality', 'capability', 'statistics', 'pqr']
    )
}}

with quality_test_results as (
    select * from {{ ref('fct_quality_test_results') }}
),

work_orders as (
    select
        batch_number,
        max(product_id) as product_id,
        max(actual_end_date) as actual_end_date
    from {{ ref('stg_work_order') }}
    where batch_number is not null
    group by batch_number
),

measurements as (
    select
        extract(year from coalesce(wo.actual_end_date, qtr.test_date)) as review_year,
        wo.product_id,
        qtr.test_item_id,
        qtr.uom,
        qtr.standard_id,
        qtr.standard_version,
        qtr.lower_limit as lsl,
        qtr.upper_limit as usl,
        qtr.result_numeric
    from quality_test_results qtr
    left join work_orders wo
        on qtr.batch_number = wo.batch_number
    where qtr.result_numeric is not null
      and qtr.lower_limit is not null
      and qtr.upper_limit is not null
      and wo.product_id is not null
      and coalesce(wo.actual_end_date, qtr.test_date) is not null
      and qtr.is_standard_effective_at_test_date is distinct from false
),

stats as (
    select
        review_year,
        product_id,
        test_item_id,
        uom,
        standard_id,
        standard_version,
        count(*) as measurement_count,
        avg(result_numeric) as mean_value,
        stddev_samp(result_numeric) as stddev_value,
        max(lsl) as lsl,
        max(usl) as usl
    from measurements
    group by
        1, 2, 3, 4, 5, 6
),

final as (
    select
        review_year,
        product_id,
        test_item_id,
        uom,
        standard_id,
        standard_version,
        measurement_count,
        round(mean_value::numeric, 6) as mean_value,
        round(stddev_value::numeric, 6) as stddev_value,
        lsl,
        usl,
        case
            when stddev_value is not null
             and stddev_value > 0
             and lsl is not null
             and usl is not null
            then least(
                (usl - mean_value) / (3 * stddev_value),
                (mean_value - lsl) / (3 * stddev_value)
            )
            else null
        end as cpk
    from stats
)

select * from final
