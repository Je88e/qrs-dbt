# output.json 文件结构说明 (v2.2)

## 概述

`output.json` 是 lineagex 包生成的数据血缘分析结果文件，包含整个 dbt 项目中所有表和模型的血缘关系信息。

---

## 文件结构

### 顶层结构

```json
{
  "表/模型的唯一标识符": {
    // === 核心字段 (v1.x 兼容) ===
    "tables": ["直接依赖的上游表列表"],
    "table_name": "实际的表名",
    "upstream_tables": ["所有上游表列表"],
    "downstream_tables": ["所有下游表列表"],
    "is_model": true/false,
    "columns": {
      "列名": ["该列的来源列列表"]
    },

    // === 表级元数据（从 catalog.json） ===
    "table_metadata": {
      "type": "VIEW/BASE TABLE",
      "schema": "public",
      "name": "表名",
      "database": "postgres",
      "comment": null,
      "owner": "postgres"
    },

    // === 列级元数据（v2.2 统一结构） ===
    "column_metadata": {
      "列名": {
        // 基础元数据
        "type": "数据类型",
        "index": 列位置,
        "name": "列名",
        "comment": "列注释（如有）",

        // 业务描述（从 manifest.json）
        "description": "列的业务描述",

        // 血缘信息
        "sources": ["来源列1", "来源列2"],
        "source_types": ["类型1"],
        "target_type": "目标类型",
        "type_change": false,
        "transformation": "explain_based/computed",
        "usage_context": {...},
        "explain_sources": [...],
        "catalog_sources": [...],
        "is_consistent": true,
        "conflicts": []
      }
    },

    // === 模型元数据（从 manifest.json） ===
    "tags": ["标签1", "标签2"],
    "description": "模型描述"
  }
}
```

---

## 字段详细说明

### 核心字段（v1.x 兼容）

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `tables` | `string[]` | ✅ | 直接依赖的上游表列表 |
| `table_name` | `string` | ✅ | 表的完整名称（schema.table_name） |
| `upstream_tables` | `string[]` | ✅ | 所有上游依赖（包括间接依赖） |
| `downstream_tables` | `string[]` | ✅ | 所有下游依赖（被哪些表使用） |
| `is_model` | `boolean` | ✅ | 是否为 dbt 模型（true）或源表/快照（false） |
| `columns` | `object<string, string[]>` | ✅ | 列级血缘，**值保持列表格式**（向后兼容） |

### 表级元数据

#### table_metadata（从 catalog.json 获取）

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `table_metadata` | `object` | ❌ | 表级别元数据（类型、所有者等） |

#### tags 和 description（从 manifest.json 获取）

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `tags` | `string[]` | ❌ | 模型标签列表 |
| `description` | `string` | ❌ | 模型描述 |

### 列级元数据（v2.2 统一后）

#### column_metadata（统一的列元数据）

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `column_metadata` | `object` | ❌ | **统一的列级元数据**，包含基础信息、业务描述和血缘信息 |

---

## 增强字段详解

### 1. table_metadata（表元数据）

```json
{
  "table_metadata": {
    "type": "VIEW",
    "schema": "public",
    "name": "dim_analysts",
    "database": "postgres",
    "comment": null,
    "owner": "postgres"
  }
}
```

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `type` | `string` | 表类型：`BASE TABLE`(普通表) / `VIEW`(视图) / `MATERIALIZED VIEW`(物化视图) |
| `schema` | `string` | 所属 schema |
| `name` | `string` | 表名（不含 schema） |
| `database` | `string` | 数据库名称 |
| `comment` | `string\|null` | 表注释（数据库级别） |
| `owner` | `string` | 表所有者 |

### 2. column_metadata（统一的列元数据，v2.2）

```json
{
  "column_metadata": {
    "analyst_id": {
      // === 基础元数据（从 catalog.json） ===
      "type": "text",
      "index": 1,
      "name": "analyst_id",
      "comment": null,

      // === 业务描述（从 manifest.json） ===
      "description": "分析员ID (主键)",

      // === 血缘信息 ===
      "sources": ["public.stg_analyst.analyst_id"],
      "source_types": ["unknown"],
      "target_type": "text",
      "type_change": false,
      "transformation": "explain_based",
      "usage_context": {
        "in_output": false,
        "in_filter": false,
        "in_join": false,
        "in_aggregate": false,
        "in_sort": false
      },
      "explain_sources": ["public.stg_analyst.analyst_id"],
      "catalog_sources": ["public.stg_analyst.analyst_id"],
      "is_consistent": true,
      "conflicts": []
    }
  }
}
```

#### 基础元数据字段（从 catalog.json）

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `type` | `string` | PostgreSQL 数据类型（如 `text`, `integer`, `timestamp without time zone`） |
| `index` | `number` | 列在表中的位置（从 1 开始） |
| `name` | `string` | 列名 |
| `comment` | `string\|null` | 列注释（PostgreSQL 数据库级别） |

#### 业务描述字段（从 manifest.json）

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `description` | `string` | 列的业务描述（从 dbt schema.yml 定义） |

#### 血缘信息字段

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `sources` | `string[]` | 该列的来源列列表（完整路径，如 `public.stg_analyst.analyst_id`） |
| `source_types` | `string[]` | 来源列的数据类型（可能为 `unknown`） |
| `target_type` | `string` | 目标列的数据类型 |
| `type_change` | `boolean` | 是否发生类型转换 |
| `transformation` | `string` | 血缘来源：`explain_based` / `computed` |
| `usage_context` | `object` | 列使用上下文（详见下文） |
| `explain_sources` | `string[]` | EXPLAIN 分析得出的来源 |
| `catalog_sources` | `string[]` | Catalog 分析得出的来源 |
| `is_consistent` | `boolean` | EXPLAIN 与 Catalog 结果是否一致 |
| `conflicts` | `array` | 冲突信息列表 |

**使用上下文（usage_context）**：

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `in_output` | `boolean` | 是否出现在最终输出中 |
| `in_filter` | `boolean` | 是否用于 WHERE 过滤条件 |
| `in_join` | `boolean` | 是否用于 JOIN 条件 |
| `in_aggregate` | `boolean` | 是否用于聚合计算 |
| `in_sort` | `boolean` | 是否用于 ORDER BY |

**transformation 字段值说明**：

| 值 | 说明 |
|----|------|
| `explain_based` | 通过 EXPLAIN 分析得出的血缘 |
| `computed` | 计算字段或无法追踪来源的列（如 seeds、自增列） |

### 3. tags（模型标签）

```json
{
  "tags": ["business_model", "lims", "quality", "master_data", "pqr"]
}
```

| 类型 | 说明 |
|------|------|
| `string[]` | 从 `manifest.json` 中提取的模型标签列表，用于分类和过滤 |

**常见标签用途**：

- **域标签**: `erp`, `mes`, `lims`, `qms`, `scada`, `pv`
- **层级标签**: `staging`, `business_model`
- **数据类型**: `master_data`, `transactional`, `snapshot`
- **业务用途**: `quality`, `production`, `reporting`, `pqr`

### 4. description（模型描述）

```json
{
  "description": "分析员信息业务模型 - 分析员主数据"
}
```

| 类型 | 说明 |
|------|------|
| `string` | 从 `manifest.json` 中提取的模型描述信息 |

**描述用途**：

- 解释模型用途和业务含义
- 说明数据来源和处理逻辑
- 帮助用户理解模型上下文

---

## 示例解析

### 示例 1: 快照表（Snapshot Table）

```json
{
  "snapshots.snap_deviations": {
    "tables": [""],
    "table_name": "snapshots.snap_deviations",
    "upstream_tables": [],
    "downstream_tables": [
      "model.qrs.int_production__batch_genealogy",
      "model.qrs.int_quality__batch_compliance",
      "model.qrs.current_deviations"
    ],
    "is_model": false,
    "columns": {
      "snowflake_id": [""],
      "deviation_id": [""],
      "deviation_code": [""],
      "dbt_valid_from": [""],
      "dbt_valid_to": [""],
      "dbt_is_deleted": [""]
    }
  }
}
```

**解读**:
- `is_model: false` 表示这是快照表而非 dbt 模型
- `tables: [""]` 表示没有上游表依赖
- 包含 dbt 快照特有字段：`dbt_valid_from`, `dbt_valid_to`, `dbt_is_deleted`

### 示例 2: 源表（Source Table）

```json
{
  "raw.lims_analyst": {
    "tables": [""],
    "table_name": "raw.lims_analyst",
    "upstream_tables": [],
    "downstream_tables": ["model.qrs.stg_analyst"],
    "is_model": false,
    "columns": {
      "analyst_id": [""],
      "analyst_name": [""],
      "department": [""]
    }
  }
}
```

**解读**:
- `is_model: false` 表示这是源表
- `tables: [""]` 表示源表没有上游依赖
- `columns` 中的值为空列表 `[""]`，表示没有列血缘

### 示例 3: Staging 模型（Seed 数据）

```json
{
  "model.qrs.stg_analyst": {
    "tables": [
      "public.stg_analyst",
      "raw.lims_analyst"
    ],
    "table_name": "public.stg_analyst",
    "upstream_tables": [
      "public.stg_analyst",
      "raw.lims_analyst"
    ],
    "downstream_tables": [
      "model.qrs.dim_analysts",
      "model.qrs.fct_inspection_tasks"
    ],
    "is_model": true,
    "columns": {
      "snowflake_id": [""],
      "analyst_id": [""],
      "analyst_code": [""]
    },
    "table_metadata": {
      "type": "BASE TABLE",
      "schema": "public",
      "name": "stg_analyst",
      "database": "postgres",
      "comment": null,
      "owner": "postgres"
    },
    "column_metadata": {
      "snowflake_id": {
        "type": "text",
        "index": 1,
        "name": "snowflake_id",
        "comment": null,
        "description": "雪花ID (主键)",
        "sources": [""],
        "source_types": [],
        "target_type": "text",
        "type_change": false,
        "transformation": "computed",
        "usage_context": {
          "in_output": false,
          "in_filter": false,
          "in_join": false,
          "in_aggregate": false,
          "in_sort": false
        },
        "explain_sources": [],
        "catalog_sources": [""],
        "is_consistent": true,
        "conflicts": []
      },
      "analyst_id": {
        "type": "text",
        "index": 2,
        "name": "analyst_id",
        "comment": null,
        "description": "分析员ID (主键)",
        "sources": [""],
        "source_types": [],
        "target_type": "text",
        "type_change": false,
        "transformation": "computed"
      }
    },
    "tags": ["staging", "lims", "master_data"],
    "description": "LIMS分析员主数据Staging层 - 每行代表一个分析员"
  }
}
```

**解读**:
- `type: "BASE TABLE"` 表示这是表（可能是 seed 数据）
- `transformation: "computed"` 表示列血缘来自计算字段或 seed
- `sources: [""]` 表示没有上游列血缘（数据来自 seed 或外部导入）
- `tags` 包含 `staging` 层级标签和域标签

### 示例 4: Business 模型（完整元数据）

```json
{
  "model.qrs.dim_analysts": {
    "tables": ["public.stg_analyst"],
    "table_name": "public.dim_analysts",
    "upstream_tables": ["public.stg_analyst"],
    "downstream_tables": [],
    "is_model": true,
    "columns": {
      "analyst_id": ["public.stg_analyst.analyst_id"],
      "analyst_code": ["public.stg_analyst.analyst_code"],
      "analyst_name": ["public.stg_analyst.analyst_name"],
      "days_until_cert_expiry": ["public.stg_analyst.certification_expiry"]
    },
    "table_metadata": {
      "type": "VIEW",
      "schema": "public",
      "name": "dim_analysts",
      "database": "postgres",
      "comment": null,
      "owner": "postgres"
    },
    "column_metadata": {
      "analyst_id": {
        "type": "text",
        "index": 1,
        "name": "analyst_id",
        "comment": null,
        "description": "分析员ID (主键)",
        "sources": ["public.stg_analyst.analyst_id"],
        "source_types": ["unknown"],
        "target_type": "text",
        "type_change": false,
        "transformation": "explain_based",
        "usage_context": {
          "in_output": false,
          "in_filter": false,
          "in_join": false,
          "in_aggregate": false,
          "in_sort": false
        },
        "explain_sources": ["public.stg_analyst.analyst_id"],
        "catalog_sources": ["public.stg_analyst.analyst_id"],
        "is_consistent": true,
        "conflicts": []
      },
      "days_until_cert_expiry": {
        "type": "integer",
        "index": 9,
        "name": "days_until_cert_expiry",
        "comment": null,
        "description": "距离认证过期天数",
        "sources": ["public.stg_analyst.certification_expiry"],
        "source_types": ["unknown"],
        "target_type": "integer",
        "type_change": false,
        "transformation": "explain_based",
        "usage_context": {...},
        "explain_sources": ["public.stg_analyst.certification_expiry"],
        "catalog_sources": [""],
        "is_consistent": false,
        "conflicts": [
          {
            "type": "source_mismatch",
            "explain": ["public.stg_analyst.certification_expiry"],
            "catalog": [""]
          }
        ]
      }
    },
    "tags": ["business_model", "lims", "quality", "master_data", "pqr"],
    "description": "分析员信息业务模型 - 分析员主数据"
  }
}
```

**解读**:
- `type: "VIEW"` 表示这是视图
- `transformation: "explain_based"` 表示血缘通过 EXPLAIN 分析得出
- `sources` 包含完整的列路径 `schema.table.column`
- `is_consistent: false` 和 `conflicts` 表示 EXPLAIN 与 Catalog 结果不一致
- `source_types: ["unknown"]` 表示来源列类型未知（可能上游是 seed）

---

## 数据生成流程

### Combine 模式流程图

```
┌─────────────────────────────────────────────────────────────┐
│                      Lineage Analysis                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  步骤 1: 加载 manifest.json 和 catalog.json │
        └─────────────────────────────────────────┘
                              │
          ┌───────────────────┴───────────────────┐
          ▼                                       ▼
┌─────────────────────┐             ┌─────────────────────┐
│  EXPLAIN 分析引擎   │             │  Catalog 分析引擎   │
│                     │             │                     │
│ - 执行 EXPLAIN SQL  │             │ - 解析 catalog.json │
│ - 提取查询计划      │             │ - 提取依赖关系      │
│ - 解析列血缘        │             │ - 推断列血缘        │
└─────────────────────┘             └─────────────────────┘
          │                                       │
          └───────────────────┬───────────────────┘
                              ▼
                ┌─────────────────────────────────┐
                │    步骤 4: 结果融合引擎          │
                │                                 │
                │  - 融合表依赖                   │
                │  - 融合列血缘                   │
                │  - 添加 Catalog 元数据          │
                └─────────────────────────────────┘
                              │
                              ▼
                ┌─────────────────────────────────┐
                │  步骤 5: 添加 Manifest 元数据    │
                │                                 │
                │  - 提取 tags                    │
                │  - 提取 description             │
                │  - 提取 column_descriptions     │
                └─────────────────────────────────┘
                              │
                              ▼
                ┌─────────────────────────────────┐
                │    步骤 6: 生成 output.json      │
                │                                 │
                │  - 核心字段（v1.x 兼容）        │
                │  - Catalog 元数据               │
                │  - Manifest 元数据              │
                │  - 增强列血缘元数据             │
                └─────────────────────────────────┘
```

### 数据来源

| 数据类型 | 来源 | 说明 |
|----------|------|------|
| 表依赖 | EXPLAIN > Catalog | EXPLAIN 反映实际查询 |
| 列血缘 | EXPLAIN > Catalog | EXPLAIN 更准确 |
| table_metadata | catalog.json | 从数据库获取 |
| column_metadata 基础字段 | catalog.json | 从数据库获取 |
| tags | manifest.json | 从 dbt 项目定义获取 |
| description | manifest.json | 从 dbt 项目定义获取 |
| column description | manifest.json | 从 dbt 项目定义获取 |

---

## 总结

### 核心功能（v1.x 兼容）

✅ **表级血缘** - `tables` 和 `upstream_tables`
✅ **列级血缘** - `columns` 字段（保持列表格式）
✅ **双向关系** - `upstream_tables` 和 `downstream_tables`
✅ **类型标识** - `is_model` 区分模型和源表

### 增强功能

#### Catalog 元数据（从 catalog.json 获取）
🆕 **技术元数据** - 表类型、数据类型、索引等
🆕 **数据库注释** - 表和列的数据库注释

#### Manifest 元数据（从 manifest.json 获取）
🆕 **模型标签** - tags 字段，用于分类和过滤
🆕 **模型描述** - description 字段，业务语义说明
🆕 **列描述** - column_metadata.description，列的业务含义

#### 增强列血缘
🆕 **类型追踪** - 数据类型转换链路
🆕 **使用上下文** - 列的使用场景分析
🆕 **一致性检查** - EXPLAIN 与 Catalog 结果对比

### 应用场景

1. **可视化血缘图** - 交互式图表、Mermaid 流程图
2. **影响分析** - 上游/下游影响追踪
3. **文档生成** - 数据字典、血缘文档
4. **数据治理** - 合规性检查、敏感数据追踪
5. **问题排查** - 异常定位、计算链路追踪
6. **模型分类** - 按标签分组、按域过滤

---

## 附录

### A. 字段速查表

| 字段路径 | 类型 | 必需 | 说明 |
|----------|------|------|------|
| **核心字段** |
| `tables` | `string[]` | ✅ | 直接上游表 |
| `table_name` | `string` | ✅ | 表完整名称 |
| `upstream_tables` | `string[]` | ✅ | 所有上游表 |
| `downstream_tables` | `string[]` | ✅ | 所有下游表 |
| `is_model` | `boolean` | ✅ | 是否为 dbt 模型 |
| `columns.{col}` | `string[]` | ✅ | 列血缘 |
| **table_metadata** |
| `table_metadata.type` | `string` | ❌ | 表类型（VIEW/BASE TABLE） |
| `table_metadata.schema` | `string` | ❌ | Schema 名称 |
| `table_metadata.name` | `string` | ❌ | 表名 |
| `table_metadata.database` | `string` | ❌ | 数据库名 |
| `table_metadata.owner` | `string` | ❌ | 所有者 |
| `table_metadata.comment` | `string\|null` | ❌ | 表注释 |
| **column_metadata** |
| `column_metadata.{col}.type` | `string` | ❌ | 数据类型 |
| `column_metadata.{col}.index` | `number` | ❌ | 列位置 |
| `column_metadata.{col}.description` | `string` | ❌ | 业务描述 |
| `column_metadata.{col}.sources` | `string[]` | ❌ | 来源列 |
| `column_metadata.{col}.transformation` | `string` | ❌ | 血缘来源 |
| `column_metadata.{col}.is_consistent` | `boolean` | ❌ | 一致性检查 |
| **Manifest 元数据** |
| `tags` | `string[]` | ❌ | 模型标签 |
| `description` | `string` | ❌ | 模型描述 |

### B. 表类型说明

| 类型值 | 说明 |
|--------|------|
| `BASE TABLE` | 普通表（包括 seed 表） |
| `VIEW` | 视图 |
| `MATERIALIZED VIEW` | 物化视图 |

### C. transformation 值说明

| 值 | 说明 | 适用场景 |
|----|------|----------|
| `explain_based` | 通过 EXPLAIN 分析得出 | 普通模型 |
| `computed` | 计算字段或无法追踪 | Seed 表、自增列、计算列 |