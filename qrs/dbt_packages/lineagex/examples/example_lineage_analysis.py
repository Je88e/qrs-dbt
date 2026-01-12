#!/usr/bin/env python3
"""
output.json 使用示例
演示如何使用血缘数据进行各种分析
"""

import json
from typing import List, Dict, Set


def load_lineage_data(file_path: str = 'output.json') -> Dict:
    """加载血缘数据"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def example_1_basic_info(data: Dict):
    """示例 1: 基本信息统计"""
    print("=" * 60)
    print("示例 1: 基本信息统计")
    print("=" * 60)
    
    total = len(data)
    models = sum(1 for v in data.values() if v.get('is_model', False))
    sources = total - models
    
    print(f"总表/模型数: {total}")
    print(f"  - dbt 模型: {models}")
    print(f"  - 源表: {sources}")
    
    # 统计各层模型数量
    staging = sum(1 for k in data.keys() if k.startswith('model.qrs.stg_'))
    intermediate = sum(1 for k in data.keys() if k.startswith('model.qrs.int_'))
    dimensions = sum(1 for k in data.keys() if k.startswith('model.qrs.dim_'))
    facts = sum(1 for k in data.keys() if k.startswith('model.qrs.fct_'))
    snapshots = sum(1 for k in data.keys() if k.startswith('snapshot.qrs.'))
    
    print(f"\n模型分层:")
    print(f"  - Staging: {staging}")
    print(f"  - Intermediate: {intermediate}")
    print(f"  - Dimensions: {dimensions}")
    print(f"  - Facts: {facts}")
    print(f"  - Snapshots: {snapshots}")


def example_2_impact_analysis(data: Dict, table_name: str):
    """示例 2: 影响分析 - 查找下游依赖"""
    print("\n" + "=" * 60)
    print(f"示例 2: 影响分析 - {table_name} 的下游依赖")
    print("=" * 60)
    
    if table_name not in data:
        print(f"❌ 表 {table_name} 不存在")
        return
    
    downstream = data[table_name].get('downstream_tables', [])
    
    if not downstream:
        print(f"✅ {table_name} 没有下游依赖（终端表）")
    else:
        print(f"⚠️  修改 {table_name} 将影响以下 {len(downstream)} 个表:")
        for i, table in enumerate(downstream, 1):
            print(f"  {i}. {table}")


def example_3_column_lineage(data: Dict, table_name: str, column_name: str):
    """示例 3: 列级血缘追踪"""
    print("\n" + "=" * 60)
    print(f"示例 3: 列级血缘 - {table_name}.{column_name}")
    print("=" * 60)
    
    if table_name not in data:
        print(f"❌ 表 {table_name} 不存在")
        return
    
    columns = data[table_name].get('columns', {})
    if column_name not in columns:
        print(f"❌ 列 {column_name} 不存在")
        print(f"可用列: {', '.join(list(columns.keys())[:5])}...")
        return
    
    sources = columns[column_name]
    
    if sources == ['']:
        print(f"✅ {column_name} 是源列（原始数据）")
    else:
        print(f"✅ {column_name} 来源于以下列:")
        for i, source in enumerate(sources, 1):
            print(f"  {i}. {source}")


def example_4_upstream_path(data: Dict, table_name: str):
    """示例 4: 上游依赖路径"""
    print("\n" + "=" * 60)
    print(f"示例 4: 上游依赖路径 - {table_name}")
    print("=" * 60)
    
    if table_name not in data:
        print(f"❌ 表 {table_name} 不存在")
        return
    
    def get_all_upstream(name: str, visited: Set[str] = None) -> List[str]:
        """递归获取所有上游依赖"""
        if visited is None:
            visited = set()
        if name in visited:
            return []
        visited.add(name)
        
        result = []
        tables = data.get(name, {}).get('tables', [])
        
        for table in tables:
            if table and table != '':
                result.append(table)
                result.extend(get_all_upstream(table, visited))
        
        return result
    
    upstream = get_all_upstream(table_name)
    
    if not upstream:
        print(f"✅ {table_name} 没有上游依赖（源表）")
    else:
        print(f"✅ {table_name} 的完整上游依赖链 ({len(upstream)} 个表):")
        for i, table in enumerate(upstream, 1):
            is_model = data.get(table, {}).get('is_model', False)
            type_str = "模型" if is_model else "源表"
            print(f"  {i}. {table} ({type_str})")


def example_5_find_complex_columns(data: Dict):
    """示例 5: 查找复杂计算列（多个来源）"""
    print("\n" + "=" * 60)
    print("示例 5: 查找复杂计算列（来源 >= 2 个列）")
    print("=" * 60)
    
    complex_columns = []
    
    for table_name, info in data.items():
        if not info.get('is_model', False):
            continue
        
        columns = info.get('columns', {})
        for col_name, sources in columns.items():
            if len(sources) >= 2 and sources != ['']:
                complex_columns.append({
                    'table': table_name,
                    'column': col_name,
                    'sources': sources
                })
    
    print(f"找到 {len(complex_columns)} 个复杂计算列\n")
    
    # 显示前 5 个
    for i, item in enumerate(complex_columns[:5], 1):
        print(f"{i}. {item['table']}.{item['column']}")
        print(f"   来源: {', '.join(item['sources'])}")


def main():
    """主函数"""
    print("=" * 60)
    print("output.json 血缘数据分析示例")
    print("=" * 60)
    
    # 加载数据
    data = load_lineage_data()
    
    # 示例 1: 基本信息
    example_1_basic_info(data)
    
    # 示例 2: 影响分析
    example_2_impact_analysis(data, 'raw.lims_analyst')
    
    # 示例 3: 列级血缘
    example_3_column_lineage(data, 'model.qrs.fct_adverse_events', 'processing_days')
    
    # 示例 4: 上游依赖路径
    example_4_upstream_path(data, 'model.qrs.fct_adverse_events')
    
    # 示例 5: 查找复杂计算列
    example_5_find_complex_columns(data)
    
    print("\n" + "=" * 60)
    print("分析完成！")
    print("=" * 60)


if __name__ == "__main__":
    main()

