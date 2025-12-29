# 审计跟踪系统执行报告

**执行日期**: 2024-12-29  
**执行人**: Data Engineering Team  
**审计工具**: dbt + audit_helper

---

## 📋 执行摘要

本次审计执行了 **audit_helper** 包提供的数据一致性审计，验证了从 Staging 层到 Business 层的数据转换逻辑正确性。

### 审计范围
- ✅ **采购订单** (purchase_orders) - 行级审计 + 列级审计
- ⚠️ **检验申请** (inspection_requests) - 待实施
- ⚠️ **变更控制** (change_controls) - 待实施

---

## 🎯 审计结果

### 1️⃣ 采购订单 - 行级审计

**审计对象**:
- 源表: `stg_purchase_order` (Staging 层)
- 目标表: `fct_purchase_orders` (Business 层)
- 主键: `purchase_order_number`

**执行命令**:
```bash
dbt run-operation execute_compiled_audit --args '{"audit_file_name": "audit_purchase_orders_rows"}'
```

**审计结果**:
```
| 在源表(stg) | 在目标表(fct) | 记录数 | 占比(%) |
|-------------|---------------|--------|---------|
| ✅ 是       | ✅ 是         | 5      | 100.00% |
```

**分析**:
- ✅ **完全匹配**: 100.00%
- ✅ **审计通过**: 数据一致性优秀 (>= 99.5%)

**结论**: 所有采购订单记录在 Staging 层和 Business 层完全一致，数据转换逻辑正确。

---

### 2️⃣ 采购订单 - 列级审计 (total_amount)

**审计对象**:
- 源表: `stg_purchase_order.total_amount`
- 目标表: `fct_purchase_orders.total_amount`
- 数据类型: NUMERIC (保留 2 位小数)

**执行命令**:
```bash
dbt run-operation execute_compiled_audit --args '{"audit_file_name": "audit_purchase_orders_columns"}'
```

**审计结果**:
```
| 匹配状态              | 记录数 | 占比(%) |
|-----------------------|--------|---------|
| ✅: perfect match     | 5      | 100.00% |
```

**分析**:
- ✅ **完全匹配**: 100.00%
- ✅ **审计通过**: 数据一致性优秀 (>= 99.0%)

**结论**: 采购订单金额字段在数据转换过程中保持完全一致，无精度损失。

---

## 📊 审计数据存储说明

### audit_helper 审计数据存储

**重要**: audit_helper 的审计结果 **不会持久化到数据库**，仅在执行时生成临时结果。

#### 当前存储方式
1. **终端输出**: 审计结果直接显示在终端
2. **编译文件**: SQL 保存在 `target/compiled/qrs/analyses/audit/`
3. **不存储**: 审计结果不写入数据库表

#### 如需持久化审计结果

可以创建审计报告表：

```sql
-- 创建审计报告 schema
CREATE SCHEMA IF NOT EXISTS audit_reports;

-- 创建行级审计历史表
CREATE TABLE audit_reports.row_audit_history (
    audit_id SERIAL PRIMARY KEY,
    audit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_table VARCHAR(100),
    target_table VARCHAR(100),
    in_source BOOLEAN,
    in_target BOOLEAN,
    record_count INTEGER,
    percent_of_total NUMERIC(5,2),
    audit_status VARCHAR(20)
);

-- 创建列级审计历史表
CREATE TABLE audit_reports.column_audit_history (
    audit_id SERIAL PRIMARY KEY,
    audit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_table VARCHAR(100),
    target_table VARCHAR(100),
    column_name VARCHAR(100),
    match_status VARCHAR(50),
    record_count INTEGER,
    percent_of_total NUMERIC(5,2)
);
```

然后修改审计宏，将结果插入到这些表中。

---

## 🔍 Snapshots 审计数据存储

与 audit_helper 不同，**Snapshots 数据是持久化存储的**。

### 存储位置
- **Schema**: `snapshots`
- **表**: `snap_purchase_orders`, `snap_material_receipts`, 等

### 表结构
```sql
SELECT 
    purchase_order_number,
    order_status,
    valid_from,           -- 记录生效时间
    valid_to,             -- 记录失效时间
    snapshot_id,          -- 快照唯一标识
    last_updated_at,      -- 最后更新时间
    is_deleted            -- 是否已删除
FROM snapshots.snap_purchase_orders
LIMIT 5;
```

### 查询示例
```sql
-- 查询当前有效记录
SELECT COUNT(*) 
FROM snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31' AND is_deleted = 'False';

-- 查询历史变更记录
SELECT 
    purchase_order_number,
    order_status,
    valid_from,
    valid_to
FROM snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO202401001'
ORDER BY valid_from;
```

---

## 🛠️ 审计工具对比

| 特性 | audit_helper | Snapshots |
|------|--------------|-----------|
| **用途** | 验证数据转换逻辑 | 追踪历史变更 |
| **运行时机** | 按需运行（开发/测试） | 定期运行（生产） |
| **数据存储** | ❌ 不持久化 | ✅ 持久化到数据库 |
| **存储位置** | 终端输出 | `snapshots` schema |
| **查询方式** | 运行宏查看 | SQL 查询表 |
| **适用场景** | 数据迁移验证 | 合规审计追踪 |

---

## 📈 审计指标

### 行级审计指标
- **目标**: >= 99.5% 完全匹配
- **当前**: 100.00% ✅
- **状态**: 优秀

### 列级审计指标
- **目标**: >= 99.0% 完全匹配
- **当前**: 100.00% ✅
- **状态**: 优秀

---

## 🎯 后续行动

### 已完成 ✅
1. ✅ 实施采购订单行级审计
2. ✅ 实施采购订单列级审计
3. ✅ 创建审计执行宏
4. ✅ 验证审计结果准确性

### 待实施 ⚠️
1. ⚠️ 实施检验申请审计宏
2. ⚠️ 实施变更控制审计宏
3. ⚠️ 创建审计结果持久化表
4. ⚠️ 设置审计结果自动保存
5. ⚠️ 配置审计失败告警

### 建议 💡
1. 💡 将审计集成到 CI/CD 流程
2. 💡 设置每日自动审计任务
3. 💡 创建审计仪表板
4. 💡 建立审计结果趋势分析

---

## 📞 联系方式

如有问题或需要支持，请联系：
- **数据工程团队**: data-engineering@novatech.com
- **文档**: `qrs/analyses/audit/README_AUDIT_USAGE.md`
- **代码**: `qrs/macros/audit/`

---

**报告生成时间**: 2024-12-29 09:05:00  
**下次审计计划**: 2024-12-30

