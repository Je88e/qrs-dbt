#!/usr/bin/env python3
"""
批量重命名 Business 层模型文件
将模型重命名为 fct_ 或 dim_ 格式
"""

import os
from pathlib import Path

# 模型重命名映射表 (根据 phase2_refactoring_plan.md)
RENAME_MAPPING = {
    # ERP 系统 (7 个)
    'purchase_order.sql': 'fct_purchase_orders.sql',
    'material_receipt.sql': 'fct_material_receipts.sql',
    'material_return.sql': 'fct_material_returns.sql',
    'inventory_management.sql': 'fct_inventory.sql',
    'inventory_transaction.sql': 'fct_inventory_transactions.sql',
    'formula_management.sql': 'fct_formulas.sql',
    'warehouse_info.sql': 'dim_warehouses.sql',
    
    # MES 系统 (8 个 - 已移除 production_efficiency)
    'work_order.sql': 'fct_work_orders.sql',
    'production_report.sql': 'fct_production_reports.sql',
    'operation_management.sql': 'fct_operations.sql',
    'material_consumption.sql': 'fct_material_consumption.sql',
    'equipment_maintenance.sql': 'fct_equipment_maintenance.sql',
    'equipment_info.sql': 'dim_equipment.sql',
    'production_line_info.sql': 'dim_production_lines.sql',
    'workshop_info.sql': 'dim_workshops.sql',
    'personnel_info.sql': 'dim_personnel.sql',
    
    # LIMS 系统 (8 个 - 已移除 quality_analytics)
    'inspection_request.sql': 'fct_inspection_requests.sql',
    'inspection_task.sql': 'fct_inspection_tasks.sql',
    'inspection_result.sql': 'fct_inspection_results.sql',
    'inspection_report.sql': 'fct_inspection_reports.sql',
    'sample_management.sql': 'dim_samples.sql',
    'quality_standard.sql': 'dim_quality_standards.sql',
    'test_item_info.sql': 'dim_test_items.sql',
    'analyst_info.sql': 'dim_analysts.sql',
    
    # QMS 系统 (6 个)
    'change_control.sql': 'fct_change_controls.sql',
    'change_impact_assessment.sql': 'fct_change_impacts.sql',
    'change_implementation.sql': 'fct_change_implementations.sql',
    'deviation_management.sql': 'fct_deviations.sql',
    'capa_management.sql': 'fct_capas.sql',
    'supplier_audit.sql': 'fct_supplier_audits.sql',
    
    # SCADA 系统 (5 个)
    'equipment_monitoring.sql': 'fct_equipment_monitoring.sql',
    'environment_monitoring.sql': 'fct_environment_monitoring.sql',
    'alarm_management.sql': 'fct_alarms.sql',
    'batch_tracking.sql': 'fct_batch_tracking.sql',
    'energy_consumption.sql': 'fct_energy_consumption.sql',
    
    # PV 系统 (3 个)
    'adverse_event.sql': 'fct_adverse_events.sql',
    'complaint_handling.sql': 'fct_complaints.sql',
    'product_recall.sql': 'fct_product_recalls.sql',
}

def main():
    """主函数"""
    business_dir = Path('qrs/models/business')
    
    if not business_dir.exists():
        print(f"❌ Directory not found: {business_dir}")
        return
    
    renamed_count = 0
    skipped_count = 0
    
    print(f"开始重命名 Business 层模型文件...")
    print(f"目标目录: {business_dir}\n")
    
    for old_name, new_name in RENAME_MAPPING.items():
        old_path = business_dir / old_name
        new_path = business_dir / new_name
        
        if not old_path.exists():
            print(f"⚠️  文件不存在,跳过: {old_name}")
            skipped_count += 1
            continue
        
        if new_path.exists():
            print(f"⚠️  目标文件已存在,跳过: {new_name}")
            skipped_count += 1
            continue
        
        # 重命名文件
        old_path.rename(new_path)
        print(f"✅ {old_name} → {new_name}")
        renamed_count += 1
    
    print(f"\n📊 重命名完成:")
    print(f"   - 成功重命名: {renamed_count} 个文件")
    print(f"   - 跳过: {skipped_count} 个文件")
    print(f"   - 总计: {len(RENAME_MAPPING)} 个映射")

if __name__ == '__main__':
    main()

