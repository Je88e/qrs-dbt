{{
    config(
        materialized='view',
        tags=['intermediate', 'quality', 'capability', 'statistics', 'pqr']
    )
}}

/*
    模型: int_quality__process_capability
    描述: PQR 过程能力（Cpk）统计模型 - 按年度/产品/检验项目聚合

    说明:
    - 仅对可解析为数字的检验值/标准上下限参与计算
    - Cpk = min((usl-mean)/(3*sigma), (mean-lsl)/(3*sigma))
*/

with inspection_results as (
    select
        result_id,
        test_item_id,
        sample_id,
        test_value,
        standard_min,
        standard_max
    from {{ ref('current_inspection_results') }}
),

samples as (
    select
        sample_id,
        batch_number
    from {{ ref('current_samples') }}
),

work_orders as (
    select
        batch_number,
        max(product_id) as product_id,
        max(actual_end_date) as actual_end_date
    from {{ ref('current_work_orders') }}
    where batch_number is not null
    group by batch_number
),

results_typed as (
    select
        result_id,
        test_item_id,
        sample_id,
        case
            when test_value ~ '^[0-9]+(\\.[0-9]+)?$' then cast(test_value as numeric)
            else null
        end as test_value_num,
        case
            when standard_min ~ '^[0-9]+(\\.[0-9]+)?$' then cast(standard_min as numeric)
            else null
        end as lsl,
        case
            when standard_max ~ '^[0-9]+(\\.[0-9]+)?$' then cast(standard_max as numeric)
            else null
        end as usl
    from inspection_results
),

results_enriched as (
    select
        extract(year from wo.actual_end_date) as review_year,
        wo.product_id,
        rt.test_item_id,
        rt.test_value_num,
        rt.lsl,
        rt.usl
    from results_typed rt
    inner join samples s
        on rt.sample_id = s.sample_id
    left join work_orders wo
        on s.batch_number = wo.batch_number
    where rt.test_value_num is not null
      and wo.product_id is not null
      and wo.actual_end_date is not null
),

stats as (
    select
        review_year,
        product_id,
        test_item_id,
        count(*) as measurement_count,
        avg(test_value_num) as mean_value,
        stddev_samp(test_value_num) as stddev_value,
        max(lsl) as lsl,
        max(usl) as usl
    from results_enriched
    group by review_year, product_id, test_item_id
),

final as (
    select
        review_year,
        product_id,
        test_item_id,
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
