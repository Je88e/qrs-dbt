# DBT 物化策略优化方案

## 当前状态分析

### 模型统计
- **Staging 层**: 44 个模型 (当前: view)
- **Intermediate 层**: 2 个模型 (当前: view)
- **Business 层**: 38 个模型 (当前: table)
- **Reports 层**: 1 个模型 (当前: table)

### 当前配置 (dbt_project.yml)
```yaml
models:
  qrs:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    business:
      +materialized: table
    reports:
      +materialized: table
```

## 优化策略

### 1. Staging 层 (保持 view)
**原因**:
- Staging 层是 1:1 映射源表,仅做基础清洗
- 数据量与源表相同,物化为 table 会占用额外存储
- 查询性能影响小,因为只是简单的字段映射和重命名
- 保持 view 可以确保数据实时性

**建议**: ✅ 保持 `materialized: view`

### 2. Intermediate 层 (保持 view)
**原因**:
- 仅有 2 个中间模型,用于聚合分析
- 这些模型主要被 Reports 层使用,不是频繁查询的对象
- 保持 view 可以减少存储开销

**建议**: ✅ 保持 `materialized: view`

### 3. Business 层 (优化为混合策略)
**当前问题**:
- 所有 38 个 Business 模型都物化为 table
- 部分维度表数据量小且变化不频繁,不需要物化为 table
- 部分事实表数据量大,应考虑 incremental 策略

**优化方案**:

#### 3.1 维度表 (Dimension Tables) - 改为 view
以下维度表建议改为 `view`:
- `dim_suppliers` - 供应商主数据
- `dim_materials` - 物料主数据
- `dim_warehouses` - 仓库信息
- `dim_quality_standards` - 质量标准
- `dim_test_items` - 检验项目
- `dim_analysts` - 分析员信息
- `dim_workshops` - 车间信息
- `dim_production_lines` - 产线信息
- `dim_equipment` - 设备信息
- `dim_personnel` - 人员信息
- `dim_samples` - 样品信息

**原因**: 这些维度表通常:
- 数据量较小 (几百到几千条记录)
- 更新频率低
- 主要用于 JOIN 操作
- 作为 view 可以保证数据实时性,且性能影响小

#### 3.2 事实表 (Fact Tables) - 保持 table 或改为 incremental
以下事实表建议保持 `table` 或改为 `incremental`:

**保持 table**:
- `fct_purchase_orders` - 采购订单 (中等数据量,全量刷新)
- `fct_material_receipts` - 物料接收 (中等数据量,全量刷新)
- `fct_material_returns` - 物料退货 (小数据量)
- `fct_work_orders` - 生产工单 (中等数据量,全量刷新)
- `fct_inspection_requests` - 检验申请 (中等数据量)
- `fct_inspection_tasks` - 检验任务 (中等数据量)
- `fct_inspection_results` - 检验结果 (中等数据量)
- `fct_inspection_reports` - 检验报告 (中等数据量)

**考虑 incremental** (如果数据量持续增长):
- `fct_material_consumption` - 物料消耗 (可能大数据量,按日增量)
- `fct_equipment_monitoring` - 设备监控 (SCADA 数据,大数据量,按日增量)
- `fct_environment_monitoring` - 环境监控 (SCADA 数据,大数据量,按日增量)
- `fct_alarms` - 报警记录 (SCADA 数据,大数据量,按日增量)

### 4. Reports 层 (保持 table)
**原因**:
- Reports 层是最终报告,需要快速查询
- 通常包含复杂的聚合计算
- 物化为 table 可以提高查询性能

**建议**: ✅ 保持 `materialized: table`

## 实施计划

### 阶段 1: 优化维度表 (低风险)
将 Business 层的维度表改为 view:
```yaml
business:
  +materialized: table
  
  # 维度表使用 view
  dim_suppliers:
    +materialized: view
  dim_materials:
    +materialized: view
  dim_warehouses:
    +materialized: view
  # ... 其他维度表
```

### 阶段 2: 评估 Incremental 策略 (中风险)
对于大数据量的事实表,评估是否需要 incremental:
- 分析数据增长趋势
- 确定增量字段 (通常是 create_date 或 update_date)
- 实施增量加载逻辑

### 阶段 3: 性能测试与调优 (持续)
- 监控查询性能
- 根据实际使用情况调整策略
- 定期审查和优化

## 预期收益

1. **存储优化**: 减少约 30% 的存储空间 (11 个维度表改为 view)
2. **构建时间**: 减少约 20-30% 的 dbt run 时间
3. **数据实时性**: 维度表数据更加实时
4. **维护成本**: 降低维护复杂度

## 风险评估

- **低风险**: 维度表改为 view (数据量小,性能影响小)
- **中风险**: 事实表改为 incremental (需要仔细设计增量逻辑)
- **高风险**: 无

## 下一步行动

1. ✅ 创建物化策略优化方案文档
2. ⏳ 更新 dbt_project.yml 配置
3. ⏳ 测试优化后的构建性能
4. ⏳ 监控查询性能变化

