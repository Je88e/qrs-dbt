# Lineagex - dbt 数据血缘分析工具

[![Python 3.13+](https://img.shields.io/badge/python-3.13+-blue.svg)](https://www.python.org/downloads/)
[![PostgreSQL 16+](https://img.shields.io/badge/postgresql-16+-blue.svg)](https://www.postgresql.org/)
[![dbt 1.9+](https://img.shields.io/badge/dbt-1.9+-orange.svg)](https://www.getdbt.com/)
[![Tests](https://img.shields.io/badge/tests-20%2F20%20passing-brightgreen.svg)](#测试)

为 dbt 项目生成完整的数据血缘分析，包括表级和列级血缘关系。

> 本项目基于 [dbt-lineagex](https://github.com/sfu-db/dbt-lineagex)，已从废弃的 `fal` 库迁移到自定义 `DbtPostgresConnector`。

---

## 特性

- **表级血缘** - 追踪表之间的依赖关系
- **列级血缘** - 追踪每个列的来源和计算逻辑
- **可视化** - 生成交互式血缘图（HTML）
- **JSON 输出** - 结构化数据，便于程序化处理
- **完整覆盖** - 支持所有 dbt 模型类型（staging, intermediate, dimension, fact, snapshot）
- **GxP 合规** - 适用于制药行业的数据治理需求

---

## 安装

### 依赖要求

| 依赖 | 版本 | 用途 |
|------|------|------|
| Python | 3.13+ | 运行环境 |
| PostgreSQL | 16+ | 数据库 |
| dbt | 1.9+ | dbt 核心框架 |

### 安装步骤

```bash
# 安装 Python 依赖
pip install -r requirements.txt
```

**requirements.txt 内容**:
```
psycopg2-binary>=2.9.0    # PostgreSQL 连接
pandas>=1.5.0             # 数据处理
pyyaml>=6.0               # YAML 解析
sqlglot>=11.5.3           # SQL 解析
lineagex>=0.0.3           # 列级血缘分析
```

---

## 命令参考

<!-- AUTO-GENERATED:START -->
### 常用命令

| 命令 | 说明 |
|------|------|
| `python3 main.py` | 生成血缘数据（JSON + HTML 可视化） |
| `bash run.sh` | 安装依赖并运行血缘分析 |
| `cd tests && ./run_all_tests.sh` | 运行所有测试（20 个用例） |
| `python3 examples/example_lineage_analysis.py` | 运行分析示例 |
| `python3 examples/visualize_lineage.py` | 生成 Mermaid 流程图 |

### 输出文件

| 文件 | 说明 | 大小参考 |
|------|------|---------|
| `output/output.json` | 血缘数据（JSON 格式） | ~210 KB |
| `output/index.html` | 交互式可视化页面 | ~210 KB |

**执行时间**: 约 2-5 分钟（85 个模型）
<!-- AUTO-GENERATED:END -->

---

## 项目结构

```
lineagex/
├── README.md                    # 本文件
├── requirements.txt             # Python 依赖
├── .gitignore                   # Git 忽略规则
│
├── 核心模块/
│   ├── main.py                  # 主入口
│   ├── lineage.py               # 血缘分析核心逻辑
│   ├── column_lineage.py        # 列级血缘分析
│   ├── db_connector.py          # 数据库连接器（替代 fal）
│   ├── catalog_lineage.py       # Catalog 分析器
│   ├── lineage_fusion.py        # 结果融合引擎
│   └── utils.py                 # 工具函数
│
├── docs/                        # 文档
│   └── OUTPUT_JSON_GUIDE.md     # output.json 详细说明
│
├── tests/                       # 测试（20 个测试用例）
│   ├── run_all_tests.sh         # 运行所有测试
│   ├── test_db_connector.py     # 数据库连接测试
│   ├── test_imports.py          # 模块导入测试
│   ├── test_lineage_integration.py  # 集成测试
│   ├── test_error_handling.py   # 错误处理测试
│   └── test_lineage_fix.py      # JSON 解析修复测试
│
├── examples/                    # 示例
│   ├── example_lineage_analysis.py  # 分析示例（5 个实用案例）
│   └── visualize_lineage.py     # 可视化示例（生成 Mermaid 图）
│
├── output/                      # 输出（生成）
│   ├── output.json              # 血缘数据
│   └── index.html               # 可视化页面
│
└── integration_tests/           # dbt 集成测试
```

---

## 使用文档

| 文档 | 说明 |
|------|------|
| [OUTPUT_JSON_GUIDE.md](docs/OUTPUT_JSON_GUIDE.md) | output.json 文件结构详解 |

---

## API 参考

<!-- AUTO-GENERATED:START -->
### Lineage 类

主入口类，用于生成完整的血缘分析。

```python
from lineage import Lineage

# 基本用法
lineage = Lineage(
    path="/path/to/dbt/project",  # dbt 项目路径
    profiles_dir="~/.dbt",        # profiles.yml 目录（可选）
    target=None,                  # 目标环境（可选）
    mode="combine"                # 分析模式（默认 combine）
)

# 完成后自动关闭连接
lineage.close()
```

**参数**:

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `path` | `str` | ✅ | - | dbt 项目根目录路径 |
| `profiles_dir` | `str` | ❌ | `~/.dbt` | dbt profiles.yml 所在目录 |
| `target` | `str` | ❌ | `None` | 目标环境（如 dev, prod） |
| `mode` | `str` | ❌ | `combine` | 分析模式 |

**方法**:

| 方法 | 说明 |
|------|------|
| `close()` | 关闭数据库连接 |
| `_run_lineage()` | 执行血缘分析（内部方法） |

### DbtPostgresConnector 类

数据库连接器，替代已废弃的 FalDbt。

```python
from db_connector import DbtPostgresConnector

connector = DbtPostgresConnector(
    profiles_dir="~/.dbt",
    project_dir="/path/to/project",
    target="dev"
)

# 执行 SQL 查询
df = connector.execute_sql("SELECT * FROM my_table")

# 关闭连接
connector.close()

# 支持上下文管理器
with DbtPostgresConnector(project_dir=".") as conn:
    df = conn.execute_sql("SELECT 1")
```

**方法**:

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `execute_sql(sql)` | `str` | `pd.DataFrame` | 执行 SQL 并返回 DataFrame |
| `close()` | - | `None` | 关闭数据库连接 |

### ColumnLineage 类

列级血缘分析器（内部使用）。

```python
from column_lineage import ColumnLineage

col_lineage = ColumnLineage(
    plan=query_plan,           # PostgreSQL 查询计划
    sql="SELECT ...",          # SQL 语句
    columns=["col1", "col2"],  # 列名列表
    conn=db_connector,         # 数据库连接
    part_tables={}             # 分区表映射
)

# 获取结果
table_list = col_lineage.table_list  # 依赖表列表
column_dict = col_lineage.column_dict  # 列血缘字典
```

### CatalogLineage 类

从 catalog.json 推断血缘关系（内部使用）。

```python
from catalog_lineage import CatalogLineage

catalog_lineage = CatalogLineage(
    manifest=manifest_data,
    catalog=catalog_data,
    node_id="model.qrs.stg_orders"
)
```

### LineageFusion 类

融合 EXPLAIN 和 Catalog 分析结果（内部使用）。

```python
from lineage_fusion import LineageFusion

fusion = LineageFusion(
    explain_result=explain_data,
    catalog_result=catalog_data,
    enhanced_columns=columns_info
)

fused_result = fusion.fused_result
```
<!-- AUTO-GENERATED:END -->

---

## 使用示例

### 示例 1: 影响分析

```python
import json

# 加载血缘数据
with open('output/output.json', 'r') as f:
    data = json.load(f)

# 查找下游依赖
table = 'raw.lims_analyst'
affected = data[table]['downstream_tables']

print(f"修改 {table} 将影响 {len(affected)} 个表:")
for t in affected:
    print(f"  - {t}")
```

### 示例 2: 列血缘追踪

```python
# 查找列的来源
table = 'model.qrs.fct_adverse_events'
column = 'processing_days'
sources = data[table]['columns'][column]

print(f"{column} 来源于:")
for source in sources:
    print(f"  - {source}")
```

### 示例 3: 查找复杂计算列

```python
# 查找来源于多个列的派生字段
for table_name, info in data.items():
    for col_name, sources in info.get('columns', {}).items():
        if len(sources) >= 2 and sources != ['']:
            print(f"{table_name}.{col_name}: {sources}")
```

更多示例请查看 [examples/](examples/) 目录。

---

## 测试

<!-- AUTO-GENERATED:START -->
### 运行测试

```bash
cd tests
./run_all_tests.sh
```

### 测试套件

| 测试文件 | 用例数 | 覆盖内容 |
|---------|--------|---------|
| `test_db_connector.py` | 5 | 数据库连接、配置解析、错误处理 |
| `test_imports.py` | 4 | 模块导入、依赖验证 |
| `test_lineage_integration.py` | 3 | 集成功能、端到端测试 |
| `test_error_handling.py` | 5 | 异常场景、边界条件 |
| `test_lineage_fix.py` | 3 | JSON 解析修复 |
| **总计** | **20** | **100% 通过率** |
<!-- AUTO-GENERATED:END -->

---

## 数据统计（QRS 项目）

- **136 个节点**: 92 个 dbt 模型 + 44 个源表
- **6 个源系统**: ERP, MES, LIMS, QMS, SCADA, PV
- **4 层架构**: Staging → Intermediate → Business → Reports
- **601 个复杂计算列**: 来源于多个列的派生字段

---

## 快速开始

1. 安装依赖: `pip install -r requirements.txt`
2. 运行分析: `python3 main.py`
3. 查看结果: 在浏览器中打开 `output/index.html`
4. 学习更多: 查看 [examples/](examples/) 目录
