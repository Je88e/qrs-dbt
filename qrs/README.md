# QRS (Quality & Reporting System)

A GxP-compliant pharmaceutical data warehouse built with dbt on PostgreSQL.

## Project Overview

QRS integrates data from 6 source systems to support Product Quality Review (PQR) reporting and GxP compliance.

| Source System | Tables | Domain |
|--------------|--------|--------|
| ERP | 12 | Purchase orders, materials, inventory, formulas |
| MES | 10 | Work orders, production, equipment, personnel |
| LIMS | 8 | Inspection requests, results, samples, standards |
| QMS | 6 | Change controls, deviations, CAPAs, audits |
| SCADA | 5 | Equipment data, alarms, environment, batch tracking |
| PV | 3 | Adverse events, complaints, product recalls |

## Quick Start

```bash
# Install dependencies
dbt deps

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate

docker run --rm \
  -p 8080:8080 \
  -v "$(pwd)/profiles:/app/profiles:ro" \
  --name qrs-dbt-docs \
  qrs-dbt-docs:latest

# Load seed data (use raw target)
dbt seed --target=raw
```

## Project Statistics

<!-- AUTO-GENERATED: Model counts -->
| Layer | Models | Materialization |
|-------|--------|-----------------|
| Staging | 58 | table |
| Intermediate | 9 | view |
| Business | 60 | mixed (view/table) |
| Reports | 1 | table |
| Snapshots | 49 | snapshot (SCD Type 2) |
| Seeds | 58 | csv |
<!-- END AUTO-GENERATED -->

## Architecture

```
raw schema (source tables)
    └── staging (stg_*) ───────────── table
        └── intermediate (int_*) ──── view
            └── business (dim_*, fct_*) ─ mixed
                └── reports ─────────── table

snapshots schema ──────────────────── SCD Type 2
```

### Layer Rules

1. **Staging Layer** (`stg_*`)
   - 1:1 mapping to source tables
   - ONLY layer that uses `{{ source() }}`
   - NO joins, NO aggregations
   - Adds surrogate keys (snowflake_id)
   - Adds loaded_at timestamp

2. **Intermediate Layer** (`int_*`)
   - Complex joins (>4 entities)
   - Aggregations and metrics calculations
   - Always materialized as view

3. **Business Layer** (`dim_*`, `fct_*`)
   - Dimension tables: view (small, low update frequency)
   - Fact tables: table (large, frequent queries)
   - All joins between domains happen here

4. **Reports Layer**
   - Final aggregated reports
   - Materialized as table

### Naming Conventions

| Type | Pattern | Examples |
|------|---------|----------|
| Staging | `stg_<entity>` | `stg_purchase_order`, `stg_material_master` |
| Intermediate | `int_<domain>__<metric>` | `int_production__efficiency_metrics` |
| Dimensions | `dim_<entity>` | `dim_warehouses`, `dim_analysts` |
| Facts | `fct_<entity>` | `fct_purchase_orders`, `fct_inspection_results` |
| Snapshots | `snap_<entity>` | `snap_purchase_orders`, `snap_deviations` |
| Primary keys | `<entity>_id` | `purchase_order_number`, `material_id` |
| Foreign keys | `<referenced_entity>_id` | `supplier_id`, `equipment_id` |
| Timestamps | `<event>_at` | `created_at`, `loaded_at` |
| Dates | `<event>_date` | `order_date`, `inspection_date` |
| Booleans | `is_*`, `has_*` | `is_deleted`, `is_frozen` |

## dbt Commands Reference

<!-- AUTO-GENERATED: Commands -->
### Development Commands

| Command | Description |
|---------|-------------|
| `dbt deps` | Install packages from packages.yml |
| `dbt run` | Execute all models |
| `dbt test` | Run all tests |
| `dbt compile` | Compile SQL without executing |
| `dbt clean` | Remove target/ and dbt_packages/ |
| `dbt docs generate` | Generate documentation site |

### Selective Execution

| Command | Description |
|---------|-------------|
| `dbt run --select stg_*` | Run staging models only |
| `dbt run --select +fct_*` | Run fact tables with upstream dependencies |
| `dbt run --select +my_model+` | Run model with upstream and downstream |
| `dbt test --select stg_*` | Test staging models only |

### Snapshot & Audit

| Command | Description |
|---------|-------------|
| `dbt snapshot` | Refresh all snapshots (SCD Type 2) |
| `dbt run-operation execute_compiled_audit` | Run audit comparison |
| `dbt run-operation create_snapshot_indexes` | Create snapshot indexes |

### Seeds

| Command | Description |
|---------|-------------|
| `dbt seed` | Load all seed files |
| `dbt seed --select lims_*` | Load LIMS seeds only |
<!-- END AUTO-GENERATED -->

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| dbt_utils | 1.3.3 | Macros: surrogate_key, date_spine, etc. |
| audit_helper | 0.12.2 | Row/column level data comparison |

## Audit Trail (GxP Compliance)

### Track 1: Snapshots (SCD Type 2)

Location: `snapshots` schema

| Snapshot | Source System | Description |
|----------|--------------|-------------|
| snap_purchase_orders | ERP | Purchase order history |
| snap_material_receipts | ERP | Material receipt history |
| snap_deviations | QMS | Deviation records history |
| snap_capas | QMS | CAPA records history |
| snap_change_controls | QMS | Change control history |
| snap_inspection_requests | LIMS | Inspection request history |
| snap_inspection_results | LIMS | Inspection result history |

Metadata columns:
- `valid_from` / `valid_to`: SCD Type 2 validity period
- `snapshot_id`: Unique snapshot record identifier
- `is_deleted`: Soft delete flag

### Track 2: audit_helper (Development)

Macros in `macros/tests/` for data validation:
- `compare_model_columns`: Column-level comparison
- `compare_model_rows`: Row-level comparison
- `execute_compiled_audit`: Full audit execution

## Global Variables

Defined in `dbt_project.yml`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `snowflake_machine_id` | 1 | Machine ID for snowflake ID generation (0-1023) |
| `snowflake_epoch` | 1704067200000 | Epoch for snowflake ID (2024-01-01 UTC) |
| `incremental_lookback_minutes` | 5 | General incremental lookback window |
| `high_frequency_lookback_minutes` | 2 | SCADA system lookback window |

## Testing Strategy

Every model must have tests in `.yml` files:

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
          - accepted_values:
              values: ['待处理', '进行中', '已完成', '已取消']
```

Test types:
- **Primary keys**: `unique` + `not_null` (mandatory)
- **Foreign keys**: `relationships` test
- **Enums**: `accepted_values` test
- **Custom tests**: In `tests/` directory

## Key Files Reference

| File | Purpose |
|------|---------|
| `dbt_project.yml` | Project config, materialization settings |
| `models/staging/_sources.yml` | 44 source table definitions |
| `models/staging/_staging.yml` | Staging model tests and docs |
| `models/business/schema.yml` | Business model tests and docs |
| `packages.yml` | Package dependencies |
| `snapshots/*.sql` | Snapshot definitions (49 total) |
| `macros/snowflake/*.sql` | Snowflake ID generation |

## Development Guidelines

### Import CTE Pattern (MANDATORY)

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

Rules:
- All `ref()` and `source()` in top CTEs only
- Last line must be `select * from final`
- Use explicit `as` for aliases
- 4-space indentation, lowercase keywords

### Layer Adherence

1. NEVER skip layers - No direct source → business connections
2. NO circular dependencies - Business cannot reference staging
3. Check for existing `stg_*` models before creating new logic

## Resources

- [dbt Documentation](https://docs.getdbt.com/docs/introduction)
- [dbt Discourse](https://discourse.getdbt.com/) - Q&A
- [dbt Slack](https://community.getdbt.com/) - Community chat
- [dbt Blog](https://blog.getdbt.com/) - Best practices