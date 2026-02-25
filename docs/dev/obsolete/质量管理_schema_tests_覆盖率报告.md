# schema tests 覆盖率报告

覆盖率口径：以 schema.yml 中该模型已声明的列为基准，统计“带至少1条 data_tests/tests 的列占比”。

| 模型 | 已声明列数 | 有测试列数 | 覆盖率 | 关键测试类型 |
|---|---:|---:|---:|---|
| fct_quality_test_results | 21 | 21 | 100.0% | accepted_values, not_null, relationships, unique |
| fct_batch_process_parameters | 26 | 26 | 100.0% | accepted_values, not_null, relationships, unique |
| dim_materials | 11 | 11 | 100.0% | not_null, unique |
| int_production__operation_windows | 8 | 8 | 100.0% | accepted_values, not_null, relationships |
| int_quality__process_capability_v2 | 12 | 12 | 100.0% | not_null |

总体：78/78（100.0%）
