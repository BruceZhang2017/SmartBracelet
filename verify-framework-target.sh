#!/bin/bash

# WatchProtocolSDK Framework 创建验证脚本
# 功能：验证 Framework Target 是否正确创建和配置

set -e  # 遇到错误继续执行，只报告问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计变量
PASSED=0
FAILED=0
WARNINGS=0

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    PASSED=$((PASSED + 1))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    FAILED=$((FAILED + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
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
echo "  WatchProtocolSDK Framework 验证工具"
echo "========================================="
echo ""

# 1. 检查项目文件
print_section "1. 项目文件检查"

if [ -f "SmartBracelet.xcworkspace/contents.xcworkspacedata" ]; then
    print_success "找到 .xcworkspace 文件（CocoaPods 已集成）"
else
    print_warning "未找到 .xcworkspace 文件，可能未运行 pod install"
fi

if [ -f "SmartBracelet.xcodeproj/project.pbxproj" ]; then
    print_success "找到项目配置文件"
else
    print_error "未找到项目配置文件"
    exit 1
fi

# 2. 检查 Framework Target 是否存在
print_section "2. Framework Target 检查"

if grep -q "WatchProtocolSDK" "SmartBracelet.xcodeproj/project.pbxproj"; then
    print_success "在项目中找到 WatchProtocolSDK Target"

    # 检查是否是 Framework 类型
    if grep -q "com.apple.product-type.framework" "SmartBracelet.xcodeproj/project.pbxproj"; then
        print_success "WatchProtocolSDK 类型为 Framework"
    else
        print_error "WatchProtocolSDK 不是 Framework 类型"
    fi
else
    print_error "未找到 WatchProtocolSDK Target，请先在 Xcode 中创建"
    exit 1
fi

# 3. 检查 Podfile 配置
print_section "3. CocoaPods 配置检查"

if [ -f "Podfile" ]; then
    print_success "找到 Podfile"

    if grep -q "target 'WatchProtocolSDK'" Podfile; then
        print_success "Podfile 中已配置 WatchProtocolSDK target"

        if grep -q "pod 'RealmSwift'" Podfile; then
            print_success "Podfile 中已添加 RealmSwift 依赖"
        else
            print_warning "Podfile 中未找到 RealmSwift 依赖"
        fi
    else
        print_error "Podfile 中未配置 WatchProtocolSDK target"
    fi
else
    print_error "未找到 Podfile"
fi

# 4. 检查 Pods 是否安装
print_section "4. Pod 依赖安装检查"

if [ -d "Pods" ]; then
    print_success "Pods 目录存在"

    if [ -d "Pods/RealmSwift" ]; then
        print_success "RealmSwift 已安装"

        # 检查版本
        if [ -f "Podfile.lock" ]; then
            REALM_VERSION=$(grep -A 1 "RealmSwift" Podfile.lock | grep -v "RealmSwift" | head -1 | tr -d ' ')
            print_info "RealmSwift 版本: $REALM_VERSION"
        fi
    else
        print_warning "RealmSwift 未安装，请运行 'pod install'"
    fi
else
    print_warning "Pods 目录不存在，请运行 'pod install'"
fi

# 5. 检查必要文件是否存在
print_section "5. 源代码文件检查"

REQUIRED_FILES=(
    "SmartBracelet/huaxin/WatchProtocol/XGZTBlueToothManager.swift"
    "SmartBracelet/huaxin/WatchProtocol/XGZTBusinessHandler.swift"
    "SmartBracelet/huaxin/WatchProtocol/XGZTCommands.swift"
    "SmartBracelet/huaxin/WatchProtocol/XGZTDeviceManager.swift"
    "SmartBracelet/huaxin/WatchProtocol/XGZTCommandStateManager.swift"
    "SmartBracelet/huaxin/WatchProtocol/XGZTConnectionStateManager.swift"
    "SmartBracelet/huaxin/WatchProtocol/XGZTSwitchDevice.swift"
    "SmartBracelet/huaxin/WatchProtocol/DatabaseManager.swift"
    "SmartBracelet/huaxin/WatchProtocol/XLogger.swift"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ $(basename $file)"
    else
        print_error "✗ $file 未找到"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    print_info "所有源代码文件都存在"
fi

# 6. 检查文档文件
print_section "6. 文档文件检查"

DOC_FILES=(
    "WatchProtocolFramework创建指南.md"
    "WatchProtocolSDK-Checklist.md"
    "Xcode操作步骤-创建Framework.md"
    "WatchProtocolSDK.podspec"
)

for file in "${DOC_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ $file"
    else
        print_warning "✗ $file 未找到"
    fi
done

# 7. 检查 Build Settings（需要已创建 Target）
print_section "7. Build Settings 检查"

print_info "检查关键配置（需要手动在 Xcode 中验证）："
echo ""
echo "  请在 Xcode 中确认以下设置："
echo "  ├─ iOS Deployment Target: 12.0"
echo "  ├─ Build Libraries for Distribution: YES"
echo "  ├─ Defines Module: YES"
echo "  ├─ Skip Install: NO"
echo "  └─ Swift Language Version: Swift 5"
echo ""

# 8. 检查系统框架（部分检查）
print_section "8. 系统框架依赖"

print_info "需要在 Xcode 的 Link Binary With Libraries 中添加："
echo "  ├─ Foundation.framework"
echo "  ├─ CoreBluetooth.framework"
echo "  └─ UIKit.framework"
echo ""

# 9. 生成检查报告
print_section "验证报告"

echo ""
echo "检查完成统计："
echo "  ✅ 通过: $PASSED"
echo "  ❌ 失败: $FAILED"
echo "  ⚠️  警告: $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        print_success "所有检查通过！可以继续下一步"
        echo ""
        echo "建议的下一步操作："
        echo "  1. 在 Xcode 中打开项目（使用 .xcworkspace）"
        echo "  2. 选择 WatchProtocolSDK Scheme"
        echo "  3. 按 ⌘+B 编译测试"
        echo "  4. 参考 'Xcode操作步骤-创建Framework.md' 继续配置"
    else
        print_warning "检查通过，但有 $WARNINGS 个警告需要注意"
        echo ""
        echo "请查看上面的警告信息并处理"
    fi
else
    print_error "检查未通过，有 $FAILED 个错误需要修复"
    echo ""
    echo "建议："
    echo "  1. 查看上面的错误信息"
    echo "  2. 参考 'Xcode操作步骤-创建Framework.md' 进行修复"
    echo "  3. 修复后重新运行此脚本验证"
fi

echo ""

# 10. 提供快速操作建议
if [ ! -d "Pods" ] || [ ! -d "Pods/RealmSwift" ]; then
    print_info "快速修复命令："
    echo "  pod install"
    echo ""
fi

if [ ! -f "SmartBracelet.xcworkspace/contents.xcworkspacedata" ]; then
    print_info "运行以下命令集成 CocoaPods："
    echo "  pod install"
    echo "  open SmartBracelet.xcworkspace"
    echo ""
fi

echo "========================================="
echo ""

exit 0
