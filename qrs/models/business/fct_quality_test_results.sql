{{
    config(
        materialized='table',
        tags=['lims', 'quality', 'inspection', 'pqr']
    )
}}

with inspection_results as (
    select * from {{ ref('stg_inspection_result') }}
),

samples as (
    select * from {{ ref('stg_sample') }}
),

test_items as (
    select * from {{ ref('stg_test_item') }}
),

quality_standards as (
    select * from {{ ref('dim_quality_standards') }}
),

parsed as (
    select
        ir.result_id,
        ir.task_id,
        ir.test_item_id,
        ti.item_code,
        ti.item_name,
        ti.test_method,

        ir.sample_id,
        s.sample_code,
        s.batch_number,
        nullif(upper(trim(s.material_id::text)), '') as material_id,

        ir.test_date,
        ir.result_status,
        ir.review_status,

        nullif(trim(ir.test_value::text), '') as result_raw,
        {{ parse_numeric('ir.test_value') }} as result_numeric,

        coalesce(nullif(trim(ir.test_unit::text), ''), nullif(trim(ti.unit::text), '')) as uom,

        nullif(trim(ir.standard_min::text), '') as standard_min_raw,
        nullif(trim(ir.standard_max::text), '') as standard_max_raw,
        {{ parse_numeric('ir.standard_min') }} as standard_min_numeric,
        {{ parse_numeric('ir.standard_max') }} as standard_max_numeric,
        {{ parse_numeric('ti.min_value') }} as default_min_numeric,
        {{ parse_numeric('ti.max_value') }} as default_max_numeric,

        case
            when nullif(trim(ir.standard_min::text), '') is not null
              or nullif(trim(ir.standard_max::text), '') is not null
            then 'result_record'
            else 'test_item_default'
        end as limit_source,

        ti.standard_id,
        qs.standard_version,
        qs.effective_date as standard_effective_date,
        qs.expiry_date as standard_expiry_date,
        qs.standard_status,

        ir.loaded_at as source_loaded_at,
        ir.create_date,
        ir.update_date
    from inspection_results ir
    left join samples s
        on ir.sample_id = s.sample_id
    left join test_items ti
        on ir.test_item_id = ti.test_item_id
    left join quality_standards qs
        on ti.standard_id = qs.standard_id
),

typed as (
    select
        *,
        case
            when result_numeric is null then result_raw
            else null
        end as result_text,

        coalesce(standard_min_numeric, default_min_numeric) as lower_limit,
        coalesce(standard_max_numeric, default_max_numeric) as upper_limit,

        case
            when result_numeric is null then null
            when (
                (coalesce(standard_min_numeric, default_min_numeric) is not null
                    and result_numeric < coalesce(standard_min_numeric, default_min_numeric))
                or (coalesce(standard_max_numeric, default_max_numeric) is not null
                    and result_numeric > coalesce(standard_max_numeric, default_max_numeric))
            )
            then true
            else false
        end as is_oos
    from parsed
),

final as (
    select
        *,
        case
            when standard_effective_date is null and standard_expiry_date is null then true
            when standard_effective_date is not null and standard_expiry_date is not null
                then test_date::date between standard_effective_date::date and standard_expiry_date::date
            when standard_effective_date is not null and standard_expiry_date is null
                then test_date::date >= standard_effective_date::date
            when standard_effective_date is null and standard_expiry_date is not null
                then test_date::date <= standard_expiry_date::date
            else null
        end as is_standard_effective_at_test_date
    from typed
)

select * from final
