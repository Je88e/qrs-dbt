#!/usr/bin/env python3
"""
生成 Mermaid 格式的血缘图
用于文档和可视化
"""

import json
from typing import Dict, List, Set


def load_lineage_data(file_path: str = 'output.json') -> Dict:
    """加载血缘数据"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def generate_table_lineage_mermaid(data: Dict, focus_table: str, max_depth: int = 2) -> str:
    """
    生成指定表的血缘图（Mermaid 格式）
    
    Args:
        data: 血缘数据
        focus_table: 焦点表名
        max_depth: 最大深度（上游和下游各自的深度）
    
    Returns:
        Mermaid 图定义
    """
    if focus_table not in data:
        return f"错误: 表 {focus_table} 不存在"
    
    # 收集相关的表
    related_tables = set([focus_table])
    
    # 向上追踪（上游）
    def collect_upstream(table: str, depth: int, visited: Set[str]):
        if depth >= max_depth or table in visited:
            return
        visited.add(table)
        
        if table in data:
            upstream = data[table].get('upstream_tables', [])
            for up in upstream:
                if up and up != '':
                    related_tables.add(up)
                    collect_upstream(up, depth + 1, visited)
    
    # 向下追踪（下游）
    def collect_downstream(table: str, depth: int, visited: Set[str]):
        if depth >= max_depth or table in visited:
            return
        visited.add(table)
        
        if table in data:
            downstream = data[table].get('downstream_tables', [])
            for down in downstream:
                if down and down != '':
                    related_tables.add(down)
                    collect_downstream(down, depth + 1, visited)
    
    collect_upstream(focus_table, 0, set())
    collect_downstream(focus_table, 0, set())
    
    # 生成 Mermaid 图
    lines = ["graph TD"]
    
    # 添加节点定义（带样式）
    for table in related_tables:
        if table not in data:
            continue
        
        is_model = data[table].get('is_model', False)
        display_name = table.split('.')[-1]  # 只显示表名，不显示完整路径
        
        # 根据类型设置样式
        if table == focus_table:
            # 焦点表 - 高亮
            lines.append(f'    {_sanitize_id(table)}["{display_name}"]:::focus')
        elif is_model:
            # dbt 模型
            if 'stg_' in table:
                lines.append(f'    {_sanitize_id(table)}["{display_name}"]:::staging')
            elif 'int_' in table:
                lines.append(f'    {_sanitize_id(table)}["{display_name}"]:::intermediate')
            elif 'dim_' in table:
                lines.append(f'    {_sanitize_id(table)}["{display_name}"]:::dimension')
            elif 'fct_' in table:
                lines.append(f'    {_sanitize_id(table)}["{display_name}"]:::fact')
            else:
                lines.append(f'    {_sanitize_id(table)}["{display_name}"]:::model')
        else:
            # 源表
            lines.append(f'    {_sanitize_id(table)}[("{display_name}")]:::source')
    
    # 添加边（关系）
    for table in related_tables:
        if table not in data:
            continue
        
        upstream = data[table].get('upstream_tables', [])
        for up in upstream:
            if up and up != '' and up in related_tables:
                lines.append(f'    {_sanitize_id(up)} --> {_sanitize_id(table)}')
    
    # 添加样式定义
    lines.extend([
        '',
        '    classDef focus fill:#ff6b6b,stroke:#c92a2a,stroke-width:3px,color:#fff',
        '    classDef source fill:#e3f2fd,stroke:#1976d2,stroke-width:2px',
        '    classDef staging fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px',
        '    classDef intermediate fill:#fff3e0,stroke:#e65100,stroke-width:2px',
        '    classDef dimension fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px',
        '    classDef fact fill:#fce4ec,stroke:#c2185b,stroke-width:2px',
        '    classDef model fill:#f5f5f5,stroke:#616161,stroke-width:2px'
    ])
    
    return '\n'.join(lines)


def _sanitize_id(table_name: str) -> str:
    """将表名转换为有效的 Mermaid ID"""
    return table_name.replace('.', '_').replace('-', '_')


def generate_column_lineage_mermaid(data: Dict, table: str, column: str) -> str:
    """
    生成列级血缘图（Mermaid 格式）
    
    Args:
        data: 血缘数据
        table: 表名
        column: 列名
    
    Returns:
        Mermaid 图定义
    """
    if table not in data:
        return f"错误: 表 {table} 不存在"
    
    columns = data[table].get('columns', {})
    if column not in columns:
        return f"错误: 列 {column} 不存在于表 {table}"
    
    sources = columns[column]
    
    lines = ["graph LR"]
    
    # 目标列
    target_id = f"{_sanitize_id(table)}_{column}"
    lines.append(f'    {target_id}["{table}.{column}"]:::target')
    
    # 来源列
    if sources == ['']:
        lines.append(f'    source["原始数据"]:::source')
        lines.append(f'    source --> {target_id}')
    else:
        for i, source in enumerate(sources):
            source_id = f"source_{i}"
            lines.append(f'    {source_id}["{source}"]:::source')
            lines.append(f'    {source_id} --> {target_id}')
    
    # 样式
    lines.extend([
        '',
        '    classDef target fill:#ff6b6b,stroke:#c92a2a,stroke-width:3px,color:#fff',
        '    classDef source fill:#e3f2fd,stroke:#1976d2,stroke-width:2px'
    ])
    
    return '\n'.join(lines)


if __name__ == "__main__":
    data = load_lineage_data()
    
    # 示例 1: 表级血缘
    print("=" * 60)
    print("示例 1: fct_adverse_events 的表级血缘图")
    print("=" * 60)
    mermaid = generate_table_lineage_mermaid(data, 'model.qrs.fct_adverse_events', max_depth=3)
    print(mermaid)
    
    print("\n" + "=" * 60)
    print("示例 2: processing_days 列的血缘图")
    print("=" * 60)
    mermaid = generate_column_lineage_mermaid(data, 'model.qrs.fct_adverse_events', 'processing_days')
    print(mermaid)

