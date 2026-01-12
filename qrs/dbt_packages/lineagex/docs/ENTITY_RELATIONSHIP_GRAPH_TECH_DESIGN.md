# Entity Relationship Graph 组件技术设计

## 1. 概述
- 目标：在现有模式层血缘技术基础上，引入实体实例级可视化，专注于 **实体与实体之间的关系**，包括：
  - 父子/包含关系（`PARENT_CHILD`）；
  - 外键关联关系（`FK`）；
  - 派生/计算来源关系（`DERIVED_FROM`）；
  - 流转关系（`FLOW`）。
- 本设计不引入任何系统/来源分类维度：所有实体仅按类型与关系建模，可在同一关系图中混合呈现与渲染。
- 约束：
  - 前端技术栈：Vue 3 + TS + AntV G6；
  - 复用已有模式层数据模型与渲染基础设施；
  - 新增实体实例层数据模型、索引、算法与视图模式。

## 2. TypeScript 数据模型扩展

### 2.1 复用模式层模型（简化示意）
```ts
export interface TableNode {
  id: string;
  tableName: string;
  isModel: boolean;
  layer: 'raw' | 'staging' | 'intermediate' | 'dimension' | 'fact' | 'report' | 'other';
  // ... 其他字段沿用现有实现
}

export interface ColumnRef {
  tableId: string;
  columnName: string;
}
```

### 2.2 实体实例层模型
```ts
// 实体类型标识：任意字符串，由配置/元数据约定，示例：
// 'PO_HEADER', 'PO_LINE', 'WORK_ORDER', 'BATCH', 'SAMPLE',
// 'TEST_RESULT', 'ISSUE', 'ACTION', 'EVENT' 等。
export type EntityKind = string;

export interface DataInstanceId {
  tableId: string;                     // 对应 TableNode.id
  pk: Record<string, string | number>; // 复合主键（业务主键或技术主键）
}

export interface DataInstanceNode {
  id: string;                          // `${tableId}::${pkHash}`
  tableId: string;
  entityKind: EntityKind;
  displayLabel: string;                // 显示名，如订单号、工单号、批次号、样品条码等
  attributes: Record<string, string | number | null>;
  parent?: DataInstanceId;             // 通用父层级：如 订单头->订单行、工单->步骤、批次->样品->测试 等
  children?: DataInstanceId[];
  createdAt?: string;
  status?: string;
}

export type DataRelationType =
  | 'PARENT_CHILD'
  | 'FK'
  | 'DERIVED_FROM'
  | 'FLOW';

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
  stats?: { nodeCount: number; edgeCount: number; truncated: boolean };
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

// 实体实例层索引
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
- 以任意根实体实例为起点（如订单头、工单、批次、样品、测试、记录等）：
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

### 3.3 跨表流转与派生路径
- 基于 `FLOW` / `DERIVED_FROM` 类型的 `DataInstanceEdge`：
  - 支持从任意业务实体实例出发，沿 `FLOW` 寻找下游记录（如从订单行到发运记录、对账记录等）；
  - 亦可反向沿 `DERIVED_FROM` 上溯至原始数据来源（如从统计报表行上溯到明细记录）；
- 采用 BFS/DFS，带深度限制与节点上限保护；
- 可与 `PARENT_CHILD` / `FK` 组合使用，形成混合路径（如：头->行->明细->聚合结果）。

### 3.4 视图模式下的可视化图构建
- Schema View：
  - `VisualizationGraph` 中仅填充 `schemaNodes` / `schemaEdges`；
- Entity View：
  - 仅填充 `dataNodes` / `dataEdges`；
  - 可按 `entityKind` + 层级深度对实例节点布局；
- Linked View：
  - 组合 `schemaNodes` / `schemaEdges` 与相关的 `dataNodes` / `dataEdges`；
  - `instanceToTableMap` 用于将实例聚集在对应表节点周围或 combo 中。

## 4. G6 渲染策略

### 4.1 视图模式与布局
- `mode = 'schema'`：沿用已有分层布局（raw→stg→dim/fct→report）。
- `mode = 'entity'`：
  - 以任意根实体为根做树形或分层布局：
    - 上层：根实体（如订单头/工单/批次等）；
    - 下层：其子实体（如订单行/步骤/样品/测试等）；
    - 更深层级：继续沿 `PARENT_CHILD` 遍历生成；
- `mode = 'linked'`：
  - 模式节点使用原有位置；
  - 实体实例节点使用二次布局：
    - 将同一表的实例聚集在表节点周围（combo 或自定义约束）；
    - 各实体树在局部内部保持自身父子层次结构。

### 4.2 节点与边的视觉编码
- Schema 节点：矩形，按 layer 着色。
- 实体节点：圆形/图标：
  - 按 `EntityKind` 配置大小与颜色，例如根实体较大、子实体中等、叶子实体较小；
- 边：
  - `PARENT_CHILD`：实线箭头；
  - `FK`：细实线或不同风格；
  - `FLOW` / `DERIVED_FROM`：虚线或不同颜色，用于区分流转与派生路径。

## 5. 性能优化方案

### 5.1 查询与加载范围控制
- 仅允许围绕有限数量的根实体实例（通常为 1–N 个）加载实例图；
- 后端接口支持：通用的 `maxChildrenPerLevel`、`maxNodes` 等参数；
- 前端在实例数或边数超出阈值时提示用户缩小范围或分页。

### 5.2 聚合节点与增量展开
- 对同一父实体下的大量子实例（如一个父记录下包含数百子记录）：
  - 初始仅显示前若干子实例 + 一个聚合节点：“+N ...”；
  - 点击聚合节点时再调用后端分页加载并展开；
- 对数据量极大的实体（如高频记录）可按时间窗口或聚合粒度进行聚合展示，仅显示统计节点而非逐条记录。

### 5.3 缓存与重用
- 对已加载的 `InstanceGraph` 缓存至 `instanceGraphCache`：
  - 再次查看同一根实例（或同一查询条件）下的实例图时直接使用缓存；
- 对常用模式+实体组合的布局结果可做缓存，避免重复布局计算。

## 6. 兼容性说明
- 实体实例节点始终通过 `tableId` 关联到 `TableNode`：
  - 不改变模式层 DAG，仅在其之上挂载 entity-level 节点；
- 多选混合视图：
  - 在现有 `selectedTables` / `selectedColumns` 基础上，增加 `selectedInstanceNodes`；
  - 子图计算时可同时考虑模式节点与实体节点，保持原有逻辑不变，仅扩展范围。
