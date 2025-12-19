#!/usr/bin/env python3
"""
批量更新 business 模型中的 Seeds 引用为 Staging 引用
"""
import os
import re
from pathlib import Path

# 定义引用映射表
REFERENCE_MAPPINGS = {
    # ERP 系统
    "{{ ref('erp_purchase_order') }}": "{{ ref('stg_purchase_order') }}",
    "{{ ref('erp_purchase_order_detail') }}": "{{ ref('stg_purchase_order_detail') }}",
    "{{ ref('erp_material_receipt') }}": "{{ ref('stg_material_receipt') }}",
    "{{ ref('erp_material_return') }}": "{{ ref('stg_material_return') }}",
    "{{ ref('erp_material_master') }}": "{{ ref('stg_material_master') }}",
    "{{ ref('erp_supplier_master') }}": "{{ ref('stg_supplier_master') }}",
    "{{ ref('erp_formula_master') }}": "{{ ref('stg_formula_master') }}",
    "{{ ref('erp_formula_detail') }}": "{{ ref('stg_formula_detail') }}",
    "{{ ref('erp_inventory') }}": "{{ ref('stg_inventory') }}",
    "{{ ref('erp_inventory_transaction') }}": "{{ ref('stg_inventory_transaction') }}",
    "{{ ref('erp_warehouse') }}": "{{ ref('stg_warehouse') }}",
    "{{ ref('erp_storage_location') }}": "{{ ref('stg_storage_location') }}",
    
    # MES 系统
    "{{ ref('mes_work_order') }}": "{{ ref('stg_work_order') }}",
    "{{ ref('mes_operation') }}": "{{ ref('stg_operation') }}",
    "{{ ref('mes_work_order_operation') }}": "{{ ref('stg_work_order_operation') }}",
    "{{ ref('mes_production_report') }}": "{{ ref('stg_production_report') }}",
    "{{ ref('mes_equipment') }}": "{{ ref('stg_equipment') }}",
    "{{ ref('mes_equipment_maintenance') }}": "{{ ref('stg_equipment_maintenance') }}",
    "{{ ref('mes_production_line') }}": "{{ ref('stg_production_line') }}",
    "{{ ref('mes_workshop') }}": "{{ ref('stg_workshop') }}",
    "{{ ref('mes_material_consumption') }}": "{{ ref('stg_material_consumption') }}",
    "{{ ref('mes_personnel') }}": "{{ ref('stg_personnel') }}",
    
    # LIMS 系统
    "{{ ref('lims_inspection_request') }}": "{{ ref('stg_inspection_request') }}",
    "{{ ref('lims_inspection_task') }}": "{{ ref('stg_inspection_task') }}",
    "{{ ref('lims_inspection_result') }}": "{{ ref('stg_inspection_result') }}",
    "{{ ref('lims_sample') }}": "{{ ref('stg_sample') }}",
    "{{ ref('lims_quality_standard') }}": "{{ ref('stg_quality_standard') }}",
    "{{ ref('lims_test_item') }}": "{{ ref('stg_test_item') }}",
    "{{ ref('lims_analyst') }}": "{{ ref('stg_analyst') }}",
    "{{ ref('lims_inspection_report') }}": "{{ ref('stg_inspection_report') }}",
    
    # QMS 系统
    "{{ ref('qms_change_control') }}": "{{ ref('stg_change_control') }}",
    "{{ ref('qms_change_impact') }}": "{{ ref('stg_change_impact') }}",
    "{{ ref('qms_change_implementation') }}": "{{ ref('stg_change_implementation') }}",
    "{{ ref('qms_deviation') }}": "{{ ref('stg_deviation') }}",
    "{{ ref('qms_capa') }}": "{{ ref('stg_capa') }}",
    "{{ ref('qms_supplier_audit') }}": "{{ ref('stg_supplier_audit') }}",
    
    # SCADA 系统
    "{{ ref('scada_equipment_data') }}": "{{ ref('stg_equipment_data') }}",
    "{{ ref('scada_environment_data') }}": "{{ ref('stg_environment_data') }}",
    "{{ ref('scada_alarm') }}": "{{ ref('stg_alarm') }}",
    "{{ ref('scada_batch_tracking') }}": "{{ ref('stg_batch_tracking') }}",
    "{{ ref('scada_energy_consumption') }}": "{{ ref('stg_energy_consumption') }}",
    
    # PV 系统
    "{{ ref('pv_adverse_event') }}": "{{ ref('stg_adverse_event') }}",
    "{{ ref('pv_complaint') }}": "{{ ref('stg_complaint') }}",
    "{{ ref('pv_product_recall') }}": "{{ ref('stg_product_recall') }}",
}

def update_file(file_path):
    """更新单个文件中的引用"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    updated_count = 0
    
    # 替换所有引用
    for old_ref, new_ref in REFERENCE_MAPPINGS.items():
        if old_ref in content:
            content = content.replace(old_ref, new_ref)
            updated_count += 1
    
    # 如果有更新,写回文件
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return updated_count
    
    return 0

def main():
    """主函数"""
    business_dir = Path('qrs/models/business')

    if not business_dir.exists():
        print(f"❌ Directory not found: {business_dir}")
        return

    total_files = 0
    total_updates = 0
    all_files = list(business_dir.rglob('*.sql'))

    print(f"Found {len(all_files)} SQL files in {business_dir}")

    # 遍历所有 SQL 文件
    for sql_file in all_files:
        updates = update_file(sql_file)
        if updates > 0:
            total_files += 1
            total_updates += updates
            print(f"✅ Updated {sql_file.relative_to(business_dir)}: {updates} references")
        else:
            # 检查文件是否包含任何旧引用
            with open(sql_file, 'r', encoding='utf-8') as f:
                content = f.read()
                if any(old_ref in content for old_ref in REFERENCE_MAPPINGS.keys()):
                    print(f"⚠️  File has old refs but not updated: {sql_file.name}")

    print(f"\n📊 Summary:")
    print(f"   - Files updated: {total_files}")
    print(f"   - Total references updated: {total_updates}")

if __name__ == '__main__':
    main()

