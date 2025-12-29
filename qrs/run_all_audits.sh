#!/bin/bash

# 审计跟踪系统 - 完整审计执行脚本
# 描述: 执行所有 audit_helper 审计分析
# 作者: Data Engineering Team
# 日期: 2024-12-29

echo "================================================================================"
echo "🔍 QRS 审计跟踪系统 - 完整审计分析"
echo "================================================================================"
echo ""

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 审计结果统计
TOTAL_AUDITS=0
PASSED_AUDITS=0
FAILED_AUDITS=0

# 函数: 运行行级审计
run_row_audit() {
    local entity=$1
    echo "--------------------------------------------------------------------------------"
    echo "📊 执行行级审计: $entity"
    echo "--------------------------------------------------------------------------------"
    
    TOTAL_AUDITS=$((TOTAL_AUDITS + 1))
    
    if dbt run-operation execute_compiled_audit --args "{\"audit_file_name\": \"audit_${entity}_rows\"}"; then
        echo -e "${GREEN}✅ 行级审计通过: $entity${NC}"
        PASSED_AUDITS=$((PASSED_AUDITS + 1))
    else
        echo -e "${RED}❌ 行级审计失败: $entity${NC}"
        FAILED_AUDITS=$((FAILED_AUDITS + 1))
    fi
    
    echo ""
}

# 函数: 运行列级审计
run_column_audit() {
    local entity=$1
    echo "--------------------------------------------------------------------------------"
    echo "📊 执行列级审计: $entity"
    echo "--------------------------------------------------------------------------------"
    
    TOTAL_AUDITS=$((TOTAL_AUDITS + 1))
    
    if dbt run-operation execute_compiled_audit --args "{\"audit_file_name\": \"audit_${entity}_columns\"}"; then
        echo -e "${GREEN}✅ 列级审计通过: $entity${NC}"
        PASSED_AUDITS=$((PASSED_AUDITS + 1))
    else
        echo -e "${RED}❌ 列级审计失败: $entity${NC}"
        FAILED_AUDITS=$((FAILED_AUDITS + 1))
    fi
    
    echo ""
}

# ============================================
# 1. 采购订单审计
# ============================================
echo "🏢 ERP 系统 - 采购订单审计"
echo ""

run_row_audit "purchase_orders"
run_column_audit "purchase_orders"

# ============================================
# 2. 检验申请审计
# ============================================
echo "🔬 LIMS 系统 - 检验申请审计"
echo ""

# 注意: 需要先实现 inspection_requests 的审计宏
# run_row_audit "inspection_requests"
# run_column_audit "inspection_requests"

echo -e "${YELLOW}⚠️  检验申请审计宏尚未实现，跳过${NC}"
echo ""

# ============================================
# 3. 变更控制审计
# ============================================
echo "📋 QMS 系统 - 变更控制审计"
echo ""

# 注意: 需要先实现 change_controls 的审计宏
# run_row_audit "change_controls"
# run_column_audit "change_controls"

echo -e "${YELLOW}⚠️  变更控制审计宏尚未实现，跳过${NC}"
echo ""

# ============================================
# 审计总结
# ============================================
echo "================================================================================"
echo "📈 审计总结"
echo "================================================================================"
echo "总审计数: $TOTAL_AUDITS"
echo -e "${GREEN}通过: $PASSED_AUDITS${NC}"
echo -e "${RED}失败: $FAILED_AUDITS${NC}"
echo ""

if [ $FAILED_AUDITS -eq 0 ]; then
    echo -e "${GREEN}✅ 所有审计通过！数据一致性良好${NC}"
    exit 0
else
    echo -e "${RED}❌ 部分审计失败！请检查数据一致性${NC}"
    exit 1
fi

