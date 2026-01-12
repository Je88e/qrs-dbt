# Vue 3 列级数据血缘可视化组件核心技术设计

## 1. 概述
- 目标：定义基于 `output.json` 的 TypeScript 数据模型与血缘算法，为 Vue 3 组件提供可靠的服务层。
- 范围：表级与列级血缘查询、跨层级路径计算、多选混合子图、性能与缓存策略。

## 2. 原始数据模型（紧贴 output.json）
```ts
export interface LineageRawNode {
  table_name: string;
  tables: string[]; // 直接上游表
  columns: Record<string, string[]>; // 列名 -> 来源列列表（如 stg_x.col_y）
  upstream_tables: string[];
  downstream_tables: string[];
  is_model: boolean;
}

export type LineageRawMap = Record<string, LineageRawNode>; // key 为 tableId
```

## 3. 衍生领域模型
```ts
export type LineageLayer =
  | 'raw' | 'staging' | 'intermediate' | 'dimension' | 'fact' | 'report' | 'other';

export type LineageDomain = 'ERP' | 'MES' | 'LIMS' | 'QMS' | 'SCADA' | 'PV' | 'UNKNOWN';

export interface TableNode {
  id: string;           // 原始 key，如 'model.qrs.fct_x'
  tableName: string;    // table_name
  isModel: boolean;
  layer: LineageLayer;
  domain: LineageDomain;
  upstream: string[];   // 上游表 id
  downstream: string[]; // 下游表 id
  columns: Record<string, string[]>; // 直接抄自 raw
}

export interface ColumnRef {
  tableId: string;
  columnName: string;
}

export interface GraphEdge {
  source: string;
  target: string;
  kind: 'table' | 'column';
}
```

## 4. 数据解析与索引构建
- 解析步骤：
  - 遍历 `LineageRawMap`，将每个条目转换为 `TableNode`。
  - 根据 `id` 与 `table_name` 判断 `layer`（raw/stg/dim/fct/report）。
  - 根据 schema 前缀（如 `raw.mes_`）推断 `domain`。
- 索引结构：
  - `tableMap: Map<string, TableNode>`。
  - `columnToSources: Map<string, ColumnRef[]>`，key 形式为 `"tableId.columnName"`。
  - `columnToTargets: Map<string, ColumnRef[]>`，由反向遍历 `columns` 建立，用于下游列查询。

## 5. 表级血缘算法设计
### 5.1 上游/下游表查询（跨层级）
```ts
function getTables(
  seeds: string[],
  direction: 'upstream' | 'downstream' | 'both',
  maxDepth: number
): Set<string> {
  const visited = new Set<string>();
  const queue: Array<{ id: string; depth: number }> = seeds.map(id => ({ id, depth: 0 }));
  while (queue.length) {
    const { id, depth } = queue.shift()!;
    if (visited.has(id) || depth > maxDepth) continue;
    visited.add(id);
    const node = tableMap.get(id);
    if (!node) continue;
    const nextIds = new Set<string>();
    if (direction === 'upstream' || direction === 'both') node.upstream.forEach(x => nextIds.add(x));
    if (direction === 'downstream' || direction === 'both') node.downstream.forEach(x => nextIds.add(x));
    nextIds.forEach(nid => queue.push({ id: nid, depth: depth + 1 }));
  }
  return visited;
}
```
- 该函数天然支持跨层级，只要 `tableMap` 中记录了完整的依赖关系。

### 5.2 端到端路径计算
- 目标：从任意 seed 表出发，找到到所有终端报表/事实表的路径。
- 实现思路：
  - 使用 DFS，从 seed 沿 `downstream` 递归。
  - 终止条件：没有下游表，或命中 `layer` 为 `fact` / `report`。
  - 利用 `visited` 防止环；每条路径记录为 `string[]`。

## 6. 列级血缘与影响分析算法
### 6.1 单列上游追溯
```ts
function traceColumnUpstream(seed: ColumnRef, maxDepth: number): ColumnRef[] {
  const results: ColumnRef[] = [];
  const stack: Array<{ ref: ColumnRef; depth: number }> = [{ ref: seed, depth: 0 }];
  const seen = new Set<string>();
  while (stack.length) {
    const { ref, depth } = stack.pop()!;
    const key = `${ref.tableId}.${ref.columnName}`;
    if (seen.has(key) || depth > maxDepth) continue;
    seen.add(key);
    results.push(ref);
    const sources = columnToSources.get(key) || [];
    sources.forEach(src => stack.push({ ref: src, depth: depth + 1 }));
  }
  return results;
}
```

### 6.2 单列下游影响分析
- 使用 `columnToTargets` 对应实现，逻辑与上游追溯对称。

### 6.3 多列混合影响分析
- 输入：`seeds: ColumnRef[]`。
- 做法：
  - 对每个 seed 调用上游/下游追溯函数。
  - 将结果合并去重，以 `ColumnRef` 为 key。
  - 生成对应的表集合，用于主图高亮和子图筛选。

## 7. 多选与混合子图计算
- 维护状态：
  - `selectedTables: Set<string>`，`selectedColumns: Set<string>`。
- 构建子图：
  - 对选中表集合调用 `getTables(seeds, direction, depth)`，得到相关表集合。
  - 过滤出需要显示的表节点和连接它们的表级边。
  - 若存在选中列，则额外构造局部列级图，用于路径面板或局部 G6 视图。

## 8. 性能与缓存策略
- 路径/影响分析结果缓存：`Map<CacheKey, Result>`，避免重复计算。
- 对于较大 `maxDepth` 的调用可限制节点上限，超过时在 UI 给出提示。
- G6 仅渲染当前子图节点与边；当筛选条件变化时重新构建子图，而非全图。
- 为长路径和大结果集预留将来迁移到 Web Worker 的接口。

## 9. 可测试性设计
- 将算法封装为独立模块（例如 `lineage-core.ts`），与 Vue 组件解耦。
- 针对以下场景编写单元测试：
  - 简单 DAG、包含多层级的复杂 DAG。
  - 列级一对一映射与多源计算列。
  - 多选场景下的混合子图与影响分析结果正确性。

