# 阶段 2: Business 层重构详细计划

## 📊 现状分析

### 当前 Business 层模型统计
- **总模型数**: 40 个
- **目录结构**: 6 个子目录 (erp/, mes/, lims/, qms/, scada/, pv/)
- **Schema 文件**: 6 个 (每个子目录一个)

### 模型分类分析

#### 1. ERP 系统 (7 个模型)
| 当前文件名 | 模型类型 | 复杂度 | 建议分层 | 建议新名称 |
|-----------|---------|--------|---------|-----------|
| purchase_order.sql | 事实表 | 中 (4表Join) | Business | fct_purchase_orders.sql |
| material_receipt.sql | 事实表 | 中 (5表Join) | Business | fct_material_receipts.sql |
| material_return.sql | 事实表 | 中 (4表Join) | Business | fct_material_returns.sql |
| inventory_management.sql | 事实表 | 高 (5表Join+聚合) | Business | fct_inventory.sql |
| inventory_transaction.sql | 事实表 | 中 (3表Join) | Business | fct_inventory_transactions.sql |
| formula_management.sql | 事实表 | 中 (3表Join) | Business | fct_formulas.sql |
| warehouse_info.sql | 维度表 | 低 (2表Join) | Business | dim_warehouses.sql |

#### 2. MES 系统 (10 个模型)
| 当前文件名 | 模型类型 | 复杂度 | 建议分层 | 建议新名称 |
|-----------|---------|--------|---------|-----------|
| work_order.sql | 事实表 | 低 (2表Join) | Business | fct_work_orders.sql |
| production_report.sql | 事实表 | 中 (4表Join) | Business | fct_production_reports.sql |
| operation_management.sql | 事实表 | 高 (5表Join) | Business | fct_operations.sql |
| material_consumption.sql | 事实表 | 中 (5表Join) | Business | fct_material_consumption.sql |
| equipment_maintenance.sql | 事实表 | 中 (3表Join) | Business | fct_equipment_maintenance.sql |
| production_efficiency.sql | 聚合分析 | 高 (聚合+计算) | Intermediate | int_production__efficiency_metrics.sql |
| equipment_info.sql | 维度表 | 低 (2表Join) | Business | dim_equipment.sql |
| production_line_info.sql | 维度表 | 低 (2表Join) | Business | dim_production_lines.sql |
| workshop_info.sql | 维度表 | 低 (1表) | Business | dim_workshops.sql |
| personnel_info.sql | 维度表 | 中 (3表Join) | Business | dim_personnel.sql |

#### 3. LIMS 系统 (9 个模型)
| 当前文件名 | 模型类型 | 复杂度 | 建议分层 | 建议新名称 |
|-----------|---------|--------|---------|-----------|
| inspection_request.sql | 事实表 | 低 (2表Join) | Business | fct_inspection_requests.sql |
| inspection_task.sql | 事实表 | 中 (5表Join) | Business | fct_inspection_tasks.sql |
| inspection_result.sql | 事实表 | 中 (4表Join) | Business | fct_inspection_results.sql |
| inspection_report.sql | 事实表 | 中 (4表Join) | Business | fct_inspection_reports.sql |
| quality_analytics.sql | 聚合分析 | 高 (聚合+计算) | Intermediate | int_quality__inspection_metrics.sql |
| sample_management.sql | 维度表 | 低 (2表Join) | Business | dim_samples.sql |
| quality_standard.sql | 维度表 | 低 (1表) | Business | dim_quality_standards.sql |
| test_item_info.sql | 维度表 | 低 (2表Join) | Business | dim_test_items.sql |
| analyst_info.sql | 维度表 | 低 (1表) | Business | dim_analysts.sql |

#### 4. QMS 系统 (6 个模型)
| 当前文件名 | 模型类型 | 复杂度 | 建议分层 | 建议新名称 |
|-----------|---------|--------|---------|-----------|
| change_control.sql | 事实表 | 低 (1表) | Business | fct_change_controls.sql |
| change_impact_assessment.sql | 事实表 | 低 (2表Join) | Business | fct_change_impacts.sql |
| change_implementation.sql | 事实表 | 低 (2表Join) | Business | fct_change_implementations.sql |
| deviation_management.sql | 事实表 | 低 (1表) | Business | fct_deviations.sql |
| capa_management.sql | 事实表 | 低 (2表Join) | Business | fct_capas.sql |
| supplier_audit.sql | 事实表 | 低 (2表Join) | Business | fct_supplier_audits.sql |

#### 5. SCADA 系统 (5 个模型)
| 当前文件名 | 模型类型 | 复杂度 | 建议分层 | 建议新名称 |
|-----------|---------|--------|---------|-----------|
| equipment_monitoring.sql | 事实表 | 中 (4表Join) | Business | fct_equipment_monitoring.sql |
| environment_monitoring.sql | 事实表 | 低 (2表Join) | Business | fct_environment_monitoring.sql |
| alarm_management.sql | 事实表 | 中 (3表Join) | Business | fct_alarms.sql |
| batch_tracking.sql | 事实表 | 中 (4表Join) | Business | fct_batch_tracking.sql |
| energy_consumption.sql | 事实表 | 中 (3表Join) | Business | fct_energy_consumption.sql |

#### 6. PV 系统 (3 个模型)
| 当前文件名 | 模型类型 | 复杂度 | 建议分层 | 建议新名称 |
|-----------|---------|--------|---------|-----------|
| adverse_event.sql | 事实表 | 低 (2表Join) | Business | fct_adverse_events.sql |
| complaint_handling.sql | 事实表 | 低 (2表Join) | Business | fct_complaints.sql |
| product_recall.sql | 事实表 | 低 (2表Join) | Business | fct_product_recalls.sql |

### 分层决策总结
- **Business 层**: 38 个模型 (28 个事实表 + 10 个维度表)
- **Intermediate 层**: 2 个模型 (聚合分析模型)
  - `int_production__efficiency_metrics.sql` (来自 production_efficiency.sql)
  - `int_quality__inspection_metrics.sql` (来自 quality_analytics.sql)

## 📋 重构执行计划

### 步骤 1: 创建 Intermediate 层目录和模型
**操作**: 
1. 创建 `qrs/models/intermediate/` 目录
2. 移动 2 个聚合分析模型到 intermediate 层
3. 重命名为 `int_` 前缀格式
4. 创建 `_intermediate.yml` 配置文件

### 步骤 2: 重新组织 Business 层目录结构
**操作**:
1. 将所有 40 个模型从子目录移动到 `qrs/models/business/` 根目录
2. 删除 6 个子目录 (erp/, mes/, lims/, qms/, scada/, pv/)
3. 合并 6 个 schema.yml 文件到一个 `_business.yml`

### 步骤 3: 统一模型命名规范
**操作**:
1. 重命名 28 个事实表为 `fct_<业务过程>.sql` 格式
2. 重命名 10 个维度表为 `dim_<实体>.sql` 格式
3. 重命名 2 个中间模型为 `int_<业务域>__<描述>.sql` 格式

### 步骤 4: 更新所有 Seeds 引用为 Staging 引用
**操作**:
1. 批量替换所有 `{{ ref('erp_*') }}` 为 `{{ ref('stg_*') }}`
2. 批量替换所有 `{{ ref('mes_*') }}` 为 `{{ ref('stg_*') }}`
3. 批量替换所有 `{{ ref('lims_*') }}` 为 `{{ ref('stg_*') }}`
4. 批量替换所有 `{{ ref('qms_*') }}` 为 `{{ ref('stg_*') }}`
5. 批量替换所有 `{{ ref('scada_*') }}` 为 `{{ ref('stg_*') }}`
6. 批量替换所有 `{{ ref('pv_*') }}` 为 `{{ ref('stg_*') }}`

### 步骤 5: 更新模型间引用
**操作**:
1. 更新 `quality_analytics.sql` 中的 `{{ ref('inspection_request') }}` 为 `{{ ref('fct_inspection_requests') }}`
2. 更新 `production_efficiency.sql` 中的 `{{ ref('work_order') }}` 为 `{{ ref('fct_work_orders') }}`
3. 更新 reports 层的引用

### 步骤 6: 验证和测试
**操作**:
1. 运行 `dbt compile` 验证语法
2. 运行 `dbt run --select intermediate.*` 构建 Intermediate 层
3. 运行 `dbt run --select business.*` 构建 Business 层
4. 运行 `dbt test` 执行所有测试
5. 生成依赖关系图验证

## 📝 详细文件操作清单

### A. Seeds 到 Staging 引用映射表 (44 个)

| Seeds 引用 | Staging 引用 |
|-----------|-------------|
| `{{ ref('erp_purchase_order') }}` | `{{ ref('stg_purchase_order') }}` |
| `{{ ref('erp_purchase_order_detail') }}` | `{{ ref('stg_purchase_order_detail') }}` |
| `{{ ref('erp_material_receipt') }}` | `{{ ref('stg_material_receipt') }}` |
| `{{ ref('erp_material_return') }}` | `{{ ref('stg_material_return') }}` |
| `{{ ref('erp_material_master') }}` | `{{ ref('stg_material_master') }}` |
| `{{ ref('erp_supplier_master') }}` | `{{ ref('stg_supplier_master') }}` |
| `{{ ref('erp_formula_master') }}` | `{{ ref('stg_formula_master') }}` |
| `{{ ref('erp_formula_detail') }}` | `{{ ref('stg_formula_detail') }}` |
| `{{ ref('erp_inventory') }}` | `{{ ref('stg_inventory') }}` |
| `{{ ref('erp_inventory_transaction') }}` | `{{ ref('stg_inventory_transaction') }}` |
| `{{ ref('erp_warehouse') }}` | `{{ ref('stg_warehouse') }}` |
| `{{ ref('erp_storage_location') }}` | `{{ ref('stg_storage_location') }}` |
| `{{ ref('mes_work_order') }}` | `{{ ref('stg_work_order') }}` |
| `{{ ref('mes_operation') }}` | `{{ ref('stg_operation') }}` |
| `{{ ref('mes_work_order_operation') }}` | `{{ ref('stg_work_order_operation') }}` |
| `{{ ref('mes_production_report') }}` | `{{ ref('stg_production_report') }}` |
| `{{ ref('mes_equipment') }}` | `{{ ref('stg_equipment') }}` |
| `{{ ref('mes_equipment_maintenance') }}` | `{{ ref('stg_equipment_maintenance') }}` |
| `{{ ref('mes_production_line') }}` | `{{ ref('stg_production_line') }}` |
| `{{ ref('mes_workshop') }}` | `{{ ref('stg_workshop') }}` |
| `{{ ref('mes_material_consumption') }}` | `{{ ref('stg_material_consumption') }}` |
| `{{ ref('mes_personnel') }}` | `{{ ref('stg_personnel') }}` |
| `{{ ref('lims_inspection_request') }}` | `{{ ref('stg_inspection_request') }}` |
| `{{ ref('lims_inspection_task') }}` | `{{ ref('stg_inspection_task') }}` |
| `{{ ref('lims_inspection_result') }}` | `{{ ref('stg_inspection_result') }}` |
| `{{ ref('lims_sample') }}` | `{{ ref('stg_sample') }}` |
| `{{ ref('lims_quality_standard') }}` | `{{ ref('stg_quality_standard') }}` |
| `{{ ref('lims_test_item') }}` | `{{ ref('stg_test_item') }}` |
| `{{ ref('lims_analyst') }}` | `{{ ref('stg_analyst') }}` |
| `{{ ref('lims_inspection_report') }}` | `{{ ref('stg_inspection_report') }}` |
| `{{ ref('qms_change_control') }}` | `{{ ref('stg_change_control') }}` |
| `{{ ref('qms_change_impact') }}` | `{{ ref('stg_change_impact') }}` |
| `{{ ref('qms_change_implementation') }}` | `{{ ref('stg_change_implementation') }}` |
| `{{ ref('qms_deviation') }}` | `{{ ref('stg_deviation') }}` |
| `{{ ref('qms_capa') }}` | `{{ ref('stg_capa') }}` |
| `{{ ref('qms_supplier_audit') }}` | `{{ ref('stg_supplier_audit') }}` |
| `{{ ref('scada_equipment_data') }}` | `{{ ref('stg_equipment_data') }}` |
| `{{ ref('scada_environment_data') }}` | `{{ ref('stg_environment_data') }}` |
| `{{ ref('scada_alarm') }}` | `{{ ref('stg_alarm') }}` |
| `{{ ref('scada_batch_tracking') }}` | `{{ ref('stg_batch_tracking') }}` |
| `{{ ref('scada_energy_consumption') }}` | `{{ ref('stg_energy_consumption') }}` |
| `{{ ref('pv_adverse_event') }}` | `{{ ref('stg_adverse_event') }}` |
| `{{ ref('pv_complaint') }}` | `{{ ref('stg_complaint') }}` |
| `{{ ref('pv_product_recall') }}` | `{{ ref('stg_product_recall') }}` |

### B. Business 模型间引用映射表

| 旧引用 | 新引用 |
|-------|-------|
| `{{ ref('inspection_request') }}` | `{{ ref('fct_inspection_requests') }}` |
| `{{ ref('work_order') }}` | `{{ ref('fct_work_orders') }}` |

### C. 文件重命名映射表 (40 个)

#### ERP 系统 (7 个)
```
models/business/erp/purchase_order.sql → models/business/fct_purchase_orders.sql
models/business/erp/material_receipt.sql → models/business/fct_material_receipts.sql
models/business/erp/material_return.sql → models/business/fct_material_returns.sql
models/business/erp/inventory_management.sql → models/business/fct_inventory.sql
models/business/erp/inventory_transaction.sql → models/business/fct_inventory_transactions.sql
models/business/erp/formula_management.sql → models/business/fct_formulas.sql
models/business/erp/warehouse_info.sql → models/business/dim_warehouses.sql
```

#### MES 系统 (10 个)
```
models/business/mes/work_order.sql → models/business/fct_work_orders.sql
models/business/mes/production_report.sql → models/business/fct_production_reports.sql
models/business/mes/operation_management.sql → models/business/fct_operations.sql
models/business/mes/material_consumption.sql → models/business/fct_material_consumption.sql
models/business/mes/equipment_maintenance.sql → models/business/fct_equipment_maintenance.sql
models/business/mes/production_efficiency.sql → models/intermediate/int_production__efficiency_metrics.sql
models/business/mes/equipment_info.sql → models/business/dim_equipment.sql
models/business/mes/production_line_info.sql → models/business/dim_production_lines.sql
models/business/mes/workshop_info.sql → models/business/dim_workshops.sql
models/business/mes/personnel_info.sql → models/business/dim_personnel.sql
```

#### LIMS 系统 (9 个)
```
models/business/lims/inspection_request.sql → models/business/fct_inspection_requests.sql
models/business/lims/inspection_task.sql → models/business/fct_inspection_tasks.sql
models/business/lims/inspection_result.sql → models/business/fct_inspection_results.sql
models/business/lims/inspection_report.sql → models/business/fct_inspection_reports.sql
models/business/lims/quality_analytics.sql → models/intermediate/int_quality__inspection_metrics.sql
models/business/lims/sample_management.sql → models/business/dim_samples.sql
models/business/lims/quality_standard.sql → models/business/dim_quality_standards.sql
models/business/lims/test_item_info.sql → models/business/dim_test_items.sql
models/business/lims/analyst_info.sql → models/business/dim_analysts.sql
```

#### QMS 系统 (6 个)
```
models/business/qms/change_control.sql → models/business/fct_change_controls.sql
models/business/qms/change_impact_assessment.sql → models/business/fct_change_impacts.sql
models/business/qms/change_implementation.sql → models/business/fct_change_implementations.sql
models/business/qms/deviation_management.sql → models/business/fct_deviations.sql
models/business/qms/capa_management.sql → models/business/fct_capas.sql
models/business/qms/supplier_audit.sql → models/business/fct_supplier_audits.sql
```

#### SCADA 系统 (5 个)
```
models/business/scada/equipment_monitoring.sql → models/business/fct_equipment_monitoring.sql
models/business/scada/environment_monitoring.sql → models/business/fct_environment_monitoring.sql
models/business/scada/alarm_management.sql → models/business/fct_alarms.sql
models/business/scada/batch_tracking.sql → models/business/fct_batch_tracking.sql
models/business/scada/energy_consumption.sql → models/business/fct_energy_consumption.sql
```

#### PV 系统 (3 个)
```
models/business/pv/adverse_event.sql → models/business/fct_adverse_events.sql
models/business/pv/complaint_handling.sql → models/business/fct_complaints.sql
models/business/pv/product_recall.sql → models/business/fct_product_recalls.sql
```

## ⚠️ 风险评估

### 高风险项
1. **Reports 层依赖**: `pqr_summary_report.sql` 可能引用了旧的模型名称
2. **模型间引用**: `quality_analytics` 和 `production_efficiency` 引用了其他 business 模型

### 缓解措施
1. 先更新 Seeds 引用,再重命名模型
2. 使用 `dbt compile` 在每个步骤后验证
3. 保留旧目录结构直到验证通过

## 📊 预期结果

### 重构后的目录结构
```
qrs/models/
├── staging/                    # 44 个 staging 模型
│   ├── _sources.yml
│   ├── _staging.yml
│   └── stg_*.sql (44 个)
├── intermediate/               # 2 个 intermediate 模型
│   ├── _intermediate.yml
│   ├── int_production__efficiency_metrics.sql
│   └── int_quality__inspection_metrics.sql
├── business/                   # 38 个 business 模型 (平铺)
│   ├── _business.yml
│   ├── fct_*.sql (28 个事实表)
│   └── dim_*.sql (10 个维度表)
└── reports/                    # 1 个报告模型
    ├── schema.yml
    └── pqr_summary_report.sql
```

### 数据流向
```
Seeds (44) → Staging (44) → Intermediate (2) → Business (38) → Reports (1)
                          ↘                   ↗
```

