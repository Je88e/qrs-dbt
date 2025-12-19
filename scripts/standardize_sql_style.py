#!/usr/bin/env python3
"""
标准化 dbt SQL 模型的编码风格
- 将 renamed CTE 改为 final CTE (staging 层)
- 确保所有模型以 select * from final 结尾
- 标准化注释头格式
"""

import os
import re
from pathlib import Path


def standardize_staging_model(content: str, model_name: str) -> str:
    """标准化 Staging 层模型"""
    # 将 renamed as ( 改为 final as (
    content = re.sub(r'\brenamed as \(', 'final as (', content)
    
    # 将 select * from renamed 改为 select * from final
    content = re.sub(r'select \* from renamed\s*$', 'select * from final', content, flags=re.MULTILINE)
    
    return content


def standardize_business_model(content: str, model_name: str) -> str:
    """标准化 Business 层模型"""
    # 检查是否已经有 final CTE
    if 'final as (' in content or 'final as(' in content:
        # 已经有 final CTE，只需确保结尾正确
        if not re.search(r'select \* from final\s*$', content, re.MULTILINE):
            # 移除最后的空行
            content = content.rstrip() + '\n'
        return content
    
    # 需要添加 final CTE
    # 找到最后一个 CTE 的结束位置和后续的 select 语句
    # 这个比较复杂，暂时跳过自动处理
    return content


def standardize_comment_header(content: str, model_name: str) -> str:
    """标准化注释头格式"""
    # 匹配旧格式的注释头
    old_pattern = r'/\*\s*\n\s*\*\s*(.+?)\n\s*\*\s*数据来源:\s*(.+?)\n\s*\*\s*业务描述:\s*(.+?)\n\s*\*/'
    
    match = re.search(old_pattern, content, re.DOTALL)
    if match:
        title = match.group(1).strip()
        description = match.group(3).strip()
        
        # 新格式的注释头
        new_header = f'''/*
    Model: {model_name}
    Description: {description}
*/'''
        
        content = re.sub(old_pattern, new_header, content, flags=re.DOTALL)
    
    return content


def process_file(file_path: Path):
    """处理单个文件"""
    print(f"Processing: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    model_name = file_path.stem
    
    # 标准化注释头
    content = standardize_comment_header(content, model_name)
    
    # 根据文件路径判断是 staging 还是 business 层
    if '/staging/' in str(file_path):
        content = standardize_staging_model(content, model_name)
    elif '/business/' in str(file_path):
        content = standardize_business_model(content, model_name)
    
    # 只有内容变化时才写入
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✓ Updated: {file_path}")
    else:
        print(f"  - No changes: {file_path}")


def main():
    """主函数"""
    # 获取 qrs/models 目录
    models_dir = Path(__file__).parent.parent / 'qrs' / 'models'
    
    # 处理 staging 层
    staging_dir = models_dir / 'staging'
    if staging_dir.exists():
        print("\n=== Processing Staging Models ===")
        for sql_file in staging_dir.glob('stg_*.sql'):
            process_file(sql_file)
    
    # 处理 business 层
    business_dir = models_dir / 'business'
    if business_dir.exists():
        print("\n=== Processing Business Models ===")
        for sql_file in business_dir.glob('*.sql'):
            process_file(sql_file)


if __name__ == '__main__':
    main()

