{{
    config(
        materialized='view',
        tags=['erp', 'master_data', 'material', 'pqr']
    )
}}

with material_master as (
    select * from {{ ref('stg_material_master') }}
),

material_master_normalized as (
    select
        nullif(upper(trim(material_id::text)), '') as material_id,
        material_name::text as material_name,
        material_type::text as material_type,
        material_specification::text as material_specification,
        unit::text as unit,
        supplier_id::text as supplier_id,
        approval_status::text as approval_status,
        is_deleted::text as is_deleted,
        create_date,
        update_date,
        loaded_at
    from material_master
),

sample_material_ids as (
    select distinct
        nullif(upper(trim(material_id::text)), '') as material_id
    from {{ ref('stg_sample') }}
    where nullif(trim(material_id::text), '') is not null
),

missing_in_master as (
    select
        sm.material_id
    from sample_material_ids sm
    left join material_master_normalized mm
        on sm.material_id = mm.material_id
    where mm.material_id is null
),

final as (
    select * from material_master_normalized

    union all

    select
        material_id,
        null::text as material_name,
        null::text as material_type,
        null::text as material_specification,
        null::text as unit,
        null::text as supplier_id,
        null::text as approval_status,
        null::text as is_deleted,
        null::timestamp as create_date,
        null::timestamp as update_date,
        null::timestamptz as loaded_at
    from missing_in_master
)

select * from final
