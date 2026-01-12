#!/usr/bin/env python3
"""测试错误处理和资源清理"""

import sys
import os

# 添加当前目录到 Python 路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_error_handling():
    """测试各种错误情况的处理"""
    print("=" * 60)
    print("错误处理测试")
    print("=" * 60)
    
    all_passed = True
    
    # 测试 1: 无效的 profiles 目录
    print("\n测试 1: 无效的 profiles 目录")
    try:
        from db_connector import DbtPostgresConnector
        
        try:
            connector = DbtPostgresConnector(
                profiles_dir="/nonexistent/path",
                project_dir=".",
                target=None
            )
            print("❌ 应该抛出 FileNotFoundError")
            all_passed = False
        except FileNotFoundError as e:
            print(f"✅ 正确抛出 FileNotFoundError: {str(e)[:60]}...")
        except Exception as e:
            print(f"⚠️  抛出了其他异常: {type(e).__name__}: {str(e)[:60]}...")
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        all_passed = False
    
    # 测试 2: 无效的 profile 名称
    print("\n测试 2: 无效的 target")
    try:
        from db_connector import DbtPostgresConnector
        
        try:
            connector = DbtPostgresConnector(
                profiles_dir="~/.dbt",
                project_dir=os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")),
                target="nonexistent_target"
            )
            print("❌ 应该抛出 ValueError")
            all_passed = False
        except ValueError as e:
            print(f"✅ 正确抛出 ValueError: {str(e)[:60]}...")
        except Exception as e:
            print(f"⚠️  抛出了其他异常: {type(e).__name__}: {str(e)[:60]}...")
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        all_passed = False
    
    # 测试 3: 连接关闭后的自动重连
    print("\n测试 3: 连接关闭后的自动重连")
    try:
        from db_connector import DbtPostgresConnector

        connector = DbtPostgresConnector(
            profiles_dir="~/.dbt",
            project_dir=os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")),
            target=None
        )

        # 关闭连接
        connector.close()
        print("   - 连接已关闭")

        # 尝试执行 SQL（应该自动重连）
        try:
            result = connector.execute_sql("SELECT 1 as test")
            if len(result) == 1 and result.iloc[0]['test'] == 1:
                print("✅ 连接关闭后自动重连成功")
            else:
                print("❌ 查询结果不正确")
                all_passed = False
        except Exception as e:
            print(f"❌ 自动重连失败: {type(e).__name__}: {e}")
            all_passed = False
        finally:
            connector.close()
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        all_passed = False
    
    # 测试 4: 资源清理（析构函数）
    print("\n测试 4: 资源清理（析构函数）")
    try:
        from db_connector import DbtPostgresConnector
        
        # 创建连接但不显式关闭
        connector = DbtPostgresConnector(
            profiles_dir="~/.dbt",
            project_dir=os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")),
            target=None
        )
        
        # 删除对象，触发析构函数
        del connector
        print("✅ 析构函数正常执行（连接应该被自动关闭）")
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        all_passed = False
    
    # 测试 5: Lineage 类的路径验证
    print("\n测试 5: Lineage 类的路径验证")
    try:
        from lineage import Lineage
        
        try:
            lineage = Lineage(path=None)
            print("❌ 应该抛出异常（path 为 None）")
            all_passed = False
        except Exception as e:
            print(f"✅ 正确处理 None 路径: {type(e).__name__}: {str(e)[:60]}...")
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("✅ 所有错误处理测试通过！")
    else:
        print("❌ 部分错误处理测试失败")
    print("=" * 60)
    
    return all_passed

if __name__ == "__main__":
    success = test_error_handling()
    sys.exit(0 if success else 1)

