{{
    config(
        materialized='view',
        tags=['quality', 'events', 'dim', 'pqr', 'h3']
    )
}}

select
    risk_level_code,
    risk_level_name,
    risk_level_description,
    sort_order,
    is_active,
    source_system,
    create_date,
    update_date,
    loaded_at as source_loaded_at
from {{ ref('stg_risk_levels') }}
