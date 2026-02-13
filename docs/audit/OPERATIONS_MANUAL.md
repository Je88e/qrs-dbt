# QRS 审计系统运维手册

> **版本**: 2.0
> **最后更新**: 2026-02-11
> **维护**: Analytics Engineering Team

---

## 1. 日常运维流程

### 1.1 执行计划

为了保证审计数据的及时性，我们配置了不同频率的调度任务。

| 频率 | 涵盖范围 | 执行命令 | 调度时间 |
|------|---------|---------|----------|
| **每小时** | SCADA, High-Freq LIMS | `dbt snapshot --select tag:high_frequency` | xx:00 |
| **每4小时** | LIMS | `dbt snapshot --select tag:lims` | 00, 04, 08... |
| **每日** | 全量快照 | `dbt snapshot` | 02:00 AM |

### 1.2 手动触发

在源系统进行大规模数据修复或迁移后，可能需要手动触发快照。

```bash
# 运行特定模型的快照
dbt snapshot --select snap_purchase_orders

# 运行特定下游依赖的测试
dbt test --select snap_purchase_orders+
```

---

## 2. 监控与告警

### 2.1 关键监控指标

1. **快照运行状态**: 确保 `dbt snapshot` 命令成功退出 (Exit Code 0)。
2. **数据新鲜度**: 检查 `dbt_updated_at` 是否在预期范围内。
3. **数据量监控**: 监控 `snapshots` Schema 的表大小增长，异常激增可能意味着配置错误（如 `strategy='check'` 选中了高频变动字段）。

### 2.2 数据完整性检查

使用 dbt test 定期验证数据完整性：

```bash
# 运行快照相关的特定测试
dbt test --select tag:audit
```

**常见测试项**:
- `unique`: `dbt_scd_id` 必须唯一。
- `not_null`: 关键业务字段不为空。
- 自定义测试: 验证 `valid_from < valid_to`。

---

## 3. Schema 变更管理 (Schema Evolution)

dbt Snapshots 能够自动处理源表新增列的情况，但需要注意以下场景。

### 3.1 源表新增列
- **行为**: 下次运行 `dbt snapshot` 时，目标表会自动添加新列。
- **注意**: 历史记录中该列为 NULL。

### 3.2 源表删除列
- **行为**: 快照表保留该列，但新记录中该列为 NULL。
- **建议**: 不要从快照表中物理删除列，以保留历史上下文。

### 3.3 源表列类型变更
- **风险**: 可能导致快照运行失败。
- **操作**: 
  1. 手动在数据库中修改快照表列类型以兼容新类型。
  2. 或者（极端情况下）重命名旧列，让 dbt 创建新列。

---

## 4. 维护与优化

### 4.1 索引维护
每周运行一次索引优化宏，清理索引碎片并确保查询性能。

```bash
dbt run-operation create_snapshot_indexes
```

### 4.2 重新初始化 (Re-snapshotting)
如果快照逻辑发生重大变更（如更换 `strategy` 或 `unique_key`），可能需要重新初始化。

**警告**: 这会导致**丢失所有历史记录**！

**步骤**:
1. 备份当前快照表：`CREATE TABLE snapshots.snap_xxx_backup AS SELECT * FROM snapshots.snap_xxx;`
2. 删除快照表：`DROP TABLE snapshots.snap_xxx;`
3. 重新运行快照：`dbt snapshot --select snap_xxx`
4. （可选）将备份表中的历史数据迁移回新表（需谨慎处理 `dbt_scd_id` 冲突）。

---

## 5. 灾难恢复

鉴于审计数据的合规重要性，必须实施严格的备份策略。

### 5.1 备份策略
- **全量备份**: 每日一次，保留 7 年（符合 GxP 要求）。
- **增量备份**: 每小时一次（数据库级 WAL 日志）。

### 5.2 恢复演练
每季度进行一次恢复演练，验证能否将快照表恢复到特定时间点。

### 5.3 误删保护
- 快照表应配置防误删策略（如 AWS S3 Object Lock 或数据库层面的 Table Lock）。
- 生产环境 dbt 用户不应拥有 `DROP TABLE` 权限（dbt 运行账号除外，且应限制在特定时间窗口）。
