# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**QRS (Quality & Reporting System)** - A GxP-compliant pharmaceutical data warehouse built with dbt on PostgreSQL.

Integrates data from 6 source systems:
- **ERP** (12 tables): Purchase orders, materials, inventory, formulas
- **MES** (10 tables): Work orders, production, equipment, personnel
- **LIMS** (8 tables): Inspection requests, results, samples, standards
- **QMS** (6 tables): Change controls, deviations, CAPAs, audits
- **SCADA** (5 tables): Equipment data, alarms, environment, batch tracking
- **PV** (3 tables): Adverse events, complaints, product recalls

---

## Common Commands

```bash
# Install dependencies
dbt deps

# Run models (staging -> intermediate -> business -> reports)
dbt run

# Run specific layers
dbt run --select stg_*
dbt run --select +fct_*
dbt run --models +my_model+

# Run tests
dbt test
dbt test --select stg_*

# Compile SQL without executing
dbt compile

# Generate documentation
dbt docs generate

# Build lineage (using dbt-column-lineage)
dbt-lineage

# Snapshot refresh (audit trail)
dbt snapshot

# Run audit operations
dbt run-operation execute_compiled_audit
dbt run-operation create_snapshot_indexes

# Clean build artifacts
dbt clean
```

---

## Architecture: 4-Layer Strategy

```
staging (50 models, view)
    -> intermediate (2 models, view)
        -> business (47 models, mixed)
            -> reports (1 model, table)
```

### Staging Layer (`stg_*`)
- **ONLY layer that can use `{{ source() }}`** - All downstream layers must use `{{ ref() }}`
- 1:1 mapping to source tables in `raw` schema
- **NO joins, NO aggregations** - Only renaming, type conversion, basic null handling
- Materialized as `view`

### Intermediate Layer (`int_*`)
- Complex joins (>4 entities) and aggregations
- Models: `int_production__efficiency_metrics`, `int_quality__inspection_metrics`
- Materialized as `view`

### Business Layer (`dim_*`, `fct_*`)
- **Dimension tables** (9): Materialized as `view` - small data, low update frequency
- **Fact tables** (38): Materialized as `table` - large data, frequent queries
- Contains all joins between domains

### Reports Layer
- Final aggregated reports (e.g., `pqr_summary_report`)
- Materialized as `table`

---

## Critical Development Rules

### Import CTE Pattern (MANDATORY)

All models MUST follow this structure:

```sql
with source_data as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

filtered_orders as (
    select
        order_id,
        customer_id,
        order_date
    from source_data
    where order_status = 'completed'
),

final as (
    select
        filtered_orders.order_id,
        customers.customer_name,
        filtered_orders.order_date
    from filtered_orders
    left join customers
        on filtered_orders.customer_id = customers.customer_id
)

select * from final
```

- All `ref()` and `source()` in top CTEs only
- Last line must be `select * from final`
- Use explicit `as` for aliases
- 4-space indentation, lowercase keywords

### Layer Adherence Rules

1. **NEVER skip layers** - No direct source -> business connections
2. **NO circular dependencies** - Business layer cannot reference staging
3. **Check for existing `stg_*` models** before creating new logic

### Naming Conventions

| Type | Convention | Examples |
|------|------------|----------|
| Staging models | `stg_<entity>` | `stg_purchase_order` |
| Intermediate | `int_<domain>__<metric>` | `int_production__efficiency` |
| Dimensions | `dim_<entity>` | `dim_warehouses`, `dim_analysts` |
| Facts | `fct_<entity>` | `fct_purchase_orders`, `fct_inspection_results` |
| Snapshots | `snap_<entity>` | `snap_purchase_orders` |
| Primary keys | `<entity>_id` | `purchase_order_number`, `material_id` |
| Foreign keys | `<referenced_entity>_id` | `supplier_id`, `equipment_id` |
| Timestamps | `<event>_at` | `created_at`, `updated_at`, `approval_date` |
| Dates | `<event>_date` | `order_date`, `inspection_date` |
| Booleans | `is_*`, `has_*` | `is_deleted`, `has_defects` |

---

## Testing Requirements

Every model MUST have tests defined in `.yml` files:

```yaml
models:
  - name: stg_purchase_order
    columns:
      - name: purchase_order_number
        data_tests:
          - unique
          - not_null
      - name: order_status
        data_tests:
          - not_null
          - accepted_values:
              values: ['待处理', '进行中', '已完成', '已取消']
```

- Primary keys: `unique` + `not_null` (mandatory)
- Foreign keys: `relationships` test
- Enums: `accepted_values` test
- Goal: 100% model test coverage

---

## Audit Trail System (GxP Compliance)

### Track 1: Snapshots (Persistent, SCD Type 2)
- Location: `snapshots` schema
- Tables: 7 snapshots (2 ERP, 2 LIMS, 3 QMS)
- Metadata: `valid_from`, `valid_to`, `snapshot_id`, `last_updated_at`, `is_deleted`
- Command: `dbt snapshot`

### Track 2: audit_helper (Ephemeral)
- Validates transformation logic during development
- Not persisted - terminal output only
- Macros in `macros/audit/` for comparison operations

---

## When Creating New Models

1. **Check if staging model exists** - Create `stg_*` first if missing
2. **Follow Import CTE pattern** - All dependencies in top CTEs
3. **Generate `.yml` alongside `.sql`** - Include descriptions and tests
4. **Verify lineage** - No layer violations, no circular dependencies
5. **Use dbt_utils macros** - Don't reinvent common patterns (e.g., `surrogate_key`, `date_spine`)

---

## Key Files Reference

| File | Purpose |
|------|---------|
| [qrs/dbt_project.yml](qrs/dbt_project.yml) | Layer configs, materialization settings |
| [qrs/models/staging/_sources.yml](qrs/models/staging/_sources.yml) | 44 source table definitions |
| [qrs/packages.yml](qrs/packages.yml) | Dependencies (dbt_utils, audit_helper) |
| [.augment/rules/dbt Development Rules.md](.augment/rules/dbt%20Development%20Rules.md) | Full development standards (Chinese) |
