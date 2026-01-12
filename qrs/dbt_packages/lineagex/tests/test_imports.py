#!/usr/bin/env python3
"""测试所有模块的导入"""

import sys
import os

# 添加当前目录到 Python 路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """测试所有模块的导入"""
    print("=" * 60)
    print("模块导入测试")
    print("=" * 60)
    
    modules_to_test = [
        ("db_connector", "DbtPostgresConnector"),
        ("utils", "dbt_preprocess_sql, dbt_produce_json, dbt_find_column"),
        ("column_lineage", "ColumnLineage"),
        ("lineage", "Lineage"),
    ]
    
    all_passed = True
    
    for module_name, items in modules_to_test:
        print(f"\n测试导入: {module_name}")
        try:
            if module_name == "db_connector":
                from db_connector import DbtPostgresConnector
                print(f"  ✅ 成功导入 DbtPostgresConnector")
            elif module_name == "utils":
                from utils import dbt_preprocess_sql, dbt_produce_json, dbt_find_column
                print(f"  ✅ 成功导入 dbt_preprocess_sql, dbt_produce_json, dbt_find_column")
            elif module_name == "column_lineage":
                from column_lineage import ColumnLineage
                print(f"  ✅ 成功导入 ColumnLineage")
            elif module_name == "lineage":
                from lineage import Lineage
                print(f"  ✅ 成功导入 Lineage")
        except Exception as e:
            print(f"  ❌ 导入失败: {e}")
            import traceback
            traceback.print_exc()
            all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("✅ 所有模块导入测试通过！")
    else:
        print("❌ 部分模块导入失败")
    print("=" * 60)
    
    return all_passed

if __name__ == "__main__":
    success = test_imports()
    sys.exit(0 if success else 1)

