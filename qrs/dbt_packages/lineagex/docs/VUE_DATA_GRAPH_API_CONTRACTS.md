# Data Graph 后端 API 契约示例

## 1. 设计原则
- 与前端 `Data Graph` 组件的数据模型一一对应，直接返回 `InstanceGraph` 结构。
- 严格控制一次查询返回的数据规模：通过通用分页/截断机制控制节点与边数量。
- 面向所有业务域（ERP、MES、LIMS、QMS、SCADA、PV）设计，域无关、实体类型可配置。

## 2. 公共类型定义（伪代码）

```jsonc
// DataInstanceNode JSON 结构
{
  "id": "string",             // `${tableId}::${pkHash}`
  "tableId": "string",
  "entityKind": "string",     // 如 "ERP_PO_HEADER"、"MES_WORK_ORDER"、"LIMS_BATCH" 等，由配置约定
  "displayLabel": "string",
  "attributes": { "field": "value" },
  "parent": {                  // 可选
    "tableId": "string",
    "pk": { "business_key": "..." }   // 业务主键字段集合，具体字段名按域/实体类型定义
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
      "from": { "tableId": "model.qrs.stg_sample", "columnName": "sample_id" },
      "to": { "tableId": "model.qrs.fct_test", "columnName": "sample_id" }
    }
  ]
}
```

```jsonc
// InstanceGraph JSON 结构
{
  "rootInstances": [
    { "tableId": "model.qrs.fct_purchase_orders", "pk": { "purchase_order_number": "PO2025-0001" } }
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

## 3. 通用根实体列表查询 API

### 3.1 GET /api/data-graph/entities

- 功能：按条件查询任意域、任意实体类型的根实体列表，用于前端选择后再加载实例图。
- 请求参数（Query）：
  - `domain`：业务域（可选）：`ERP` / `MES` / `LIMS` / `QMS` / `SCADA` / `PV`。
  - `entityKind`：实体类型标识（可选），如 `ERP_PO_HEADER`、`MES_WORK_ORDER`。
  - `fromDate` / `toDate`：基于业务时间字段的时间范围过滤（可选）。
  - `status`：业务状态过滤（可选，多值）。
  - `text`：关键字搜索（可选），如订单号、批次号等。
  - `limit`：每页大小，默认 20，最大 100。
  - `offset`：分页偏移量。
- 响应示例：
```jsonc
{
  "items": [
    {
      "domain": "ERP",
      "entityKind": "ERP_PO_HEADER",
      "tableId": "model.qrs.fct_purchase_orders",
      "pk": { "purchase_order_number": "PO2025-0001" },
      "displayLabel": "PO2025-0001",
      "createdAt": "2025-01-01T10:00:00Z",
      "status": "APPROVED"
    }
  ],
  "total": 120
}
```

## 4. 通用实例图 API（跨域）

### 4.1 POST /api/lineage/instance-graph

- 功能：围绕任意域的一个或多个根实例构建实例图，可跨多个业务域与实体类型。
- 请求体示例：
```jsonc
{
  "roots": [
    {
      "tableId": "model.qrs.fct_purchase_orders",
      "pk": { "purchase_order_number": "PO2025-0001" },
      "domain": "ERP",
      "entityKind": "ERP_PO_HEADER"
    }
  ],
  "maxDepth": 4,
  "maxNodes": 1500,
  "directions": ["upstream", "downstream"],
  "relationTypes": ["PARENT_CHILD", "FLOW", "DERIVED_FROM"],
  "domainFilter": ["ERP", "MES", "LIMS", "QMS", "PV"],
  "entityKindFilter": ["ERP_PO_HEADER", "ERP_PO_LINE", "MES_WORK_ORDER", "LIMS_BATCH", "LIMS_SAMPLE", "LIMS_TEST"],
  "timeRange": {
    "field": "created_at",
    "from": "2025-01-01T00:00:00Z",
    "to": "2025-01-31T23:59:59Z"
  }
}
```

- 响应：
  - 类型：`InstanceGraph` JSON。
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
  "id": "AGG_CHILD::PO2025-0001",
  "entityKind": "GENERIC_RECORD",
  "displayLabel": "+490 子记录",
  "attributes": { "aggregated": true, "count": 490 }
}
```
- 前端依据 `attributes.aggregated` 判定为“聚合节点”，点击时再调用带分页参数的接口加载真实样品列表并展开。

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
  - API 应根据用户权限过滤可见数据（如仅允许查看本部门批次）。
  - 对于审计需要，可在响应头中包含数据快照时间与源系统版本信息。
