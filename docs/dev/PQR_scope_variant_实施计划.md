# PQR Scope + Variant 体系改造实施计划（多车间合并 / 多规格拆分）

## 0. 背景与目标

本计划用于指导 QRS dbt 项目落地 PQR（产品质量回顾）数据模型体系升级，使 PQR 报告对象从“工单/批号”升级为“回顾范围 Scope”，同时支持：

- 多车间合并展示：同一份 PQR 报告（Scope）可包含多个车间，但输出为合并结果，且保留可追溯证据链
- 多规格拆分：同一 `product_id` 不同规格/包装输出不同 Scope（引入 `product_variant_id`）
- GxP/GMP 合规：可追溯、可复算、口径可冻结（版本化、审计字段齐备）
- 生产报表零中断：新增链路与旧报表并行产出，切换可回滚

## 1. 依据与现状基线

### 1.1 设计依据（口径来源）

- 建议文档（本次改造的唯一口径来源）：[PQR数据模型体系调整建议_多车间合并_多规格拆分.md](file:///mnt/d/Work/NovaTech/QRS/dbt/docs/PQR数据模型体系调整建议_多车间合并_多规格拆分.md)
  - 明确新增实体：`dim_pqr_review_scope`、`dim_product_variant`、`bridge_pqr_scope_workshop`、`int_pqr__batch_universe`、`fct_pqr_*` 等
  - 明确强制测试与冻结字段：主键/外键 tests、`is_frozen/frozen_at/version_no/source_loaded_at_max` 等

### 1.2 仓库现状（可复用资产）

- 项目分层与物化策略：[dbt_project.yml](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/dbt_project.yml#L38-L156)
  - 目录分层：`staging/ intermediate/ business/ utils/ reports`
- 现有 PQR 报表：仅有全局概览型 [pqr_summary_report.sql](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/reports/pqr_summary_report.sql)（不按 Scope 输出）
- 已具备的关键主链与事实表（后续将被 Scope 总线复用）：
  - 车间与产线维度：[dim_workshops](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/dim_workshops.sql)、[dim_production_lines](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/dim_production_lines.sql)
  - 批次/生产主链：[fct_work_orders](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/fct_work_orders.sql)、[fct_batch_tracking](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/fct_batch_tracking.sql)
  - §23 退货已落地：[stg_customer_return](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/staging/stg_customer_return.sql)、[fct_customer_returns](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/fct_customer_returns.sql)
  - 投诉/召回已落地：[fct_complaints](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/fct_complaints.sql)、[fct_product_recalls](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/fct_product_recalls.sql)
- 审计/可复算基础：仓库已有 snapshots 与 current 视图模式（用于“快照当前态”取数），例如 [current_work_orders](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/utils/snapshots/current_work_orders.sql)

### 1.3 强制工程约束（分层引用）

如需新增数据支持，必须按 `seed → staging → business` 分层；`staging` 只能引用 `seed/source`，`business` 只能引用 `staging/intermediate`，禁止跨层直接引用。

## 2. 总体设计（Scope/Variant/车间证据链）

### 2.1 关键实体与关系（概念对齐）

- `dim_pqr_review_scope`：PQR 报告对象（Scope）主表，粒度为“一份报告对象=1条 scope”
- `dim_product_variant`：产品规格/包装维度（支撑多规格拆分）
- `bridge_pqr_scope_workshop`：scope 与车间多对多（合并展示但保留证据）
- `int_pqr__batch_universe`：统一纳入批次集合（Scope 总线），所有章节统计必须以其为准
- `fct_pqr_batch_summary`：批次级 PQR 宽表（章节输入）
- `fct_pqr_review_scope_summary`：Scope 合并汇总指标（章节输出主轴）

### 2.2 Scope 的最小稳定维度（必须具备）

- `product_id`
- `product_variant_id`
- `period_start_date` / `period_end_date`
- `version_no`

### 2.3 冻结与复算（GxP）

`dim_pqr_review_scope` 必须具备：

- `is_frozen`：是否冻结
- `frozen_at`：冻结时间
- `generated_at`：生成时间
- `source_loaded_at_max`：Scope 生成时刻所依赖上游数据的最大抽取时间（作为复算边界）

冻结后：

- Scope 纳入批次集合（`int_pqr__batch_universe`）不得变化
- 若上游回灌/迟到数据触发重新计算，只能生成新 `version_no`，不得覆盖冻结版本

## 3. 落地范围与交付物（P0 / P1）

### 3.1 P0（最小闭环，必须先完成）

目标：打通 `scope → batch_universe → batch_summary → scope_summary → 章节报表(§03, §23)`。

交付物：

- 新增 3 张 P0 输入（Seeds/Data Contract）
- 新增 staging 清洗模型（3个）
- 新增 Scope 总线 intermediate 模型（1个）
- 新增 business 维表/桥表/事实表（6个）
- 新增章节化 reports（3个）
- 新增 UAT/singular tests（先落模板，再扩到 20+/30+ 用例）

### 3.2 P1（扩展闭环，按章节逐步补齐）

交付物：

- 环境监测与批次关联时间窗桥接
- 公用系统与批次关联时间窗桥接
- 标准变更联接策略（快照/SCD2）
- CPP 限度与阈值校验（基于限度版本）

## 4. 目录与文件清单（对齐仓库分层）

建议新增目录（不影响现有目录结构）：

- `qrs/models/staging/pqr/`
- `qrs/models/intermediate/pqr/`
- `qrs/models/business/pqr/`
- `qrs/models/reports/pqr/`
- `qrs/tests/singular/pqr/`

### 4.1 Seeds / Data Contract（P0）

新增 CSV（建议作为过渡，最终应被真实业务源表替换）：

- `qrs/seeds/seed_pqr_review_scope.csv`
- `qrs/seeds/seed_pqr_scope_workshops.csv`
- `qrs/seeds/seed_product_variant_map.csv`

重要说明（需一次性决策）：

- 当前 staging 通常通过 `source('..._raw', ...)` 读取（见 [staging/_sources.yml](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/staging/_sources.yml)）
- 若 P0 阶段仍采用 seed，必须保证这些 seed 表能被 dbt 以一致方式读取（避免“seed 在 schema A，source 指向 schema B”的断裂）

### 4.2 Staging（P0）

新增模型：

- `stg_pqr_review_scope.sql`：读取 seed/source，类型规范化、审计字段统一（`loaded_at` 必填）
- `stg_pqr_scope_workshops.sql`：读取 seed/source
- `stg_product_variant_map.sql`：读取 seed/source

新增 `schema.yml`（同目录）：

- 所有 staging：`loaded_at not_null`
- Scope/Variant mapping：关键字段 `not_null` 与可接受值校验（如 `version_no` 格式）

### 4.3 Intermediate（P0）

新增模型：

- `int_pqr__batch_universe.sql`
  - 输入：`stg_pqr_review_scope`、`stg_pqr_scope_workshops`、（生产主链）[fct_work_orders](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/business/fct_work_orders.sql)
  - 输出字段（必须覆盖）：`review_scope_id, batch_number, product_id, product_variant_id, workshop_id, batch_start_at, batch_end_at`
  - 强制约束：同一 `version_no` 下 `batch_number` 只能归属一个 `review_scope_id`

可选模型（用于展示/审计）：

- `int_pqr__scope_workshop_agg.sql`：输出 `workshop_list/workshop_count`

### 4.4 Business（P0）

新增模型：

- `dim_product_variant.sql`
- `dim_pqr_review_scope.sql`
- `bridge_pqr_scope_workshop.sql`
- `fct_pqr_batch_summary.sql`
- `fct_pqr_review_scope_summary.sql`
- `fct_pqr_complaint_return_recall.sql`（统一事件口径，复用现有投诉/退货/召回事实）

新增 `schema.yml`（同目录），强制 tests：

- 所有 `dim_*/fct_*`：主键 `unique + not_null`
- 关键外键 `relationships`：至少 `review_scope_id`、`product_variant_id`、`batch_number`

### 4.5 Reports（P0）

新增模型（章节化输出，先保留旧报表不动）：

- `rpt_pqr_scope_header.sql`
- `rpt_pqr_section_03_production.sql`
- `rpt_pqr_section_23_events.sql`

原则：

- report 层不再做复杂多源 join，优先引用 `fct_pqr_batch_summary` 与 `fct_pqr_review_scope_summary`，保证可维护与性能稳定
- 旧报表 [pqr_summary_report.sql](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/reports/pqr_summary_report.sql) 保持不变，实现零中断

## 5. 实施路径（P0→P1→上线切换）

### 5.1 阶段 0：设计基线确认（冻结输入契约）

完成以下内容即进入开发：

- `review_scope_id` 的生成与管理规则（建议稳定 surrogate key + 业务键校验）
- `product_variant_id` 的编码规则与来源（seed 过渡 vs 主数据系统）
- Scope 的冻结规则与版本号规则（何时冻结、如何审批、冻结后如何复算）

### 5.2 阶段 1：P0 最小闭环开发

推荐顺序：

1) Seeds/Data Contract（3表） → staging 清洗（3个模型 + schema）
2) `int_pqr__batch_universe`（Scope 总线）
3) `dim_product_variant / dim_pqr_review_scope / bridge_pqr_scope_workshop`
4) `fct_pqr_batch_summary` → `fct_pqr_review_scope_summary`
5) `rpt_pqr_*` 三张章节化报表
6) UAT/singular tests（先落模板再扩充用例）

### 5.3 阶段 2：P1 扩展与章节补齐

按章节逐步扩展，不做“大爆改”：

- 环境/公用系统时间窗桥接（先出可解释关联，再做汇总）
- 标准变更快照联接（按当期有效标准复算）
- CPP 限度阈值校验与超限事件口径对齐

### 5.4 阶段 3：零中断切换与回滚演练

并行策略（Shadow Run）：

- 新口径输出独立命名空间或新前缀，不影响旧表与旧 BI
- 验证通过后，通过“兼容层视图/语义层指向”切换到新模型

回滚策略：

- 仅回滚视图指向旧模型即可（旧模型保留不删不改）
- 冻结版本禁止覆盖，只能产生新版本

## 6. 测试、UAT 与验收标准

### 6.1 强制 dbt tests（门槛）

- staging：`loaded_at not_null`
- business：主键 `unique + not_null`
- relationships：`review_scope_id`、`product_variant_id`、`batch_number`

### 6.2 UAT 用例（落地为 singular tests，数量要求）

目录建议：`qrs/tests/singular/pqr/`

#### 多车间合并（20+）

必含模板（建议先实现 6 个，再扩展到 20+）：

- Scope-workshop 覆盖一致（seed 清单 vs bridge）
- 同一 Scope 的批次数/产量等合并指标可回溯到批次集合
- `workshop_count` 与 batch_universe distinct(workshop_id) 一致
- 冻结后 bridge 与 batch_universe 行集不可变化

#### 多规格拆分（30+）

必含模板（建议先实现 7 个，再扩展到 30+）：

- 每个 Scope 必须有且仅有一个 `product_variant_id`
- 同一 `version_no` 下 `batch_number` 不得跨 variant/scope
- variant 主数据完整性（必填参数、有效期）
- 参数阈值校验与超限事件可追溯

### 6.3 P0 验收（可上线前置条件）

- `int_pqr__batch_universe` 的唯一归属约束全部通过
- `fct_pqr_review_scope_summary` 与 `fct_pqr_batch_summary` 的聚合对账差异为 0（或在预设阈值内且可解释）
- 三张章节报表按 scope 输出稳定、可 drill 到批次与车间证据链

## 7. 角色分工建议（可直接用于任务分派）

- 数据治理/QA：Scope 定义与冻结审批、variant mapping 维护与复核、UAT 用例验收
- dbt 开发：staging/intermediate/business/reports 模型开发与 schema tests
- 平台/运维：并行发布、视图切换、回滚演练、监控告警落地

## 8. 风险与控制点（必须提前处理）

- Seed 与 source schema 不一致导致读取断裂：P0 阶段必须明确“读 seed”还是“读 source”，并保证 dbt 读取路径一致
- 规格映射缺失导致 scope 无法冻结：必须建立缺失清单与阻断策略（缺失即不可冻结）
- 多车间合并的去重规则：对“批次去重、事件去重、比率类指标”必须在 `fct_pqr_*` 层固化口径，禁止在 report 层临时拼接

## 9. 附录：现状与目标差距速览

- 现状已有：生产主链事实、投诉/退货/召回事实、车间/产线维度、快照审计机制
- 现状缺失：Scope 实体与冻结、规格维度（variant）、Scope 总线（batch_universe）、PQR 章节化报表体系

