#!/usr/bin/env python3
"""
更新 schema.yml 文件中的模型名称
将旧模型名更新为新的 fct_/dim_ 格式
"""

import re
from pathlib import Path

# 模型名称映射表
MODEL_NAME_MAPPING = {
    # ERP 系统
    'purchase_order': 'fct_purchase_orders',
    'material_receipt': 'fct_material_receipts',
    'material_return': 'fct_material_returns',
    'inventory_management': 'fct_inventory',
    'inventory_transaction': 'fct_inventory_transactions',
    'formula_management': 'fct_formulas',
    'warehouse_info': 'dim_warehouses',
    
    # MES 系统
    'work_order': 'fct_work_orders',
    'production_report': 'fct_production_reports',
    'operation_management': 'fct_operations',
    'material_consumption': 'fct_material_consumption',
    'equipment_maintenance': 'fct_equipment_maintenance',
    'equipment_info': 'dim_equipment',
    'production_line_info': 'dim_production_lines',
    'workshop_info': 'dim_workshops',
    'personnel_info': 'dim_personnel',
    
    # LIMS 系统
    'inspection_request': 'fct_inspection_requests',
    'inspection_task': 'fct_inspection_tasks',
    'inspection_result': 'fct_inspection_results',
    'inspection_report': 'fct_inspection_reports',
    'sample_management': 'dim_samples',
    'quality_standard': 'dim_quality_standards',
    'test_item_info': 'dim_test_items',
    'analyst_info': 'dim_analysts',
    
    # QMS 系统
    'change_control': 'fct_change_controls',
    'change_impact_assessment': 'fct_change_impacts',
    'change_implementation': 'fct_change_implementations',
    'deviation_management': 'fct_deviations',
    'capa_management': 'fct_capas',
    'supplier_audit': 'fct_supplier_audits',
    
    # SCADA 系统
    'equipment_monitoring': 'fct_equipment_monitoring',
    'environment_monitoring': 'fct_environment_monitoring',
    'alarm_management': 'fct_alarms',
    'batch_tracking': 'fct_batch_tracking',
    'energy_consumption': 'fct_energy_consumption',
    
    # PV 系统
    'adverse_event': 'fct_adverse_events',
    'complaint_handling': 'fct_complaints',
    'product_recall': 'fct_product_recalls',
}

def update_schema_file(file_path: Path) -> int:
    """更新 schema.yml 文件中的模型名称"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        updates = 0
        
        # 替换模型名称 (格式: "  - name: old_name")
        for old_name, new_name in MODEL_NAME_MAPPING.items():
            # 匹配 "  - name: old_name" 格式
            old_pattern = f"  - name: {old_name}\n"
            new_pattern = f"  - name: {new_name}\n"
            
            if old_pattern in content:
                content = content.replace(old_pattern, new_pattern)
                updates += 1
                print(f"   ✅ {old_name} → {new_name}")
        
        # 写回文件
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return updates
        
        return 0
    
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return 0

def main():
    """主函数"""
    schema_file = Path('qrs/models/business/schema.yml')
    
    if not schema_file.exists():
        print(f"❌ File not found: {schema_file}")
        return
    
    print(f"开始更新 schema.yml 文件...\n")
    print(f"文件: {schema_file}\n")
    
    updates = update_schema_file(schema_file)
    
    print(f"\n📊 更新完成:")
    print(f"   - 更新的模型名称: {updates} 个")

if __name__ == '__main__':
    main()

