#!/bin/bash
# 运行所有测试脚本

echo "=========================================="
echo "Lineagex 包迁移 - 完整测试套件"
echo "=========================================="
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 运行测试函数
run_test() {
    local test_name=$1
    local test_script=$2
    
    echo "=========================================="
    echo "运行测试: $test_name"
    echo "=========================================="
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if python "$test_script"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "✅ $test_name 通过"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "❌ $test_name 失败"
    fi
    
    echo ""
}

# 运行所有测试
run_test "数据库连接测试" "test_db_connector.py"
run_test "模块导入测试" "test_imports.py"
run_test "集成功能测试" "test_lineage_integration.py"
run_test "错误处理测试" "test_error_handling.py"
run_test "JSON 解析修复测试" "test_lineage_fix.py"

# 输出总结
echo "=========================================="
echo "测试总结"
echo "=========================================="
echo "总测试数: $TOTAL_TESTS"
echo "通过: $PASSED_TESTS"
echo "失败: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ 所有测试通过！"
    exit 0
else
    echo "❌ 有 $FAILED_TESTS 个测试失败"
    exit 1
fi

