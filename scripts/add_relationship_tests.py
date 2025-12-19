#!/usr/bin/env python3
"""
为 Business 层模型添加 relationships 测试
分析外键关系并自动生成测试配置
"""

import yaml
from pathlib import Path
from typing import Dict, List


# 定义外键关系映射
FOREIGN_KEY_RELATIONSHIPS = {
    # ERP 系统
    'supplier_id': ('stg_supplier_master', 'supplier_id'),
    'material_id': ('stg_material_master', 'material_id'),
    'warehouse_id': ('stg_warehouse', 'warehouse_id'),
    'location_id': ('stg_storage_location', 'location_id'),
    'purchase_order_number': ('stg_purchase_order', 'purchase_order_number'),
    'formula_id': ('stg_formula_master', 'formula_id'),
    
    # MES 系统
    'work_order_number': ('stg_work_order', 'work_order_number'),
    'workshop_id': ('stg_workshop', 'workshop_id'),
    'production_line_id': ('stg_production_line', 'production_line_id'),
    'equipment_id': ('stg_equipment', 'equipment_id'),
    'operation_id': ('stg_operation', 'operation_id'),
    'personnel_id': ('stg_personnel', 'personnel_id'),
    
    # LIMS 系统
    'request_id': ('stg_inspection_request', 'request_id'),
    'task_id': ('stg_inspection_task', 'task_id'),
    'sample_id': ('stg_sample', 'sample_id'),
    'standard_id': ('stg_quality_standard', 'standard_id'),
    'test_item_id': ('stg_test_item', 'test_item_id'),
    'analyst_id': ('stg_analyst', 'analyst_id'),
    
    # QMS 系统
    'change_id': ('stg_change_control', 'change_id'),
    'deviation_id': ('stg_deviation', 'deviation_id'),
    'capa_id': ('stg_capa', 'capa_id'),
    'audit_id': ('stg_supplier_audit', 'audit_id'),
}


def add_relationship_test(column_config: Dict, field_name: str) -> Dict:
    """为字段添加 relationship 测试"""
    if field_name not in FOREIGN_KEY_RELATIONSHIPS:
        return column_config
    
    to_model, to_field = FOREIGN_KEY_RELATIONSHIPS[field_name]
    
    # 检查是否已有 data_tests
    if 'data_tests' not in column_config:
        column_config['data_tests'] = []
    
    # 检查是否已有 relationships 测试
    has_relationship = False
    for test in column_config['data_tests']:
        if isinstance(test, dict) and 'relationships' in test:
            has_relationship = True
            break
    
    # 如果没有，添加 relationships 测试
    if not has_relationship:
        column_config['data_tests'].append({
            'relationships': {
                'to': f'ref(\'{to_model}\')',
                'field': to_field
            }
        })
    
    return column_config


def process_schema_file(schema_path: Path) -> bool:
    """处理单个 schema.yml 文件"""
    print(f"\nProcessing: {schema_path}")
    
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema_data = yaml.safe_load(f)
    
    if not schema_data or 'models' not in schema_data:
        print("  - No models found")
        return False
    
    modified = False
    
    for model in schema_data['models']:
        model_name = model.get('name', 'unknown')
        
        if 'columns' not in model:
            continue
        
        for column in model['columns']:
            field_name = column.get('name')
            if not field_name:
                continue
            
            # 检查是否是外键
            if field_name in FOREIGN_KEY_RELATIONSHIPS:
                original_tests = column.get('data_tests', [])
                column = add_relationship_test(column, field_name)
                new_tests = column.get('data_tests', [])
                
                if len(new_tests) > len(original_tests):
                    print(f"  ✓ Added relationship test for {model_name}.{field_name}")
                    modified = True
    
    if modified:
        # 写回文件
        with open(schema_path, 'w', encoding='utf-8') as f:
            yaml.dump(schema_data, f, allow_unicode=True, sort_keys=False, default_flow_style=False)
        print(f"  ✓ Updated: {schema_path}")
        return True
    else:
        print(f"  - No changes needed")
        return False


def main():
    """主函数"""
    # 获取 qrs/models/business 目录
    business_dir = Path(__file__).parent.parent / 'qrs' / 'models' / 'business'
    
    if not business_dir.exists():
        print(f"Directory not found: {business_dir}")
        return
    
    print("=== Adding Relationship Tests to Business Models ===")
    
    # 处理主 schema.yml
    main_schema = business_dir / 'schema.yml'
    if main_schema.exists():
        process_schema_file(main_schema)
    
    # 处理子目录中的 schema.yml
    for subdir in business_dir.iterdir():
        if subdir.is_dir():
            schema_file = subdir / 'schema.yml'
            if schema_file.exists():
                process_schema_file(schema_file)
    
    print("\n=== Done ===")


if __name__ == '__main__':
    main()

