# Entity Relationship Graph 组件开发计划

## 1. 项目背景与目标
- 背景：在现有基于 `output.json` 的模式层（schema-level）血缘可视化基础上，引入 **实体实例级（entity-level）关系图**。
- 目标：
  - 展示业务实体之间的层次结构关系（父子/包含）、外键关联、派生/计算来源以及跨表流转；
  - 支持围绕任意“根实体实例”（如订单头、订单行、工单、批次、样品、测试、偏差、事件等）进行上下游实体关系浏览；
  - 支持从实际数据库动态加载实体实例数据，并与模式图联动；
  - 保持与现有**跨层级模式图**和**多选混合视图**能力兼容。

## 2. 技术栈与整体架构
- 前端：Vue 3 + TypeScript + Composition API。
- 图引擎：AntV G6。
- 构建：Vite。
- 复用部分：
  - 现有列级血缘组件的通用逻辑：
    - `TableNode` / `ColumnRef` / `GraphEdge` 等模式层数据模型；
    - 图渲染基础设施（G6 初始化、缩放、布局、事件绑定）；
    - 状态管理与过滤逻辑（层级过滤、多选混合视图）。
- 新增部分：
  - 实体关系图（Entity Relationship Graph）专用数据模型与核心算法（实例级）；
  - 面向实体级的后端 API 契约与前端调用封装；
  - 支持 schema-level / entity-level / linked 三种视图模式的组件。

## 3. 组件架构设计
- 顶层容器：`EntityRelationshipGraphExplorer.vue`
  - 职责：
    - 视图模式切换（schema / entity / linked）；
    - 协调模式图与实体实例图的数据与交互；
    - 触发后端实例图加载（按实体类型、时间区间、业务主键、状态、关键字等）。
  - 与现有 `ColumnLineageExplorer` 并行存在，可集成在同一页面 Tab 中。

- 图画布组件：`EntityRelationshipGraphCanvas.vue`
  - 封装 G6 实例，接收 `VisualizationGraph`（模式节点 + 实体实例节点）。
  - 支持：
    - 仅模式图渲染；
    - 仅实体实例子图渲染；
    - 模式+实体联动视图渲染。

- 控制面板组件：`EntityRelationshipGraphControls.vue`
  - 功能：
    - 视图模式切换（schema/entity/linked）；
    - 根实体筛选（按实体类型、时间、状态、关键字等）；
    - 上下游深度限制、节点数量限制；
    - 实例级分页/增量加载触发。

- 实体详情组件：`EntityInstanceDetail.vue`
  - 展示选中业务实体实例（如订单头/行、工单、批次、样品、测试、记录等）的关键属性与上下游关联；
  - 支持从详情中跳转到模式层（对应表）或列级血缘路径。

- 图例与统计组件：`EntityRelationshipGraphLegend.vue`
  - 统一说明：
    - 节点颜色/形状编码（不同实体类型与模式层节点的区分）；
    - 当前视图数据量（节点/边数量、分页信息）。

- 服务与工具模块：
  - `entity-instance-graph-core.ts`：实体实例级数据模型、索引与核心算法；
  - 复用 `lineage-core.ts` 中的模式层逻辑与工具函数。

## 4. 视图模式与核心功能
- 视图模式：
  - **Schema View**：沿用现有跨层级模式图，仅展示表与血缘；可从表详情或列级血缘启动实体视图。
  - **Entity View**：围绕选定的根业务实体实例（例如订单头、订单行、工单、批次、样品、测试、偏差、事件等），展示其上下游多级实体关系及跨表流转；隐藏模式层节点，仅保留少量参考信息（表名）。
  - **Linked View**：模式层 DAG 与实体节点同屏展示，通过颜色/大小/组合（combo）区分；点击实体高亮对应表，点击表高亮其所有相关实体实例。

- 通用实体层次结构（可配置）：
  - 通过配置或元数据定义实体类型之间的层次与关系类型，例如：
    - `ORDER_HEADER -> ORDER_LINE`；
    - `WORK_ORDER -> OPERATION -> RECORD`；
    - `BATCH -> SAMPLE -> TEST_RESULT`；
    - `ISSUE -> ACTION -> AUDIT_RECORD`；
  - 前端实体关系图组件不硬编码具体层次，而是根据 `EntityKind` / 元数据驱动：
    - 哪些实体可以作为根；
    - 每种实体允许的父类型、子类型；
    - 每条关系采用 `PARENT_CHILD` / `FLOW` / `DERIVED_FROM` / `FK` 中的哪种关系类型。

## 5. 开发阶段与里程碑
- 阶段 0：需求澄清与方案评审（0.5 周）
  - 梳理关键实体类型、表/视图与主外键关系；
  - 评审实体关系图设计方案与 API 范围。

- 阶段 1：数据模型与核心算法库（1 周）
  - 定义扩展的 TypeScript 数据模型（模式层 + 实体实例层）；
  - 在 `entity-instance-graph-core.ts` 中实现通用索引与遍历算法（基于父子关系、外键关系与流转关系，支持任意深度）；
  - 单元测试覆盖对象构建与路径遍历逻辑。

- 阶段 2：后端 API 接口设计与初版实现（1–1.5 周）
  - 设计通用实例图加载 API（按实体类型、根业务主键/过滤条件）；
  - 实现实例图查询 SQL/ORM 逻辑与分页机制；
  - 与前端联调，校验数据结构与性能。

- 阶段 3：EntityRelationshipGraphExplorer 与基础 UI（1–1.5 周）
  - 实现 `EntityRelationshipGraphExplorer`、`EntityRelationshipGraphCanvas`、`EntityRelationshipGraphControls` 的基本骨架；
  - 支持模式视图与实体视图的切换、根实体选择与实例图加载。

- 阶段 4：联动视图与多选混合视图集成（1–1.5 周）
  - 支持 Linked View：模式层节点与实体实例节点同屏渲染、互相高亮；
  - 扩展现有多选逻辑以支持实体实例节点的选中与组合分析。

- 阶段 5：性能优化与大数据量支持（1–2 周）
  - 引入分页、聚合节点、子图渲染与节点上限保护；
  - 针对典型大业务场景（如一个订单包含数百行、一个批次包含数百样品、一个工单包含数百步骤/记录）进行压力测试与调优。

- 阶段 6：合规增强、文档与培训（1–1.5 周）
  - 明确数据来源版本与时间戳展示策略；
  - 补充用户使用手册与开发者技术文档；
  - 内部 QA/验证与反馈迭代。

## 6. 与现有功能的集成策略
- 与列级血缘组件共享：
  - 模式层数据模型与解析逻辑（`output.json`）；
  - 图渲染基础能力（G6 初始化与通用交互）；
  - 层级过滤与多选混合视图逻辑（扩展以支持实体实例节点）。
- 集成方式：
  - UI 层可使用 Tab 或路由区分 "Schema Lineage" 与 "Entity Relationship Graph"；
  - `EntityRelationshipGraphExplorer` 与 `ColumnLineageExplorer` 共用一套 store/service；
  - 保证不破坏现有模式层血缘能力，只在其基础上增加 entity-level 视图。
