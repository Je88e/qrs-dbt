---
type: "manual"
---

## **dbt 项目开发标准规则集 (dbt Development Rules)**

#### **1. 核心工作流与架构原则 (Core Workflow & Architecture)**

* **引用原则**：
* **禁止**在模型中硬编码数据库名称或 Schema 名称。
* **必须**使用 `{{ ref('model_name') }}` 引用其他模型，使用 `{{ source('source_name', 'table_name') }}` 引用原始数据。


* **分层架构**：项目必须严格遵循 Staging -> Intermediate -> Marts 的三层架构。
* **Staging 层**：
* **唯一性**：这是唯一允许使用 `{{ source() }}` 的层级。
* **原子性**：必须与源表保持 1:1 关系，禁止 Join 或聚合（Aggregation）。
* **职责**：仅进行重命名、类型转换和基础清洗。


* **Intermediate 层**：
* **逻辑封装**：处理复杂 Join（>4个实体）和中间计算逻辑。
* **物化**：通常物化为 `view` 或 `ephemeral`，不直接暴露给最终用户。


* **Marts 层**：
* **业务导向**：高度去规范化（宽表），优先考虑查询性能。
* **物化**：通常物化为 `table` 或 `incremental`。





#### **2. 命名规范 (Naming Conventions)**

* **语言与风格**：全小写，使用下划线分隔（snake_case），禁止使用缩写（如用 `cust` 代替 `customer`）。
* **模型命名**：
* 使用复数形式（如 `customers`, `orders`）。
* Staging 模型前缀：`stg_<source>_<entity>`。
* Intermediate 模型前缀：`int_<domain>_<action>`。
* Marts 模型前缀：`fct_` (事实表) 或 `dim_` (维度表)。


* **字段命名**：
* **主键**：统一格式 `<object>_id`（如 `account_id`），严禁只用 `id`。
* **布尔值**：必须加前缀 `is_` 或 `has_`。
* **时间戳**：格式 `<event>_at`，且必须转换为 UTC。
* **日期**：格式 `<event>_date`。
* **金额**：使用十进制单位（如美元），字段名建议带币种后缀（如 `total_amount_usd`）。



#### **3. SQL 编码风格 (SQL Style Guide)**

* **Import CTE 模式（强制）**：
* 所有 `ref` 和 `source` 必须在文件顶部的 CTE 中声明。
* 最后一行必须是 `select * from final`（或最后一个 CTE 名称）。
* *目的：提高可读性，便于调试依赖关系。*


* **格式要求**：
* 使用 4 个空格缩进。
* 关键字、函数名全小写。
* 字段/表别名必须使用 `as` 显式声明。
* 每行 SQL 不超过 80 个字符。


* **逻辑处理**：
* 遵循“尽早过滤”原则，在 CTE 阶段剔除无效数据。
* 使用 SQLFluff 进行代码格式化。



#### **4. 测试与质量保证 (Testing & Quality)**

* **强制测试**：
* 每个模型必须至少包含 `unique` 和 `not_null` 测试（针对主键）。
* 外键必须配置 `relationships` 测试。
* 枚举值必须配置 `accepted_values` 测试。


* **测试覆盖率**：目标为 100% 模型覆盖率，严禁提交无测试的新模型。
* **复杂逻辑**：对于复杂的 SQL 逻辑，必须编写 Unit Test（单元测试）。

#### **5. 物化与性能优化 (Materialization & Performance)**

* **物化策略演进**：默认从 `view` 开始 -> 性能不足转 `table` -> 数据量巨大转 `incremental`。
* **增量模型 (Incremental)**：
* 必须包含 `{% if is_incremental() %}` 块。
* 必须设置数据回溯窗口（Lookback window）以处理迟到数据（如 `created_at > max(created_at) - 3 days`）。
* 大数据集应使用 `incremental_predicates` 优化扫描。


* **仓库优化**：对于 Snowflake/Redshift，应显式配置集群键（Cluster keys）或分布键（Dist keys）。

#### **6. 宏、包管理与代码复用 (Macros, Packages & Reusability)**
* **单一职责原则**：宏应当像编程语言中的函数一样，只做一件事，且保持逻辑纯粹。
* **命名与组织**：
* 使用动词驱动的蛇形命名法清晰表达宏的行为（如 calculate_growth_rate 而非 growth_rate）。
* 按功能域（Domain）对宏文件进行分类存储（如 macros/date_utils.sql）。
* 文档化：所有自定义宏必须包含参数说明。

* **包管理策略 (Package Management Strategy)**：
* “不重复造轮子”原则：在编写任何通用工具（Utils）代码前，可以先检查 dbt 官方或社区包中是否已存在现成解决方案。

* 核心包清单 (The Essential Stack)：积极使用以下标准包，以维持工程标准：
* - dbt_utils：用于通用 SQL 模式（如 surrogate_key, date_spine）。几乎每个项目都应安装。
* - dbt_expectations：用于高级数据质量测试（如财务数据验证、分布测试），补充原生测试的不足。
* - dbt_project_evaluator：用于自动化项目健康检查，强制执行最佳实践（如防止循环依赖、检查文档覆盖率）。
* - dbt_codegen：用于自动生成 Staging 层模型代码和 YAML 基础结构，减少手动样板代码。

#### **7. AI Coding Agent 专项指令 (Instructions for AI Agents)**

* **上下文注入**：在编写代码前，必须读取 `manifest.json` 或依赖图，严禁凭空猜测表结构。
* **Staging 优先**：
* 在编写业务逻辑前，检查是否已有 `stg_` 模型。
* 如果不存在，**必须**先创建 `stg_` 模型（推荐调用 `dbt-codegen`），**严禁**直接跳过 Staging 层引用 Raw Data。

* **生成代码**：遇到常见模式（如生成代理键、日期维度生成），必须优先调用 dbt_utils 中的宏。

* **依赖声明**：生成的 SQL 代码顶部必须显式列出所有依赖。
* **配套交付**：生成的每一个 `.sql` 模型文件，必须同步生成包含 description 和 tests 的 `.yml` 文件。
* **血缘合规检查**：
* 检查：是否出现了 Source 直接 Join Marts 的情况？（禁止）
* 检查：是否出现了 Staging 依赖 Marts 的循环依赖？（禁止）。


* **自修正**：
* 如果 `dbt run` 或 `dbt compile` 失败，AI 应分析日志并自动尝试修复语法错误。
* 提交代码前，应自我评估是否违反了 dbt_project_evaluator 的规则（例如：是否为 Marts 模型添加了描述？是否避免了直接 Join Source？）

---

### **附：标准模型模板 (Standard Model Template)**

开发人员和 AI Agent 应始终遵循以下模板结构编写模型：

```sql
/*
    Model: <model_name>
    Description: <Brief summary of what this model does>
*/

-- 1. Import CTEs: 显式声明所有依赖
with source_data as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

-- 2. Logic CTEs: 业务逻辑处理
filtered_orders as (
    select
        order_id,
        customer_id,
        order_date,
        total_amount
    from source_data
    where order_status = 'completed' -- 尽早过滤
),

-- 3. Final CTE: 组装最终结果
final as (
    select
        filtered_orders.order_id,
        customers.customer_name,
        filtered_orders.order_date,
        filtered_orders.total_amount
    from filtered_orders
    left join customers 
        on filtered_orders.customer_id = customers.customer_id
)

-- 4. Output: 必须选择 Final CTE
select * from final

```