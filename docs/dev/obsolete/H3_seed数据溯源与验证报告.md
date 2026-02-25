## H3 新增 seed 数据溯源与验证报告

### 0. 范围说明

本报告覆盖 H3 新增的 seed 数据（用于统一质量事件模型的根因/风险标准化与映射）：

- `quality_root_cause_categories`
- `quality_root_cause_mapping`
- `quality_risk_levels`
- `quality_risk_mapping`

### 1. 合法上游业务系统清单（校验口径）

判定为“合法上游业务系统来源”的枚举值如下（若 seed 行缺失或不在枚举内，判定为错误数据）：

- `qms`：质量管理系统（偏差/CAPA/变更等）
- `pv`：药物警戒系统（投诉/召回等）
- `erp`：ERP 系统
- `mes`：MES 系统
- `lims`：LIMS 系统
- `scada`：SCADA 系统

### 2. seed 级溯源归属分析与验证结果

#### 2.1 `quality_root_cause_categories`（根因分类字典）

- **用途与业务含义**：标准化根因分类（人机料法环测），用于 `fct_quality_events.root_cause_category_code` 的统一口径
- **上游业务系统来源**：`qms`（作为 QMS 中受控字典/配置主数据的导出）
- **更新频率**：按需（字典受控变更；一般低频）
- **关键字段**：
  - `root_cause_category_code`：分类编码（主键）
  - `root_cause_category_name`：分类名称
  - `source_system`：上游业务系统来源（必须为合法枚举）
- **溯源验证规则**：
  - `source_system` 非空且 ∈ 合法枚举
  - 主键唯一/非空
- **验证结果**：
  - 当前数据全部满足：`source_system = qms`
  - 错误数据：0 行
- **文件**：[quality_root_cause_categories.csv](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/seeds/quality_root_cause_categories.csv)

#### 2.2 `quality_root_cause_mapping`（根因映射规则）

- **用途与业务含义**：将上游事件中的 `root_cause_raw` 文本按规则映射到标准根因分类
- **上游业务系统来源**：由字段 `source_system` 指示（本批次为 `qms`）
- **更新频率**：按需（规则受控变更；可较字典稍高频）
- **关键字段**：
  - `mapping_id`：规则主键
  - `source_system`：产生 `root_cause_raw` 的系统（必须为合法枚举）
  - `event_type`：事件类型（必须为受控枚举）
  - `match_type/match_value`：匹配方式与匹配值
  - `root_cause_category_code`：目标分类编码
- **溯源验证规则**：
  - `source_system` 非空且 ∈ 合法枚举
  - `event_type` ∈ {deviation, capa, complaint, product_recall, change_control}
  - `match_type` ∈ {contains, equals}
  - `root_cause_category_code` 非空（并在 business 层通过维表关系测试约束）
- **验证结果**：
  - 当前数据全部满足（本批次所有规则 `source_system=qms`，`event_type` 为 deviation/capa）
  - 错误数据：0 行
- **文件**：[quality_root_cause_mapping.csv](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/seeds/quality_root_cause_mapping.csv)

#### 2.3 `quality_risk_levels`（风险等级字典）

- **用途与业务含义**：标准化风险等级（critical/high/medium/low），用于统一事件风险口径
- **上游业务系统来源**：`qms`（作为 QMS 中受控字典/配置主数据的导出）
- **更新频率**：按需（低频）
- **关键字段**：
  - `risk_level_code`：风险编码（主键）
  - `risk_level_name`：风险名称
  - `source_system`：上游业务系统来源（必须为合法枚举）
- **溯源验证规则**：
  - `source_system` 非空且 ∈ 合法枚举
  - 主键唯一/非空
- **验证结果**：
  - 当前数据全部满足：`source_system = qms`
  - 错误数据：0 行
- **文件**：[quality_risk_levels.csv](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/seeds/quality_risk_levels.csv)

#### 2.4 `quality_risk_mapping`（风险等级映射规则）

- **用途与业务含义**：将上游事件中的 `priority/recall_level` 等风险字段映射为标准风险等级
- **上游业务系统来源**：由字段 `source_system` 指示（本批次包含 `pv` 与 `qms`）
- **更新频率**：按需（规则受控变更）
- **关键字段**：
  - `mapping_id`：规则主键
  - `source_system`：产生 `raw_value` 的系统（必须为合法枚举）
  - `event_type`：事件类型（必须为受控枚举）
  - `raw_value`：上游原始取值（如 “高/中/低”、“一级召回/二级召回/三级召回”）
  - `risk_level_code`：目标风险等级编码
- **溯源验证规则**：
  - `source_system` 非空且 ∈ 合法枚举
  - `event_type` ∈ {deviation, capa, complaint, product_recall, change_control}
  - `risk_level_code` 非空（并在 business 层通过维表关系测试约束）
- **验证结果**：
  - 当前数据全部满足（`source_system` 分别为 pv/qms）
  - 错误数据：0 行
- **文件**：[quality_risk_mapping.csv](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/seeds/quality_risk_mapping.csv)

### 3. 错误数据清单（按规则判定）

本批次新增 seed 数据中，按“缺失/非法 source_system”与“枚举非法”规则判定：

- 错误数据：无（0 行）

说明：在引入 `source_system` 字段前，`quality_root_cause_categories`、`quality_risk_levels` 不具备明确上游业务系统字段，按本规范应判定为错误；现已补齐并纳入测试门禁，确保后续不会回归。

### 4. 基于 staging 的数据构建方案（严格分层）

#### 4.1 分层约束

- staging 层：仅允许引用 seed（`ref('seed_name')`），禁止直接引用 source 或 business
- business 层：仅允许引用 staging（`ref('stg_*')`），禁止直接引用 seed 或 source

#### 4.2 H3 事件域数据集构建（示例：统一质量事件）

**seed**

- 事件原子数据：`qms_deviation`、`qms_capa`、`qms_change_control`、`pv_complaint`、`pv_product_recall`
- 标准化字典与映射：`quality_root_cause_*`、`quality_risk_*`

**staging（仅 ref seed）**

- 事件标准化：`stg_quality_event_*_seed`
- 字典与映射标准化：`stg_quality_root_cause_*`、`stg_quality_risk_*`

**business（仅 ref staging）**

- 维度输出：`dim_root_cause_categories`、`dim_risk_levels`
- 事实汇总：`fct_quality_events`

#### 4.3 血缘追溯（从 business 指标回溯到 seed）

- `fct_quality_events.root_cause_category_code`
  - 由 `stg_quality_root_cause_mapping` 规则匹配 `root_cause_raw` 得到
  - 最终约束关联到 `dim_root_cause_categories`（字典来自 `quality_root_cause_categories` seed）
- `fct_quality_events.risk_level_code`
  - 由 `stg_quality_risk_mapping` 根据 `priority_raw/recall_level_raw` 匹配得到
  - 最终约束关联到 `dim_risk_levels`（字典来自 `quality_risk_levels` seed）

