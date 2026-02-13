# QRS 快照架构详解

> **版本**: 2.0
> **最后更新**: 2026-02-11
> **维护**: Analytics Engineering Team

---

## 1. 架构概览

QRS 审计追踪系统采用 dbt Snapshots 功能实现 SCD Type 2 (Slowly Changing Dimension) 历史记录追踪。本系统覆盖 ERP, MES, LIMS, QMS, SCADA, PV 六大业务系统的 49 个关键数据实体。

### 核心配置策略

所有快照遵循统一的配置规范：

- **目标 Schema**: `snapshots`
- **策略**: `timestamp` (优先) 或 `check`
- **硬删除**: `invalidate` (标记为删除但不物理移除) 或 `new_record` (视具体情况而定，默认配置倾向于保留历史)
- **有效期截止**: `9999-12-31` (当前有效记录)

### 命名规范

- **文件名**: `snap_<业务实体>.sql`
- **表名**: `snapshots.snap_<业务实体>`
- **唯一键**: 通常为业务主键 (如 `purchase_order_number`) 或代理键

---

## 2. ERP 领域快照 (12个)

ERP 快照主要追踪供应链、库存和物料主数据的变更。

| 快照名称 | 业务实体 | 唯一键 | 更新频率 | 说明 |
|---------|---------|--------|---------|------|
| `snap_purchase_orders` | 采购订单 | `purchase_order_number` | 每日 | 追踪订单状态、审批流程及金额变更 |
| `snap_purchase_order_detail` | 采购订单明细 | `po_detail_id` | 每日 | 追踪行项目的数量、价格变更 |
| `snap_inventory` | 库存余额 | `inventory_id` | 每日 | 追踪各仓库/库位的库存数量变化 |
| `snap_inventory_transaction` | 库存事务 | `transaction_id` | 每日 | 追踪入库、出库、调拨记录 |
| `snap_material_master` | 物料主数据 | `material_code` | 每日 | **关键**: 追踪物料属性、规格变更 |
| `snap_material_receipts` | 物料接收 | `receipt_number` | 每日 | 追踪收货状态和检验结果 |
| `snap_material_return` | 物料退货 | `return_number` | 每日 | 追踪退货原因和处理状态 |
| `snap_formula_master` | 配方主数据 | `formula_code` | 每日 | **关键**: 追踪生产配方的版本变更 |
| `snap_formula_detail` | 配方明细 | `formula_detail_id` | 每日 | 追踪配方成分和用量调整 |
| `snap_supplier_master` | 供应商主数据 | `supplier_code` | 每日 | 追踪供应商资质、联系人变更 |
| `snap_warehouse` | 仓库定义 | `warehouse_code` | 每日 | 追踪仓库属性变更 |
| `snap_storage_location` | 库位定义 | `location_code` | 每日 | 追踪库位状态和类型变更 |

---

## 3. MES 领域快照 (10个)

MES 快照聚焦于生产执行过程、设备状态和车间管理。

| 快照名称 | 业务实体 | 唯一键 | 更新频率 | 说明 |
|---------|---------|--------|---------|------|
| `snap_production_report` | 生产报表 | `report_id` | 每日 | 追踪生产日报、班次产量 |
| `snap_work_order` | 生产工单 | `work_order_number` | 每日 | 追踪工单状态、计划/实际时间 |
| `snap_work_order_operation` | 工单工序 | `operation_id` | 每日 | 追踪工序执行情况 |
| `snap_equipment` | 设备台账 | `equipment_code` | 每日 | 追踪设备状态、位置、属性 |
| `snap_equipment_maintenance` | 设备维修 | `maintenance_id` | 每日 | 追踪维修记录和结果 |
| `snap_equipment_calibration` | 设备校准 | `calibration_id` | 每日 | **关键**: 追踪校准证书和有效期 |
| `snap_material_consumption` | 生产投料 | `consumption_id` | 每日 | 追踪实际投料量和批次 |
| `snap_production_line` | 产线定义 | `line_code` | 每日 | 追踪产线配置 |
| `snap_operation` | 标准工序 | `operation_code` | 每日 | 追踪标准工序定义 |
| `snap_personnel` | 人员资质 | `personnel_id` | 每日 | 追踪上岗资质和培训状态 |

---

## 4. LIMS 领域快照 (9个)

LIMS 快照对质量检验过程进行高频追踪，确保数据完整性。

| 快照名称 | 业务实体 | 唯一键 | 更新频率 | 说明 |
|---------|---------|--------|---------|------|
| `snap_inspection_requests` | 检验申请 | `request_number` | **4小时** | 追踪申请状态、采样时间 |
| `snap_inspection_tasks` | 检验任务 | `task_id` | **4小时** | 追踪任务分配、完成情况 |
| `snap_inspection_result` | 检验结果 | `result_id` | **4小时** | **关键**: 追踪原始读数修改记录 |
| `snap_inspection_report` | 检验报告 | `report_number` | 每日 | 追踪COA生成和批准状态 |
| `snap_sample` | 样品管理 | `sample_id` | 每日 | 追踪样品流转状态 |
| `snap_quality_standard` | 质量标准 | `standard_code` | 每日 | **关键**: 追踪检验标准限度变更 |
| `snap_test_item` | 检验项目 | `test_item_code` | 每日 | 追踪检验方法定义 |
| `snap_stability_study` | 稳定性研究 | `study_id` | 每日 | 追踪稳定性考察计划和状态 |
| `snap_water_quality` | 水质监测 | `record_id` | 每日 | 追踪制药用水检测结果 |

---

## 5. QMS 领域快照 (9个)

QMS 快照是 GxP 合规的核心，记录质量管理流程的每一次状态流转。

| 快照名称 | 业务实体 | 唯一键 | 更新频率 | 说明 |
|---------|---------|--------|---------|------|
| `snap_change_controls` | 变更控制 | `change_control_number` | 每日 | 追踪变更申请、评估、批准全过程 |
| `snap_change_impact` | 变更影响 | `impact_id` | 每日 | 追踪变更涉及的范围 |
| `snap_change_implementation` | 变更实施 | `implementation_id` | 每日 | 追踪实施任务完成情况 |
| `snap_deviations` | 偏差管理 | `deviation_number` | 每日 | 追踪偏差调查、根本原因分析 |
| `snap_capas` | CAPA | `capa_number` | 每日 | 追踪纠正预防措施执行 |
| `snap_supplier_audit` | 供应商审计 | `audit_id` | 每日 | 追踪审计计划和发现项 |
| `snap_training_record` | 培训记录 | `record_id` | 每日 | 追踪员工SOP培训记录 |
| `snap_validation_record` | 验证记录 | `validation_id` | 每日 | 追踪验证计划和报告状态 |
| `snap_analyst` | 检验员资质 | `analyst_id` | 每日 | 追踪检验员授权范围 |

---

## 6. SCADA 领域快照 (6个)

SCADA 快照记录自动化系统的高频数据。

| 快照名称 | 业务实体 | 唯一键 | 更新频率 | 说明 |
|---------|---------|--------|---------|------|
| `snap_alarm` | 系统报警 | `alarm_id` | **1小时** | 追踪报警触发、确认、恢复时间 |
| `snap_equipment_data` | 设备运行参数 | `record_id` | **1小时** | 追踪温度、压力等关键参数 |
| `snap_environment_data` | 环境监测 | `record_id` | **1小时** | 追踪温湿度、压差数据 |
| `snap_energy_consumption` | 能耗数据 | `record_id` | **1小时** | 追踪水电气消耗 |
| `snap_batch_tracking` | 批次追踪 | `batch_id` | **1小时** | 追踪批次在设备间的流转 |
| `snap_workshop` | 车间定义 | `workshop_code` | 每日 | 追踪车间区域定义 |

---

## 7. PV 领域快照 (3个)

PV (药物警戒) 快照关注上市后产品安全。

| 快照名称 | 业务实体 | 唯一键 | 更新频率 | 说明 |
|---------|---------|--------|---------|------|
| `snap_adverse_event` | 不良事件 | `ae_number` | 每日 | 追踪不良反应报告及处理 |
| `snap_complaint` | 客户投诉 | `complaint_number` | 每日 | 追踪投诉调查及反馈 |
| `snap_product_recall` | 产品召回 | `recall_number` | 每日 | 追踪召回计划及执行进度 |

---

## 8. 技术实现细节

### Timestamp 策略详解

对于拥有 `updated_at` 或 `loaded_at` 字段的源表，我们使用 `timestamp` 策略。这是最推荐的方式，因为它能准确反映源系统的变更时间。

```sql
{% snapshot snap_example %}
{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='timestamp',
        updated_at='loaded_at',
    )
}}
...
{% endsnapshot %}
```

### Check 策略详解

对于缺乏可靠时间戳的源表，我们使用 `check` 策略，通过比较指定列的哈希值来检测变更。

```sql
{% snapshot snap_example_check %}
{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='check',
        check_cols=['status', 'amount', 'user_id'], -- 或 'all'
    )
}}
...
{% endsnapshot %}
```

### 元数据列说明

- `dbt_scd_id`: 唯一标识一次特定的快照记录（基于主键+时间戳的哈希）。
- `dbt_updated_at`: 记录被 dbt 捕获的时间。
- `dbt_valid_from`: 记录生效时间（通常来源于源表的 `updated_at`）。
- `dbt_valid_to`: 记录失效时间（下一条记录的 `valid_from` 或 NULL/未来时间）。
