#!/usr/bin/env python3
"""
批量更新模型引用
将所有 {{ ref('old_name') }} 更新为 {{ ref('new_name') }}
"""

import re
from pathlib import Path

# 模型引用更新映射表 (旧模型名 -> 新模型名,不含 .sql 后缀)
REFERENCE_MAPPING = {
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

def update_file(file_path: Path) -> int:
    """更新单个文件中的引用"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        updates = 0
        
        # 替换所有引用
        for old_ref, new_ref in REFERENCE_MAPPING.items():
            old_pattern = f"{{{{ ref('{old_ref}') }}}}"
            new_pattern = f"{{{{ ref('{new_ref}') }}}}"
            
            if old_pattern in content:
                content = content.replace(old_pattern, new_pattern)
                count = original_content.count(old_pattern)
                updates += count
        
        # 如果有更新,写回文件
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
    models_dir = Path('qrs/models')
    
    if not models_dir.exists():
        print(f"❌ Directory not found: {models_dir}")
        return
    
    total_files = 0
    total_updates = 0
    
    # 需要更新的目录
    target_dirs = [
        models_dir / 'intermediate',
        models_dir / 'business',
        models_dir / 'reports',
    ]
    
    print("开始更新模型引用...\n")
    
    for target_dir in target_dirs:
        if not target_dir.exists():
            print(f"⚠️  目录不存在,跳过: {target_dir}")
            continue
        
        print(f"📁 处理目录: {target_dir.relative_to(models_dir.parent)}")
        
        for sql_file in target_dir.rglob('*.sql'):
            updates = update_file(sql_file)
            if updates > 0:
                total_files += 1
                total_updates += updates
                print(f"   ✅ {sql_file.name}: {updates} 处引用已更新")
        
        print()
    
    print(f"📊 更新完成:")
    print(f"   - 文件数: {total_files}")
    print(f"   - 引用数: {total_updates}")

if __name__ == '__main__':
    main()

