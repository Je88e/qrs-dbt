#!/usr/bin/env python3
"""
为 Business 层模型添加 final CTE
确保所有模型以 select * from final 结尾
"""

import os
import re
from pathlib import Path


def add_final_cte_to_business_model(content: str) -> str:
    """为 Business 层模型添加 final CTE"""
    
    # 如果已经有 final CTE，跳过
    if re.search(r'\bfinal as \(', content, re.IGNORECASE):
        return content
    
    # 找到最后一个 CTE 的结束位置
    # 匹配模式: ) 后面跟着 select 语句
    pattern = r'(\)\s*\n\s*)(select\s+.*?from\s+\w+.*?)(\n\s*)$'
    
    match = re.search(pattern, content, re.DOTALL | re.MULTILINE)
    if not match:
        return content
    
    # 提取 select 语句
    select_statement = match.group(2).strip()
    
    # 构建新的 final CTE
    new_content = content[:match.start(2)]
    new_content += '\n-- 2. Logic CTEs: 业务逻辑处理\n'
    new_content += 'final as (\n'
    new_content += '    ' + select_statement.replace('\n', '\n    ')
    new_content += '\n)\n\n'
    new_content += '-- 3. Output: 必须选择 Final CTE\n'
    new_content += 'select * from final\n'
    
    return new_content


def process_file(file_path: Path):
    """处理单个文件"""
    print(f"Processing: {file_path.name}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 添加 final CTE
    content = add_final_cte_to_business_model(content)
    
    # 只有内容变化时才写入
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✓ Updated: {file_path.name}")
        return True
    else:
        print(f"  - No changes: {file_path.name}")
        return False


def main():
    """主函数"""
    # 获取 qrs/models/business 目录
    business_dir = Path(__file__).parent.parent / 'qrs' / 'models' / 'business'
    
    if not business_dir.exists():
        print(f"Directory not found: {business_dir}")
        return
    
    print("\n=== Processing Business Models ===")
    updated_count = 0
    total_count = 0
    
    for sql_file in sorted(business_dir.glob('*.sql')):
        total_count += 1
        if process_file(sql_file):
            updated_count += 1
    
    print(f"\n=== Summary ===")
    print(f"Total files: {total_count}")
    print(f"Updated files: {updated_count}")
    print(f"No changes: {total_count - updated_count}")


if __name__ == '__main__':
    main()

