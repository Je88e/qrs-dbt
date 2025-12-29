#!/usr/bin/env python3
"""
验证 DBT 物化策略配置
检查 dbt_project.yml 中的物化策略是否正确配置
"""

import yaml
from pathlib import Path


def load_dbt_project():
    """加载 dbt_project.yml"""
    project_file = Path(__file__).parent.parent / 'qrs' / 'dbt_project.yml'
    with open(project_file, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def verify_materialization_config(config):
    """验证物化策略配置"""
    print("=" * 60)
    print("DBT 物化策略配置验证")
    print("=" * 60)
    
    models_config = config.get('models', {}).get('qrs', {})
    
    # 检查 Staging 层
    staging_config = models_config.get('staging', {})
    staging_mat = staging_config.get('+materialized', 'unknown')
    print(f"\n✓ Staging 层: {staging_mat}")
    assert staging_mat == 'view', f"Staging 层应该是 view, 当前是 {staging_mat}"
    
    # 检查 Intermediate 层
    intermediate_config = models_config.get('intermediate', {})
    intermediate_mat = intermediate_config.get('+materialized', 'unknown')
    print(f"✓ Intermediate 层: {intermediate_mat}")
    assert intermediate_mat == 'view', f"Intermediate 层应该是 view, 当前是 {intermediate_mat}"
    
    # 检查 Business 层
    business_config = models_config.get('business', {})
    business_default_mat = business_config.get('+materialized', 'unknown')
    print(f"\n✓ Business 层默认: {business_default_mat}")
    
    # 检查维度表
    print("\n维度表 (应该是 view):")
    dim_tables = [
        'dim_suppliers', 'dim_materials', 'dim_warehouses',
        'dim_quality_standards', 'dim_test_items', 'dim_analysts',
        'dim_workshops', 'dim_production_lines', 'dim_equipment',
        'dim_personnel', 'dim_samples'
    ]
    
    for dim_table in dim_tables:
        mat = business_config.get(dim_table, {}).get('+materialized', 'not_configured')
        status = "✓" if mat == 'view' else "✗"
        print(f"  {status} {dim_table}: {mat}")
    
    # 检查事实表
    print("\n事实表 (应该是 table):")
    fct_tables = [
        'fct_purchase_orders', 'fct_material_receipts', 'fct_material_returns',
        'fct_work_orders', 'fct_inspection_requests', 'fct_inspection_tasks',
        'fct_inspection_results', 'fct_inspection_reports'
    ]
    
    for fct_table in fct_tables:
        mat = business_config.get(fct_table, {}).get('+materialized', 'not_configured')
        status = "✓" if mat == 'table' else "✗"
        print(f"  {status} {fct_table}: {mat}")
    
    # 检查 Reports 层
    reports_config = models_config.get('reports', {})
    reports_mat = reports_config.get('+materialized', 'unknown')
    print(f"\n✓ Reports 层: {reports_mat}")
    assert reports_mat == 'table', f"Reports 层应该是 table, 当前是 {reports_mat}"
    
    print("\n" + "=" * 60)
    print("验证完成!")
    print("=" * 60)


def main():
    """主函数"""
    try:
        config = load_dbt_project()
        verify_materialization_config(config)
    except Exception as e:
        print(f"错误: {e}")
        return 1
    
    return 0


if __name__ == '__main__':
    exit(main())

