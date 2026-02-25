## 1) stg_capa

- seed：qrs/seeds/qms_capa.csv
- staging：[stg_capa.sql](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/staging/stg_capa.sql)

| 字段名 | 差异类型 | 来源说明 / 映射关系 | 处理结论 |
|---|---|---|---|
| capa_id | 缺失源字段 | 已标准化为 source_event_id（trim/nullif） | 不补录 |
| capa_code | 缺失源字段 | 已标准化为 event_code（trim/nullif） | 不补录 |
| capa_title | 缺失源字段 | 已标准化为 event_title（trim/nullif） | 不补录 |
| capa_type | 缺失源字段 | 已标准化为 event_subtype（trim/nullif） | 不补录 |
| description | 缺失源字段 | 已标准化为 event_description（trim/nullif） | 不补录 |
| root_cause_analysis | 缺失源字段 | 已标准化为 root_cause_raw（trim/nullif） | 不补录 |
| planned_completion | 缺失源字段 | 已标准化为 planned_completion_date（::date） | 不补录 |
| actual_completion | 缺失源字段 | 已标准化为 actual_completion_date（::date） | 不补录 |
| status | 缺失源字段 | 已标准化为 status_raw（trim/nullif） | 不补录 |
| _airbyte_extracted_at | 缺失源字段 | 已标准化为 loaded_at（trim/nullif ::timestamptz） | 不补录 |
| snowflake_id | 冗余字段 | generate_snowflake_id() 生成 | 保留 |
| source_system | 冗余字段 | 常量 'qms' | 保留 |
| event_type | 冗余字段 | 常量 'capa' | 保留 |
| source_event_id | 冗余字段 | 由 capa_id 标准化得到 | 保留 |
| event_code | 冗余字段 | 由 capa_code 标准化得到 | 保留 |
| event_title | 冗余字段 | 由 capa_title 标准化得到 | 保留 |
| event_subtype | 冗余字段 | 由 capa_type 标准化得到 | 保留 |
| event_description | 冗余字段 | 由 description 标准化得到 | 保留 |
| root_cause_raw | 冗余字段 | 由 root_cause_analysis 标准化得到 | 保留 |
| planned_completion_date | 冗余字段 | 由 planned_completion 标准化得到 | 保留 |
| actual_completion_date | 冗余字段 | 由 actual_completion 标准化得到 | 保留 |
| status_raw | 冗余字段 | 由 status 标准化得到 | 保留 |
| loaded_at | 冗余字段 | 由 _airbyte_extracted_at 标准化得到 | 保留 |

结论：stg_capa 为统一质量事件标准字段口径；源字段以映射方式表达，不新增重复原字段。

---

## 2) qms_deviation → stg_deviation

- seed：qrs/seeds/qms_deviation.csv
- staging：[stg_deviation.sql](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/staging/stg_deviation.sql)

| 字段名 | 差异类型 | 来源说明 / 映射关系 | 处理结论 |
|---|---|---|---|
| deviation_id | 缺失源字段 | 已标准化为 source_event_id（trim/nullif） | 不补录 |
| deviation_code | 缺失源字段 | 已标准化为 event_code（trim/nullif） | 不补录 |
| deviation_title | 缺失源字段 | 已标准化为 event_title（trim/nullif） | 不补录 |
| deviation_type | 缺失源字段 | 已标准化为 event_subtype（trim/nullif） | 不补录 |
| deviation_category | 缺失源字段 | 已标准化为 event_category（trim/nullif） | 不补录 |
| description | 缺失源字段 | 已标准化为 event_description（trim/nullif） | 不补录 |
| root_cause | 缺失源字段 | 已标准化为 root_cause_raw（trim/nullif） | 不补录 |
| status | 缺失源字段 | 已标准化为 status_raw（trim/nullif） | 不补录 |
| _airbyte_extracted_at | 缺失源字段 | 已标准化为 loaded_at（trim/nullif ::timestamptz） | 不补录 |
| snowflake_id | 冗余字段 | generate_snowflake_id() 生成 | 保留 |
| source_system | 冗余字段 | 常量 'qms' | 保留 |
| event_type | 冗余字段 | 常量 'deviation' | 保留 |
| source_event_id | 冗余字段 | 由 deviation_id 标准化得到 | 保留 |
| event_code | 冗余字段 | 由 deviation_code 标准化得到 | 保留 |
| event_title | 冗余字段 | 由 deviation_title 标准化得到 | 保留 |
| event_subtype | 冗余字段 | 由 deviation_type 标准化得到 | 保留 |
| event_category | 冗余字段 | 由 deviation_category 标准化得到 | 保留 |
| event_description | 冗余字段 | 由 description 标准化得到 | 保留 |
| root_cause_raw | 冗余字段 | 由 root_cause 标准化得到 | 保留 |
| status_raw | 冗余字段 | 由 status 标准化得到 | 保留 |
| loaded_at | 冗余字段 | 由 _airbyte_extracted_at 标准化得到 | 保留 |

结论：stg_deviation 为统一质量事件标准字段口径；源字段以映射方式表达，不新增重复原字段。

---

## 3) qms_change_control → stg_change_control

- seed：qrs/seeds/qms_change_control.csv
- staging：[stg_change_control.sql](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/staging/stg_change_control.sql)

| 字段名 | 差异类型 | 来源说明 / 映射关系 | 处理结论 |
|---|---|---|---|
| change_id | 缺失源字段 | 已标准化为 source_event_id（trim/nullif） | 不补录 |
| change_code | 缺失源字段 | 已标准化为 event_code（trim/nullif） | 不补录 |
| change_title | 缺失源字段 | 已标准化为 event_title（trim/nullif） | 不补录 |
| change_type | 缺失源字段 | 已标准化为 event_subtype（trim/nullif） | 不补录 |
| change_category | 缺失源字段 | 已标准化为 event_category（trim/nullif） | 不补录 |
| change_description | 缺失源字段 | 已标准化为 event_description（trim/nullif） | 不补录 |
| priority | 缺失源字段 | 已标准化为 priority_raw（trim/nullif） | 不补录 |
| status | 缺失源字段 | 已标准化为 status_raw（trim/nullif） | 不补录 |
| planned_completion | 缺失源字段 | 已标准化为 planned_completion_date（::date） | 不补录 |
| actual_completion | 缺失源字段 | 已标准化为 actual_completion_date（::date） | 不补录 |
| _airbyte_extracted_at | 缺失源字段 | 已标准化为 loaded_at（trim/nullif ::timestamptz） | 不补录 |
| snowflake_id | 冗余字段 | generate_snowflake_id() 生成 | 保留 |
| source_system | 冗余字段 | 常量 'qms' | 保留 |
| event_type | 冗余字段 | 常量 'change_control' | 保留 |
| source_event_id | 冗余字段 | 由 change_id 标准化得到 | 保留 |
| event_code | 冗余字段 | 由 change_code 标准化得到 | 保留 |
| event_title | 冗余字段 | 由 change_title 标准化得到 | 保留 |
| event_subtype | 冗余字段 | 由 change_type 标准化得到 | 保留 |
| event_category | 冗余字段 | 由 change_category 标准化得到 | 保留 |
| event_description | 冗余字段 | 由 change_description 标准化得到 | 保留 |
| priority_raw | 冗余字段 | 由 priority 标准化得到 | 保留 |
| status_raw | 冗余字段 | 由 status 标准化得到 | 保留 |
| planned_completion_date | 冗余字段 | 由 planned_completion 标准化得到 | 保留 |
| actual_completion_date | 冗余字段 | 由 actual_completion 标准化得到 | 保留 |
| loaded_at | 冗余字段 | 由 _airbyte_extracted_at 标准化得到 | 保留 |

结论：stg_change_control 为统一质量事件标准字段口径；源字段以映射方式表达，不新增重复原字段。

---

## 4) pv_complaint → stg_complaint

- seed：qrs/seeds/pv_complaint.csv
- staging：[stg_complaint.sql](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/staging/stg_complaint.sql)

| 字段名 | 差异类型 | 来源说明 / 映射关系 | 处理结论 |
|---|---|---|---|
| complaint_id | 缺失源字段 | 已标准化为 source_event_id（trim/nullif） | 不补录 |
| complaint_code | 缺失源字段 | 已标准化为 event_code（trim/nullif） | 不补录 |
| complaint_type | 缺失源字段 | 已标准化为 event_category（trim/nullif） | 不补录 |
| complaint_source | 缺失源字段 | 已标准化为 event_source（trim/nullif） | 不补录 |
| complaint_description | 缺失源字段 | 已标准化为 event_description（trim/nullif） | 不补录 |
| priority | 缺失源字段 | 已标准化为 priority_raw（trim/nullif） | 不补录 |
| status | 缺失源字段 | 已标准化为 status_raw（trim/nullif） | 不补录 |
| contact_name | 缺失源字段 | 统一质量事件口径未纳入 | 不补录 |
| contact_phone | 缺失源字段 | 统一质量事件口径未纳入 | 不补录 |
| _airbyte_extracted_at | 缺失源字段 | 已标准化为 loaded_at（trim/nullif ::timestamptz） | 不补录 |
| snowflake_id | 冗余字段 | generate_snowflake_id() 生成 | 保留 |
| source_system | 冗余字段 | 常量 'pv' | 保留 |
| event_type | 冗余字段 | 常量 'complaint' | 保留 |
| source_event_id | 冗余字段 | 由 complaint_id 标准化得到 | 保留 |
| event_code | 冗余字段 | 由 complaint_code 标准化得到 | 保留 |
| event_category | 冗余字段 | 由 complaint_type 标准化得到 | 保留 |
| event_source | 冗余字段 | 由 complaint_source 标准化得到 | 保留 |
| event_description | 冗余字段 | 由 complaint_description 标准化得到 | 保留 |
| priority_raw | 冗余字段 | 由 priority 标准化得到 | 保留 |
| status_raw | 冗余字段 | 由 status 标准化得到 | 保留 |
| loaded_at | 冗余字段 | 由 _airbyte_extracted_at 标准化得到 | 保留 |

结论：stg_complaint 为统一质量事件标准字段口径；部分投诉联系信息不在当前统一口径中，未补录。

---

## 5) pv_product_recall → stg_product_recall

- seed：qrs/seeds/pv_product_recall.csv
- staging：[stg_product_recall.sql](file:///mnt/d/Work/NovaTech/QRS/dbt/qrs/models/staging/stg_product_recall.sql)

| 字段名 | 差异类型 | 来源说明 / 映射关系 | 处理结论 |
|---|---|---|---|
| recall_id | 缺失源字段 | 已标准化为 source_event_id（trim/nullif） | 不补录 |
| recall_code | 缺失源字段 | 已标准化为 event_code（trim/nullif） | 不补录 |
| batch_numbers | 缺失源字段 | 已标准化为 batch_numbers_raw（trim/nullif） | 不补录 |
| recall_level | 缺失源字段 | 已标准化为 recall_level_raw（trim/nullif） | 不补录 |
| recall_reason | 缺失源字段 | 已标准化为 event_description（trim/nullif） | 不补录 |
| recall_qty | 缺失源字段 | 已标准化为 recall_quantity（::numeric） | 不补录 |
| actual_return_qty | 缺失源字段 | 已标准化为 actual_return_quantity（::numeric） | 不补录 |
| status | 缺失源字段 | 已标准化为 status_raw（trim/nullif） | 不补录 |
| _airbyte_extracted_at | 缺失源字段 | 已标准化为 loaded_at（trim/nullif ::timestamptz） | 不补录 |
| snowflake_id | 冗余字段 | generate_snowflake_id() 生成 | 保留 |
| source_system | 冗余字段 | 常量 'pv' | 保留 |
| event_type | 冗余字段 | 常量 'product_recall' | 保留 |
| source_event_id | 冗余字段 | 由 recall_id 标准化得到 | 保留 |
| event_code | 冗余字段 | 由 recall_code 标准化得到 | 保留 |
| batch_numbers_raw | 冗余字段 | 由 batch_numbers 标准化得到 | 保留 |
| batch_number | 冗余字段 | 由 batch_numbers 取首个批号 split_part(',', 1) | 保留 |
| recall_level_raw | 冗余字段 | 由 recall_level 标准化得到 | 保留 |
| event_description | 冗余字段 | 由 recall_reason 标准化得到 | 保留 |
| recall_quantity | 冗余字段 | 由 recall_qty 标准化得到 | 保留 |
| actual_return_quantity | 冗余字段 | 由 actual_return_qty 标准化得到 | 保留 |
| status_raw | 冗余字段 | 由 status 标准化得到 | 保留 |
| loaded_at | 冗余字段 | 由 _airbyte_extracted_at 标准化得到 | 保留 |

结论：stg_product_recall 为统一质量事件标准字段口径；批次号拆分与数值类型转换为必要的标准化派生。
