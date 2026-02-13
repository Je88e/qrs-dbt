{{
    config(
        materialized='view',
        tags=['intermediate', 'quality', 'batch', 'compliance', 'pqr']
    )
}}

/*
    模型: int_quality__batch_compliance
    描述: 批次合规指标中间模型（基于批次谱系输出测试通过率等指标）
*/

with genealogy as (
    select * from {{ ref('int_production__batch_genealogy') }}
),

final as (
    select
        work_order_number,
        batch_number,
        product_id,
        manufacture_date,

        count_deviations,
        count_oos,
        total_tests,
        failed_tests,
        (total_tests - failed_tests) as passed_tests,

        case
            when total_tests > 0 then round((total_tests - failed_tests) * 100.0 / total_tests, 2)
            else 0
        end as test_pass_rate_percent,

        compliance_status
    from genealogy
)

select * from final
