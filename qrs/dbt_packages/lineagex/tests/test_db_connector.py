#!/usr/bin/env python3
"""测试 DbtPostgresConnector 数据库连接器"""

import sys
import os

# 添加当前目录到 Python 路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_db_connector():
    """测试数据库连接器的基本功能"""
    print("=" * 60)
    print("测试 1: 导入 DbtPostgresConnector")
    print("=" * 60)
    
    try:
        from db_connector import DbtPostgresConnector
        print("✅ 成功导入 DbtPostgresConnector")
    except Exception as e:
        print(f"❌ 导入失败: {e}")
        return False
    
    print("\n" + "=" * 60)
    print("测试 2: 初始化数据库连接")
    print("=" * 60)
    
    try:
        # 使用 QRS 项目目录
        project_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
        print(f"项目目录: {project_dir}")
        
        connector = DbtPostgresConnector(
            profiles_dir="~/.dbt",
            project_dir=project_dir,
            target=None  # 使用默认 target
        )
        print("✅ 成功初始化数据库连接器")
        print(f"   - 连接状态: {'已连接' if connector.connection else '未连接'}")
    except Exception as e:
        print(f"❌ 初始化失败: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    print("\n" + "=" * 60)
    print("测试 3: 执行简单 SQL 查询")
    print("=" * 60)
    
    try:
        # 测试简单查询
        result = connector.execute_sql("SELECT 1 as test_column")
        print("✅ 成功执行 SQL 查询")
        print(f"   - 结果类型: {type(result)}")
        print(f"   - 结果形状: {result.shape}")
        print(f"   - 结果内容:\n{result}")
    except Exception as e:
        print(f"❌ SQL 查询失败: {e}")
        import traceback
        traceback.print_exc()
        connector.close()
        return False
    
    print("\n" + "=" * 60)
    print("测试 4: 查询数据库元数据")
    print("=" * 60)
    
    try:
        # 查询 schema 列表
        result = connector.execute_sql("""
            SELECT schema_name 
            FROM information_schema.schemata 
            WHERE schema_name IN ('raw', 'staging', 'business', 'reports')
            ORDER BY schema_name
        """)
        print("✅ 成功查询数据库元数据")
        print(f"   - 找到的 schema 数量: {len(result)}")
        if len(result) > 0:
            print(f"   - Schema 列表: {result['schema_name'].tolist()}")
    except Exception as e:
        print(f"❌ 元数据查询失败: {e}")
        import traceback
        traceback.print_exc()
        connector.close()
        return False
    
    print("\n" + "=" * 60)
    print("测试 5: 关闭数据库连接")
    print("=" * 60)
    
    try:
        connector.close()
        print("✅ 成功关闭数据库连接")
    except Exception as e:
        print(f"❌ 关闭连接失败: {e}")
        return False
    
    print("\n" + "=" * 60)
    print("✅ 所有测试通过！")
    print("=" * 60)
    return True

if __name__ == "__main__":
    success = test_db_connector()
    sys.exit(0 if success else 1)

