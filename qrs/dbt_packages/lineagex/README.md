# Lineagex - dbt 数据血缘分析工具

[![Python 3.13+](https://img.shields.io/badge/python-3.13+-blue.svg)](https://www.python.org/downloads/)
[![PostgreSQL 16+](https://img.shields.io/badge/postgresql-16+-blue.svg)](https://www.postgresql.org/)
[![dbt 1.9+](https://img.shields.io/badge/dbt-1.9+-orange.svg)](https://www.getdbt.com/)
[![Tests](https://img.shields.io/badge/tests-20%2F20%20passing-brightgreen.svg)](#测试)

为 dbt 项目生成完整的数据血缘分析，包括表级和列级血缘关系。

> 本项目基于 [dbt-lineagex](https://github.com/sfu-db/dbt-lineagex)，已从废弃的 `fal` 库迁移到自定义 `DbtPostgresConnector`。

---

## ✨ 特性

- 🔍 **表级血缘** - 追踪表之间的依赖关系
- 📊 **列级血缘** - 追踪每个列的来源和计算逻辑
- 🎨 **可视化** - 生成交互式血缘图（HTML）
- 📝 **JSON 输出** - 结构化数据，便于程序化处理
- 🚀 **完整覆盖** - 支持所有 dbt 模型类型（staging, intermediate, dimension, fact, snapshot）
- ✅ **GxP 合规** - 适用于制药行业的数据治理需求

---

## 🚀 快速开始

### 1. 生成血缘数据

\`\`\`bash
python3 main.py
\`\`\`

**输出**:
- \`output/output.json\` - 血缘数据（JSON 格式，210 KB）
- \`output/index.html\` - 交互式可视化页面（210 KB）

**执行时间**: 约 2-5 分钟（85 个模型）

### 2. 查看可视化结果

在浏览器中打开 \`output/index.html\`

### 3. 运行分析示例

\`\`\`bash
python3 examples/example_lineage_analysis.py
\`\`\`

---

## 📁 项目结构

\`\`\`
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
│   └── utils.py                 # 工具函数
│
├── docs/                        # 📚 文档
│   ├── 血缘分析使用指南.md       # 中文使用指南 ⭐ 推荐
│   ├── OUTPUT_JSON_GUIDE.md     # output.json 详细说明
│   ├── MIGRATION_SUMMARY.md     # 迁移总结
│   ├── FIX_REPORT.md            # 修复报告
│   └── TEST_REPORT.md           # 测试报告
│
├── tests/                       # 🧪 测试（20 个测试用例，100% 通过）
│   ├── run_all_tests.sh         # 运行所有测试
│   ├── test_db_connector.py     # 数据库连接测试
│   ├── test_imports.py          # 模块导入测试
│   ├── test_lineage_integration.py  # 集成测试
│   └── test_error_handling.py   # 错误处理测试
│
├── examples/                    # 💡 示例
│   ├── example_lineage_analysis.py  # 分析示例（5 个实用案例）
│   └── visualize_lineage.py     # 可视化示例（生成 Mermaid 图）
│
├── output/                      # 📊 输出（生成）
│   ├── output.json              # 血缘数据（136 个表/模型）
│   └── index.html               # 可视化页面
│
└── integration_tests/           # dbt 集成测试
\`\`\`

---

## 📖 使用文档

### 🌟 推荐阅读

| 文档 | 说明 |
|------|------|
| [血缘分析使用指南.md](docs/血缘分析使用指南.md) | **完整的中文使用指南**（包含实际应用示例） |
| [OUTPUT_JSON_GUIDE.md](docs/OUTPUT_JSON_GUIDE.md) | output.json 文件结构详解 |
| [MIGRATION_SUMMARY.md](docs/MIGRATION_SUMMARY.md) | 从 fal 库迁移的详细说明 |
| [FIX_REPORT.md](docs/FIX_REPORT.md) | JSON 解析错误修复报告 |
| [TEST_REPORT.md](docs/TEST_REPORT.md) | 完整测试报告 |

---

## 💡 使用示例

### 示例 1: 影响分析

\`\`\`python
import json

# 加载血缘数据
data = json.load(open('output/output.json'))

# 查找下游依赖
table = 'raw.lims_analyst'
affected = data[table]['downstream_tables']

print(f"修改 {table} 将影响 {len(affected)} 个表:")
for t in affected:
    print(f"  - {t}")
\`\`\`

### 示例 2: 列血缘追踪

\`\`\`python
# 查找列的来源
table = 'model.qrs.fct_adverse_events'
column = 'processing_days'
sources = data[table]['columns'][column]

print(f"{column} 来源于:")
for source in sources:
    print(f"  - {source}")
\`\`\`

更多示例请查看 [examples/](examples/) 目录。

---

## 🧪 测试

### 运行所有测试

\`\`\`bash
cd tests
./run_all_tests.sh
\`\`\`

### 测试覆盖

| 测试套件 | 用例数 | 状态 |
|---------|--------|------|
| 数据库连接测试 | 5 | ✅ 100% |
| 模块导入测试 | 4 | ✅ 100% |
| 集成功能测试 | 3 | ✅ 100% |
| 错误处理测试 | 5 | ✅ 100% |
| JSON 解析修复测试 | 3 | ✅ 100% |
| **总计** | **20** | **✅ 100%** |

---

## 📊 数据统计（QRS 项目）

- **136 个节点**: 92 个 dbt 模型 + 44 个源表
- **6 个源系统**: ERP, MES, LIMS, QMS, SCADA, PV
- **4 层架构**: Staging → Intermediate → Business → Reports
- **601 个复杂计算列**: 来源于多个列的派生字段

---

## 🎯 下一步

1. 📖 阅读 [血缘分析使用指南.md](docs/血缘分析使用指南.md)
2. 🚀 运行 \`python3 main.py\` 生成血缘数据
3. 🎨 在浏览器中打开 \`output/index.html\` 查看可视化
4. 💡 查看 [examples/](examples/) 目录学习更多用法

祝您使用愉快！🎉
