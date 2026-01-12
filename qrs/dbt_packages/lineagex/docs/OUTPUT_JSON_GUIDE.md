# output.json 文件结构说明

## 概述

`output.json` 是 lineagex 包生成的数据血缘分析结果文件，包含了整个 dbt 项目中所有表和模型的血缘关系信息。

**文件大小**: 210 KB  
**包含内容**: 136 个表/模型（85 个 dbt 模型 + 51 个源表）

---

## 文件结构

### 顶层结构

```json
{
  "表/模型的唯一标识符": {
    "table_name": "实际的表名",
    "tables": ["上游依赖的表列表"],
    "columns": {
      "列名": ["该列的来源列列表"]
    },
    "upstream_tables": ["上游表列表"],
    "downstream_tables": ["下游表列表"],
    "is_model": true/false
  }
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `table_name` | string | 表的完整名称（schema.table_name） |
| `tables` | array | 直接依赖的上游表列表 |
| `columns` | object | 列级血缘，每个列及其来源 |
| `upstream_tables` | array | 所有上游依赖（包括间接依赖） |
| `downstream_tables` | array | 所有下游依赖（被哪些表使用） |
| `is_model` | boolean | 是否为 dbt 模型（true）或源表（false） |

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
      "department": [""],
      "qualification": [""],
      "status": [""]
    },
    "upstream_tables": [],
    "downstream_tables": ["model.qrs.stg_analyst"],
    "is_model": false
  }
}
```

**解读**:
- 这是一个源表（来自 LIMS 系统）
- `tables: [""]` - 没有上游依赖（是数据源头）
- `columns` 中每个列的来源都是 `[""]` - 表示是原始数据
- `downstream_tables` - 被 `stg_analyst` 模型使用
- `is_model: false` - 不是 dbt 模型，是源表

### 示例 2: Staging 模型

```json
{
  "model.qrs.stg_analyst": {
    "table_name": "public.stg_analyst",
    "tables": ["raw.lims_analyst"],
    "columns": {
      "analyst_id": ["lims_analyst.analyst_id"],
      "analyst_name": ["lims_analyst.analyst_name"],
      "analyst_code": ["lims_analyst.analyst_code"],
      "department": ["lims_analyst.department"],
      "qualification": ["lims_analyst.qualification"]
    },
    "upstream_tables": ["raw.lims_analyst"],
    "downstream_tables": ["model.qrs.dim_analysts"],
    "is_model": true
  }
}
```

**解读**:
- 这是一个 staging 模型
- `tables: ["raw.lims_analyst"]` - 依赖一个源表
- `columns` - 每个列都来自源表的对应列（1:1 映射）
- `downstream_tables` - 被 `dim_analysts` 维度表使用
- `is_model: true` - 是 dbt 模型

### 示例 3: Fact 表（复杂血缘）

```json
{
  "model.qrs.fct_adverse_events": {
    "table_name": "public.fct_adverse_events",
    "tables": ["raw.pv_adverse_event"],
    "columns": {
      "event_id": ["stg_adverse_event.event_id"],
      "event_date": ["stg_adverse_event.event_date"],
      "severity": ["stg_adverse_event.severity"],
      "processing_days": [
        "stg_adverse_event.close_date",
        "stg_adverse_event.report_date"
      ]
    },
    "upstream_tables": [
      "raw.pv_adverse_event",
      "model.qrs.stg_adverse_event"
    ],
    "downstream_tables": [],
    "is_model": true
  }
}
```

**解读**:
- 这是一个 fact 表
- `tables` - 直接依赖源表
- `columns` - 大部分列来自 staging 层
- `processing_days` - 这是一个计算列，来源于两个列的计算
- `upstream_tables` - 包含所有上游依赖（源表 + staging 模型）
- `downstream_tables: []` - 没有下游依赖（是终端表）

---

## 血缘图生成原理

### 1. 表级血缘（Table-Level Lineage）

通过 `tables` 和 `upstream_tables`/`downstream_tables` 字段构建：

```
raw.pv_adverse_event
    ↓
model.qrs.stg_adverse_event
    ↓
model.qrs.fct_adverse_events
```

### 2. 列级血缘（Column-Level Lineage）

通过 `columns` 字段追踪每个列的来源：

```
fct_adverse_events.processing_days
    ← stg_adverse_event.close_date
    ← stg_adverse_event.report_date
        ← pv_adverse_event.close_date
        ← pv_adverse_event.report_date
```

### 3. 血缘图可视化

`index.html` 使用 `output.json` 中的数据生成交互式血缘图：

1. **节点（Nodes）**: 每个表/模型是一个节点
2. **边（Edges）**: `tables` 关系形成有向边
3. **颜色编码**:
   - 源表（`is_model: false`）- 一种颜色
   - dbt 模型（`is_model: true`）- 另一种颜色
4. **交互功能**:
   - 点击节点查看列级血缘
   - 过滤特定路径
   - 搜索表/列

---

## 实际应用场景

### 场景 1: 影响分析

**问题**: 如果修改 `raw.lims_analyst` 表结构，会影响哪些下游模型？

**查询**:
```python
import json
data = json.load(open('output.json'))
affected = data['raw.lims_analyst']['downstream_tables']
print(f"直接影响: {affected}")
```

### 场景 2: 列血缘追踪

**问题**: `fct_adverse_events.processing_days` 这个列是如何计算的？

**查询**:
```python
sources = data['model.qrs.fct_adverse_events']['columns']['processing_days']
print(f"来源列: {sources}")
# 输出: ['stg_adverse_event.close_date', 'stg_adverse_event.report_date']
```

### 场景 3: 依赖路径分析

**问题**: 从源表到报表的完整数据流是什么？

**查询**:
```python
def get_upstream_path(table_name, data, visited=None):
    if visited is None:
        visited = set()
    if table_name in visited:
        return []
    visited.add(table_name)
    
    upstream = data.get(table_name, {}).get('tables', [])
    if upstream == ['']:
        return [table_name]
    
    paths = []
    for up in upstream:
        if up:
            paths.extend(get_upstream_path(up, data, visited))
    paths.append(table_name)
    return paths
```

---

## 数据生成流程

### 步骤 1: SQL 解析

对每个 dbt 模型执行 `EXPLAIN (FORMAT JSON)`:
```sql
EXPLAIN (VERBOSE TRUE, FORMAT JSON, COSTS FALSE) 
SELECT * FROM ...
```

### 步骤 2: 查询计划分析

PostgreSQL 返回查询执行计划（JSON 格式），包含：
- 扫描的表（Seq Scan, Index Scan）
- JOIN 操作
- 列的引用关系

### 步骤 3: 列血缘提取

通过分析查询计划中的：
- `Output` 字段 - 输出列
- `Relation Name` - 引用的表
- `Alias` - 表别名
- 表达式计算 - 派生列

### 步骤 4: 血缘关系构建

```python
# 伪代码
for model in dbt_models:
    plan = execute_explain(model.sql)
    tables = extract_tables(plan)
    columns = extract_column_lineage(plan)
    
    output_dict[model.name] = {
        'tables': tables,
        'columns': columns,
        'table_name': model.full_name
    }
```

### 步骤 5: 上下游关系计算

```python
# 计算下游依赖
for model, info in output_dict.items():
    for upstream_table in info['tables']:
        if upstream_table in output_dict:
            output_dict[upstream_table]['downstream_tables'].append(model)
```

---

## 可视化示例

### 使用提供的脚本

```bash
# 运行分析示例
python3 example_lineage_analysis.py

# 生成 Mermaid 图
python3 visualize_lineage.py
```

### 示例输出

**表级血缘图**:
```
源表 (pv_adverse_event) → Fact 表 (fct_adverse_events)
```

**列级血缘图**:
```
stg_adverse_event.close_date  ↘
                                → fct_adverse_events.processing_days
stg_adverse_event.report_date ↗
```

**多表 JOIN 血缘图**:
```
mes_equipment        ↘
mes_production_line  → dim_equipment
mes_workshop         ↗
```

---

## 总结

`output.json` 是一个完整的数据血缘知识图谱，包含：

✅ **136 个节点** - 所有表和模型（92 个 dbt 模型 + 44 个源表）
✅ **表级血缘** - 通过 `tables` 和 `upstream_tables` 字段
✅ **列级血缘** - 通过 `columns` 字段（601 个复杂计算列）
✅ **双向关系** - `upstream_tables` 和 `downstream_tables`
✅ **类型标识** - `is_model` 区分模型和源表

### 实际应用场景

这个文件可以用于：

1. **📊 可视化血缘图**
   - 使用 `index.html` 查看交互式血缘图
   - 使用 `visualize_lineage.py` 生成 Mermaid 图

2. **🔍 影响分析**
   - 查找修改某个表会影响哪些下游模型
   - 追踪数据从源头到报表的完整路径

3. **📝 自动化文档生成**
   - 生成数据字典
   - 生成血缘关系文档

4. **🛡️ 数据治理和合规性检查**
   - 验证数据流向是否符合规范
   - 审计敏感数据的使用情况

5. **🐛 问题排查**
   - 当数据异常时，快速定位问题来源
   - 追踪计算逻辑的完整链路

### 提供的工具

| 文件 | 用途 |
|------|------|
| `output.json` | 血缘数据（JSON 格式） |
| `index.html` | 交互式血缘可视化页面 |
| `example_lineage_analysis.py` | 血缘数据分析示例 |
| `visualize_lineage.py` | 生成 Mermaid 血缘图 |
| `OUTPUT_JSON_GUIDE.md` | 本文档 |

