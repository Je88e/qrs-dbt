# Vue 3 Data Graph 组件技术设计

## 1. 概述
- 目标：在现有模式层血缘技术基础上，引入数据实例级可视化，支持各业务域（ERP、MES、LIMS、QMS、SCADA、PV）的实体结构与跨域流转，例如：
  - ERP：采购订单头/行与供应商、物料记录；
  - MES：工单、工序、设备/人员记录；
  - LIMS：实验批次、样品、测试/检验结果；
  - QMS：偏差、CAPA、审核记录；
  - SCADA：设备数据点、环境监测记录；
  - PV：不良事件、投诉、召回等。
- 约束：
  - 前端技术栈：Vue 3 + TS + AntV G6；
  - 复用已有模式层数据模型与渲染基础设施；
  - 新增实例层数据模型、索引、算法与视图模式。

## 2. TypeScript 数据模型扩展

### 2.1 复用模式层模型
```ts
// 来自列级血缘模块
export interface TableNode {
  id: string;
  tableName: string;
  isModel: boolean;
  layer: 'raw' | 'staging' | 'intermediate' | 'dimension' | 'fact' | 'report' | 'other';
  domain: 'ERP' | 'MES' | 'LIMS' | 'QMS' | 'SCADA' | 'PV' | 'UNKNOWN';
  upstream: string[];
  downstream: string[];
  columns: Record<string, string[]>;
}

export interface ColumnRef {
  tableId: string;
  columnName: string;
}
```

### 2.2 数据实例层模型
```ts
// 业务域（与 TableNode.domain 对齐）
export type BusinessDomain =
  | 'ERP'
  | 'MES'
  | 'LIMS'
  | 'QMS'
  | 'SCADA'
  | 'PV'
  | 'UNKNOWN';

// 通用实体类型标识：
// 建议采用 "<DOMAIN>_<ENTITY>" 命名，例如：
// 'ERP_PO_HEADER', 'ERP_PO_LINE', 'MES_WORK_ORDER', 'LIMS_BATCH',
// 'QMS_DEVIATION', 'SCADA_EQUIP_EVENT', 'PV_ADVERSE_EVENT' 等。
// 为保持可扩展性，这里使用 string 类型，由配置/元数据约定具体取值。
export type EntityKind = string;

export interface DataInstanceId {
  tableId: string;                     // 对应 TableNode.id
  pk: Record<string, string | number>; // 复合主键
}

export interface DataInstanceNode {
  id: string;                          // `${tableId}::${pkHash}`
  tableId: string;
  entityKind: EntityKind;
  displayLabel: string;                // 业务主键/显示名，如批次号、样品条码、工单号、订单号等
  attributes: Record<string, string | number | null>;
  parent?: DataInstanceId;             // 通用父层级：如 批次->样品、工单->工序、订单头->订单行 等
  children?: DataInstanceId[];
  createdAt?: string;
  status?: string;
}

export type DataRelationType =
  | 'PARENT_CHILD'   // 通用父子关系：批次-样品、工单-工序、订单头-订单行 等
  | 'FK'             // 主外键记录关联
  | 'DERIVED_FROM'   // 聚合/计算来源
  | 'FLOW';          // 跨表流转

export interface DataInstanceEdge {
  id: string;
  sourceInstanceId: string; // DataInstanceNode.id
  targetInstanceId: string;
  relationType: DataRelationType;
  columnMapping?: Array<{ from: ColumnRef; to: ColumnRef }>;
}

export interface InstanceGraph {
  rootInstances: DataInstanceId[];
  nodes: DataInstanceNode[];
  edges: DataInstanceEdge[];
}

export interface VisualizationGraph {
  schemaNodes: TableNode[];
  schemaEdges: GraphEdge[];           // 表级边，来自模式层
  dataNodes: DataInstanceNode[];
  dataEdges: DataInstanceEdge[];
  instanceToTableMap: Map<string, string>; // 实例节点 -> 所属表
}
```

### 2.3 前端索引结构
```ts
// 模式层（已有）
const tableMap = new Map<string, TableNode>();

// 实例层索引
const instanceMap = new Map<string, DataInstanceNode>();
const instancesByTable = new Map<string, DataInstanceNode[]>();
const instanceEdgesBySource = new Map<string, DataInstanceEdge[]>();
const instanceEdgesByTarget = new Map<string, DataInstanceEdge[]>();

// 实例图缓存
const instanceGraphCache = new Map<string, InstanceGraph>(); // key 示例: `${tableId}::${pkHash}`
```

## 3. 核心算法设计

### 3.1 构建索引
- 在收到后端返回的 `InstanceGraph` 后：
  - 将 `nodes` 中每个 `DataInstanceNode` 写入 `instanceMap` 与 `instancesByTable`；
  - 将 `edges` 写入 `instanceEdgesBySource` 与 `instanceEdgesByTarget`；
  - 维护 `instanceGraphCache`（按根实例标识 key 缓存）。

### 3.2 通用父子层次遍历
- 以任意根实例为起点（如 ERP 订单头、MES 工单、LIMS 批次、QMS 偏差等）：
  - 顺着 `PARENT_CHILD` 边遍历其所有子实例；
  - 深度可以是任意值，由 `maxDepth` 控制；
- 伪代码：
```ts
function getSubtree(rootId: string, maxDepth: number): Set<string> {
  const visited = new Set<string>();
  const queue: Array<{ id: string; depth: number }> = [{ id: rootId, depth: 0 }];
  while (queue.length) {
    const { id, depth } = queue.shift()!;
    if (visited.has(id) || depth > maxDepth) continue;
    visited.add(id);
    const children = (instanceEdgesBySource.get(id) || [])
      .filter(e => e.relationType === 'PARENT_CHILD')
      .map(e => e.targetInstanceId);
    children.forEach(childId => queue.push({ id: childId, depth: depth + 1 }));
  }
  return visited;
}
```

### 3.3 跨表流转路径
- 基于 `FLOW` / `DERIVED_FROM` 类型的 `DataInstanceEdge`：
  - 支持从任意业务记录（如 ERP 订单、MES 工单、LIMS 测试结果、QMS 偏差、PV 事件等）出发；
  - 沿 `FLOW` 寻找下游记录（例如 ERP 物料 -> MES 生产 -> LIMS 检验 -> QMS 偏差 -> PV 不良事件）；
  - 亦可反向沿 `DERIVED_FROM` 上溯至原始数据来源；
- 可以使用 BFS/DFS，带深度限制与节点上限保护，并支持按 domain/EntityKind 过滤。

### 3.4 视图模式下的可视化图构建
- Schema View：
  - `VisualizationGraph` 中仅填充 `schemaNodes` / `schemaEdges`；
- Data View：
  - 仅填充 `dataNodes` / `dataEdges`；
  - 可按 `entityKind` + 层级深度对实例节点布局；
- Linked View：
  - `schemaNodes` / `schemaEdges` + 与当前实例图相关的 `dataNodes` / `dataEdges`；
  - `instanceToTableMap` 用于将实例分组到对应表节点周围或 combo 中。

## 4. G6 渲染策略

### 4.1 视图模式与布局
- `mode = 'schema'`：沿用已有分层布局（raw→stg→dim/fct→report）。
- `mode = 'instance'`：
  - 以任意根实例为根做树形或分层布局：
    - 上层：根实体（如订单头/工单/批次/偏差等）；
    - 下层：其子实体（如订单行/工序/样品/测试/设备记录等）；
    - 更深层级：继续沿 `PARENT_CHILD` 遍历生成；
- `mode = 'linked'`：
  - 模式节点使用原有位置；
  - 实例节点使用二次布局：
    - 将同一表的实例聚集在表节点周围（可使用 combo 或自定义约束）；
    - 各域实体树在局部内部保持自身父子层次结构（如 工单→工序、批次→样品→测试 等）。

### 4.2 节点与边的视觉编码
- Schema 节点：矩形，按 layer 着色。
- Data 节点：圆形/图标：
  - 可按 EntityKind/实体类型配置大小与颜色，例如：
    - ERP：订单头较大、订单行中等；
    - MES：工单较大、工序/设备事件中等；
    - LIMS：批次较大、样品中等、测试结果较小；
- 边：
  - `PARENT_CHILD`：实线箭头；
  - `FLOW` / `DERIVED_FROM`：虚线或不同颜色，用于区分跨表流转。

## 5. 性能优化方案

### 5.1 查询与加载范围控制
- 仅允许围绕有限数量的根实例（通常为 1–N 个根业务对象：订单/工单/批次/偏差/事件等）加载实例图。
- 后端接口支持：通用的 `maxChildrenPerLevel`、`maxNodes` 等参数，或按实体类型细分（如每个订单的最大订单行数、每个批次的最大样品数等）；
- 前端在实例数或边数超出阈值时提示用户缩小范围或分页。

### 5.2 聚合节点与增量展开
- 对同一父实体下的大量子实例（如订单下的行项目、批次下的样品、工单下的工序/设备记录等）：
  - 初始仅显示前若干子实例 + 一个聚合节点：“+N ...”；
  - 点击聚合节点时再调用后端分页加载并展开。
- 对数据量极大的实体（如 SCADA 采集点或高频设备事件）可按时间窗口或聚合粒度（分钟/小时/天）进行聚合展示，必要时只显示统计节点而非逐条记录。

### 5.3 缓存与重用
- 对已加载的 `InstanceGraph` 缓存至 `instanceGraphCache`：
  - 再次查看同一根实例（或同一查询条件）下的实例图时直接使用缓存。
- 对常用模式+实例组合的布局结果可做缓存，避免重复布局计算。

## 6. 兼容性说明
- 数据实例节点始终通过 `tableId` 关联到 `TableNode`：
  - 不改变模式层 DAG，仅在其之上挂载 data-level 节点；
- 多选混合视图：
  - 在现有 `selectedTables` / `selectedColumns` 基础上，增加 `selectedInstanceNodes`；
  - 子图计算时可同时考虑模式节点与实例节点，保持原有逻辑不变，仅扩展范围。
