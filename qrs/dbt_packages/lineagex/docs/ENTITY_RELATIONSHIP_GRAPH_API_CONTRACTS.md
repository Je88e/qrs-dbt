# Entity Relationship Graph 后端 API 契约示例

## 1. 设计原则
- 与前端实体关系图组件的数据模型一一对应，直接返回 `InstanceGraph` 结构；
- 专注于实体之间的关系（父子、外键、派生、流转），不引入任何系统/来源分类维度；
- 通过通用分页/截断机制控制一次查询返回的节点与边数量。

## 2. 公共类型定义（JSON 结构示意）

```jsonc
// DataInstanceNode JSON 结构
{
  "id": "string",             // `${tableId}::${pkHash}`
  "tableId": "string",
  "entityKind": "string",     // 例如 "PO_HEADER"、"WORK_ORDER"、"BATCH"、"SAMPLE" 等
  "displayLabel": "string",   // 显示名，如业务单号/批次号/条码等
  "attributes": { "field": "value" },
  "parent": {                  // 可选：父实体标识
    "tableId": "string",
    "pk": { "business_key": "..." }   // 业务主键字段集合，具体字段名由模型约定
  },
  "children": [ { "tableId": "string", "pk": { } } ],
  "createdAt": "2025-01-01T10:00:00Z",
  "status": "string"
}
```

```jsonc
// DataInstanceEdge JSON 结构
{
  "id": "string",
  "sourceInstanceId": "string",
  "targetInstanceId": "string",
  "relationType": "PARENT_CHILD" | "FK" | "DERIVED_FROM" | "FLOW",
  "columnMapping": [
    {
      "from": { "tableId": "model.qrs.stg_x", "columnName": "from_col" },
      "to": { "tableId": "model.qrs.fct_y", "columnName": "to_col" }
    }
  ]
}
```

```jsonc
// InstanceGraph JSON 结构
{
  "rootInstances": [
    { "tableId": "model.qrs.fct_orders", "pk": { "order_number": "O2025-0001" } }
  ],
  "nodes": [ /* DataInstanceNode[] */ ],
  "edges": [ /* DataInstanceEdge[] */ ],
  "stats": {                    // 可选统计
    "nodeCount": 123,
    "edgeCount": 456,
    "truncated": true          // 是否因限制被截断
  }
}
```

## 3. 根实体列表查询 API

### 3.1 GET /api/entity-graph/entities

- 功能：按条件查询可作为“根实体实例”的业务对象列表，用于前端选择后再加载实例图；
- 请求参数（Query）：
  - `entityKind`：实体类型标识（可选），如 `PO_HEADER`、`WORK_ORDER`、`BATCH` 等；
  - `fromDate` / `toDate`：基于指定业务时间字段的时间范围过滤（可选）；
  - `status`：业务状态过滤（可选，多值）；
  - `text`：关键字搜索（可选），如订单号、批次号、条码等；
  - `limit`：每页大小，默认 20，最大 100；
  - `offset`：分页偏移量；
- 响应示例：
```jsonc
{
  "items": [
    {
      "entityKind": "PO_HEADER",
      "tableId": "model.qrs.fct_orders",
      "pk": { "order_number": "O2025-0001" },
      "displayLabel": "O2025-0001",
      "createdAt": "2025-01-01T10:00:00Z",
      "status": "APPROVED"
    }
  ],
  "total": 120
}
```

## 4. 通用实例图 API

### 4.1 POST /api/lineage/instance-graph

- 功能：围绕一个或多个根实体实例构建实例关系图，可同时包含多种实体类型；
- 请求体示例：
```jsonc
{
  "roots": [
    {
      "tableId": "model.qrs.fct_orders",
      "pk": { "order_number": "O2025-0001" },
      "entityKind": "PO_HEADER"
    }
  ],
  "maxDepth": 4,
  "maxNodes": 1500,
  "directions": ["upstream", "downstream"],
  "relationTypes": ["PARENT_CHILD", "FK", "FLOW", "DERIVED_FROM"],
  "entityKindFilter": ["PO_HEADER", "PO_LINE", "WORK_ORDER", "BATCH", "SAMPLE", "TEST_RESULT"],
  "timeRange": {
    "field": "created_at",
    "from": "2025-01-01T00:00:00Z",
    "to": "2025-01-31T23:59:59Z"
  }
}
```

- 响应：
  - 类型：`InstanceGraph` JSON；
  - 若 `stats.truncated = true`，前端需提示“结果已截断，可通过更严条件重试或分页加载”。

## 5. 分页、聚合与增量加载约定

### 5.1 分页与截断
- 若一次查询可能返回过多实例：
  - 后端根据 `maxNodes` 或各层级 `maxChildrenPerLevel` 做限制；
  - 在 `stats.truncated = true` 时，告知前端数据被截断；
  - 可在后端返回 `nextPageToken` 或 `nextOffsets` 用于增量查询（如继续加载更多子实例）。

### 5.2 聚合显示支持
- 后端可在节点属性中标记聚合信息，例如：
```jsonc
{
  "id": "AGG_CHILD::O2025-0001",
  "entityKind": "GENERIC_RECORD",
  "displayLabel": "+490 子记录",
  "attributes": { "aggregated": true, "count": 490 }
}
```
- 前端依据 `attributes.aggregated` 判定为“聚合节点”，点击时再调用带分页参数的接口加载真实子记录列表并展开。

## 6. 错误处理与安全
- 统一错误结构：
```jsonc
{
  "error": {
    "code": "STRING",
    "message": "详细错误信息",
    "details": {}
  }
}
```
- 安全与合规：
  - API 应根据用户权限过滤可见数据（如仅允许查看授权范围内的实体）；
  - 对于审计需要，可在响应头中包含数据快照时间与源系统版本信息。
