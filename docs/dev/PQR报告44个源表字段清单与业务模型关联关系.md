## 文档说明

本文档详细列出了PQR报告中涉及的44个业务系统源表的字段定义，以及这些源表与30个业务模型的关联关系。

---

## 一、ERP系统源表（12个表）

### 1.1 物料主数据表 (erp_material_master)

**业务模型关联：** 物料信息模型

| 字段名称            | 数据类型         | 约束            | 业务含义           | 关联关系      |
| --------------- | ------------ | ------------- | -------------- | --------- |
| material_id     | VARCHAR(20)  | PK            | 物料编码           | 关联所有物料相关表 |
| material_name   | VARCHAR(200) | NOT NULL      | 物料名称           | -         |
| material_type   | VARCHAR(50)  | -             | 物料类型(原料/辅料/包材) | -         |
| specification   | VARCHAR(500) | -             | 规格型号           | -         |
| unit            | VARCHAR(20)  | NOT NULL      | 单位             | -         |
| supplier_id     | VARCHAR(20)  | FK            | 供应商ID          | 关联供应商表    |
| approval_status | VARCHAR(20)  | NOT NULL      | 审批状态           | -         |
| create_date     | DATETIME     | NOT NULL      | 创建日期           | -         |
| update_date     | DATETIME     | -             | 更新日期           | -         |
| is_deleted      | BOOLEAN      | DEFAULT FALSE | 删除标记           | -         |

### 1.2 供应商主数据表 (erp_supplier_master)

**业务模型关联：** 供应商信息模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|supplier_id|VARCHAR(20)|PK|供应商编码|关联采购、物料表|
|supplier_name|VARCHAR(200)|NOT NULL|供应商名称|-|
|supplier_type|VARCHAR(50)|-|供应商类型|-|
|contact_person|VARCHAR(100)|-|联系人|-|
|contact_phone|VARCHAR(50)|-|联系电话|-|
|address|VARCHAR(500)|-|地址|-|
|qualification_status|VARCHAR(20)|NOT NULL|资质状态|-|
|audit_date|DATE|-|审计日期|-|
|audit_score|DECIMAL(5,2)|-|审计得分|-|
|create_date|DATETIME|NOT NULL|创建日期|-|

### 1.3 采购订单表 (erp_purchase_order)

**业务模型关联：** 采购订单模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|po_id|VARCHAR(30)|PK|采购订单号|关联采购明细、收货表|
|supplier_id|VARCHAR(20)|FK|供应商ID|关联供应商表|
|po_date|DATE|NOT NULL|采购日期|-|
|delivery_date|DATE|-|预计交期|-|
|po_status|VARCHAR(20)|NOT NULL|订单状态|-|
|total_amount|DECIMAL(15,2)|-|订单总金额|-|
|currency|VARCHAR(10)|DEFAULT 'CNY'|币种|-|
|payment_terms|VARCHAR(200)|-|付款条件|-|
|create_by|VARCHAR(50)|NOT NULL|创建人|-|
|approve_date|DATETIME|-|审批日期|-|

### 1.4 采购订单明细表 (erp_po_detail)

**业务模型关联：** 采购订单模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|po_detail_id|BIGINT|PK|明细ID|-|
|po_id|VARCHAR(30)|FK|采购订单号|关联采购订单表|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|quantity|DECIMAL(15,4)|NOT NULL|采购数量|-|
|unit_price|DECIMAL(15,4)|NOT NULL|单价|-|
|total_price|DECIMAL(15,2)|NOT NULL|总价|-|
|received_qty|DECIMAL(15,4)|DEFAULT 0|已收货数量|-|
|return_qty|DECIMAL(15,4)|DEFAULT 0|退货数量|-|
|line_status|VARCHAR(20)|NOT NULL|行状态|-|

### 1.5 采购收货单表 (erp_purchase_receipt)

**业务模型关联：** 物料接收模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|receipt_id|VARCHAR(30)|PK|收货单号|关联质检、库存表|
|po_id|VARCHAR(30)|FK|采购订单号|关联采购订单表|
|supplier_id|VARCHAR(20)|FK|供应商ID|关联供应商表|
|receipt_date|DATETIME|NOT NULL|收货日期|-|
|receipt_status|VARCHAR(20)|NOT NULL|收货状态|-|
|batch_number|VARCHAR(50)|-|批次号|-|
|total_qty|DECIMAL(15,4)|NOT NULL|收货总量|-|
|warehouse_id|VARCHAR(20)|FK|仓库ID|关联仓库表|
|inspector|VARCHAR(50)|-|检验员|-|
|inspection_status|VARCHAR(20)|DEFAULT '待检'|检验状态|-|

### 1.6 采购退货单表 (erp_purchase_return)

**业务模型关联：** 物料退货模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|return_id|VARCHAR(30)|PK|退货单号|-|
|receipt_id|VARCHAR(30)|FK|收货单号|关联收货表|
|po_detail_id|BIGINT|FK|采购订单明细ID|关联采购明细表|
|return_date|DATE|NOT NULL|退货日期|-|
|return_qty|DECIMAL(15,4)|NOT NULL|退货数量|-|
|return_reason|VARCHAR(500)|NOT NULL|退货原因|-|
|return_type|VARCHAR(50)|-|退货类型(质量/交期/其他)|-|
|approve_status|VARCHAR(20)|NOT NULL|审批状态|-|
|create_by|VARCHAR(50)|NOT NULL|创建人|-|

### 1.7 生产订单表 (erp_production_order)

**业务模型关联：** 生产订单模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|wo_id|VARCHAR(30)|PK|生产订单号|关联工单、BOM表|
|product_id|VARCHAR(20)|FK|产品编码|关联物料表|
|planned_qty|DECIMAL(15,4)|NOT NULL|计划数量|-|
|actual_qty|DECIMAL(15,4)|DEFAULT 0|实际产量|-|
|planned_start_date|DATETIME|NOT NULL|计划开始日期|-|
|planned_end_date|DATETIME|NOT NULL|计划结束日期|-|
|actual_start_date|DATETIME|-|实际开始日期|-|
|actual_end_date|DATETIME|-|实际结束日期|-|
|wo_status|VARCHAR(20)|NOT NULL|工单状态|-|
|workshop_id|VARCHAR(20)|FK|车间ID|关联车间表|

### 1.8 生产BOM表 (erp_production_bom)

**业务模型关联：** 配方管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|bom_id|BIGINT|PK|BOM ID|-|
|product_id|VARCHAR(20)|FK|产品编码|关联物料表|
|material_id|VARCHAR(20)|FK|原料编码|关联物料表|
|quantity|DECIMAL(15,4)|NOT NULL|用量|-|
|unit|VARCHAR(20)|NOT NULL|单位|-|
|loss_rate|DECIMAL(5,4)|DEFAULT 0|损耗率|-|
|is_active|BOOLEAN|DEFAULT TRUE|启用状态|-|
|version|VARCHAR(20)|NOT NULL|版本号|-|
|create_date|DATETIME|NOT NULL|创建日期|-|

### 1.9 库存记录表 (erp_inventory_record)

**业务模型关联：** 库存管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|inventory_id|BIGINT|PK|库存记录ID|-|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|batch_number|VARCHAR(50)|-|批次号|-|
|warehouse_id|VARCHAR(20)|FK|仓库ID|关联仓库表|
|stock_quantity|DECIMAL(15,4)|NOT NULL|库存数量|-|
|available_qty|DECIMAL(15,4)|NOT NULL|可用数量|-|
|locked_qty|DECIMAL(15,4)|DEFAULT 0|锁定数量|-|
|last_update|DATETIME|NOT NULL|最后更新|-|
|inventory_date|DATE|NOT NULL|库存日期|-|

### 1.10 质量检验记录表 (erp_quality_inspection)

**业务模型关联：** 质量检验模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|inspection_id|BIGINT|PK|检验记录ID|-|
|receipt_id|VARCHAR(30)|FK|收货单号|关联收货表|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|inspection_date|DATE|NOT NULL|检验日期|-|
|inspection_type|VARCHAR(50)|NOT NULL|检验类型|-|
|inspector|VARCHAR(50)|NOT NULL|检验员|-|
|sample_size|INT|NOT NULL|抽样数量|-|
|qualified_qty|INT|DEFAULT 0|合格数量|-|
|unqualified_qty|INT|DEFAULT 0|不合格数量|-|
|qualification_rate|DECIMAL(5,2)|-|合格率|-|
|inspection_result|VARCHAR(20)|NOT NULL|检验结果|-|
|inspection_report|VARCHAR(500)|-|检验报告路径|-|

### 1.11 不合格品处理表 (erp_nonconforming_disposal)

**业务模型关联：** 不合格品管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|disposal_id|BIGINT|PK|处理记录ID|-|
|inspection_id|BIGINT|FK|检验记录ID|关联质检表|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|quantity|DECIMAL(15,4)|NOT NULL|不合格数量|-|
|defect_type|VARCHAR(100)|NOT NULL|缺陷类型|-|
|severity_level|VARCHAR(20)|-|严重等级|-|
|disposal_method|VARCHAR(50)|NOT NULL|处理方式|-|
|disposal_result|VARCHAR(200)|-|处理结果|-|
|disposal_date|DATE|NOT NULL|处理日期|-|
|handler|VARCHAR(50)|NOT NULL|处理人|-|

### 1.12 仓库主数据表 (erp_warehouse_master)

**业务模型关联：** 仓库信息模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|warehouse_id|VARCHAR(20)|PK|仓库编码|关联库存、收货表|
|warehouse_name|VARCHAR(200)|NOT NULL|仓库名称|-|
|warehouse_type|VARCHAR(50)|-|仓库类型|-|
|location|VARCHAR(500)|-|位置|-|
|storage_capacity|DECIMAL(15,2)|-|存储容量|-|
|temperature_range|VARCHAR(50)|-|温度范围|-|
|humidity_range|VARCHAR(50)|-|湿度范围|-|
|is_active|BOOLEAN|DEFAULT TRUE|启用状态|-|

---

## 二、MES系统源表（10个表）

### 2.1 生产工单表 (mes_work_order)

**业务模型关联：** 生产工单模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|wo_number|VARCHAR(30)|PK|工单号|关联工序、报工表|
|wo_id|VARCHAR(30)|FK|ERP生产订单号|关联ERP生产订单|
|product_id|VARCHAR(20)|FK|产品编码|关联物料表|
|planned_qty|DECIMAL(15,4)|NOT NULL|计划数量|-|
|actual_qty|DECIMAL(15,4)|DEFAULT 0|实际产量|-|
|planned_start_time|DATETIME|NOT NULL|计划开始时间|-|
|planned_end_time|DATETIME|NOT NULL|计划结束时间|-|
|actual_start_time|DATETIME|-|实际开始时间|-|
|actual_end_time|DATETIME|-|实际结束时间|-|
|wo_status|VARCHAR(20)|NOT NULL|工单状态|-|
|line_id|VARCHAR(20)|FK|产线ID|关联产线表|
|batch_number|VARCHAR(50)|-|批次号|-|
|yield_rate|DECIMAL(5,2)|-|收率|-|

### 2.2 工序管理表 (mes_process_step)

**业务模型关联：** 工序管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|process_id|BIGINT|PK|工序ID|关联报工、质检表|
|wo_number|VARCHAR(30)|FK|工单号|关联工单表|
|process_code|VARCHAR(50)|NOT NULL|工序编码|-|
|process_name|VARCHAR(200)|NOT NULL|工序名称|-|
|sequence_no|INT|NOT NULL|序号|-|
|planned_duration|DECIMAL(10,2)|-|计划时长(小时)|-|
|actual_duration|DECIMAL(10,2)|-|实际时长|-|
|equipment_id|VARCHAR(20)|FK|设备ID|关联设备表|
|operator_id|VARCHAR(50)|FK|操作员ID|关联人员表|
|process_status|VARCHAR(20)|NOT NULL|工序状态|-|
|start_time|DATETIME|-|开始时间|-|
|end_time|DATETIME|-|结束时间|-|

### 2.3 生产报工表 (mes_work_report)

**业务模型关联：** 生产报工模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|report_id|BIGINT|PK|报工记录ID|-|
|wo_number|VARCHAR(30)|FK|工单号|关联工单表|
|process_id|BIGINT|FK|工序ID|关联工序表|
|operator_id|VARCHAR(50)|FK|操作员ID|关联人员表|
|equipment_id|VARCHAR(20)|FK|设备ID|关联设备表|
|report_date|DATE|NOT NULL|报工日期|-|
|good_qty|DECIMAL(15,4)|NOT NULL|良品数量|-|
|scrap_qty|DECIMAL(15,4)|DEFAULT 0|废品数量|-|
|rework_qty|DECIMAL(15,4)|DEFAULT 0|返工数量|-|
|working_hours|DECIMAL(8,2)|NOT NULL|工时|-|
|efficiency|DECIMAL(5,2)|-|效率|-|
|report_time|DATETIME|NOT NULL|报工时间|-|

### 2.4 设备主数据表 (mes_equipment_master)

**业务模型关联：** 设备管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|equipment_id|VARCHAR(20)|PK|设备编码|关联报工、维护表|
|equipment_name|VARCHAR(200)|NOT NULL|设备名称|-|
|equipment_type|VARCHAR(50)|-|设备类型|-|
|model|VARCHAR(100)|-|型号|-|
|manufacturer|VARCHAR(200)|-|制造商|-|
|purchase_date|DATE|-|购买日期|-|
|install_date|DATE|-|安装日期|-|
|workshop_id|VARCHAR(20)|FK|车间ID|关联车间表|
|status|VARCHAR(20)|NOT NULL|设备状态|-|
|last_maintenance|DATE|-|最后维护日期|-|
|next_maintenance|DATE|-|下次维护日期|-|
|oee|DECIMAL(5,2)|-|设备综合效率|-|

### 2.5 设备维护记录表 (mes_equipment_maintenance)

**业务模型关联：** 设备维护模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|maintenance_id|BIGINT|PK|维护记录ID|-|
|equipment_id|VARCHAR(20)|FK|设备编码|关联设备表|
|maintenance_type|VARCHAR(50)|NOT NULL|维护类型|-|
|maintenance_date|DATE|NOT NULL|维护日期|-|
|duration|DECIMAL(8,2)|NOT NULL|维护时长(小时)|-|
|maintenance_content|TEXT|-|维护内容|-|
|maintenance_cost|DECIMAL(12,2)|-|维护费用|-|
|maintainer|VARCHAR(50)|NOT NULL|维护人|-|
|next_maintenance_date|DATE|-|下次维护日期|-|
|status|VARCHAR(20)|NOT NULL|状态|-|

### 2.6 产线配置表 (mes_production_line)

**业务模型关联：** 产线管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|line_id|VARCHAR(20)|PK|产线编码|关联工单、设备表|
|line_name|VARCHAR(200)|NOT NULL|产线名称|-|
|line_type|VARCHAR(50)|-|产线类型|-|
|workshop_id|VARCHAR(20)|FK|车间ID|关联车间表|
|capacity_per_hour|DECIMAL(15,4)|-|小时产能|-|
|efficiency_target|DECIMAL(5,2)|-|效率目标|-|
|oee_target|DECIMAL(5,2)|-|OEE目标|-|
|is_active|BOOLEAN|DEFAULT TRUE|启用状态|-|
|create_date|DATETIME|NOT NULL|创建日期|-|

### 2.7 车间管理表 (mes_workshop)

**业务模型关联：** 车间管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|workshop_id|VARCHAR(20)|PK|车间编码|关联产线、设备表|
|workshop_name|VARCHAR(200)|NOT NULL|车间名称|-|
|workshop_type|VARCHAR(50)|-|车间类型|-|
|manager|VARCHAR(50)|-|车间主任|-|
|location|VARCHAR(500)|-|位置|-|
|area|DECIMAL(10,2)|-|面积(m²)|-|
|is_active|BOOLEAN|DEFAULT TRUE|启用状态|-|
|create_date|DATETIME|NOT NULL|创建日期|-|

### 2.8 物料消耗记录表 (mes_material_consumption)

**业务模型关联：** 物料消耗模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|consumption_id|BIGINT|PK|消耗记录ID|-|
|wo_number|VARCHAR(30)|FK|工单号|关联工单表|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|batch_number|VARCHAR(50)|-|批次号|-|
|planned_qty|DECIMAL(15,4)|NOT NULL|计划用量|-|
|actual_qty|DECIMAL(15,4)|NOT NULL|实际用量|-|
|loss_qty|DECIMAL(15,4)|DEFAULT 0|损耗量|-|
|consumption_date|DATE|NOT NULL|消耗日期|-|
|process_id|BIGINT|FK|工序ID|关联工序表|
|operator_id|VARCHAR(50)|FK|操作员ID|关联人员表|

### 2.9 人员主数据表 (mes_personnel)

**业务模型关联：** 人员管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|personnel_id|VARCHAR(50)|PK|人员ID|关联报工、工序表|
|employee_no|VARCHAR(20)|UNIQUE|工号|-|
|name|VARCHAR(100)|NOT NULL|姓名|-|
|department|VARCHAR(100)|-|部门|-|
|position|VARCHAR(100)|-|职位|-|
|skill_level|VARCHAR(20)|-|技能等级|-|
|certification|VARCHAR(200)|-|资质认证|-|
|hire_date|DATE|-|入职日期|-|
|status|VARCHAR(20)|NOT NULL|状态|-|
|workshop_id|VARCHAR(20)|FK|车间ID|关联车间表|

### 2.10 工艺参数表 (mes_process_parameter)

**业务模型关联：** 工艺参数模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|parameter_id|BIGINT|PK|参数记录ID|-|
|wo_number|VARCHAR(30)|FK|工单号|关联工单表|
|process_id|BIGINT|FK|工序ID|关联工序表|
|parameter_code|VARCHAR(50)|NOT NULL|参数编码|-|
|parameter_name|VARCHAR(200)|NOT NULL|参数名称|-|
|standard_value|DECIMAL(15,4)|-|标准值|-|
|upper_limit|DECIMAL(15,4)|-|上限值|-|
|lower_limit|DECIMAL(15,4)|-|下限值|-|
|actual_value|DECIMAL(15,4)|NOT NULL|实际值|-|
|record_time|DATETIME|NOT NULL|记录时间|-|
|operator_id|VARCHAR(50)|FK|操作员ID|关联人员表|
|equipment_id|VARCHAR(20)|FK|设备ID|关联设备表|
|is_qualified|BOOLEAN|NOT NULL|是否合格|-|

---

## 三、LIMS系统源表（8个表）

### 3.1 检验申请单表 (lims_inspection_request)

**业务模型关联：** 检验申请模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|request_id|VARCHAR(30)|PK|申请单号|关联检验任务表|
|sample_id|VARCHAR(50)|NOT NULL|样品ID|-|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|request_type|VARCHAR(50)|NOT NULL|申请类型|-|
|request_date|DATE|NOT NULL|申请日期|-|
|requester|VARCHAR(50)|NOT NULL|申请人|-|
|priority|VARCHAR(20)|DEFAULT '普通'|优先级|-|
|sample_quantity|DECIMAL(15,4)|NOT NULL|样品数量|-|
|sampling_date|DATE|NOT NULL|取样日期|-|
|sampling_location|VARCHAR(200)|-|取样地点|-|
|request_status|VARCHAR(20)|NOT NULL|申请状态|-|

### 3.2 检验任务表 (lims_inspection_task)

**业务模型关联：** 检验任务模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|task_id|BIGINT|PK|任务ID|关联检验结果表|
|request_id|VARCHAR(30)|FK|申请单号|关联申请单表|
|task_number|VARCHAR(30)|UNIQUE|任务编号|-|
|inspection_item|VARCHAR(200)|NOT NULL|检验项目|-|
|test_method|VARCHAR(200)|-|检验方法|-|
|standard_value|VARCHAR(200)|-|标准值|-|
|assigned_analyst|VARCHAR(50)|FK|分配分析员|关联分析员表|
|task_status|VARCHAR(20)|NOT NULL|任务状态|-|
|planned_start_date|DATE|-|计划开始日期|-|
|planned_end_date|DATE|-|计划结束日期|-|
|actual_start_date|DATE|-|实际开始日期|-|
|actual_end_date|DATE|-|实际结束日期|-|
|priority|VARCHAR(20)|-|优先级|-|
|task_progress|DECIMAL(5,2)|DEFAULT 0|任务进度|-|

### 3.3 检验结果记录表 (lims_test_result)

**业务模型关联：** 检验结果模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|result_id|BIGINT|PK|结果记录ID|-|
|task_id|BIGINT|FK|任务ID|关联检验任务表|
|test_item|VARCHAR(200)|NOT NULL|测试项目|-|
|test_value|DECIMAL(15,6)|NOT NULL|测试值|-|
|unit|VARCHAR(20)|-|单位|-|
|standard_value|DECIMAL(15,6)|-|标准值|-|
|upper_limit|DECIMAL(15,6)|-|上限|-|
|lower_limit|DECIMAL(15,6)|-|下限|-|
|test_result|VARCHAR(20)|NOT NULL|测试结果|-|
|analyst|VARCHAR(50)|NOT NULL|分析员|-|
|test_date|DATE|NOT NULL|测试日期|-|
|equipment_id|VARCHAR(50)|-|设备ID|-|
|deviation_reason|VARCHAR(500)|-|偏差原因|-|
|is_reviewed|BOOLEAN|DEFAULT FALSE|是否审核|-|
|reviewer|VARCHAR(50)|-|审核人|-|
|review_date|DATE|-|审核日期|-|

### 3.4 样品管理表 (lims_sample)

**业务模型关联：** 样品管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|sample_id|VARCHAR(50)|PK|样品编码|关联检验申请表|
|sample_type|VARCHAR(50)|NOT NULL|样品类型|-|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|sample_quantity|DECIMAL(15,4)|NOT NULL|样品数量|-|
|sample_unit|VARCHAR(20)|NOT NULL|样品单位|-|
|sampling_date|DATE|NOT NULL|取样日期|-|
|sampler|VARCHAR(50)|NOT NULL|取样人|-|
|sampling_location|VARCHAR(200)|-|取样地点|-|
|storage_condition|VARCHAR(100)|-|存储条件|-|
|sample_status|VARCHAR(20)|NOT NULL|样品状态|-|
|retention_days|INT|-|留样天数|-|
|expiration_date|DATE|-|失效日期|-|
|storage_location|VARCHAR(200)|-|存储位置|-|

### 3.5 质量标准表 (lims_quality_standard)

**业务模型关联：** 质量标准模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|standard_id|BIGINT|PK|标准ID|关联检验项目表|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|standard_name|VARCHAR(200)|NOT NULL|标准名称|-|
|standard_version|VARCHAR(20)|NOT NULL|版本号|-|
|effective_date|DATE|NOT NULL|生效日期|-|
|expiry_date|DATE|-|失效日期|-|
|is_active|BOOLEAN|DEFAULT TRUE|启用状态|-|
|create_by|VARCHAR(50)|NOT NULL|创建人|-|
|create_date|DATETIME|NOT NULL|创建日期|-|
|approve_status|VARCHAR(20)|NOT NULL|审批状态|-|

### 3.6 检验项目表 (lims_test_item)

**业务模型关联：** 检验项目模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|item_id|BIGINT|PK|项目ID|-|
|standard_id|BIGINT|FK|标准ID|关联质量标准表|
|item_name|VARCHAR(200)|NOT NULL|项目名称|-|
|item_code|VARCHAR(50)|UNIQUE|项目编码|-|
|test_method|VARCHAR(500)|-|检验方法|-|
|data_type|VARCHAR(20)|NOT NULL|数据类型|-|
|unit|VARCHAR(20)|-|单位|-|
|standard_value|VARCHAR(200)|-|标准值|-|
|upper_limit|DECIMAL(15,6)|-|上限值|-|
|lower_limit|DECIMAL(15,6)|-|下限值|-|
|precision_digits|INT|DEFAULT 2|精度位数|-|
|is_required|BOOLEAN|DEFAULT TRUE|是否必检|-|
|test_frequency|VARCHAR(50)|-|检验频次|-|

### 3.7 分析员资质表 (lims_analyst_qualification)

**业务模型关联：** 分析员管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|analyst_id|VARCHAR(50)|PK|分析员ID|关联检验任务表|
|analyst_name|VARCHAR(100)|NOT NULL|分析员姓名|-|
|employee_no|VARCHAR(20)|UNIQUE|工号|-|
|department|VARCHAR(100)|-|部门|-|
|position|VARCHAR(100)|-|职位|-|
|qualification_level|VARCHAR(20)|-|资质等级|-|
|certification_no|VARCHAR(100)|-|证书编号|-|
|certified_items|VARCHAR(500)|-|认证项目|-|
|certification_date|DATE|-|认证日期|-|
|expiry_date|DATE|-|到期日期|-|
|status|VARCHAR(20)|NOT NULL|状态|-|

### 3.8 检验报告表 (lims_inspection_report)

**业务模型关联：** 检验报告模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|report_id|BIGINT|PK|报告ID|-|
|request_id|VARCHAR(30)|FK|申请单号|关联申请单表|
|report_number|VARCHAR(50)|UNIQUE|报告编号|-|
|report_type|VARCHAR(50)|NOT NULL|报告类型|-|
|sample_id|VARCHAR(50)|FK|样品编码|关联样品表|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|material_id|VARCHAR(20)|FK|物料编码|关联物料表|
|overall_result|VARCHAR(20)|NOT NULL|总体结论|-|
|report_date|DATE|NOT NULL|报告日期|-|
|reviewer|VARCHAR(50)|-|审核人|-|
|review_date|DATE|-|审核日期|-|
|approve_status|VARCHAR(20)|NOT NULL|审批状态|-|
|report_file_path|VARCHAR(500)|-|报告文件路径|-|
|remarks|TEXT|-|备注|-|

---

## 四、QMS系统源表（6个表）

### 4.1 变更申请单表 (qms_change_request)

**业务模型关联：** 变更管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|request_id|VARCHAR(30)|PK|申请单号|关联变更评估表|
|request_type|VARCHAR(50)|NOT NULL|申请类型|-|
|request_title|VARCHAR(500)|NOT NULL|申请标题|-|
|request_content|TEXT|-|申请内容|-|
|request_reason|VARCHAR(500)|NOT NULL|申请原因|-|
|requester|VARCHAR(50)|NOT NULL|申请人|-|
|request_date|DATE|NOT NULL|申请日期|-|
|affected_system|VARCHAR(200)|-|影响系统|-|
|urgency_level|VARCHAR(20)|DEFAULT '普通'|紧急程度|-|
|request_status|VARCHAR(20)|NOT NULL|申请状态|-|
|attachments|VARCHAR(500)|-|附件路径|-|

### 4.2 变更影响评估表 (qms_change_assessment)

**业务模型关联：** 变更影响评估模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|assessment_id|BIGINT|PK|评估记录ID|-|
|request_id|VARCHAR(30)|FK|申请单号|关联变更申请表|
|impact_area|VARCHAR(100)|NOT NULL|影响领域|-|
|impact_description|TEXT|-|影响描述|-|
|risk_level|VARCHAR(20)|-|风险等级|-|
|affected_processes|VARCHAR(500)|-|影响流程|-|
|affected_documents|VARCHAR(500)|-|影响文件|-|
|validation_required|BOOLEAN|DEFAULT FALSE|是否需要验证|-|
|assessor|VARCHAR(50)|NOT NULL|评估人|-|
|assessment_date|DATE|NOT NULL|评估日期|-|
|assessment_conclusion|TEXT|-|评估结论|-|

### 4.3 变更实施记录表 (qms_change_implementation)

**业务模型关联：** 变更实施模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|implementation_id|BIGINT|PK|实施记录ID|-|
|request_id|VARCHAR(30)|FK|申请单号|关联变更申请表|
|implementation_plan|TEXT|-|实施计划|-|
|implementation_steps|TEXT|-|实施步骤|-|
|responsible_person|VARCHAR(50)|NOT NULL|负责人|-|
|start_date|DATE|NOT NULL|开始日期|-|
|end_date|DATE|-|结束日期|-|
|actual_completion|DATE|-|实际完成日期|-|
|implementation_status|VARCHAR(20)|NOT NULL|实施状态|-|
|completion_rate|DECIMAL(5,2)|DEFAULT 0|完成率|-|
|implementation_result|TEXT|-|实施结果|-|
|issues_encountered|TEXT|-|问题记录|-|

### 4.4 偏差报告表 (qms_deviation_report)

**业务模型关联：** 偏差管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|deviation_id|BIGINT|PK|偏差ID|-|
|deviation_number|VARCHAR(50)|UNIQUE|偏差编号|-|
|deviation_type|VARCHAR(50)|NOT NULL|偏差类型|-|
|deviation_level|VARCHAR(20)|-|偏差等级|-|
|discovery_date|DATE|NOT NULL|发现日期|-|
|discovery_person|VARCHAR(50)|NOT NULL|发现人|-|
|occurrence_location|VARCHAR(200)|NOT NULL|发生地点|-|
|deviation_description|TEXT|NOT NULL|偏差描述|-|
|immediate_action|TEXT|-|立即采取的措施|-|
|impact_assessment|TEXT|-|影响评估|-|
|investigation_result|TEXT|-|调查结果|-|
|corrective_action|TEXT|-|纠正措施|-|
|preventive_action|TEXT|-|预防措施|-|
|capa_status|VARCHAR(20)|NOT NULL|CAPA状态|-|
|responsible_person|VARCHAR(50)|NOT NULL|责任人|-|
|completion_date|DATE|-|完成日期|-|
|deviation_status|VARCHAR(20)|NOT NULL|偏差状态|-|

### 4.5 CAPA记录表 (qms_capa_record)

**业务模型关联：** CAPA管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|capa_id|BIGINT|PK|CAPA ID|-|
|capa_number|VARCHAR(50)|UNIQUE|CAPA编号|-|
|source_type|VARCHAR(50)|NOT NULL|来源类型|-|
|source_id|VARCHAR(50)|FK|来源ID|关联偏差、投诉表|
|capa_type|VARCHAR(20)|NOT NULL|CAPA类型|-|
|issue_description|TEXT|NOT NULL|问题描述|-|
|root_cause|TEXT|-|根本原因|-|
|corrective_action|TEXT|-|纠正措施|-|
|preventive_action|TEXT|-|预防措施|-|
|implementation_plan|TEXT|-|实施计划|-|
|responsible_person|VARCHAR(50)|NOT NULL|责任人|-|
|due_date|DATE|NOT NULL|到期日期|-|
|implementation_status|VARCHAR(20)|NOT NULL|实施状态|-|
|effectiveness_verification|TEXT|-|有效性验证|-|
|verification_result|VARCHAR(20)|-|验证结果|-|
|verification_date|DATE|-|验证日期|-|
|capa_status|VARCHAR(20)|NOT NULL|CAPA状态|-|

### 4.6 供应商审计表 (qms_supplier_audit)

**业务模型关联：** 供应商审计模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|audit_id|BIGINT|PK|审计ID|-|
|supplier_id|VARCHAR(20)|FK|供应商ID|关联供应商表|
|audit_number|VARCHAR(50)|UNIQUE|审计编号|-|
|audit_type|VARCHAR(50)|NOT NULL|审计类型|-|
|audit_date|DATE|NOT NULL|审计日期|-|
|audit_plan|TEXT|-|审计计划|-|
|audit_team|VARCHAR(500)|-|审计团队|-|
|audit_scope|VARCHAR(500)|-|审计范围|-|
|audit_findings|TEXT|-|审计发现|-|
|audit_score|DECIMAL(5,2)|-|审计得分|-|
|audit_grade|VARCHAR(20)|-|审计等级|-|
|audit_conclusion|TEXT|-|审计结论|-|
|improvement_requirements|TEXT|-|改进要求|-|
|follow_up_date|DATE|-|跟踪日期|-|
|audit_status|VARCHAR(20)|NOT NULL|审计状态|-|
|auditor|VARCHAR(50)|NOT NULL|审计员|-|

---

## 五、SCADA系统源表（5个表）

### 5.1 设备运行数据表 (scada_equipment_data)

**业务模型关联：** 设备运行监控模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|data_id|BIGINT|PK|数据记录ID|-|
|equipment_id|VARCHAR(20)|FK|设备编码|关联设备表|
|parameter_code|VARCHAR(50)|NOT NULL|参数编码|-|
|parameter_name|VARCHAR(200)|NOT NULL|参数名称|-|
|parameter_value|DECIMAL(15,4)|NOT NULL|参数值|-|
|unit|VARCHAR(20)|-|单位|-|
|data_timestamp|DATETIME|NOT NULL|数据时间戳|-|
|data_quality|VARCHAR(20)|DEFAULT '正常'|数据质量|-|
|alarm_status|VARCHAR(20)|DEFAULT '正常'|报警状态|-|
|collection_interval|INT|-|采集间隔(秒)|-|

### 5.2 环境监控数据表 (scada_environmental_data)

**业务模型关联：** 环境监控模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|env_id|BIGINT|PK|环境数据ID|-|
|monitoring_point|VARCHAR(100)|NOT NULL|监控点位|-|
|parameter_type|VARCHAR(50)|NOT NULL|参数类型|-|
|parameter_name|VARCHAR(200)|NOT NULL|参数名称|-|
|parameter_value|DECIMAL(10,2)|NOT NULL|参数值|-|
|unit|VARCHAR(20)|-|单位|-|
|data_timestamp|DATETIME|NOT NULL|数据时间戳|-|
|location|VARCHAR(200)|-|位置|-|
|alarm_threshold_upper|DECIMAL(10,2)|-|报警上限|-|
|alarm_threshold_lower|DECIMAL(10,2)|-|报警下限|-|
|alarm_status|VARCHAR(20)|DEFAULT '正常'|报警状态|-|
|data_status|VARCHAR(20)|DEFAULT '正常'|数据状态|-|

### 5.3 报警记录表 (scada_alarm_record)

**业务模型关联：** 报警管理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|alarm_id|BIGINT|PK|报警记录ID|-|
|alarm_code|VARCHAR(50)|NOT NULL|报警编码|-|
|alarm_name|VARCHAR(200)|NOT NULL|报警名称|-|
|alarm_level|VARCHAR(20)|NOT NULL|报警级别|-|
|alarm_type|VARCHAR(50)|-|报警类型|-|
|equipment_id|VARCHAR(20)|FK|设备编码|关联设备表|
|alarm_message|TEXT|NOT NULL|报警信息|-|
|alarm_cause|TEXT|-|报警原因|-|
|alarm_time|DATETIME|NOT NULL|报警时间|-|
|acknowledge_time|DATETIME|-|确认时间|-|
|acknowledge_person|VARCHAR(50)|-|确认人|-|
|recovery_time|DATETIME|-|恢复时间|-|
|alarm_status|VARCHAR(20)|NOT NULL|报警状态|-|
|handling_measures|TEXT|-|处理措施|-|

### 5.4 批次追踪表 (scada_batch_tracking)

**业务模型关联：** 批次追踪模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|tracking_id|BIGINT|PK|追踪记录ID|-|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|product_id|VARCHAR(20)|FK|产品编码|关联物料表|
|wo_number|VARCHAR(30)|FK|工单号|关联工单表|
|process_stage|VARCHAR(100)|NOT NULL|工序阶段|-|
|equipment_id|VARCHAR(20)|FK|设备编码|关联设备表|
|operator_id|VARCHAR(50)|FK|操作员ID|关联人员表|
|start_time|DATETIME|NOT NULL|开始时间|-|
|end_time|DATETIME|-|结束时间|-|
|quantity|DECIMAL(15,4)|NOT NULL|数量|-|
|unit|VARCHAR(20)|NOT NULL|单位|-|
|quality_status|VARCHAR(20)|DEFAULT '待检'|质量状态|-|
|data_record_time|DATETIME|NOT NULL|记录时间|-|

### 5.5 能耗监控数据表 (scada_energy_consumption)

**业务模型关联：** 能耗监控模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|energy_id|BIGINT|PK|能耗记录ID|-|
|energy_type|VARCHAR(50)|NOT NULL|能耗类型|-|
|equipment_id|VARCHAR(20)|FK|设备编码|关联设备表|
|workshop_id|VARCHAR(20)|FK|车间ID|关联车间表|
|consumption_value|DECIMAL(15,4)|NOT NULL|消耗值|-|
|unit|VARCHAR(20)|NOT NULL|单位|-|
|data_timestamp|DATETIME|NOT NULL|数据时间戳|-|
|cost_center|VARCHAR(50)|-|成本中心|-|
|price_per_unit|DECIMAL(10,4)|-|单价|-|
|total_cost|DECIMAL(15,2)|-|总成本|-|
|data_source|VARCHAR(50)|-|数据来源|-|

---

## 六、药物警戒系统源表（3个表）

### 6.1 不良反应报告表 (pv_adverse_reaction_report)

**业务模型关联：** 不良反应模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|report_id|BIGINT|PK|报告ID|-|
|report_number|VARCHAR(50)|UNIQUE|报告编号|-|
|patient_id|VARCHAR(50)|-|患者ID|-|
|product_id|VARCHAR(20)|FK|产品编码|关联物料表|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|adverse_event|TEXT|NOT NULL|不良事件描述|-|
|event_severity|VARCHAR(20)|-|事件严重程度|-|
|event_outcome|VARCHAR(50)|-|事件结果|-|
|onset_date|DATE|-|发生日期|-|
|reporter_name|VARCHAR(100)|NOT NULL|报告人姓名|-|
|reporter_contact|VARCHAR(100)|-|报告人联系方式|-|
|report_source|VARCHAR(50)|NOT NULL|报告来源|-|
|causality_assessment|VARCHAR(50)|-|因果关系评价|-|
|report_date|DATE|NOT NULL|报告日期|-|
|report_status|VARCHAR(20)|NOT NULL|报告状态|-|
|medical_confirmation|TEXT|-|医学确认|-|

### 6.2 投诉处理表 (pv_complaint_handling)

**业务模型关联：** 投诉处理模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|complaint_id|BIGINT|PK|投诉ID|-|
|complaint_number|VARCHAR(50)|UNIQUE|投诉编号|-|
|complainant_name|VARCHAR(100)|NOT NULL|投诉人姓名|-|
|complainant_contact|VARCHAR(100)|-|投诉人联系方式|-|
|product_id|VARCHAR(20)|FK|产品编码|关联物料表|
|batch_number|VARCHAR(50)|NOT NULL|批次号|-|
|complaint_content|TEXT|NOT NULL|投诉内容|-|
|complaint_category|VARCHAR(50)|-|投诉类别|-|
|complaint_date|DATE|NOT NULL|投诉日期|-|
|priority|VARCHAR(20)|DEFAULT '普通'|优先级|-|
|investigation_result|TEXT|-|调查结果|-|
|investigation_date|DATE|-|调查日期|-|
|investigation_person|VARCHAR(50)|-|调查人|-|
|resolution_method|TEXT|-|解决方法|-|
|resolution_result|VARCHAR(200)|-|解决结果|-|
|customer_satisfaction|VARCHAR(20)|-|客户满意度|-|
|complaint_status|VARCHAR(20)|NOT NULL|投诉状态|-|
|close_date|DATE|-|关闭日期|-|

### 6.3 召回记录表 (pv_product_recall)

**业务模型关联：** 产品召回模型

|字段名称|数据类型|约束|业务含义|关联关系|
|---|---|---|---|---|
|recall_id|BIGINT|PK|召回记录ID|-|
|recall_number|VARCHAR(50)|UNIQUE|召回编号|-|
|product_id|VARCHAR(20)|FK|产品编码|关联物料表|
|batch_range|VARCHAR(200)|NOT NULL|批次范围|-|
|recall_reason|TEXT|NOT NULL|召回原因|-|
|risk_assessment|TEXT|-|风险评估|-|
|recall_level|VARCHAR(20)|NOT NULL|召回级别|-|
|recall_strategy|TEXT|-|召回策略|-|
|affected_quantity|DECIMAL(15,4)|NOT NULL|影响数量|-|
|distributed_quantity|DECIMAL(15,4)|-|已分发数量|-|
|recalled_quantity|DECIMAL(15,4)|DEFAULT 0|已召回数量|-|
|recall_rate|DECIMAL(5,2)|-|召回率|-|
|initiation_date|DATE|NOT NULL|启动日期|-|
|completion_date|DATE|-|完成日期|-|
|regulatory_report_date|DATE|-|监管报告日期|-|
|recall_status|VARCHAR(20)|NOT NULL|召回状态|-|
|responsible_person|VARCHAR(50)|NOT NULL|责任人|-|
|effectiveness_evaluation|TEXT|-|有效性评价|-|

---

## 七、业务模型与源表关联关系汇总

### 7.1 物料信息模型

**关联源表：**

- erp_material_master (物料主数据表) - 主表
    
- erp_supplier_master (供应商主数据表) - 通过supplier_id关联
    

**关联关系：**

- 物料基本信息 ← erp_material_master
    
- 供应商信息 ← erp_supplier_master
    
- 物料合格率 = 合格批次数 / 总检验批次数 (通过erp_quality_inspection计算)
    

---

### 7.2 供应商信息模型

**关联源表：**

- erp_supplier_master (供应商主数据表) - 主表
    
- qms_supplier_audit (供应商审计表) - 通过supplier_id关联
    
- erp_purchase_order (采购订单表) - 通过supplier_id关联
    

**关联关系：**

- 供应商基本信息 ← erp_supplier_master
    
- 供应商审计记录 ← qms_supplier_audit
    
- 采购订单记录 ← erp_purchase_order
    
- 供应商合格率 = 合格批次数 / 总供货批次数
    

---

### 7.3 采购订单模型

**关联源表：**

- erp_purchase_order (采购订单表) - 主表
    
- erp_po_detail (采购订单明细表) - 通过po_id关联
    
- erp_supplier_master (供应商主数据表) - 通过supplier_id关联
    

**关联关系：**

- 采购订单主信息 ← erp_purchase_order
    
- 采购订单明细 ← erp_po_detail
    
- 供应商信息 ← erp_supplier_master
    
- 订单完成率 = 收货数量 / 订单数量
    

---

### 7.4 物料接收模型

**关联源表：**

- erp_purchase_receipt (采购收货单表) - 主表
    
- erp_po_detail (采购订单明细表) - 通过po_id关联
    
- erp_quality_inspection (质量检验记录表) - 通过receipt_id关联
    

**关联关系：**

- 收货记录 ← erp_purchase_receipt
    
- 采购订单信息 ← erp_po_detail
    
- 检验结果 ← erp_quality_inspection
    
- 准时交付率 = 准时交付批次数 / 总交付批次数
    

---

### 7.5 物料退货模型

**关联源表：**

- erp_purchase_return (采购退货单表) - 主表
    
- erp_purchase_receipt (采购收货单表) - 通过receipt_id关联
    
- erp_po_detail (采购订单明细表) - 通过po_detail_id关联
    

**关联关系：**

- 退货记录 ← erp_purchase_return
    
- 收货记录 ← erp_purchase_receipt
    
- 采购订单信息 ← erp_po_detail
    
- 退货率 = 退货数量 / 收货数量
    

---

### 7.6 生产订单模型

**关联源表：**

- erp_production_order (生产订单表) - 主表
    
- erp_production_bom (生产BOM表) - 通过product_id关联
    
- mes_work_order (生产工单表) - 通过wo_id关联
    

**关联关系：**

- 生产订单信息 ← erp_production_order
    
- BOM信息 ← erp_production_bom
    
- MES工单信息 ← mes_work_order
    
- 订单完成率 = 实际产量 / 计划产量
    

---

### 7.7 配方管理模型

**关联源表：**

- erp_production_bom (生产BOM表) - 主表
    
- erp_material_master (物料主数据表) - 通过material_id关联
    
- mes_material_consumption (物料消耗记录表) - 通过material_id关联
    

**关联关系：**

- BOM主信息 ← erp_production_bom
    
- 物料信息 ← erp_material_master
    
- 实际消耗记录 ← mes_material_consumption
    
- 配方偏差率 = |实际用量 - 理论用量| / 理论用量
    

---

### 7.8 库存管理模型

**关联源表：**

- erp_inventory_record (库存记录表) - 主表
    
- erp_material_master (物料主数据表) - 通过material_id关联
    
- erp_warehouse_master (仓库主数据表) - 通过warehouse_id关联
    

**关联关系：**

- 库存记录 ← erp_inventory_record
    
- 物料信息 ← erp_material_master
    
- 仓库信息 ← erp_warehouse_master
    
- 库存周转率 = 出库数量 / 平均库存
    

---

### 7.9 质量检验模型

**关联源表：**

- erp_quality_inspection (质量检验记录表) - 主表
    
- erp_material_master (物料主数据表) - 通过material_id关联
    
- lims_inspection_request (检验申请单表) - 关联
    

**关联关系：**

- 检验记录 ← erp_quality_inspection
    
- 物料信息 ← erp_material_master
    
- LIMS申请信息 ← lims_inspection_request
    
- 批次合格率 = 合格批次数 / 总检验批次数
    

---

### 7.10 不合格品管理模型

**关联源表：**

- erp_nonconforming_disposal (不合格品处理表) - 主表
    
- erp_quality_inspection (质量检验记录表) - 通过inspection_id关联
    
- erp_material_master (物料主数据表) - 通过material_id关联
    

**关联关系：**

- 不合格品处理记录 ← erp_nonconforming_disposal
    
- 检验记录 ← erp_quality_inspection
    
- 物料信息 ← erp_material_master
    
- 不合格品率 = 不合格数量 / 检验数量
    

---

### 7.11 仓库信息模型

**关联源表：**

- erp_warehouse_master (仓库主数据表) - 主表
    
- erp_inventory_record (库存记录表) - 通过warehouse_id关联
    
- erp_purchase_receipt (采购收货单表) - 通过warehouse_id关联
    

**关联关系：**

- 仓库基本信息 ← erp_warehouse_master
    
- 库存信息 ← erp_inventory_record
    
- 收货记录 ← erp_purchase_receipt
    
- 仓库利用率 = 已用容量 / 总容量
    

---

### 7.12 生产工单模型

**关联源表：**

- mes_work_order (生产工单表) - 主表
    
- erp_production_order (生产订单表) - 通过wo_id关联
    
- mes_production_line (产线配置表) - 通过line_id关联
    

**关联关系：**

- 工单基本信息 ← mes_work_order
    
- ERP订单信息 ← erp_production_order
    
- 产线信息 ← mes_production_line
    
- 工单收率 = 实际产量 / 理论产量
    

---

### 7.13 工序管理模型

**关联源表：**

- mes_process_step (工序管理表) - 主表
    
- mes_work_order (生产工单表) - 通过wo_number关联
    
- mes_equipment_master (设备主数据表) - 通过equipment_id关联
    
- mes_personnel (人员主数据表) - 通过operator_id关联
    

**关联关系：**

- 工序信息 ← mes_process_step
    
- 工单信息 ← mes_work_order
    
- 设备信息 ← mes_equipment_master
    
- 人员信息 ← mes_personnel
    
- 工序完成率 = 已完成工序数 / 总工序数
    

---

### 7.14 生产报工模型

**关联源表：**

- mes_work_report (生产报工表) - 主表
    
- mes_work_order (生产工单表) - 通过wo_number关联
    
- mes_process_step (工序管理表) - 通过process_id关联
    
- mes_personnel (人员主数据表) - 通过operator_id关联
    

**关联关系：**

- 报工记录 ← mes_work_report
    
- 工单信息 ← mes_work_order
    
- 工序信息 ← mes_process_step
    
- 人员信息 ← mes_personnel
    
- 工时效率 = 标准工时 / 实际工时
    

---

### 7.15 设备管理模型

**关联源表：**

- mes_equipment_master (设备主数据表) - 主表
    
- mes_equipment_maintenance (设备维护记录表) - 通过equipment_id关联
    
- mes_workshop (车间管理表) - 通过workshop_id关联
    

**关联关系：**

- 设备基本信息 ← mes_equipment_master
    
- 维护记录 ← mes_equipment_maintenance
    
- 车间信息 ← mes_workshop
    
- 设备OEE = 可用率 × 性能效率 × 质量率
    

---

### 7.16 设备维护模型

**关联源表：**

- mes_equipment_maintenance (设备维护记录表) - 主表
    
- mes_equipment_master (设备主数据表) - 通过equipment_id关联
    

**关联关系：**

- 维护记录 ← mes_equipment_maintenance
    
- 设备信息 ← mes_equipment_master
    
- 设备故障率 = 故障次数 / 运行时间
    
- MTBF = 总运行时间 / 故障次数
    

---

### 7.17 产线管理模型

**关联源表：**

- mes_production_line (产线配置表) - 主表
    
- mes_workshop (车间管理表) - 通过workshop_id关联
    
- mes_work_order (生产工单表) - 通过line_id关联
    

**关联关系：**

- 产线配置 ← mes_production_line
    
- 车间信息 ← mes_workshop
    
- 工单信息 ← mes_work_order
    
- 产线OEE = 产线综合效率
    

---

### 7.18 车间管理模型

**关联源表：**

- mes_workshop (车间管理表) - 主表
    
- mes_production_line (产线配置表) - 通过workshop_id关联
    
- mes_equipment_master (设备主数据表) - 通过workshop_id关联
    

**关联关系：**

- 车间信息 ← mes_workshop
    
- 产线配置 ← mes_production_line
    
- 设备信息 ← mes_equipment_master
    
- 车间产能利用率 = 实际产量 / 设计产能
    

---

### 7.19 物料消耗模型

**关联源表：**

- mes_material_consumption (物料消耗记录表) - 主表
    
- mes_work_order (生产工单表) - 通过wo_number关联
    
- erp_material_master (物料主数据表) - 通过material_id关联
    
- mes_process_step (工序管理表) - 通过process_id关联
    

**关联关系：**

- 消耗记录 ← mes_material_consumption
    
- 工单信息 ← mes_work_order
    
- 物料信息 ← erp_material_master
    
- 工序信息 ← mes_process_step
    
- 物料损耗率 = 损耗量 / 理论用量
    

---

### 7.20 人员管理模型

**关联源表：**

- mes_personnel (人员主数据表) - 主表
    
- mes_work_report (生产报工表) - 通过operator_id关联
    
- mes_process_step (工序管理表) - 通过operator_id关联
    
- mes_workshop (车间管理表) - 通过workshop_id关联
    

**关联关系：**

- 人员基本信息 ← mes_personnel
    
- 报工记录 ← mes_work_report
    
- 工序记录 ← mes_process_step
    
- 车间信息 ← mes_workshop
    
- 人员效率 = 完成工单数 / 总工时
    

---

### 7.21 工艺参数模型

**关联源表：**

- mes_process_parameter (工艺参数表) - 主表
    
- mes_work_order (生产工单表) - 通过wo_number关联
    
- mes_process_step (工序管理表) - 通过process_id关联
    
- mes_equipment_master (设备主数据表) - 通过equipment_id关联
    

**关联关系：**

- 工艺参数 ← mes_process_parameter
    
- 工单信息 ← mes_work_order
    
- 工序信息 ← mes_process_step
    
- 设备信息 ← mes_equipment_master
    
- 工艺参数Cpk = min(USL-μ, μ-LSL) / 3σ
    

---

### 7.22 检验申请模型

**关联源表：**

- lims_inspection_request (检验申请单表) - 主表
    
- lims_sample (样品管理表) - 通过sample_id关联
    
- erp_material_master (物料主数据表) - 通过material_id关联
    

**关联关系：**

- 检验申请 ← lims_inspection_request
    
- 样品信息 ← lims_sample
    
- 物料信息 ← erp_material_master
    
- 申请及时率 = 及时申请数 / 总申请数
    

---

### 7.23 检验任务模型

**关联源表：**

- lims_inspection_task (检验任务表) - 主表
    
- lims_inspection_request (检验申请单表) - 通过request_id关联
    
- lims_analyst_qualification (分析员资质表) - 通过assigned_analyst关联
    

**关联关系：**

- 检验任务 ← lims_inspection_task
    
- 检验申请 ← lims_inspection_request
    
- 分析员资质 ← lims_analyst_qualification
    
- 任务按时完成率 = 按时完成任务数 / 总任务数
    

---

### 7.24 检验结果模型

**关联源表：**

- lims_test_result (检验结果记录表) - 主表
    
- lims_inspection_task (检验任务表) - 通过task_id关联
    
- lims_quality_standard (质量标准表) - 关联
    

**关联关系：**

- 检验结果 ← lims_test_result
    
- 检验任务 ← lims_inspection_task
    
- 质量标准 ← lims_quality_standard
    
- 检验合格率 = 合格项目数 / 总检验项目数
    

---

### 7.25 样品管理模型

**关联源表：**

- lims_sample (样品管理表) - 主表
    
- erp_material_master (物料主数据表) - 通过material_id关联
    
- lims_inspection_request (检验申请单表) - 通过sample_id关联
    

**关联关系：**

- 样品信息 ← lims_sample
    
- 物料信息 ← erp_material_master
    
- 检验申请 ← lims_inspection_request
    
- 样品完好率 = 完好样品数 / 总样品数
    

---

### 7.26 质量标准模型

**关联源表：**

- lims_quality_standard (质量标准表) - 主表
    
- erp_material_master (物料主数据表) - 通过material_id关联
    
- lims_test_item (检验项目表) - 通过standard_id关联
    

**关联关系：**

- 质量标准 ← lims_quality_standard
    
- 物料信息 ← erp_material_master
    
- 检验项目 ← lims_test_item
    
- 标准覆盖率 = 有标准项目数 / 总项目数
    

---

### 7.27 检验项目模型

**关联源表：**

- lims_test_item (检验项目表) - 主表
    
- lims_quality_standard (质量标准表) - 通过standard_id关联
    

**关联关系：**

- 检验项目 ← lims_test_item
    
- 质量标准 ← lims_quality_standard
    
- 项目覆盖率 = 有标准项目数 / 总项目数
    

---

### 7.28 分析员管理模型

**关联源表：**

- lims_analyst_qualification (分析员资质表) - 主表
    
- lims_inspection_task (检验任务表) - 通过assigned_analyst关联
    

**关联关系：**

- 分析员资质 ← lims_analyst_qualification
    
- 检验任务 ← lims_inspection_task
    
- 资质符合率 = 有资质分析员数 / 总分析员数
    

---

### 7.29 检验报告模型

**关联源表：**

- lims_inspection_report (检验报告表) - 主表
    
- lims_inspection_request (检验申请单表) - 通过request_id关联
    
- lims_sample (样品管理表) - 通过sample_id关联
    

**关联关系：**

- 检验报告 ← lims_inspection_report
    
- 检验申请 ← lims_inspection_request
    
- 样品信息 ← lims_sample
    
- 报告及时率 = 及时报告数 / 总报告数
    

---

### 7.30 变更管理模型

**关联源表：**

- qms_change_request (变更申请单表) - 主表
    
- qms_change_assessment (变更影响评估表) - 通过request_id关联
    
- qms_change_implementation (变更实施记录表) - 通过request_id关联
    

**关联关系：**

- 变更申请 ← qms_change_request
    
- 影响评估 ← qms_change_assessment
    
- 实施记录 ← qms_change_implementation
    
- 变更完成率 = 已完成变更数 / 总变更数
    

---

## 八、数据流向说明

### 8.1 ERP → MES 数据流

- 生产订单信息从ERP同步到MES工单表
    
- 物料主数据从ERP同步到MES物料消耗记录
    
- 设备主数据从ERP同步到MES设备管理
    

### 8.2 MES → SCADA 数据流

- 设备编码从MES同步到SCADA监控点配置
    
- 工单信息从MES同步到SCADA批次追踪
    
- 工艺参数从MES同步到SCADA数据采集
    

### 8.3 LIMS ↔ ERP/MES 数据流

- 物料信息从ERP同步到LIMS样品管理
    
- 批次信息从MES同步到LIMS检验申请
    
- 检验结果从LIMS反馈到ERP质量模块
    

### 8.4 QMS ↔ 其他系统 数据流

- 变更申请可能影响所有系统的配置
    
- CAPA记录关联偏差、投诉来源
    
- 供应商审计结果反馈到ERP供应商主数据
    

### 8.5 药物警戒系统数据流

- 产品信息从ERP同步到药物警戒系统
    
- 批次信息从MES同步到不良反应报告
    
- 召回信息需要反馈给ERP库存管理
    

---

## 九、关键业务指标计算逻辑

### 9.1 质量指标

- **物料合格率** = 合格批次数 / 总检验批次数 × 100%
    
- **供应商合格率** = 合格供货批次数 / 总供货批次数 × 100%
    
- **批次合格率** = 合格检验项目数 / 总检验项目数 × 100%
    
- **Cpk** = min(USL-μ, μ-LSL) / 3σ
    

### 9.2 生产指标

- **收率** = 实际产量 / 理论产量 × 100%
    
- **设备OEE** = 可用率 × 性能效率 × 质量率
    
- **计划完成率** = 按时完成工单数 / 总工单数 × 100%
    
- **物料损耗率** = (实际用量 - 理论用量) / 理论用量 × 100%
    

### 9.3 供应链指标

- **准时交付率** = 准时交付批次数 / 总交付批次数 × 100%
    
- **订单完成率** = 已完成订单数 / 总订单数 × 100%
    
- **库存周转率** = 出库数量 / 平均库存 × 100%
    
- **退货率** = 退货数量 / 收货数量 × 100%
    

### 9.4 合规性指标

- **变更完成率** = 已完成变更数 / 总变更数 × 100%
    
- **CAPA关闭率** = 已关闭CAPA数 / 总CAPA数 × 100%
    
- **审计通过率** = 通过审计供应商数 / 总审计供应商数 × 100%
    
- **召回率** = 已召回数量 / 应召回数量 × 100%
    

---

## 十、附录

### 10.1 数据字典

- **状态字段取值：**
    
    - 启用状态：启用、停用
        
    - 审批状态：草稿、待审、已审、驳回
        
    - 执行状态：未开始、进行中、已完成、已取消
        

### 10.2 编码规则

- 物料编码：分类码(2位) + 流水号(6位)
    
- 批次号：日期(YYYYMMDD) + 产线码(2位) + 流水号(4位)
    
- 工单号：WO + 日期(YYYYMMDD) + 流水号(6位)