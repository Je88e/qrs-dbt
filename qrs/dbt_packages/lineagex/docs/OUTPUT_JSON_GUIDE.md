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
    "table_name": "实际的表名",
    "tables": ["直接依赖的上游表列表"],
    "columns": {
      "列名": ["该列的来源列列表"]
    },
    "upstream_tables": ["所有上游表列表"],
    "downstream_tables": ["所有下游表列表"],
    "is_model": true/false,

    // === 表级元数据 ===
    "table_metadata": {
      "type": "BASE/VIEW/MATERIALIZED_VIEW",
      "owner": "postgres",
      "comment": "表注释"
    },
    "tags": ["标签1", "标签2"],
    "description": "模型描述",

    // === 列级元数据 (v2.2 统一后的完整结构) ===
    "column_metadata": {
      "列名": {
        // 基础元数据（从 catalog.json）
        "type": "数据类型",
        "index": 列位置,
        "name": "列名",
        "comment": "列注释（如有）",
        
        // 业务描述（从 manifest.json）
        "description": "列的业务描述",
        
        // 血缘信息（从 enhanced_columns_metadata 合并）
        "sources": ["来源列1", "来源列2"],
        "source_types": ["类型1", "类型2"],
        "target_type": "目标类型",
        "type_change": false,
        "transformation": "explain_based",
        "usage_context": {
          "in_output": true,
          "in_filter": false,
          "in_join": false,
          "in_aggregate": false,
          "in_sort": false
        },
        "explain_sources": [...],
        "catalog_sources": [...],
        "is_consistent": true,
        "conflicts": []
      }
    }
  }
}
```

**注意**：如果 enhanced_columns_metadata 中的字段与 column_metadata 中已有字段冲突（如 `type`），则该字段会被重命名为 `explain_type`。

---

## 字段详细说明

### 核心字段（v1.x 兼容）

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `table_name` | `string` | ✅ | 表的完整名称（schema.table_name） |
| `tables` | `string[]` | ✅ | 直接依赖的上游表列表 |
| `columns` | `object<string, string[]>` | ✅ | 列级血缘，**值保持列表格式**（向后兼容） |
| `upstream_tables` | `string[]` | ✅ | 所有上游依赖（包括间接依赖） |
| `downstream_tables` | `string[]` | ✅ | 所有下游依赖（被哪些表使用） |
| `is_model` | `boolean` | ✅ | 是否为 dbt 模型（true）或源表（false） |

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
    "owner": "postgres",
    "schema": "public",
    "comment": "分析师维度表",
    "options": {...}
  }
}
```

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `type` | `string` | 表类型：`BASE`(普通表) / `VIEW`(视图) / `MATERIALIZED_VIEW`(物化视图) |
| `owner` | `string` | 表所有者 |
| `schema` | `string` | 所属 schema |
| `comment` | `string\|null` | 表注释 |
| `options` | `object` | 其他 PostgreSQL 表属性 |

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
      
      // === 业务描述（从 manifest.json，v2.2 新增） ===
      "description": "分析员ID (主键)",
      
      // === 血缘信息（从 enhanced_columns_metadata 合并，v2.2 新增） ===
      "sources": ["stg_analyst.analyst_id"],
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
      "explain_sources": ["stg_analyst.analyst_id"],
      "catalog_sources": ["public.stg_analyst.analyst_id"],
      "is_consistent": false,
      "conflicts": [
        {
          "type": "source_mismatch",
          "explain": ["stg_analyst.analyst_id"],
          "catalog": ["public.stg_analyst.analyst_id"]
        }
      ]
    }
  }
}
```

#### 基础元数据字段（从 catalog.json）

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `type` | `string` | PostgreSQL 数据类型 |
| `index` | `number` | 列在表中的位置（从 1 开始） |
| `name` | `string` | 列名 |
| `comment` | `string\|null` | 列注释（PostgreSQL 数据库级别） |

#### 业务描述字段（从 manifest.json，v2.2 新增）

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `description` | `string` | 列的业务描述（从 dbt schema.yml 定义） |

#### 血缘信息字段（从 enhanced_columns_metadata 合并，v2.2 新增）

| 子字段 | 类型 | 说明 |
|--------|------|------|
| `sources` | `string[]` | 该列的来源列列表 |
| `source_types` | `string[]` | 来源列的数据类型 |
| `target_type` | `string` | 目标列的数据类型 |
| `type_change` | `boolean` | 是否发生类型转换 |
| `transformation` | `string` | 血缘来源：`explain_based` / `catalog_based` / `computed` |
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

**字段冲突处理**：

如果 enhanced_columns_metadata 中的字段与 column_metadata 中已有字段冲突（例如同名），该字段会被重命名为 `explain_${原字段名}`。

例如：
- 如果 enhanced_columns_metadata 有 `type` 字段，而 column_metadata 也有 `type` 字段
- 则 enhanced_columns_metadata 的 `type` 会被重命名为 `explain_type`

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
- **层级标签**: `staging_model`, `business_model`
- **数据类型**: `master_data`, `transactional`, `snapshot`
- **业务用途**: `quality`, `production`, `reporting`

### 4. description（模型描述）

```json
{
  "description": "分析师信息业务模型 - 分析师主数据"
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

### 示例 1: 源表（基础表）

```json
{
  "raw.lims_analyst": {
    "table_name": "raw.lims_analyst",
    "tables": [""],
    "columns": {
      "analyst_id": [""],
      "analyst_name": [""],
      "department": [""]
    },
    "upstream_tables": [],
    "downstream_tables": ["model.qrs.stg_analyst"],
    "is_model": false,

    "table_metadata": {
      "type": "BASE",
      "owner": "admin"
    },
    "column_metadata": {
      "analyst_id": {
        "type": "text",
        "index": 1
      }
    }
  }
}
```

**解读**:
- ✅ 核心字段与 v1.x 完全一致
- 🆕 `table_metadata` 显示这是基础表
- 🆕 `column_metadata` 提供列类型信息

### 示例 2: Staging 模型（v2.2 统一后）

```json
{
  "model.qrs.stg_analyst": {
    "table_name": "public.stg_analyst",
    "tables": ["raw.lims_analyst"],
    "columns": {
      "analyst_id": ["lims_analyst.analyst_id"],
      "analyst_name": ["lims_analyst.analyst_name"],
      "analyst_code": ["lims_analyst.analyst_code"]
    },
    "upstream_tables": ["raw.lims_analyst"],
    "downstream_tables": ["model.qrs.dim_analysts"],
    "is_model": true,

    "table_metadata": {
      "type": "VIEW",
      "owner": "postgres"
    },
    "tags": ["staging_model", "lims"],
    "description": "分析师数据源表 - 1:1 映射",
    "column_metadata": {
      "analyst_id": {
        "type": "text",
        "index": 1,
        "name": "analyst_id",
        "comment": null,
        "description": "分析师唯一标识",
        "sources": ["lims_analyst.analyst_id"],
        "source_types": ["text"],
        "target_type": "text",
        "type_change": false,
        "transformation": "explain_based"
      },
      "analyst_name": {
        "type": "text",
        "index": 2,
        "name": "analyst_name",
        "comment": null,
        "description": "分析师姓名",
        "sources": ["lims_analyst.analyst_name"],
        "source_types": ["text"],
        "target_type": "text",
        "type_change": false,
        "transformation": "explain_based"
      }
    }
  }
}
```

**解读**:
- ✅ `tags` 显示这是 staging 模型和 LIMS 域
- ✅ `description` 说明模型用途
- 🆕 `column_metadata` 统一包含了技术元数据、业务描述和血缘信息

### 示例 3: Business 模型（v2.2 统一后的完整元数据）

```json
{
  "model.qrs.dim_analysts": {
    "table_name": "public.dim_analysts",
    "tables": ["raw.lims_analyst"],
    "columns": {
      "analyst_id": ["lims_analyst.analyst_id"],
      "analyst_code": ["lims_analyst.analyst_code"],
      "analyst_name": ["lims_analyst.analyst_name"]
    },
    "upstream_tables": ["raw.lims_analyst"],
    "downstream_tables": [],
    "is_model": true,

    "table_metadata": {
      "type": "VIEW",
      "owner": "postgres"
    },
    "tags": ["business_model", "lims", "quality", "master_data", "pqr"],
    "description": "分析师信息业务模型 - 分析师主数据",
    "column_metadata": {
      "analyst_id": {
        // 基础元数据（从 catalog.json）
        "type": "text",
        "index": 1,
        "name": "analyst_id",
        "comment": null,
        
        // 业务描述（从 manifest.json）
        "description": "分析师ID (主键)",
        
        // 血缘信息（从 enhanced_columns_metadata 合并）
        "sources": ["lims_analyst.analyst_id"],
        "source_types": ["text"],
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
        "explain_sources": ["lims_analyst.analyst_id"],
        "catalog_sources": ["public.lims_analyst.analyst_id"],
        "is_consistent": true,
        "conflicts": []
      },
      "analyst_code": {
        "type": "text",
        "index": 2,
        "name": "analyst_code",
        "comment": null,
        "description": "分析师编码",
        "sources": ["lims_analyst.analyst_code"],
        "source_types": ["text"],
        "target_type": "text",
        "type_change": false,
        "transformation": "explain_based"
      }
    }
  }
}
```

**解读**:
- ✅ `tags` 显示业务模型类型和所属域
- ✅ `description` 提供模型业务含义
- 🆕 `column_metadata` **统一包含**：技术元数据、业务描述和血缘信息
- 🆕 所有列信息集中在一处，无需在多个字段间查找

---

## 数据生成流程（v2.1）

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
                │  - 提取 description              │
                │  - 提取 column_descriptions      │
                └─────────────────────────────────┘
                              │
                              ▼
                ┌─────────────────────────────────┐
                │    步骤 6: 生成 output.json      │
                │                                 │
                │  - 核心字段（v1.x 兼容）        │
                │  - Catalog 元数据               │
                │  - Manifest 元数据（v2.1 新增） │
                │  - 增强列血缘元数据             │
                └─────────────────────────────────┘
```

### 数据来源

| 数据类型 | 来源 | 说明 |
|----------|------|------|
| 表依赖 | EXPLAIN > Catalog | EXPLAIN 反映实际查询 |
| 列血缘 | EXPLAIN > Catalog | EXPLAIN 更准确 |
| table_metadata | catalog.json | 从数据库获取 |
| column_metadata | catalog.json | 从数据库获取 |
| tags | manifest.json | 从 dbt 项目定义获取 |
| description | manifest.json | 从 dbt 项目定义获取 |
| column_descriptions | manifest.json | 从 dbt 项目定义获取 |

---

## 总结

`output.json` v2.1 提供了完整的数据血缘知识图谱：

### 核心功能（v1.x 兼容）

✅ **表级血缘** - `tables` 和 `upstream_tables`
✅ **列级血缘** - `columns` 字段（保持列表格式）
✅ **双向关系** - `upstream_tables` 和 `downstream_tables`
✅ **类型标识** - `is_model` 区分模型和源表

### 增强功能

#### Catalog 元数据（从 catalog.json 获取）
🆕 **技术元数据** - 表类型、数据类型、索引等
🆕 **数据库注释** - 表和列的数据库注释

#### Manifest 元数据（从 manifest.json 获取，v2.1 新增）
🆕 **模型标签** - tags 字段，用于分类和过滤
🆕 **模型描述** - description 字段，业务语义说明
🆕 **列描述** - column_descriptions，列的业务含义

#### 增强列血缘
🆕 **类型追踪** - 数据类型转换链路
🆕 **使用上下文** - 列的使用场景分析

### 应用场景

1. **📊 可视化血缘图** - 交互式图表、Mermaid 流程图
2. **🔍 影响分析** - 上游/下游影响追踪
3. **📝 文档生成** - 数据字典、血缘文档
4. **🛡️ 数据治理** - 合规性检查、敏感数据追踪
5. **🐛 问题排查** - 异常定位、计算链路追踪
6. **🏷️ 模型分类** - 按标签分组、按域过滤

---

## 附录

### A. 字段速查表

| 字段路径 | 类型 | v1.x | v2.0 | v2.1 | 示例值 |
|----------|------|------|------|------|--------|
| **核心字段** |
| `table_name` | string | ✅ | ✅ | ✅ | `"public.dim_analysts"` |
| `tables` | string[] | ✅ | ✅ | ✅ | `["raw.source"]` |
| `columns.{col}` | string[] | ✅ | ✅ | ✅ | `["source.col"]` |
| `is_model` | boolean | ✅ | ✅ | ✅ | `true` |
| **Catalog 元数据** |
| `table_metadata.type` | string | ❌ | ✅ | ✅ | `"VIEW"` |
| `column_metadata.{col}.type` | string | ❌ | ✅ | ✅ | `"text"` |
| **Manifest 元数据（v2.1 新增）** |
| `tags` | string[] | ❌ | ❌ | ✅ | `["business_model", "lims"]` |
| `description` | string | ❌ | ❌ | ✅ | `"分析师主数据"` |
| `column_descriptions.{col}` | string | ❌ | ❌ | ✅ | `"分析师唯一标识"` |
| **增强列血缘** |
| `enhanced_columns_metadata.{col}.type_change` | boolean | ❌ | ✅ | ✅ | `false` |
| **v2.0 移除字段** |
| `dependency_analysis.*` | object | ❌ | ✅ | ❌ | (已移除) |
| `query_analysis.*` | object | ❌ | ✅ | ❌ | (已移除) |

