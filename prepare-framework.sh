#!/bin/bash

# WatchProtocolSDK Framework 准备脚本
# 功能：自动化一些准备工作

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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
    echo -e "ℹ️  $1"
}

# 标题
echo "========================================="
echo "  WatchProtocolSDK Framework 准备工具"
echo "========================================="
echo ""

# 1. 检查 Xcode
print_info "检查 Xcode 版本..."
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_success "Xcode 已安装: $XCODE_VERSION"
else
    print_error "未找到 Xcode，请先安装 Xcode"
    exit 1
fi

# 2. 检查 CocoaPods
print_info "检查 CocoaPods..."
if command -v pod &> /dev/null; then
    POD_VERSION=$(pod --version)
    print_success "CocoaPods 已安装: $POD_VERSION"
else
    print_warning "未找到 CocoaPods"
    read -p "是否安装 CocoaPods? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo gem install cocoapods
        print_success "CocoaPods 安装完成"
    else
        print_warning "跳过 CocoaPods 安装"
    fi
fi

# 3. 检查 Git 状态
print_info "检查 Git 状态..."
if [ -d ".git" ]; then
    # 检查是否有未提交的更改
    if [[ -n $(git status -s) ]]; then
        print_warning "有未提交的更改"
        git status -s
        echo ""
        read -p "是否创建提交? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "准备创建 WatchProtocolSDK framework"
            print_success "已创建提交"
        fi
    else
        print_success "工作区干净"
    fi

    # 创建新分支
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    print_info "当前分支: $CURRENT_BRANCH"

    read -p "是否创建新分支 'feature/watchprotocol-framework'? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout -b feature/watchprotocol-framework 2>/dev/null || git checkout feature/watchprotocol-framework
        print_success "已切换到新分支"
    fi
else
    print_warning "当前目录不是 Git 仓库"
fi

# 4. 备份 Podfile
print_info "备份 Podfile..."
if [ -f "Podfile" ]; then
    cp Podfile Podfile.backup
    print_success "Podfile 已备份到 Podfile.backup"

    # 检查 Podfile 中是否已包含 WatchProtocolSDK target
    if grep -q "target 'WatchProtocolSDK'" Podfile; then
        print_success "Podfile 中已包含 WatchProtocolSDK target"
    else
        print_warning "Podfile 中未找到 WatchProtocolSDK target"
        print_info "请手动添加以下内容到 Podfile:"
        echo ""
        echo "target 'WatchProtocolSDK' do"
        echo "  pod 'RealmSwift', '~> 10.0'"
        echo "end"
        echo ""
    fi
else
    print_warning "未找到 Podfile"
fi

# 5. 检查必要文件
print_info "检查必要文件..."
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
        print_success "✓ $file"
    else
        print_error "✗ $file 未找到"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    print_success "所有必要文件都存在"
else
    print_error "缺少 $MISSING_FILES 个文件"
    exit 1
fi

# 6. 创建 Framework 目录结构（占位符）
print_info "准备 Framework 目录结构..."
echo "
Framework 目录结构规划：

WatchProtocolSDK/
├── Core/
│   ├── XGZTBlueToothManager.swift
│   ├── XGZTBusinessHandler.swift
│   ├── XGZTCommands.swift
│   ├── XGZTDeviceManager.swift
│   ├── XGZTCommandStateManager.swift
│   └── XGZTConnectionStateManager.swift
│
├── Models/
│   ├── XGZTSwitchDevice.swift
│   └── DatabaseManager.swift
│
├── Utils/
│   └── XLogger.swift
│
└── Public/
    ├── WatchProtocolSDK.h
    └── WPPublicAPI.swift
"

# 7. 生成 Podfile 建议
print_info "生成 Podfile 配置建议..."
cat > Podfile.framework.example << 'EOF'
# WatchProtocolSDK Framework Podfile 配置示例
# 将以下内容添加到你的 Podfile 中

platform :ios, '12.0'
use_frameworks!

# 主项目 Target
target 'SmartBracelet' do
  # 现有依赖...
  pod 'RealmSwift', '~> 10.0'
  # ...
end

# Framework Target（新增）
target 'WatchProtocolSDK' do
  pod 'RealmSwift', '~> 10.0'
end

# Framework 测试 Target（如果创建了测试）
target 'WatchProtocolSDKTests' do
  pod 'RealmSwift', '~> 10.0'
end
EOF

print_success "已生成 Podfile.framework.example"

# 8. 总结
echo ""
echo "========================================="
echo "  准备工作完成"
echo "========================================="
echo ""
print_success "准备工作已完成，接下来请："
echo ""
echo "1. 打开 Xcode: SmartBracelet.xcodeproj"
echo "2. 按照 WatchProtocolFramework创建指南.md 的步骤操作"
echo "3. 使用 WatchProtocolSDK-Checklist.md 跟踪进度"
echo ""
print_info "相关文档："
echo "  - WatchProtocolFramework创建指南.md    （详细步骤）"
echo "  - WatchProtocolSDK-Checklist.md        （检查清单）"
echo "  - Podfile.framework.example            （Podfile 配置示例）"
echo ""
print_warning "重要提示："
echo "  - 在 Xcode 中创建 Framework Target 后，需要手动移动文件"
echo "  - 记得更新 Podfile 并运行 'pod install'"
echo "  - 遇到问题请查看创建指南的'常见问题'章节"
echo ""
