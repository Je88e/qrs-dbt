基于对您项目结构的深度分析，我为您制定了以下的重构方案。您当前的 `audit` 目录实际上混合了**测试（Tests）**、**转换（Transformations）**和**分析（Analyses）**三种完全不同的意图。

### 1. 功能分类分析与现状诊断

目前 `audit` 散落在四个位置，存在职责不清的问题：

| 位置 | 典型文件 | 实际功能 | 传统架构弊端 |
| :--- | :--- | :--- | :--- |
| **`analyses/audit/`** | `row_audit/audit_purchase_orders_rows.sql` | **Ad-hoc Data Quality Scripts**<br>手动运行的 SQL 脚本，用于开发调试或一次性验证。 | **不可自动化**：这些脚本不会在 `dbt test` 中运行，无法集成到 CI/CD 流程中。随着时间推移，这些手动脚本极易因为没人运行而过时（Code Rot）。 |
| **`models/audit/`** | `current_purchase_orders.sql` | **Utility Views (Snapshots)**<br>基于 SCD Type 2 快照表，过滤出 `valid_to=9999-12-31` 的当前有效记录。 | **命名误导**：这些是下游模型依赖的基础设施（数据转换），而非“审计结果”。放在 `audit` 下会让开发者困惑：这是测试报告表吗？且容易形成循环依赖。 |
| **`tests/audit/`** | `test_snapshot_integrity.sql` | **Singular Tests**<br>自定义 SQL 测试，用于检测快照时间重叠等逻辑错误。 | **结构孤立**：这是标准的 dbt 测试，应该遵循 dbt 的测试目录规范，而不是单独开辟一个 `audit` 目录，导致测试逻辑分散。 |
| **`macros/audit/`** | `compare_model_rows.sql`<br>`get_current_snapshot.sql` | **Mixed Macros**<br>混合了测试辅助宏（如对比行）和数据转换辅助宏（如获取快照）。 | **职责耦合**：将测试逻辑与数据处理逻辑混合在同一个目录中，降低了代码的可读性和维护性。 |

---

### 2. 最佳实践重构方案

我们将基于 **“按意图归档 (Organize by Intent)”** 的原则重新规划目录结构。

*   **Singular Tests**: 移至 `tests/singular/`，并按业务领域或测试类型细分。
*   **Generic Tests**: 定义在 `macros/tests/` 或直接使用 `audit_helper` 包。
*   **Audit Logs**: 如果需要持久化存储测试结果，建议使用 dbt 的 `store_failures` 功能，数据会自动存入数据库。
*   **Utility Views**: 移至 `models/utils/`。

#### 目录结构对比树状图

**重构前 (As-Is):**
```text
qrs/
├── analyses/
│   └── audit/              <-- [废弃] 手动脚本
├── models/
│   └── audit/              <-- [误导] 其实是转换逻辑
│       └── current_*.sql
├── tests/
│   └── audit/              <-- [孤立] 只有部分测试
└── macros/
    └── audit/              <-- [混乱] 混合了各种宏
```

**重构后 (To-Be):**
```text
qrs/
├── tests/                          # 统一存放所有自动化测试
│   ├── generic/                    # 自定义通用测试宏
│   └── singular/                   # 特定 SQL 测试
│       ├── data_integrity/         # 技术性检查 (原 analyses/audit 和 tests/audit)
│       │   ├── assert_snapshot_integrity.sql
│       │   └── assert_row_counts_match.sql
│       └── business_logic/         # 业务规则检查
│           └── assert_order_total_match.sql
├── models/
│   ├── utils/                      # 工具/辅助模型
│   │   └── snapshots/              # [迁移] 原 models/audit
│   │       └── current_purchase_orders.sql
│   └── marts/
│       └── governance/             # (可选) 数据治理/审计报告表
├── macros/
│   ├── utils/                      # 通用工具宏 (如 get_current_snapshot)
│   └── tests/                      # 测试专用辅助宏 (如 compare_rows)
└── analyses/                       # 仅保留真正的分析草稿，移除测试脚本
```

---

### 3. 实施路线图 (Migration Roadmap)

请按以下顺序执行迁移，以确保项目运行不中断。

#### 第一阶段：迁移工具视图 (Utility Views)
*目标：解决 `models/audit` 的命名误导问题，确保下游依赖稳定。*

1.  **创建目录**：新建 `models/utils/snapshots/`。
2.  **移动文件**：将 `qrs/models/audit/current_*.sql` 移动到新目录。
3.  **更新引用**：由于 dbt 使用 `ref()` 引用模型名称，只要模型文件名不变，**下游代码不需要修改**。
4.  **清理**：删除 `qrs/models/audit/` 目录。

#### 第二阶段：标准化测试 (Standardize Tests)
*目标：将散落的检查逻辑统一为 dbt Tests，实现自动化。*

1.  **迁移 Singular Tests**：
    *   创建 `tests/singular/data_integrity/`。
    *   将 `qrs/tests/audit/test_snapshot_integrity.sql` 移动到此目录。
2.  **转化 Analyses 为 Tests**：
    *   针对 `analyses/audit/row_audit/` 下的脚本（如 `audit_purchase_orders_rows.sql`），它们目前是“查询并显示结果”。
    *   **方案**：将其转化为 **Generic Test** 配置。不需要写 SQL 文件，直接在 `models/staging/schema.yml` 中添加：
        ```yaml
        models:
          - name: stg_purchase_order
            tests:
              - audit_helper.compare_model_subset:
                  compare_to: ref('fct_purchase_orders')
                  primary_key: purchase_order_number
        ```
    *   如果必须保留复杂 SQL，请修改其逻辑，使其**仅返回失败的行**，并移动到 `tests/singular/data_integrity/`。

#### 第三阶段：拆分 Macros
1.  **移动测试宏**：将 `compare_model_rows.sql` 等用于测试的宏移至 `macros/tests/`。
2.  **移动工具宏**：将 `get_current_snapshot.sql` 等用于生成的宏移至 `macros/utils/`。

---

### 4. 配置建议 (dbt_project.yml)

为了适配新结构并实现精细化控制，请在 `dbt_project.yml` 中添加以下配置。

```yaml
# dbt_project.yml

# 1. 定义资源路径
test-paths: ["tests"]
macro-paths: ["macros"]

models:
  qrs:
    # 2. 配置工具视图 (原 models/audit)
    utils:
      +schema: utils         # 在数据库中生成 qrs_utils schema
      snapshots:
        +materialized: view  # 强制为视图，保持轻量
        +tags: ["utility", "snapshot_view"]
    
    # 业务模型配置
    business:
      +materialized: table

tests:
  qrs:
    # 3. 配置测试严重性
    singular:
      # 数据完整性是红线，失败即阻断 Pipeline
      data_integrity:
        +severity: error
        +store_failures: true  # 失败时将结果存入数据库 schema: dbt_test_failures
        +tags: ["integrity", "audit"]
      
      # 业务逻辑警告，比如某非核心指标异常，允许跑批继续，但发出警告
      business_logic:
        +severity: warn
        +store_failures: false
        +tags: ["business_logic"]
```