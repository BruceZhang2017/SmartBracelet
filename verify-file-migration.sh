#!/bin/bash

# WatchProtocolSDK 文件迁移验证脚本
# 功能：验证源代码文件是否正确添加到 Framework Target

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 统计变量
TOTAL_FILES=0
ADDED_FILES=0
MISSING_FILES=0

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 标题
echo ""
echo "========================================="
echo "  文件迁移验证工具"
echo "========================================="
echo ""

# 1. 检查项目文件
if [ ! -f "SmartBracelet.xcodeproj/project.pbxproj" ]; then
    print_error "未找到项目配置文件"
    exit 1
fi

# 2. 定义需要检查的文件列表
print_section "检查文件 Target Membership"

# Core 文件
CORE_FILES=(
    "XGZTBlueToothManager.swift"
    "XGZTBusinessHandler.swift"
    "XGZTCommands.swift"
    "XGZTDeviceManager.swift"
    "XGZTCommandStateManager.swift"
    "XGZTConnectionStateManager.swift"
)

# Models 文件
MODELS_FILES=(
    "XGZTSwitchDevice.swift"
    "DatabaseManager.swift"
)

# Utils 文件
UTILS_FILES=(
    "XLogger.swift"
)

# 检查函数
check_file_in_target() {
    local filename=$1
    local category=$2

    TOTAL_FILES=$((TOTAL_FILES + 1))

    # 在 project.pbxproj 中查找文件
    if ! grep -q "$filename" "SmartBracelet.xcodeproj/project.pbxproj"; then
        print_error "[$category] $filename - 文件未找到在项目中"
        MISSING_FILES=$((MISSING_FILES + 1))
        return 1
    fi

    # 检查文件是否属于 WatchProtocolSDK Target
    # 这个检查比较复杂，简化为检查文件是否在项目中被引用
    local file_found=false

    # 获取文件的引用 ID
    local file_ref=$(grep -B5 "$filename" "SmartBracelet.xcodeproj/project.pbxproj" | grep "fileRef" | head -1 | sed 's/.*= \(.*\) .*/\1/')

    if [ -n "$file_ref" ]; then
        # 检查这个引用是否在 WatchProtocolSDK 的 PBXBuildFile 中
        if grep -q "$file_ref" "SmartBracelet.xcodeproj/project.pbxproj"; then
            print_success "[$category] $filename"
            ADDED_FILES=$((ADDED_FILES + 1))
            file_found=true
        fi
    fi

    if [ "$file_found" = false ]; then
        print_warning "[$category] $filename - 可能未添加到 WatchProtocolSDK Target"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
}

# 检查 Core 文件
print_info "检查 Core 文件 (6个):"
for file in "${CORE_FILES[@]}"; do
    check_file_in_target "$file" "Core"
done

echo ""
print_info "检查 Models 文件 (2个):"
for file in "${MODELS_FILES[@]}"; do
    check_file_in_target "$file" "Models"
done

echo ""
print_info "检查 Utils 文件 (1个):"
for file in "${UTILS_FILES[@]}"; do
    check_file_in_target "$file" "Utils"
done

# 3. 检查源文件是否实际存在
print_section "检查源文件是否存在"

SOURCE_DIR="SmartBracelet/huaxin/WatchProtocol"

for file in "${CORE_FILES[@]}" "${MODELS_FILES[@]}" "${UTILS_FILES[@]}"; do
    if [ -f "$SOURCE_DIR/$file" ]; then
        print_success "✓ $SOURCE_DIR/$file"
    else
        print_error "✗ $SOURCE_DIR/$file 文件不存在"
    fi
done

# 4. 统计报告
print_section "验证报告"

echo ""
echo "文件迁移统计："
echo "  📊 总文件数: $TOTAL_FILES"
echo "  ✅ 已添加: $ADDED_FILES"
echo "  ❌ 缺失: $MISSING_FILES"
echo ""

if [ $MISSING_FILES -eq 0 ]; then
    print_success "所有文件都已正确添加到项目中！"
    echo ""
    echo "下一步："
    echo "  1. 在 Xcode 中验证文件的 Target Membership"
    echo "  2. 确认每个文件都勾选了 WatchProtocolSDK"
    echo "  3. 尝试编译 WatchProtocolSDK Scheme"
    echo "  4. 记录编译错误（预期会有错误）"
else
    print_warning "有 $MISSING_FILES 个文件可能未正确添加"
    echo ""
    echo "建议："
    echo "  1. 在 Xcode 中检查这些文件的 Target Membership"
    echo "  2. 手动勾选 WatchProtocolSDK Target"
    echo "  3. 参考 '阶段2-迁移代码到Framework.md' 重新操作"
fi

echo ""
echo "========================================="
echo ""

# 5. 提供编译命令
print_info "编译测试命令："
echo ""
echo "  xcodebuild -workspace SmartBracelet.xcworkspace \\"
echo "    -scheme WatchProtocolSDK \\"
echo "    -sdk iphonesimulator \\"
echo "    clean build"
echo ""

exit 0
