# Vue 3 Data Graph 组件开发计划

## 1. 项目背景与目标
- 背景：在现有基于 `output.json` 的模式层（schema-level）血缘可视化基础上，引入 **数据实例级（data-level）可视化**。
- 目标：
  - 支持所有业务域（ERP、MES、LIMS、QMS、SCADA、PV）中典型的实体层次关系展示，例如：
    - ERP：采购订单 → 订单行项目；
    - MES：工单 → 工序 → 设备/人员记录；
    - LIMS：实验批次 → 多个样品 → 多个测试/检验项目；
    - QMS：偏差 → CAPA → 审核记录；
    - PV：不良事件 → 投诉/召回等。
  - 展示具体业务数据实例及其跨表、跨域流转关系，不仅限于表/列结构与血缘。
  - 支持从实际数据库动态加载实例数据，并与模式图联动。
  - 保持与现有**跨层级展示**和**多选混合视图**能力兼容。

## 2. 技术栈与整体架构
- 前端：Vue 3 + TypeScript + Composition API。
- 图引擎：AntV G6。
- 构建：Vite。
- 复用部分：
  - 现有列级血缘组件的通用逻辑：
    - `TableNode` / `ColumnRef` / `GraphEdge` 等模式层数据模型。
    - 图渲染基础设施（G6 初始化、缩放、布局、事件绑定）。
    - 状态管理与过滤逻辑（层级过滤、多选混合视图）。
- 新增部分：
  - Data Graph 专用数据模型与核心算法（实例级）。
  - 面向实例级的后端 API 契约与前端调用封装。
  - 支持 schema-level / data-level / linked 三种视图模式的组件。

## 3. 组件架构设计
- 顶层容器：`DataGraphExplorer.vue`
  - 职责：
    - 视图模式切换（schema / data / linked）。
    - 协调模式图与实例图的数据与交互。
    - 触发后端实例图加载（按业务域、实体类型、时间区间、业务主键等）。
  - 与现有 `ColumnLineageExplorer` 并行存在，可集成在同一页面 Tab 中。

- 图画布组件：`DataGraphCanvas.vue`
  - 封装 G6 实例，接收 `VisualizationGraph`（模式节点 + 实例节点）。
  - 支持：
    - 仅模式图渲染；
    - 仅实例子图渲染；
    - 模式+实例联动视图渲染。

- 控制面板组件：`DataGraphControls.vue`
  - 功能：
    - 视图模式切换（schema/data/linked）。
    - 根实体筛选（按业务域、实体类型、时间、状态等）。
    - 上下游深度限制、节点数量限制。
    - 实例级分页/增量加载触发。

- 实例详情组件：`DataInstanceDetail.vue`
  - 展示选中业务实例（如批次、样品、测试、工单、订单头/行等）的关键属性与上下游关联。
  - 支持从详情中跳转到模式层（对应表）或列级血缘路径。

- 图例与统计组件：`DataGraphLegend.vue`
  - 统一说明：
    - 节点颜色/形状编码（不同实体类型，如批次/样品/测试、工单/工序、订单头/行等 vs 表层级）。
    - 当前视图数据量（节点/边数量、分页信息）。

- 服务与工具模块：
  - `instance-graph-core.ts`：实例级数据模型、索引与核心算法。
  - 复用 `lineage-core.ts` 中的模式层逻辑与工具函数。

## 4. 视图模式与核心功能
- 视图模式：
  - **Schema View**：沿用现有跨层级模式图，仅展示表与血缘；可从表详情启动实例视图。
  - **Data View**：围绕选定的根业务实例（例如 LIMS 批次、MES 工单、ERP 采购订单、SCADA 设备采集点等），展示其上下游多级实例关系及跨表/跨域流转；隐藏模式层节点，仅保留少量参考信息（表名/域）。
  - **Linked View**：模式层 DAG 与实例节点同屏展示，通过颜色/大小/组合（combo）区分；点击实例高亮对应表，点击表高亮其所有相关实例。

- 通用实体层次结构（可配置）：
  - 通过配置或元数据定义各业务域的实体层次与关系类型，例如：
    - ERP：`PO_HEADER -> PO_LINE`；
    - MES：`WORK_ORDER -> OPERATION -> EQUIPMENT_EVENT / PERSONNEL_RECORD`；
    - LIMS：`BATCH -> SAMPLE -> TEST_RESULT`；
    - QMS：`DEVIATION -> CAPA -> AUDIT_RECORD`；
    - PV：`ADVERSE_EVENT -> COMPLAINT / RECALL`；
  - 前端 Data Graph 组件不硬编码具体层次，而是根据 `EntityKind` / 元数据驱动：
    - 哪些实体可以作为根；
    - 每种实体允许的父类型、子类型；
    - 每条关系采用 `PARENT_CHILD` / `FLOW` / `DERIVED_FROM` 等哪种关系类型。

## 5. 开发阶段与里程碑
- 阶段 0：需求澄清与方案评审（0.5 周）
  - 明确各业务域（ERP、MES、LIMS、QMS、SCADA、PV）的关键实体、表/视图与主外键关系。
  - 评审 Data Graph 设计方案与 API 范围。

- 阶段 1：数据模型与核心算法库（1 周）
  - 定义扩展的 TypeScript 数据模型（模式层 + 实例层）。
  - 在 `instance-graph-core.ts` 中实现通用索引与遍历算法（基于父子关系与流转关系，支持任意深度与任意域）。
  - 单元测试覆盖对象构建与路径遍历逻辑。

- 阶段 2：后端 API 接口设计与初版实现（1–1.5 周）
  - 设计通用实例图加载 API（按业务域、实体类型、根业务主键/过滤条件）。
  - 实现各域实例图查询 SQL/ORM 逻辑与分页机制（ERP 订单、MES 工单、LIMS 批次、QMS 偏差、PV 事件等）。
  - 与前端联调，校验数据结构与性能。

- 阶段 3：DataGraphExplorer 与基础 UI（1–1.5 周）
  - 实现 `DataGraphExplorer`、`DataGraphCanvas`、`DataGraphControls` 的基本骨架。
  - 支持模式视图与数据视图的切换、根实体选择与实例图加载。

- 阶段 4：联动视图与多选混合视图集成（1–1.5 周）
  - 支持 Linked View：模式层节点与实例节点同屏渲染、互相高亮。
  - 扩展现有多选逻辑以支持实例节点的选中与组合分析。

- 阶段 5：性能优化与大数据量支持（1–2 周）
  - 引入分页、聚合节点、子图渲染与节点上限保护。
  - 针对典型大业务场景（如一个采购订单包含数百行、一个工单包含数百工序与设备记录、一个批次包含数百样品与测试）进行压力测试与调优。

- 阶段 6：GxP 合规增强、文档与培训（1–1.5 周）
  - 明确数据来源版本与时间戳展示策略。
  - 补充用户使用手册与开发者技术文档。
  - 内部 QA/CSV 验证与反馈迭代。

## 6. 与现有功能的集成策略
- 与列级血缘组件共享：
  - 模式层数据模型与解析逻辑（`output.json`）。
  - 图渲染基础能力（G6 初始化与通用交互）。
  - 层级过滤与多选混合视图逻辑（扩展以支持实例节点）。
- 集成方式：
  - UI 层可使用 Tab 或路由区分 "Schema Lineage" 与 "Data Graph"；
  - `DataGraphExplorer` 与 `ColumnLineageExplorer` 共用一套 store/service；
  - 保证不破坏现有模式层血缘能力，只在其基础上增加 data-level 视图。
