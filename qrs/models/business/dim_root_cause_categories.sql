{{
    config(
        materialized='view',
        tags=['quality', 'events', 'dim', 'pqr', 'h3']
    )
}}

select
    root_cause_category_code,
    root_cause_category_name,
    root_cause_category_description,
    sort_order,
    is_active,
    source_system,
    create_date,
    update_date,
    loaded_at as source_loaded_at
from {{ ref('stg_root_cause_categories') }}
