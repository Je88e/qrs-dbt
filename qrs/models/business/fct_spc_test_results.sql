{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'inspection', 'pqr']
    )
}}

/*
    Model: fct_spc_test_results
    Description: LIMS 检验结果事实表 - 映射 JSON 种子数据格式，用于 PQR 质量回顾
    Source: LIMS 系统检验结果、样品、检验项目、分析员数据
    Grain: 每行代表一条检验结果记录（与 JSON 样本数据一致）
*/

with inspection_result as (
    select * from {{ ref('stg_inspection_result') }}
),

inspection_task as (
    select * from {{ ref('stg_inspection_task') }}
),

inspection_request as (
    select * from {{ ref('stg_inspection_request') }}
),

sample as (
    select * from {{ ref('stg_sample') }}
),

test_item as (
    select * from {{ ref('stg_test_item') }}
),

analyst as (
    select * from {{ ref('stg_analyst') }}
),

joined as (
    select
        -- 序号（行号）
        row_number() over (order by ir.sample_id, ir.test_item_id, ir.test_date) as index,

        -- 批次号 (BatchNo)
        s.batch_number as batch_no,

        -- 检验申请单号/订单号 (OrdNo)
        irq.request_id as ord_no,

        -- 物料代码 (MatCode)
        nullif(upper(trim(s.material_id::text)), '') as mat_code,

        -- 检验项目编号 (TestNo)
        ti.item_name as test_no,

        -- 分析物/检验项目名称 (Analyte)
        ti.item_name as analyte,

        -- 采样日期 (SampDate)
        s.sample_date as samp_date,

        -- 检验结果值 (Final)
        ir.test_value as final,

        -- 单位 (Units)
        ir.test_unit as units,

        -- 状态 (S) - 检验结果状态
        ir.result_status as s,

        -- 标准限度 A (LowA/HighA)
        ir.standard_min as low_a,
        ir.standard_max as high_a,

        -- 标准限度 B (LowB/HighB) - 预留字段，当前数据源无此字段
        null::numeric as low_b,
        null::numeric as high_b,

        -- 同义词 (Sinonym) - 检验项目同义词
        ti.item_name as sinonym,

        -- 数字结果 (Numres) - 预留字段
        null::numeric as numres,

        -- 分析员姓名 (FullName)
        a.analyst_name as full_name,

        -- 检验计划 (TestPlan)
        irq.test_plan as test_plan

    from inspection_result ir
    left join sample s on ir.sample_id = s.sample_id
    left join inspection_task it on ir.task_id = it.task_id
    left join inspection_request irq on it.request_id = irq.request_id
    left join test_item ti on ir.test_item_id = ti.test_item_id
    left join analyst a on ir.analyst_id = a.analyst_id
)

select * from joined
