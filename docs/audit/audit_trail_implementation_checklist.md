# 审计跟踪系统实施检查清单

本文档提供详细的实施检查清单，确保审计跟踪系统的成功部署。

---

## 阶段 1: 基础设施准备

### 1.1 包安装

- [ ] 更新 `qrs/packages.yml`，添加 audit_helper
  ```yaml
  packages:
    - package: dbt-labs/dbt_utils
      version: 1.1.1
    - package: dbt-labs/audit_helper
      version: 0.12.2
  ```

- [ ] 运行 `dbt deps` 安装包
- [ ] 验证包安装成功
  ```bash
  ls qrs/dbt_packages/audit_helper
  ```

### 1.2 数据库 Schema 创建

- [ ] 创建快照 Schema
  ```sql
  CREATE SCHEMA IF NOT EXISTS qrs_snapshots;
  GRANT ALL ON SCHEMA qrs_snapshots TO dbt_user;
  ```

- [ ] 创建归档 Schema
  ```sql
  CREATE SCHEMA IF NOT EXISTS qrs_archive;
  GRANT ALL ON SCHEMA qrs_archive TO dbt_user;
  ```

- [ ] 验证权限
  ```sql
  SELECT schema_name FROM information_schema.schemata 
  WHERE schema_name IN ('qrs_snapshots', 'qrs_archive');
  ```

### 1.3 目录结构创建

- [ ] 创建快照目录
  ```bash
  mkdir -p qrs/snapshots/erp
  mkdir -p qrs/snapshots/lims
  mkdir -p qrs/snapshots/qms
  mkdir -p qrs/snapshots/mes
  mkdir -p qrs/snapshots/scada
  ```

- [ ] 创建审计分析目录
  ```bash
  mkdir -p qrs/analyses/audit/row_audit
  mkdir -p qrs/analyses/audit/column_audit
  ```

- [ ] 创建审计宏目录
  ```bash
  mkdir -p qrs/macros/audit
  ```

### 1.4 核心宏开发

- [ ] 创建 `standardize_for_audit.sql`
- [ ] 创建 `get_current_snapshot.sql`
- [ ] 创建 `get_snapshot_history.sql`
- [ ] 创建 `create_snapshot_indexes.sql`
- [ ] 创建 `maintain_snapshots.sql`
- [ ] 测试所有宏编译通过
  ```bash
  dbt compile --select tag:audit
  ```

### 1.5 配置更新

- [ ] 更新 `qrs/dbt_project.yml`
  ```yaml
  snapshots:
    qrs:
      +schema: snapshots
      +tags: ['snapshot', 'audit']
      +dbt_valid_to_current: '9999-12-31'
      +hard_deletes: new_record
  
  analyses:
    qrs:
      audit:
        +tags: ['audit', 'quality']
  ```

- [ ] 验证配置语法
  ```bash
  dbt parse
  ```

---

## 阶段 2: 快照实施

### 2.1 高优先级快照（Week 1）

#### snap_purchase_orders

- [ ] 创建快照配置文件 `qrs/snapshots/erp/snap_purchase_orders.yml`
- [ ] 首次运行快照
  ```bash
  dbt snapshot --select snap_purchase_orders
  ```
- [ ] 验证快照表结构
  ```sql
  \d qrs_snapshots.snap_purchase_orders
  ```
- [ ] 验证元字段存在
  ```sql
  SELECT column_name FROM information_schema.columns 
  WHERE table_name = 'snap_purchase_orders'
    AND column_name IN ('valid_from', 'valid_to', 'snapshot_id', 'is_deleted');
  ```
- [ ] 创建索引
  ```bash
  dbt run-operation create_snapshot_indexes
  ```
- [ ] 运行测试
  ```bash
  dbt test --select snap_purchase_orders
  ```
- [ ] 验证数据质量
  ```sql
  SELECT 
      count(*) as total_records,
      count(DISTINCT purchase_order_number) as unique_keys,
      sum(CASE WHEN valid_to = '9999-12-31' THEN 1 ELSE 0 END) as current_records
  FROM qrs_snapshots.snap_purchase_orders;
  ```

#### snap_inspection_requests

- [ ] 创建快照配置文件
- [ ] 首次运行快照
- [ ] 验证表结构和数据
- [ ] 创建索引
- [ ] 运行测试

#### snap_inspection_tasks

- [ ] 创建快照配置文件
- [ ] 首次运行快照
- [ ] 验证表结构和数据
- [ ] 创建索引
- [ ] 运行测试

### 2.2 中优先级快照（Week 2）

#### snap_change_controls

- [ ] 创建快照配置文件
- [ ] 首次运行快照
- [ ] 验证并测试

#### snap_deviations

- [ ] 创建快照配置文件
- [ ] 首次运行快照
- [ ] 验证并测试

#### snap_capas

- [ ] 创建快照配置文件
- [ ] 首次运行快照
- [ ] 验证并测试

#### snap_material_receipts

- [ ] 创建快照配置文件
- [ ] 首次运行快照
- [ ] 验证并测试

### 2.3 性能验证

- [ ] 测试当前记录查询性能
  ```sql
  EXPLAIN ANALYZE
  SELECT * FROM qrs_snapshots.snap_purchase_orders
  WHERE valid_to = '9999-12-31' AND is_deleted = 'False';
  ```
  - 目标: < 100ms

- [ ] 测试历史查询性能
  ```sql
  EXPLAIN ANALYZE
  SELECT * FROM qrs_snapshots.snap_purchase_orders
  WHERE valid_from <= '2024-01-01'
    AND valid_to > '2024-01-01';
  ```
  - 目标: < 500ms

- [ ] 检查表大小
  ```sql
  SELECT 
      tablename,
      pg_size_pretty(pg_total_relation_size('qrs_snapshots.'||tablename)) as size
  FROM pg_tables
  WHERE schemaname = 'qrs_snapshots'
  ORDER BY pg_total_relation_size('qrs_snapshots.'||tablename) DESC;
  ```

---

## 阶段 3: 审计实施

### 3.1 行级审计（Week 1）

#### 采购订单审计

- [ ] 创建审计模型 `audit_purchase_orders_rows.sql`
- [ ] 编译审计模型
  ```bash
  dbt compile --select audit_purchase_orders_rows
  ```
- [ ] 执行审计（复制编译后的 SQL 到查询工具）
- [ ] 记录审计结果
  - 匹配率: _____%
  - 仅在旧系统: _____ 条
  - 仅在新系统: _____ 条
- [ ] 分析差异原因
- [ ] 修复问题（如有）
- [ ] 重新审计验证

#### 检验请求审计

- [ ] 创建审计模型
- [ ] 执行审计
- [ ] 记录结果
- [ ] 分析并修复

#### 变更控制审计

- [ ] 创建审计模型
- [ ] 执行审计
- [ ] 记录结果
- [ ] 分析并修复

### 3.2 列级审计（Week 2）

#### 采购订单列级审计

- [ ] 创建审计模型 `audit_purchase_orders_columns.sql`
- [ ] 定义核心列列表
  ```sql
  {% set core_columns = [
      'total_amount',
      'order_status',
      'supplier_id'
  ] %}
  ```
- [ ] 执行核心列审计
- [ ] 记录每列匹配率
  - total_amount: _____%
  - order_status: _____%
  - supplier_id: _____%
- [ ] 扩展到全部列
- [ ] 最终匹配率: _____%

---

## 阶段 4: 生产化

### 4.1 调度配置

- [ ] 配置快照调度（dbt Cloud 或 Airflow）
  - 高频快照: 每 4 小时
  - 日常快照: 每日 02:00 UTC
  - 低频快照: 每周一 02:00 UTC

- [ ] 配置审计调度
  - 每周执行一次完整审计
  - 每月生成审计报告

### 4.2 监控配置

- [ ] 部署快照性能监控模型
- [ ] 部署审计质量监控模型
- [ ] 配置告警规则
  - 快照失败告警
  - 匹配率低于阈值告警
  - 表膨胀告警

### 4.3 文档完善

- [ ] 完成所有快照表文档
- [ ] 完成所有审计模型文档
- [ ] 编写运维手册
- [ ] 编写故障排查指南

### 4.4 团队培训

- [ ] dbt Snapshots 培训（4 小时）
- [ ] audit_helper 使用培训（2 小时）
- [ ] 审计流程培训（2 小时）
- [ ] 运维培训（2 小时）

---

## 验收标准

### 功能验收

- [ ] 所有快照表成功创建并运行
- [ ] 所有快照测试通过
- [ ] 所有审计模型编译成功
- [ ] 核心模型审计匹配率 >= 99%

### 性能验收

- [ ] 当前记录查询 < 100ms
- [ ] 历史记录查询 < 500ms
- [ ] 快照运行时间 < 30 分钟

### 质量验收

- [ ] 无时间重叠记录
- [ ] 无时间逻辑错误
- [ ] 硬删除正确追踪
- [ ] 索引健康度良好

### 文档验收

- [ ] 所有模型有完整文档
- [ ] 运维手册完整
- [ ] 故障排查指南完整
- [ ] 培训材料完整

---

## 签字确认

| 角色 | 姓名 | 签字 | 日期 |
|------|------|------|------|
| Analytics Engineer | | | |
| Data Engineer | | | |
| QA Engineer | | | |
| 项目经理 | | | |

---

**检查清单版本**: v1.0  
**创建日期**: 2024-12-24  
**最后更新**: 2024-12-24

